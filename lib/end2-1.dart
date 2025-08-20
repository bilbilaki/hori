import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Required for Clipboard



class FileContent {
  final String fileName;
  final String filePath;
  String content; // Made mutable for editing
  final String fileExtension;
  bool isSelected; // Added for selection

  FileContent({
    required this.fileName,
    required this.filePath,
    required this.content,
    required this.fileExtension,
    this.isSelected = false, // Default to not selected
  });

  @override
  String toString() {
    return 'FileContent{fileName: $fileName, filePath: $filePath, contentLength: ${content.length}, fileExtension: $fileExtension, isSelected: $isSelected}';
  }
}

class FileSearchScreen extends StatefulWidget {
  const FileSearchScreen({super.key});

  @override
  State<FileSearchScreen> createState() => _FileSearchScreenState();
}

class _FileSearchScreenState extends State<FileSearchScreen> {
  String? selectedPath;
  final TextEditingController _fileTypeController = TextEditingController();
  List<FileContent> foundFiles = [];
  bool isSearching = false;
  int totalFilesFound = 0;
  bool _isAnyFileSelected = false; // To enable/disable delete/export buttons

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  Future<void> _selectDirectory() async {
    try {
      String? path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        setState(() {
          selectedPath = path;
        });
      }
    } catch (e) {
      _showError('Error selecting directory: $e');
    }
  }

  Future<void> _startSearch() async {
    if (selectedPath == null) {
      _showError('Please select a directory first');
      return;
    }

    if (_fileTypeController.text.isEmpty) {
      _showError('Please enter file types');
      return;
    }

    setState(() {
      isSearching = true;
      foundFiles = [];
      totalFilesFound = 0;
      _isAnyFileSelected = false; // Reset selection state
    });

    try {
      List<String> fileTypes = _fileTypeController.text
          .split(',')
          .map((type) => type.trim().toLowerCase())
          .where((type) => type.isNotEmpty)
          .toList();

      if (fileTypes.isEmpty) {
        _showError('Please enter valid file types');
        return;
      }

      await _searchFiles(selectedPath!, fileTypes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search completed! Found $totalFilesFound files'),
        ),
      );
    } catch (e) {
      _showError('Error during search: $e');
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void _cancelSearch() {
    setState(() {
      isSearching = false;
    });
  }

  Future<void> _exportSelectedResults() async {
    final selectedFiles = foundFiles.where((file) => file.isSelected).toList();

    if (selectedFiles.isEmpty) {
      _showError('No files selected for export');
      return;
    }

    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Exported Files As',
        fileName: 'selected_files_export.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (outputPath == null) {
        // User cancelled the dialog
        return;
      }

      final File outputFile = File(outputPath);
      StringBuffer buffer = StringBuffer();

      buffer.writeln('--- Selected Files Export ---');
      buffer.writeln('Export Date: ${DateTime.now().toIso8601String()}\n');

      for (final fileContent in selectedFiles) {
        buffer.writeln('--- File Info ---');
        buffer.writeln('File Name: ${fileContent.fileName}');
        buffer.writeln('File Path: ${fileContent.filePath}');
        buffer.writeln('File Extension: ${fileContent.fileExtension}');
        buffer.writeln('Content Length: ${fileContent.content.length} characters');
        buffer.writeln('\n--- File Content ---');
        buffer.writeln(fileContent.content); // Full content
        buffer.writeln('\n--- End File ---\n');
      }

      await outputFile.writeAsString(buffer.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected files exported to ${outputFile.path}'),
        ),
      );
    } catch (e) {
      _showError('Error exporting selected results: $e');
    }
  }

  Future<void> _searchFiles(String directoryPath, List<String> fileTypes) async {
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      return;
    }

    try {
      final List<FileSystemEntity> entities = directory.listSync();

      for (final entity in entities) {
        if (isSearching == false) break;

        if (entity is File) {
          final String fileName = entity.path.split('/').last;
          final String fileExtension = fileName.contains('.')
              ? '.${fileName.split('.').last.toLowerCase()}'
              : '';

          if (fileTypes.contains(fileExtension)) {
            try {
              final String content = await entity.readAsString();
              final fileContent = FileContent(
                fileName: fileName,
                filePath: entity.path,
                content: content,
                fileExtension: fileExtension,
              );

              setState(() {
                foundFiles.add(fileContent);
                totalFilesFound++;
              });
            } catch (e) {
              print('Error reading file ${entity.path}: $e');
            }
          }
        } else if (entity is Directory) {
          await _searchFiles(entity.path, fileTypes);
        }
      }
    } catch (e) {
      print('Error accessing directory $directoryPath: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _updateSelectionState() {
    setState(() {
      _isAnyFileSelected = foundFiles.any((file) => file.isSelected);
    });
  }

  void _selectAllFiles() {
    setState(() {
      for (var file in foundFiles) {
        file.isSelected = true;
      }
      _isAnyFileSelected = true;
    });
  }

  void _deselectAllFiles() {
    setState(() {
      for (var file in foundFiles) {
        file.isSelected = false;
      }
      _isAnyFileSelected = false;
    });
  }

  void _deleteSelectedFiles() {
    setState(() {
      foundFiles.removeWhere((file) => file.isSelected);
      _isAnyFileSelected = false; // After deletion, no files are selected
      totalFilesFound = foundFiles.length; // Update total count
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selected files deleted from list.'),
      ),
    );
  }

  Future<void> _showFileContent(FileContent fileContent) async {
    final TextEditingController contentController =
        TextEditingController(text: fileContent.content);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fileContent.fileName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Path: ${fileContent.filePath}'),
              const SizedBox(height: 8),
              Text('Extension: ${fileContent.fileExtension}'),
              const SizedBox(height: 16),
              const Text('Content:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: contentController,
                  maxLines: null, // Allow multiline
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration.collapsed(
                      hintText: 'No content to display'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Copy to Clipboard Button
              final String metadata =
                  'File Name: ${fileContent.fileName}\nFile Path: ${fileContent.filePath}\nFile Extension: ${fileContent.fileExtension}\n\n';
              await Clipboard.setData(
                  ClipboardData(text: metadata + contentController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File info and content copied!')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () {
              // Cancel Button
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save Button
              try {
                final File file = File(fileContent.filePath);
                await file.writeAsString(contentController.text);
                setState(() {
                  fileContent.content =
                      contentController.text; // Update content in memory
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'File ${fileContent.fileName} saved successfully!')),
                );
                Navigator.pop(context);
              } catch (e) {
                _showError('Error saving file: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<String> _generateFileTree(String directoryPath,
      [String prefix = '']) async {
    final buffer = StringBuffer();
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      return '';
    }

    final List<FileSystemEntity> entities = directory.listSync(recursive: false)
      ..sort((a, b) => a.path.compareTo(b.path)); // Sort for consistent order

    for (int i = 0; i < entities.length; i++) {
      final entity = entities[i];
      final isLast = i == entities.length - 1;
      final newPrefix = isLast ? '└── ' : '├── ';
      final nextPrefix = isLast ? '    ' : '│   ';

      buffer.writeln('$prefix$newPrefix${entity.path.split('/').last}');

      if (entity is Directory) {
        buffer.write(await _generateFileTree(entity.path, prefix + nextPrefix));
      }
    }
    return buffer.toString();
  }

  Future<void> _showFileTree() async {
    if (selectedPath == null) {
      _showError('Please select a directory first to generate a file tree.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating file tree... This might take a moment.')),
    );

    try {
      final String tree = await _generateFileTree(selectedPath!);
      final TextEditingController treeController = TextEditingController(text: tree);

      if (!mounted) return; // Check if widget is still in the tree

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Generated File Tree'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: treeController,
                    readOnly: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration.collapsed(
                        hintText: 'No tree generated'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Copy to Clipboard
                await Clipboard.setData(ClipboardData(text: treeController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File tree copied to clipboard!')),
                );
              },
              child: const Text('Copy to Clipboard'),
            ),
            TextButton(
              onPressed: () async {
                // Save
                String? outputPath = await FilePicker.platform.saveFile(
                  dialogTitle: 'Save File Tree As',
                  fileName: 'file_tree.txt',
                  type: FileType.custom,
                  allowedExtensions: ['txt'],
                );

                if (outputPath != null) {
                  try {
                    final File outputFile = File(outputPath);
                    await outputFile.writeAsString(treeController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File tree saved to ${outputFile.path}')),
                    );
                  } catch (e) {
                    _showError('Error saving file tree: $e');
                  }
                }
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                // Discard (Close)
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Error generating file tree: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Search App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Directory Selection
            ElevatedButton(
              onPressed: _selectDirectory,
              child: const Text('Select Directory'),
            ),
            const SizedBox(height: 8),
            Text(
              selectedPath ?? 'No directory selected',
              style: TextStyle(
                color: selectedPath != null ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // File Type Input
            TextField(
              controller: _fileTypeController,
              decoration: const InputDecoration(
                labelText: 'File Types (comma separated)',
                hintText: '.dart, .py, .sh, .go',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Search/Cancel Button
            ElevatedButton(
              onPressed: isSearching ? null : _startSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isSearching
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 8),
                        Text('Searching...'),
                      ],
                    )
                  : const Text('Start Search'),
            ),
            const SizedBox(height: 10),

            // Control Buttons: Select All, Deselect All, Delete Selected, Export Selected, Generate File Tree
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: foundFiles.isNotEmpty ? _selectAllFiles : null,
                  child: const Text('Select All'),
                ),
                ElevatedButton(
                  onPressed: _isAnyFileSelected ? _deselectAllFiles : null,
                  child: const Text('Deselect All'),
                ),
                ElevatedButton(
                  onPressed: _isAnyFileSelected ? _deleteSelectedFiles : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete Selected'),
                ),
                ElevatedButton(
                  onPressed: _isAnyFileSelected ? _exportSelectedResults : null,
                  child: const Text('Export Selected'),
                ),
                ElevatedButton(
                  onPressed: selectedPath != null ? _showFileTree : null,
                  child: const Text('Generate File Tree'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Results
            Expanded(
              child: foundFiles.isEmpty
                  ? Center(
                      child: Text(
                        isSearching
                            ? 'Searching...'
                            : 'No files found yet. Select a directory and start search.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: foundFiles.length,
                      itemBuilder: (context, index) {
                        final file = foundFiles[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Checkbox(
                              value: file.isSelected,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  file.isSelected = newValue ?? false;
                                  _updateSelectionState();
                                });
                              },
                            ),
                            title: Text(file.fileName),
                            subtitle: Text(file.filePath),
                            trailing: Text(
                              '${file.content.length} chars',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _showFileContent(file),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fileTypeController.dispose();
    super.dispose();
  }
}