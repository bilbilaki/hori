
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hori/translator/configuration/config.dart';
import 'package:hori/translator/services/text_chunker.dart';
import 'package:hori/translator/services/text_translator.dart';
import 'package:hori/translator/widgets/content_box.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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

  // Translation State
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _targetLanguageController = TextEditingController(
    text: 'Spanish',
  );
  final TranslationService _translationService = TranslationService();
  List<String> _chunks = [];
  List<String?>? _translatedChunks;
  bool _isTranslating = false;
  double _translationProgress = 0.0;
////TODO implanting usage costs based on some presets and value user input for price of input and output to culculating of usage for each task .
///TODO implanting service to get and Show user credits based on api (some prooviders support that, some of those not)
  @override
  void dispose() {
    _linesPerChunkController.dispose();
    _wordsPerChunkController.dispose();
    _charactersPerChunkController.dispose();
    _regexPatternController.dispose();
    _overlapController.dispose();
    _apiKeyController.dispose();
    _targetLanguageController.dispose();
    super.dispose();
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
////TODO  Implanting ai ocr to can support image and handwriting
///TODO finding more smart method to can with less power in platform like android add files
  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true, // Ensure bytes are available for SAF on Android
        allowCompression: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile platformFile = result.files.single;
        _fileName = platformFile.name;

        String content = '';
        final ext = (platformFile.extension ?? '').toLowerCase();

        if (ext == 'pdf') {
          if (platformFile.bytes != null) {
            content = await _extractTextFromPdfBytes(platformFile.bytes!);
          } else if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final bytes = await file.readAsString();
            content = bytes;
          } else {
            throw Exception('No readable data for selected PDF.');
          }
        } else {
          if (platformFile.path != null) {
            content = await File(platformFile.path!).readAsString();
          } else if (platformFile.bytes != null) {
            content = utf8.decode(platformFile.bytes!, allowMalformed: true);
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
        });
      }
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
            .map((entry) {
              return '--- Chunk ${entry.key + 1} ---\n${entry.value}';
            })
            .join('\n\n');
        _translatedContent = 'Ready to translate ${_chunks.length} chunks.';
        _translatedChunks = null;
        _translationProgress = 0.0;
      });
    } catch (e) {
      _showSnack('Error during chunking: $e', error: true);
    }
  }

  Future<void> _performTranslation() async {
    if (_chunks.isEmpty) {
      _showSnack('Please chunk the text before translating.', error: true);
      return;
    }
    if (_apiKeyController.text.isEmpty) {
      _showSnack('Please enter your OpenAI API Key.', error: true);
      return;
    }

    setState(() {
      _isTranslating = true;
      _translationProgress = 0.0;
      _translatedChunks = List.filled(_chunks.length, null);
      _translatedContent = 'Translating...';
    });

    _translationService.setApiKey(_apiKeyController.text);
    int completedCount = 0;
////TODO implant helper service to user can Set Some rate limit for each ai models and can save that value using shared prefs
    try {
      await _translationService.translateChunksConcurrently(
        chunks: _chunks,
        targetLanguage: _targetLanguageController.text,
        onChunkTranslated: (index, translatedChunk) {
          setState(() {
            _translatedChunks![index] = translatedChunk;
            completedCount++;
            _translationProgress = completedCount / _chunks.length;
          });
        },
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
    if (Platform.isAndroid == false) return true;

    final status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) return true;

    _showSnack(
      'Storage permission denied. Trying SAF-based save...',
      error: false,
    );
    return false;
  }

  Future<bool> saveStringToFile(String content) async {
    try {
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select where to save the .txt file',
        fileName: 'my_documentTranslated.txt', 
        type: FileType.custom,
        allowedExtensions: ['txt'], 
      );

      if (filePath == null) {
        debugPrint('File save operation cancelled by the user.');
        return false;
      }

      if (!filePath.toLowerCase().endsWith('.txt')) {
        filePath = '$filePath.txt';
      }

      final file = File(filePath);

      await file.writeAsString(content);

      debugPrint('File saved successfully to: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error saving file: $e');
      // You might want to show a user-friendly error message here, e.g., using a SnackBar
      return false;
    }
  }

  Future<void> _saveResult() async {
    // Prioritize translated content, then chunked, then original.
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
                  final String? dirPath = await FilePicker.platform
                      .getDirectoryPath();
                  if (dirPath == null) {
                    return;
                  }
                  final suggestedBase =
                      (_fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ??
                      'output');
                  String fileName = suggestedBase;

                  final PdfDocument document = PdfDocument();
                  // Add a PDF page and draw text.
                  document.pages.add().graphics.drawString(
                    contentToSave,
                    PdfStandardFont(PdfFontFamily.helvetica, 12),
                    brush: PdfSolidBrush(PdfColor(0, 0, 0)),
                    bounds: const Rect.fromLTWH(0, 0, 150, 20),
                  );
                  // Save the document.
                  File(
                    '$dirPath/$fileName.pdf',
                  ).writeAsBytes(await document.save());
                  // Dispose the document.
                  document.dispose();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Export as TXT'),
                onTap: () async {
                  final String? dirPath = await FilePicker.platform
                      .getDirectoryPath();
                  if (dirPath == null) {
                    return;
                  }
                  final suggestedBase =
                      (_fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ??
                      'output');

                  await _ensureStoragePermission(); // Proceed even if denied; SAF will handle.
                  final csvFilePath = p.join(dirPath, '$suggestedBase.txt');

                  await File(csvFilePath).writeAsString(contentToSave);

                  //   saveStringToFile(contentToSave);
                  Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter File Chunker & Translator',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: DefaultTabController(
        length: 3,
        child: Builder(
          builder: (ctx) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('File Chunker & Translator'),
                centerTitle: true,
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.description), text: 'Original'),
                    Tab(icon: Icon(Icons.segment), text: 'Chunked'),
                    Tab(icon: Icon(Icons.translate), text: 'Translated'),
                  ],
                ),
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final controls = Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: <Widget>[
                          // Controls
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        children: [
                                          FilledButton.icon(
                                            onPressed: _pickFile,
                                            icon: const Icon(Icons.folder_open),
                                            label: const Text('Select File'),
                                            style: const ButtonStyle(
                                              minimumSize:
                                                  WidgetStatePropertyAll(
                                                    Size.fromHeight(48),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _fileName ?? 'No file selected',
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: _apiKeyController,
                                            decoration: const InputDecoration(
                                              labelText: 'OpenAI API Key',
                                              prefixIcon: Icon(Icons.vpn_key),
                                            ),
                                            obscureText: true,
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller:
                                                _targetLanguageController,
                                            decoration: const InputDecoration(
                                              labelText: 'Target Language',
                                              prefixIcon: Icon(Icons.language),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _pickFile,
                                      icon: const Icon(Icons.folder_open),
                                      label: const Text('Select File'),
                                      style: const ButtonStyle(
                                        minimumSize: WidgetStatePropertyAll(
                                          Size.fromHeight(48),
                                        ),
                                      ),
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
                                    TextField(
                                      controller: _apiKeyController,
                                      decoration: const InputDecoration(
                                        labelText: 'OpenAI API Key',
                                        prefixIcon: Icon(Icons.vpn_key),
                                      ),
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _targetLanguageController,
                                      decoration: const InputDecoration(
                                        labelText: 'Target Language',
                                        prefixIcon: Icon(Icons.language),
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          const Divider(height: 24),
                          // Chunking Options
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Chunking Method:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8.0,
                                            runSpacing: 6.0,
                                            children: ChunkingMethod.values.map((
                                              method,
                                            ) {
                                              return ChoiceChip(
                                                label: Text(
                                                  method.name[0].toUpperCase() +
                                                      method.name.substring(1),
                                                ),
                                                selected:
                                                    _selectedChunkingMethod ==
                                                    method,
                                                onSelected: (selected) {
                                                  if (selected) {
                                                    setState(
                                                      () =>
                                                          _selectedChunkingMethod =
                                                              method,
                                                    );
                                                  }
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildChunkingInputs()),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Chunking Method:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 6.0,
                                      children: ChunkingMethod.values.map((
                                        method,
                                      ) {
                                        return ChoiceChip(
                                          label: Text(
                                            method.name[0].toUpperCase() +
                                                method.name.substring(1),
                                          ),
                                          selected:
                                              _selectedChunkingMethod == method,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(
                                                () => _selectedChunkingMethod =
                                                    method,
                                              );
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildChunkingInputs(),
                                  ],
                                ),
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
                                    minimumSize: WidgetStatePropertyAll(
                                      Size.fromHeight(48),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isTranslating
                                      ? null
                                      : _performTranslation,
                                  icon: const Icon(Icons.translate),
                                  label: const Text('Translate Chunks'),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            WidgetState.disabled,
                                          )) {
                                            return Colors.grey.shade400;
                                          }
                                          return Colors.green.shade600;
                                        }),
                                    foregroundColor:
                                        const WidgetStatePropertyAll(
                                          Colors.white,
                                        ),
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
                                    foregroundColor:
                                        const WidgetStatePropertyAll(
                                          Colors.white,
                                        ),
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
                                  LinearProgressIndicator(
                                    value: _translationProgress,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Translating... ${(_translationProgress * 100).toStringAsFixed(0)}%',
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );

                    final contentTabs = TabBarView(
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
                    );

                    return Column(
                      children: [
                        // 1. Give the controls a flexible portion of the screen
                        Expanded(
                          flex: 2, // You can adjust this value
                          // 2. Make the controls scrollable if they are too big for their space
                          child: SingleChildScrollView(child: controls),
                        ),
                        const Divider(height: 0),
                        // 3. Give the content tabs the remaining portion of the screen
                        Expanded(
                          flex: 3, // You can adjust this value
                          child: contentTabs,
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
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

/// Enum to define different chunking methods for text.
