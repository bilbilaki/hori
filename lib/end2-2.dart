import 'package:openai_dart/openai_dart.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; // Needed for Uint8List

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // New import for PDF processing

void main() {
  runApp(const ChunkerInterface());
}

class ChunkerInterface extends StatefulWidget {
  const ChunkerInterface({super.key});

  @override
  State<ChunkerInterface> createState() => _ChunkerInterfaceState();
}

class _ChunkerInterfaceState extends State<ChunkerInterface> {
  // File and Content State
  String? _fileName;
  String _originalFileContent = 'Select a text file to display its content here.';
  String _chunkedContent = 'Chunked content will appear here after processing.';
  String _translatedContent = 'Translated content will appear here.';

  // UI and Chunking Parameters
  ChunkingMethod _selectedChunkingMethod = ChunkingMethod.lines;
  final TextEditingController _linesPerChunkController = TextEditingController(text: '10');
  final TextEditingController _wordsPerChunkController = TextEditingController(text: '100');
  final TextEditingController _charactersPerChunkController = TextEditingController(text: '1000');
  final TextEditingController _regexPatternController = TextEditingController(text: r'\n\n+');
  final TextEditingController _overlapController = TextEditingController(text: '0');

  // Translation State
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _targetLanguageController = TextEditingController(text: 'Spanish');
  final TranslationService _translationService = TranslationService();
  List<String> _chunks = [];
  List<String?>? _translatedChunks;
  bool _isTranslating = false;
  double _translationProgress = 0.0;

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

  /// Extracts text from a PDF file.
  Future<String> _extractTextFromPdf(File pdfFile) async {
    try {
      final Uint8List bytes = await pdfFile.readAsBytes();
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf'], // Allow both txt and pdf
      );

      if (result != null && result.files.single.path != null) {
        PlatformFile platformFile = result.files.single;
        File file = File(platformFile.path!);
        String content;

        if (platformFile.extension?.toLowerCase() == 'pdf') {
          content = await _extractTextFromPdf(file);
        } else {
          content = await file.readAsString();
        }

        setState(() {
          _fileName = platformFile.name;
          _originalFileContent = content;
          _chunkedContent = 'Press "Chunk Text" to process.';
          _translatedContent = 'Translate chunks to see the result.';
          _chunks = [];
          _translatedChunks = null;
          _translationProgress = 0.0; // Reset progress
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking or reading file: $e');
    }
  }

  void _performChunking() {
    try {
      if (_originalFileContent.isEmpty || _originalFileContent == 'Select a text file to display its content here.') {
        _showErrorSnackBar('Please select a file first.');
        return;
      }

      _chunks = TextChunkerService.chunkText(
        originalContent: _originalFileContent,
        method: _selectedChunkingMethod,
        linesPerChunk: int.tryParse(_linesPerChunkController.text) ?? 10,
        wordsPerChunk: int.tryParse(_wordsPerChunkController.text) ?? 100,
        charactersPerChunk: int.tryParse(_charactersPerChunkController.text) ?? 1000,
        regexPattern: _regexPatternController.text,
        overlap: int.tryParse(_overlapController.text) ?? 0,
      );

      setState(() {
        _chunkedContent = _chunks.asMap().entries.map((entry) {
          return '--- Chunk ${entry.key + 1} ---\n${entry.value}';
        }).join('\n\n');
        _translatedContent = 'Ready to translate ${_chunks.length} chunks.';
        _translatedChunks = null;
        _translationProgress = 0.0;
      });
    } catch (e) {
      _showErrorSnackBar('Error during chunking: $e');
    }
  }

  Future<void> _performTranslation() async {
    if (_chunks.isEmpty) {
      _showErrorSnackBar('Please chunk the text before translating.');
      return;
    }
    if (_apiKeyController.text.isEmpty) {
      _showErrorSnackBar('Please enter your OpenAI API Key.');
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
      _showErrorSnackBar('Translation failed: $e');
    } finally {
      setState(() {
        _isTranslating = false;
        _translatedContent = _translatedChunks?.where((s) => s != null).join('\n\n') ?? 'Translation finished with errors.';
        if (_translatedContent.trim().isEmpty && (_translatedChunks?.isNotEmpty ?? false)) {
          _translatedContent = 'Translation finished, but content is empty. Check API key or response.';
        }
      });
    }
  }

  /// Saves text content as a PDF file with flow layout.
  Future<void> _saveTextAsPdf(String text, String outputPath) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Use PdfTextElement for flow layout to handle large amounts of text across pages
    final PdfTextElement textElement = PdfTextElement(
      text: text,
      font: PdfStandardFont(PdfFontFamily.helvetica, 12),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
    );

    textElement.draw(
      page: page,
      bounds: Rect.fromLTWH(
          50, 50, page.getClientSize().width - 100, page.getClientSize().height - 100), // Add margins
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate), // Enable pagination
    );

    File(outputPath).writeAsBytes(await document.save());
    document.dispose();
  }

  Future<void> _saveResult() async {
    // Prioritize translated content, then chunked, then original.
    final String contentToSave = _translatedContent.isNotEmpty && _translatedContent != 'Translated content will appear here.'
        ? _translatedContent
        : (_chunkedContent.isNotEmpty && _chunkedContent != 'Chunked content will appear here after processing.'
            ? _chunkedContent
            : _originalFileContent);

    if (contentToSave.isEmpty || contentToSave == 'Select a text file to display its content here.') {
      _showErrorSnackBar('No content to save. Please load a file and process it.');
      return;
    }

    final String? exportType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Export Format'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export as PDF'),
                onTap: () {
                  Navigator.of(context).pop('pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Export as TXT'),
                onTap: () {
                  Navigator.of(context).pop('txt');
                },
              ),
            ],
          ),
        );
      },
    );

    if (exportType == null) {
      return; // User cancelled the dialog
    }

    String? outputPath;
    String suggestedFileName = (_fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'output');

    if (exportType == 'txt') {
      outputPath = await FilePicker.platform.saveFile(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        fileName: suggestedFileName + '.txt',
      );
      if (outputPath != null) {
        try {
          await File(outputPath).writeAsString(contentToSave);
          _showErrorSnackBar('Content saved to $outputPath');
        } catch (e) {
          _showErrorSnackBar('Failed to save TXT file: $e');
        }
      } else {
        _showErrorSnackBar('Save operation cancelled.');
      }
    } else if (exportType == 'pdf') {
      outputPath = await FilePicker.platform.saveFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        fileName: suggestedFileName + '.pdf',
      );
      if (outputPath != null) {
        try {
          await _saveTextAsPdf(contentToSave, outputPath);
          _showErrorSnackBar('Content saved to $outputPath');
        } catch (e) {
          _showErrorSnackBar('Failed to save PDF file: $e');
        }
      } else {
        _showErrorSnackBar('Save operation cancelled.');
      }
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter File Chunker & Translator',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('File Chunker & Translator'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Top Control Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select File'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                        ),
                        const SizedBox(height: 8),
                        Text(_fileName ?? 'No file selected', textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
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
                          decoration: const InputDecoration(labelText: 'OpenAI API Key'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _targetLanguageController,
                          decoration: const InputDecoration(labelText: 'Target Language'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Chunking Options and Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chunking Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8.0,
                          children: ChunkingMethod.values.map((method) {
                            return ChoiceChip(
                              label: Text(method.name[0].toUpperCase() + method.name.substring(1)),
                              selected: _selectedChunkingMethod == method,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedChunkingMethod = method);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        if (_selectedChunkingMethod == ChunkingMethod.lines)
                          TextField(controller: _linesPerChunkController, decoration: const InputDecoration(labelText: 'Lines per chunk'), keyboardType: TextInputType.number)
                        else if (_selectedChunkingMethod == ChunkingMethod.words)
                          TextField(controller: _wordsPerChunkController, decoration: const InputDecoration(labelText: 'Words per chunk'), keyboardType: TextInputType.number)
                        else if (_selectedChunkingMethod == ChunkingMethod.characters)
                          TextField(controller: _charactersPerChunkController, decoration: const InputDecoration(labelText: 'Characters per chunk'), keyboardType: TextInputType.number)
                        else
                          TextField(controller: _regexPatternController, decoration: const InputDecoration(labelText: 'Regex Pattern')),
                        const SizedBox(height: 8),
                        if (_selectedChunkingMethod != ChunkingMethod.regex)
                          TextField(controller: _overlapController, decoration: InputDecoration(labelText: 'Overlap (${_selectedChunkingMethod.name})'), keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _performChunking,
                      icon: const Icon(Icons.cut),
                      label: const Text('Chunk Text'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTranslating ? null : _performTranslation,
                      icon: const Icon(Icons.translate),
                      label: const Text('Translate Chunks'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ),
                  // New "Save Result" button
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveResult,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Result'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
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
                      Text('Translating... ${(_translationProgress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              const Divider(height: 24),
              // Content Display
              Expanded(
                child: Row(
                  children: [
                    ContentDisplayBox(title: 'Original Content', content: _originalFileContent),
                    const SizedBox(width: 16),
                    ContentDisplayBox(title: 'Chunked Content (${_chunks.length} chunks)', content: _chunkedContent),
                    const SizedBox(width: 16),
                    ContentDisplayBox(title: 'Translated Content', content: _translatedContent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enum to define different chunking methods for text.
enum ChunkingMethod {
  lines,
  words,
  regex,
  characters,
}

/// Service class responsible for text chunking operations.
class TextChunkerService {
  static List<String> chunkText({
    required String originalContent,
    required ChunkingMethod method,
    int linesPerChunk = 10,
    int wordsPerChunk = 100,
    int charactersPerChunk = 500,
    String regexPattern = r'\n\n+',
    int overlap = 0,
  }) {
    if (originalContent.isEmpty) return [];

    if (overlap < 0) {
      throw ArgumentError('Overlap must be a non-negative number.');
    }

    List<String> chunks = [];

    switch (method) {
      case ChunkingMethod.lines:
        if (linesPerChunk <= 0) throw ArgumentError('Lines per chunk must be a positive number.');
        if (overlap >= linesPerChunk) throw ArgumentError('Overlap must be smaller than lines per chunk.');

        final List<String> contentLines = originalContent.split('\n');
        int step = linesPerChunk - overlap;
        if (step <= 0) step = 1; // Prevent infinite loop if overlap equals or exceeds chunk size

        for (int i = 0; i < contentLines.length; i += step) {
          int end = (i + linesPerChunk > contentLines.length) ? contentLines.length : i + linesPerChunk;
          chunks.add(contentLines.sublist(i, end).join('\n'));
          if (end == contentLines.length) break;
        }
        break;

      case ChunkingMethod.words:
        if (wordsPerChunk <= 0) throw ArgumentError('Words per chunk must be a positive number.');
        if (overlap >= wordsPerChunk) throw ArgumentError('Overlap must be smaller than words per chunk.');

        final List<String> contentWords = originalContent.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        int step = wordsPerChunk - overlap;
        if (step <= 0) step = 1;

        for (int i = 0; i < contentWords.length; i += step) {
          int end = (i + wordsPerChunk > contentWords.length) ? contentWords.length : i + wordsPerChunk;
          chunks.add(contentWords.sublist(i, end).join(' '));
          if (end == contentWords.length) break;
        }
        break;

      case ChunkingMethod.characters:
        if (charactersPerChunk <= 0) throw ArgumentError('Characters per chunk must be a positive number.');
        if (overlap >= charactersPerChunk) throw ArgumentError('Overlap must be smaller than characters per chunk.');

        final String content = originalContent;
        int step = charactersPerChunk - overlap;
        if (step <= 0) step = 1;

        for (int i = 0; i < content.length; i += step) {
          int end = (i + charactersPerChunk > content.length) ? content.length : i + charactersPerChunk;
          chunks.add(content.substring(i, end));
          if (end == content.length) break;
        }
        break;

      case ChunkingMethod.regex:
        if (regexPattern.isEmpty) throw ArgumentError('Regex pattern cannot be empty.');
        final RegExp regExp = RegExp(regexPattern);
        chunks = originalContent.split(regExp).where((s) => s.isNotEmpty).toList();
        break;
    }

    // If after chunking, no chunks were created but original content existed, add the whole content as one chunk.
    if (chunks.isEmpty && originalContent.isNotEmpty) {
      chunks.add(originalContent);
    }
    return chunks;
  }
}

/// Service for handling translation via OpenAI API.
class TranslationService {
  // A single client can handle concurrent requests.
  OpenAIClient? _client;

  // Use a setter for the API key to initialize the client.
  void setApiKey(String apiKey) {
    if (apiKey.isNotEmpty) {
      _client = OpenAIClient(apiKey: apiKey, baseUrl: "https://api.avalai.org/v1");
    } else {
      _client = null;
    }
  }

  Future<String> _translateTextChunk(String text, String targetLanguage) async {
    if (_client == null) {
      throw Exception('API Key not set. Please provide a valid OpenAI API key.');
    }
    if (text.trim().isEmpty) {
      return text; // Return empty or whitespace text as is.
    }

    final prompt = 'Translate the following text to $targetLanguage. Return only the translated text, without any introductory phrases or explanations.';

    try {
      final res = await _client!.createChatCompletion(
        request: CreateChatCompletionRequest(
          // Using a standard, reliable OpenAI model.
          model: const ChatCompletionModel.modelId('gemini-2.5-flash-lite'), // Model from user provided code
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string('$prompt\n\nText: """$text"""'),
            ),
          ],
          temperature: 0.2, // Lower temperature for more deterministic translations.
        ),
      );
      return res.choices.first.message.content?.trim() ?? '[Translation Failed: Empty Response]';
    } catch (e) {
      // Return a specific error message for this chunk.
      return '[Translation Error: ${e.toString()}]';
    }
  }

  /// Translates a list of text chunks concurrently.
  ///
  /// This method processes chunks in batches to avoid overwhelming the API and to manage memory.
  /// It's more stable than managing a complex queue of individual futures.
  Future<void> translateChunksConcurrently({
    required List<String> chunks,
    required String targetLanguage,
    required Function(int index, String translatedChunk) onChunkTranslated,
    int batchSize = 5, // Process 5 chunks at a time. Adjust based on performance.
  }) async {
    if (_client == null) {
      throw Exception('API Key not set before starting translation.');
    }

    for (int i = 0; i < chunks.length; i += batchSize) {
      // Determine the end of the current batch.
      int end = (i + batchSize > chunks.length) ? chunks.length : i + batchSize;
      List<String> batchChunks = chunks.sublist(i, end);

      // Create a list of translation futures for the current batch.
      List<Future<String>> batchFutures = batchChunks
          .map((chunk) => _translateTextChunk(chunk, targetLanguage))
          .toList();

      // Wait for all translations in the current batch to complete.
      List<String> translatedBatch = await Future.wait(batchFutures);

      // Report progress for each completed chunk in the batch.
      for (int j = 0; j < translatedBatch.length; j++) {
        onChunkTranslated(i + j, translatedBatch[j]);
      }
    }
  }
}

class ContentDisplayBox extends StatelessWidget {
  final String title;
  final String content;

  const ContentDisplayBox({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: SingleChildScrollView(child: Text(content, style: const TextStyle(fontFamily: 'monospace'))),
            ),
          ),
        ],
      ),
    );
  }
}