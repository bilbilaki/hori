import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hori/main.dart';
import 'package:hori/translator/configuration/config.dart';
import 'package:hori/translator/interfaces/configuration_interface.dart';
import 'package:hori/translator/services/text_chunker.dart';
import 'package:hori/translator/services/text_translator.dart';
import 'package:hori/translator/widgets/content_box.dart';
import 'package:hori/translator/widgets/language_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:tiktoken/tiktoken.dart' as tk;

class ChunkerInterfaceand extends StatefulWidget {
  const ChunkerInterfaceand({super.key});

  @override
  State<ChunkerInterfaceand> createState() => _ChunkerInterfaceandState();
}

class _ChunkerInterfaceandState extends State<ChunkerInterfaceand> {
  // File and Content State
  String? _fileName;
  String _originalFileContent =
      'Select a text file to display its content here.';
  String _chunkedContent = 'Chunked content will appear here after processing.';
  String _translatedContent = 'Translated content will appear here.';

  // UI and Chunking Parameters
  ChunkingMethod _selectedChunkingMethod = ChunkingMethod.lines;
  final TextEditingController _linesPerChunkController = TextEditingController(
    text: '10',
  );
  final TextEditingController _wordsPerChunkController = TextEditingController(
    text: '100',
  );
  final TextEditingController _charactersPerChunkController =
      TextEditingController(text: '1000');
  final TextEditingController _regexPatternController = TextEditingController(
    text: r'\n\n+',
  );
  final TextEditingController _overlapController = TextEditingController(
    text: '0',
  );
  final TextEditingController _targetLanguageController = TextEditingController(
    text: selectedDialogLanguage.name,
  );

  // Translation State
  final TranslationService _translationService = TranslationService();
  late final tk.Tiktoken _enc;
  List<String> _chunks = [];
  List<String?>? _translatedChunks;
  bool _isTranslating = false;
  double _translationProgress = 0.0;

  // Live token/cost and monitor
  int _inputTokens = 0;
  int _outputTokens = 0;
  int _lastResultTokens = 0;
  double _usageCost = 0.0; // $ per 1K tokens math
  int _rpmThisMinute = 0;
  int _tpmThisMinute = 0;
  Timer? _minuteTimer;
  bool _monitoring = false;

  @override
  void initState() {
    super.initState();
    _enc = _encoderForModel(translatorConfig.modelId);
  }

  @override
  void dispose() {
    _linesPerChunkController.dispose();
    _wordsPerChunkController.dispose();
    _charactersPerChunkController.dispose();
    _regexPatternController.dispose();
    _overlapController.dispose();
    _targetLanguageController.dispose();
    _minuteTimer?.cancel();
    super.dispose();
  }

  // Tokenizer helpers
  tk.Tiktoken _encoderForModel(String modelId) {
    final String enc =
        (modelId.contains('gpt-4.1') ||
            modelId.contains('gpt-4o') ||
            modelId.contains('o1'))
        ? 'o200k_base'
        : 'cl100k_base';
    return tk.getEncoding(enc);
  }

  int _countTokens(String text) => text.isEmpty ? 0 : _enc.encode(text).length;

  void _recomputeUsageCost() {
    final double inCost = translatorConfig.inputCost;
    final double outCost = translatorConfig.outputCost;
    _usageCost =
        (_inputTokens / 1000000.0 * inCost) +
        (_outputTokens / 1000000.0 * outCost);
  }

  Future<String> _extractTextFromPdfBytes(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'pdf'],
        withData: false, // avoid loading large files into memory
        allowCompression: false,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile pf = result.files.single;
      _fileName = pf.name;

      String content = '';
      final ext = (pf.extension ?? '').toLowerCase();

      if (ext == 'pdf') {
        if (pf.bytes != null) {
          content = await _extractTextFromPdfBytes(pf.bytes!);
        } else if (pf.readStream != null) {
          // stream into bytes for PDF
          final builder = BytesBuilder();
          await for (final chunk in pf.readStream!) {
            builder.add(chunk);
          }
          content = await _extractTextFromPdfBytes(builder.takeBytes());
        } else if (pf.path != null) {
          final bytes = await File(pf.path!).readAsBytes();
          content = await _extractTextFromPdfBytes(bytes);
        } else {
          throw Exception('No readable data for selected PDF.');
        }
      } else {
        if (pf.path != null) {
          // Prefer file path when available (fast and memory-safe)
          content = await File(pf.path!).readAsString();
        } else if (pf.readStream != null) {
          // Stream-decode text safely for huge files
          content = await pf.readStream!.transform(utf8.decoder).join();
        } else if (pf.bytes != null) {
          content = utf8.decode(pf.bytes!, allowMalformed: true);
        } else {
          throw Exception('No readable data for selected text file.');
        }
      }

      setState(() {
        _originalFileContent = content;
        _chunkedContent = 'Press "Chunk Text" to process.';
        _translatedContent = 'Translate chunks to see the result.';
        _chunks = [];
        _translatedChunks = null;
        _translationProgress = 0.0;

        // Live update tokens from input immediately
        _inputTokens = _countTokens(_originalFileContent);
        _outputTokens = 0;
        _lastResultTokens = 0;
        _recomputeUsageCost();
      });
    } catch (e) {
      _showSnack('Error picking or reading file: $e', error: true);
    }
  }

  void _performChunking() {
    try {
      if (_originalFileContent.isEmpty ||
          _originalFileContent ==
              'Select a text file to display its content here.') {
        _showSnack('Please select a file first.', error: true);
        return;
      }

      _chunks = TextChunkerService.chunkText(
        originalContent: _originalFileContent,
        method: _selectedChunkingMethod,
        linesPerChunk: int.tryParse(_linesPerChunkController.text) ?? 10,
        wordsPerChunk: int.tryParse(_wordsPerChunkController.text) ?? 100,
        charactersPerChunk:
            int.tryParse(_charactersPerChunkController.text) ?? 1000,
        regexPattern: _regexPatternController.text,
        overlap: int.tryParse(_overlapController.text) ?? 0,
      );

      setState(() {
        _chunkedContent = _chunks
            .asMap()
            .entries
            .map((e) => '--- Chunk ${e.key + 1} ---\n${e.value}')
            .join('\n\n');
        _translatedContent = 'Ready to translate ${_chunks.length} chunks.';
        _translatedChunks = null;
        _translationProgress = 0.0;

        // Input tokens as sum over chunks for better accuracy
        _inputTokens = _chunks.fold<int>(0, (sum, c) => sum + _countTokens(c));
        _outputTokens = 0;
        _lastResultTokens = 0;
        _recomputeUsageCost();
      });
    } catch (e) {
      _showSnack('Error during chunking: $e', error: true);
    }
  }

  void _startMinuteMonitor() {
    _minuteTimer?.cancel();
    setState(() {
      _rpmThisMinute = 0;
      _tpmThisMinute = 0;
      _monitoring = true;
    });
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _rpmThisMinute = 0;
        _tpmThisMinute = 0;
      });
    });
  }

  void _stopMinuteMonitor() {
    _minuteTimer?.cancel();
    setState(() {
      _monitoring = false; // keep last counters visible until next run
    });
  }

 Future<void> _performTranslation() async {
    if (_chunks.isEmpty) {
      _showSnack('Please chunk the text before translating.', error: true);
      return;
    }

    setState(() {
      _isTranslating = true;
      _translationProgress = 0.0;
      _translatedChunks = List.filled(_chunks.length, null);
      _translatedContent = 'Translating...';
    });

    _translationService.setApiKey();
    _startMinuteMonitor();
       int completedCount = 0;
    try {
      await _translationService.translateChunksConcurrently(
        chunks: _chunks,
        targetLanguage: translatorConfig.outputLang,
        onChunkTranslated: (index, translatedChunk) {
          setState(() {
            _translatedChunks![index] = translatedChunk;
            completedCount++;
            _translationProgress = completedCount / _chunks.length;
          });
        }, batchSize: translatorConfig.batchN,
      );
    } catch (e) {
      _showSnack('Translation failed: $e', error: true);
    } finally {
      setState(() {
        _isTranslating = false;
        _translatedContent =
            _translatedChunks?.where((s) => s != null).join('\n\n') ??
            'Translation finished with errors.';
        if (_translatedContent.trim().isEmpty &&
            (_translatedChunks?.isNotEmpty ?? false)) {
          _translatedContent =
              'Translation finished, but content is empty. Check API key or response.';
        }
      });
    }
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) return true;
    _showSnack(
      'Storage permission denied. Trying SAF-based save...',
      error: false,
    );
    return false;
    // SAF saving handled by file_picker save dialog when permission is denied.
  }

  Future<void> _saveResult() async {
    final String contentToSave =
        _translatedContent.isNotEmpty &&
            _translatedContent != 'Translated content will appear here.'
        ? _translatedContent
        : (_chunkedContent.isNotEmpty &&
                  _chunkedContent !=
                      'Chunked content will appear here after processing.'
              ? _chunkedContent
              : _originalFileContent);

    if (contentToSave.isEmpty ||
        contentToSave == 'Select a text file to display its content here.') {
      _showSnack(
        'No content to save. Please load a file and process it.',
        error: true,
      );
      return;
    }

    final String? exportType = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export as PDF'),
                onTap: () async {
                 // ... inside the 'Export as PDF' ListTile onTap callback
final String? dirPath = await FilePicker.platform.getDirectoryPath();
if (dirPath == null) return;
final suggestedBase = (_fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'output');
final pdfPath = p.join(dirPath, '$suggestedBase.pdf');

final PdfDocument document = PdfDocument();
final PdfPage page = document.pages.add();

// Use PdfTextElement for proper text wrapping and pagination
final PdfTextElement textElement = PdfTextElement(
  text: contentToSave,
  font: PdfStandardFont(PdfFontFamily.helvetica, 12),
  brush: PdfSolidBrush(PdfColor(0, 0, 0)),
);

// Use a layout format that automatically paginates
final PdfLayoutFormat layoutFormat = PdfLayoutFormat(
  layoutType: PdfLayoutType.paginate,
);

// Draw the text element on the page
textElement.draw(
  page: page,
  bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
  format: layoutFormat,
);

// Save the document to the file
File(pdfPath).writeAsBytes(await document.save());
document.dispose();

if (mounted) Navigator.of(context).pop('pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Export as TXT'),
                onTap: () async {
                  final String? dirPath = await FilePicker.platform
                      .getDirectoryPath();
                  if (dirPath == null) return;
                  final suggestedBase =
                      (_fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ??
                      'output');
                  await _ensureStoragePermission();
                  final txtPath = p.join(dirPath, '$suggestedBase.txt');
                  await File(txtPath).writeAsString(contentToSave);
                  if (mounted) Navigator.of(context).pop('txt');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (exportType == null) return;
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _monitorBar() {
    final styleLabel = Theme.of(context).textTheme.labelSmall;
    final styleValue = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget chip(String label, String value, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.tealAccent),
              const SizedBox(width: 6),
            ],
            Text('$label ', style: styleLabel),
            Text(value, style: styleValue),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: -6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('Input tok', '$_inputTokens', icon: Icons.input),
        chip('Output tok', '$_outputTokens', icon: Icons.outbond),
        chip('Last result tok', '$_lastResultTokens', icon: Icons.history),
        chip('Usage', _usageCost.toStringAsFixed(4), icon: Icons.payments),
        chip('RPM (min)', '$_rpmThisMinute', icon: Icons.av_timer),
        chip('TPM (min)', '$_tpmThisMinute', icon: Icons.speed),
        chip(
          'Status',
          _monitoring ? 'monitoring' : 'idle',
          icon: _monitoring ? Icons.play_arrow : Icons.pause,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controls = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          // Top row: File and Config button
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select File'),
                  style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ConfigPage())),
                icon: const Icon(Icons.settings),
                label: const Text('Open Config'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _fileName ?? 'No file selected',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 12),


          ElevatedButton(
            child: Text('Target Language ${translatorConfig.outputLang}'),
            onPressed: () {
              openLanguagePickerDialog(context);
              setState(() {
                
              });
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 24),

          // Chunking options
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ChunkingMethod.values.map((method) {
                return ChoiceChip(
                  label: Text(
                    method.name[0].toUpperCase() + method.name.substring(1),
                  ),
                  selected: _selectedChunkingMethod == method,
                  onSelected: (selected) =>
                      setState(() => _selectedChunkingMethod = method),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _buildChunkingInputs(),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _performChunking,
                  icon: const Icon(Icons.cut),
                  label: const Text('Chunk Text'),
                  style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isTranslating ? null : _performTranslation,
                  icon: const Icon(Icons.translate),
                  label: const Text('Translate Chunks'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled))
                        return Colors.grey.shade600;
                      return Colors.green.shade600;
                    }),
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    minimumSize: const WidgetStatePropertyAll(
                      Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveResult,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Result'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      Colors.blue.shade600,
                    ),
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    minimumSize: const WidgetStatePropertyAll(
                      Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isTranslating)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: _translationProgress),
                  const SizedBox(height: 4),
                  Text(
                    'Translating... ${(_translationProgress * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),
          _monitorBar(),
        ],
      ),
    );

    final contentTabs = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.description), text: 'Original'),
              Tab(icon: Icon(Icons.segment), text: 'Chunked'),
              Tab(icon: Icon(Icons.translate), text: 'Translated'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ContentDisplayBox(
                  title: 'Original Content',
                  content: _originalFileContent,
                ),
                ContentDisplayBox(
                  title: 'Chunked Content (${_chunks.length} chunks)',
                  content: _chunkedContent,
                ),
                ContentDisplayBox(
                  title: 'Translated Content',
                  content: _translatedContent,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return MaterialApp(
      title: 'File Chunker & Translator',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark, // Awesome style often includes dark theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.black12,
        ),
        scaffoldBackgroundColor: Colors.black87,
        cardColor: Colors.black26, // For cards/sections
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          hintStyle: TextStyle(color: Colors.white30),
          labelStyle: TextStyle(color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.tealAccent;
            }
            return Colors.grey[600];
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.tealAccent.withOpacity(0.5);
            }
            return Colors.grey[700];
          }),
        ),
        sliderTheme: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: Colors.tealAccent,
          inactiveTrackColor: Colors.white.withOpacity(0.3),
          thumbColor: Colors.tealAccent,
          overlayColor: Colors.tealAccent.withOpacity(0.2),
          valueIndicatorColor: Colors.tealAccent,
          valueIndicatorTextStyle: TextStyle(color: Colors.black),
          showValueIndicator: ShowValueIndicator.always,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // Button background color
            foregroundColor: Colors.white, // Button text color
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('File Chunker & Translator'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Configuration',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ConfigPage())),
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 24 : 8,
                          ),
                          child: controls,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 0),
                  Expanded(flex: 2, child: contentTabs),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChunkingInputs() {
    return Column(
      children: [
        if (_selectedChunkingMethod == ChunkingMethod.lines)
          TextField(
            controller: _linesPerChunkController,
            decoration: const InputDecoration(
              labelText: 'Lines per chunk',
              prefixIcon: Icon(Icons.wrap_text),
            ),
            keyboardType: TextInputType.number,
          )
        else if (_selectedChunkingMethod == ChunkingMethod.words)
          TextField(
            controller: _wordsPerChunkController,
            decoration: const InputDecoration(
              labelText: 'Words per chunk',
              prefixIcon: Icon(Icons.format_list_bulleted),
            ),
            keyboardType: TextInputType.number,
          )
        else if (_selectedChunkingMethod == ChunkingMethod.characters)
          TextField(
            controller: _charactersPerChunkController,
            decoration: const InputDecoration(
              labelText: 'Characters per chunk',
              prefixIcon: Icon(Icons.text_increase),
            ),
            keyboardType: TextInputType.number,
          )
        else
          TextField(
            controller: _regexPatternController,
            decoration: const InputDecoration(
              labelText: 'Regex Pattern',
              prefixIcon: Icon(Icons.functions),
            ),
          ),
        const SizedBox(height: 8),
        if (_selectedChunkingMethod != ChunkingMethod.regex)
          TextField(
            controller: _overlapController,
            decoration: InputDecoration(
              labelText: 'Overlap (${_selectedChunkingMethod.name})',
              prefixIcon: const Icon(Icons.flip),
            ),
            keyboardType: TextInputType.number,
          ),
      ],
    );
  }
}
