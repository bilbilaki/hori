import 'dart:convert';
import 'dart:io';

import 'package:openai_dart/openai_dart.dart';
import '../platforms/input_helpers.dart' as helpers;
import '../core/database/sdk_message.dart';

/// MemoryBox is a utility that accepts simple inputs (String),
/// file paths (pointing to images/audio/etc), or raw Map<String, dynamic>
/// tool outputs and converts them into a canonical List<ChatCompletionMessage>
/// (historyMessages) that can be used directly with the openai_dart chat APIs.
///
/// This file preserves the older MemoryBox named-parameter constructor so
/// existing call sites keep working (backwards compatibility). New code
/// can use the addInput / addInputsToHistory APIs instead.
class MemoryBox {
final List<ChatCompletionMessage> historyMessages;

// Legacy fields kept for backward compatibility with existing code that used
// the older MemoryBox signature and helper methods.
int? id;
String? userMessages;
String? systemMessage;
String? modelResponse;
Map<String, dynamic>? toolCalls;
dynamic toolResult;
String? modelGeneratedAudio; // base64
String? modelGeneratedImage; // base64
String? filePath;
String? fileType;
String? audioOutTranscript;
String? chatSummery;

/// Primary constructor: supports legacy named-parameter usage:
/// MemoryBox(historyMessages: [], userMessages: '...').
MemoryBox({
List<ChatCompletionMessage>? historyMessages,
this.id,
this.userMessages,
this.systemMessage,
this.modelResponse,
this.toolCalls,
this.toolResult,
this.modelGeneratedAudio,
this.modelGeneratedImage,
this.filePath,
this.fileType,
this.audioOutTranscript,
this.chatSummery,
}) : historyMessages = historyMessages ?? [];

  /// Alternate simple constructor that accepts a positional initial list.
  MemoryBox.withInitial([List<ChatCompletionMessage>? initialMessages])
      : historyMessages = initialMessages ?? [];

  /// Convenience factory.
  factory MemoryBox.withMessages(List<ChatCompletionMessage> messages) =>
      MemoryBox(historyMessages: messages);

  /// Convert a plain user text into a ChatCompletionMessage (user role).
  ChatCompletionMessage _userTextMessage(String text) {
    return ChatCompletionMessage.user(
      content: ChatCompletionUserMessageContent.parts([
        ChatCompletionMessageContentPart.text(text: text.trim()),
      ]),
    );
  }

  /// Convert simple assistant text into a ChatCompletionMessage (assistant role).
  ChatCompletionMessage _assistantTextMessage(String text) {
    return ChatCompletionMessage.assistant(content: text.trim());
  }

  /// Convert a file path into a ChatCompletionMessage containing an image or audio content part.
  /// Uses helpers.contentFromPath which returns a ChatCompletionMessageContentPart.
  Future<ChatCompletionMessage> _messageFromPath(String path,
      {String role = 'user'}) async {
    try {
      final part = await helpers.contentFromPath(path);
      // Use user message with content parts for file attachments by default.
      return ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.parts([part]),
      );
    } catch (e) {
      return ChatCompletionMessage.system(
        content: '[file read error] $path -> $e',
      );
    }
  }

  /// Build a ChatCompletionMessage from a Map<String, dynamic> produced by tools.
  /// Supported keys:
  /// - 'role' -> 'user' | 'assistant' | 'system'
  /// - 'content' -> plain string
  /// - 'path' | 'file_path' -> local file path
  /// - 'base64' + 'mime' -> inline base64 data
  /// - 'tool' / 'function_call' -> encoded as assistant/tool text
  Future<ChatCompletionMessage> _messageFromMap(
      Map<String, dynamic> map) async {
    final role = (map['role'] as String?)?.toLowerCase();
    final content = map['content'];
    final path = (map['path'] ?? map['file_path'] ?? map['file'] ?? map['filepath'])
        as String?;
    final base64Data = map['base64'] as String?;
    final mime = map['mime'] as String?;

    if (path != null && path.trim().isNotEmpty) {
      return await _messageFromPath(path, role: role ?? 'user');
    }

    if (base64Data != null && base64Data.trim().isNotEmpty) {
      final detectedMime = mime ?? 'application/octet-stream';
      final dataUrl = 'data:$detectedMime;base64,$base64Data';
      if (detectedMime.startsWith('image/')) {
        final part = ChatCompletionMessageContentPart.image(
          imageUrl: ChatCompletionMessageImageUrl(url: dataUrl),
        );
        return ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.parts([part]),
        );
      } else {
        // treat as audio: save base64 to a temp file and re-use path handling
        try {
          final savedPath = await helpers.saveBase64ToFile(base64Data,
              ext: detectedMime.contains('wav') ? '.wav' : '.dat');
          return await _messageFromPath(savedPath);
        } catch (e) {
          return ChatCompletionMessage.system(
              content: '[base64->file error] $e (mime: $detectedMime)');
        }
      }
    }

    if (content is String && content.trim().isNotEmpty) {
      if (role == 'assistant') {
        return _assistantTextMessage(content);
      } else if (role == 'system') {
        return ChatCompletionMessage.system(content: content.trim());
      } else {
        return _userTextMessage(content);
      }
    }

    // If contains tool/function structured output, encode as assistant text.
    if (map.containsKey('tool') || map.containsKey('function_call')) {
      return ChatCompletionMessage.assistant(
          content: '[tool output] ${jsonEncode(map)}');
    }

    // Fallback: encode entire map as assistant text
    return ChatCompletionMessage.assistant(content: jsonEncode(map));
  }

  /// Add a single input (String, Map, File, or file path) to history.
  /// Strings that point to an existing file will be treated as file inputs.
/// Sync fields from an [SdkMessage] into this MemoryBox's legacy properties.
  /// After calling this, you can call [addNonNullValuesToHistory] to convert
  /// the synced fields into [historyMessages].
  void _syncFromSdkMessage(SdkMessage sdk) {
    // Copy scalar and text fields
    id = sdk.id;
    userMessages = sdk.userMessages;
    systemMessage = sdk.systemMessage;
    modelResponse = sdk.modelResponse;

    // Tool outputs / structured data
    toolCalls = sdk.toolCalls == null ? null : Map<String, dynamic>.from(sdk.toolCalls!);
    toolResult = sdk.toolResult == null ? null : Map<String, dynamic>.from(sdk.toolResult!);

    // Generated media (base64)
    modelGeneratedAudio = sdk.modelGeneratedAudio;
    modelGeneratedImage = sdk.modelGeneratedImage;

    // File metadata
    filePath = sdk.filePath;
    fileType = sdk.fileType;

    // Transcripts / summaries
    audioOutTranscript = sdk.audioOutTranscript;
    chatSummery = sdk.chatSummery;
  }
  Future<void> addInput(dynamic input, {String defaultRole = 'user'}) async {
  if (input == null) return;
  
  // If an SdkMessage instance is passed, sync fields and convert to history messages
  if (input is SdkMessage) {
  _syncFromSdkMessage(input);
  await addNonNullValuesToHistory();
  return;
  }
  
  if (input is String) {
  final s = input.trim();
  // If string refers to an existing file, treat it as a file path
  try {
  final f = File(s);
  if (f.existsSync()) {
  final msg = await _messageFromPath(s, role: defaultRole);
  historyMessages.add(msg);
  return;
  }
  } catch (_) {
  // ignore file check errors and treat as plain text below
  }
  // plain text -> user message by default
  historyMessages.add(_userTextMessage(s));
  return;
  }
  
  if (input is Map<String, dynamic>) {
  // If the map looks like a serialized SdkMessage (contains id or several sdk keys)
  // convert it into an SdkMessage and sync fields automatically.
  final hasSdkLikeKeys = input.containsKey('id') ||
  input.containsKey('userMessages') ||
  input.containsKey('modelResponse') ||
  input.containsKey('model_generated_image') ||
  input.containsKey('modelGeneratedImage');
  if (hasSdkLikeKeys) {
  try {
  final sdk = SdkMessage.fromMap(input);
  _syncFromSdkMessage(sdk);
  await addNonNullValuesToHistory();
  return;
  } catch (_) {
    // fall through to treat as generic map
  }
  }
  
  final msg = await _messageFromMap(input);
  historyMessages.add(msg);
  return;
  }
  
  // If someone passes a File directly
  if (input is File) {
  final path = input.path;
  final msg = await _messageFromPath(path);
  historyMessages.add(msg);
  return;
  }
  
  // Unknown type -> stringify and add as system debug note
  historyMessages
  .add(ChatCompletionMessage.system(content: '[unhandled input] ${input.toString()}'));
  }

  /// Add multiple mixed inputs at once.
  Future<void> addInputsToHistory(List<dynamic> inputs,
      {String defaultRole = 'user'}) async {
    for (final item in inputs) {
      await addInput(item, defaultRole: defaultRole);
    }
  }

  /// Backwards-compatible helper that converts legacy fields into messages
  /// and appends them into [historyMessages].
  Future<void> addNonNullValuesToHistory() async {
  bool isNotEmpty(String? s) => s != null && s.trim().isNotEmpty;
  
  // Optionally include id as a system note if present
  if (id != null) {
  historyMessages.add(ChatCompletionMessage.system(content: '[id] ${id.toString()}'));
  }
  
  // 1) userMessages -> user message
  if (isNotEmpty(userMessages)) {
  historyMessages.add(_userTextMessage(userMessages!.trim()));
  }
  
  // 2) systemMessage -> system message
  if (isNotEmpty(systemMessage)) {
  historyMessages.add(ChatCompletionMessage.system(content: systemMessage!.trim()));
  }
  
  // 3) modelResponse -> assistant message
  if (isNotEmpty(modelResponse)) {
  historyMessages.add(_assistantTextMessage(modelResponse!.trim()));
  }
  
  // 4) toolCalls -> assistant note with tool call payload
  if (toolCalls != null) {
  historyMessages.add(ChatCompletionMessage.assistant(content: '[tool_calls] ${jsonEncode(toolCalls)}'));
  }
  
  // 5) toolResult -> assistant message labeled as tool output (structured)
  if (toolResult != null) {
  historyMessages.add(ChatCompletionMessage.assistant(content: '[tool_result] ${jsonEncode(toolResult)}'));
  }
  
  // 6) modelGeneratedImage -> try to treat as inline image via base64
  if (isNotEmpty(modelGeneratedImage)) {
  final map = {
  'base64': modelGeneratedImage!,
  'mime': 'image/png',
  'role': 'assistant'
  };
  final msg = await _messageFromMap(map);
  historyMessages.add(msg);
  }
  
  // 7) modelGeneratedAudio -> try to treat as inline audio via base64
  if (isNotEmpty(modelGeneratedAudio)) {
  final map = {
  'base64': modelGeneratedAudio!,
  'mime': 'audio/wav',
  'role': 'assistant'
  };
  final msg = await _messageFromMap(map);
  historyMessages.add(msg);
  }
  
  // 8) filePath/fileType -> add file as content part if possible
  if (isNotEmpty(filePath) || isNotEmpty(fileType)) {
  final fp = filePath?.trim() ?? '';
  if (fp.isNotEmpty) {
  final msg = await _messageFromPath(fp);
  historyMessages.add(msg);
  } else {
  final ft = fileType?.trim() ?? '';
  final combined = 'fileType: $ft';
  historyMessages.add(ChatCompletionMessage.system(content: combined));
  }
  }
  
  // 9) audioOutTranscript -> user message with transcript text
  if (isNotEmpty(audioOutTranscript)) {
  historyMessages.add(_userTextMessage('[audio transcript] ${audioOutTranscript!.trim()}'));
  }
  
  // 10) chatSummery -> system summary note
  if (isNotEmpty(chatSummery)) {
  historyMessages.add(ChatCompletionMessage.system(content: '[summary] ${chatSummery!.trim()}'));
  }
  }

  /// Alias kept for older code that used processAndAddMessages().
  Future<void> processAndAddMessages() async => addNonNullValuesToHistory();

  /// Clear stored history messages.
  void clear() => historyMessages.clear();
}

/// Small usage example:
/// final box = MemoryBox();
/// await box.addInputsToHistory([
///   'Hello from user',
///   {'role': 'assistant', 'content': 'Hi back'},
///   {'file_path': '/tmp/example.png'},
///   {'base64': '<...>', 'mime': 'image/png'},
///   {'tool': {'name': 'search', 'result': 'ok'}}
/// ]);
/// // box.historyMessages now contains ChatCompletionMessage items ready to use.
