import 'package:hive/hive.dart';

part 'sdk_message.g.dart';

@HiveType(typeId: 8)
class SdkMessage extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String? userMessages;

  @HiveField(2)
  String? systemMessage;

  @HiveField(3)
  String? modelResponse;

  @HiveField(4)
  String? modelGeneratedAudio; // base64

  @HiveField(5)
  String? modelGeneratedImage; // base64

  @HiveField(6)
  Map<String, dynamic>? toolCalls;
  
  @HiveField(7)
  dynamic toolResult;

  @HiveField(8)
  String? filePath;

  @HiveField(9)
  String? fileType; // mime

  @HiveField(10)
  String? audioOutTranscript;

  @HiveField(11)
  String? chatSummery;

  SdkMessage({
    required this.id,
    this.userMessages,
    this.systemMessage,
    this.modelResponse,
    this.modelGeneratedAudio,
    this.modelGeneratedImage,
    this.toolCalls,
    this.toolResult,
    this.filePath,
    this.fileType,
    this.audioOutTranscript,
    this.chatSummery,
  });

  /// Create an SdkMessage from a raw map/record (e.g. a Hive entry or JSON).
  /// This helper will tolerate several common key naming variations.
  factory SdkMessage.fromMap(Map<String, dynamic> map) {
    return SdkMessage(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse('${map['id'] ?? 0}') ?? 0,
      userMessages: map['userMessages'] as String? ??
          map['user_messages'] as String?,
      systemMessage: map['systemMessage'] as String? ??
          map['system_message'] as String?,
      modelResponse: map['modelResponse'] as String? ??
          map['model_response'] as String?,
      modelGeneratedAudio: map['modelGeneratedAudio'] as String? ??
          map['model_generated_audio'] as String?,
      modelGeneratedImage: map['modelGeneratedImage'] as String? ??
          map['model_generated_image'] as String?,
      toolCalls: (map['toolCalls'] ?? map['tool_calls']) is Map
          ? Map<String, dynamic>.from(
              map['toolCalls'] ?? map['tool_calls'] as Map)
          : null,
      toolResult: (map['toolResult'] ?? map['tool_result']) is Map
          ? Map<String, dynamic>.from(
              map['toolResult'] ?? map['tool_result'] as Map)
          : (map['toolResult'] is String
              ? {'result': map['toolResult']}
              : null),
      filePath: map['filePath'] as String? ?? map['file_path'] as String?,
      fileType: map['fileType'] as String? ?? map['file_type'] as String?,
      audioOutTranscript: map['audioOutTranscript'] as String? ??
          map['audio_out_transcript'] as String?,
      chatSummery: map['chatSummery'] as String? ??
          map['chat_summery'] as String? ??
          map['chat_summary'] as String?,
    );
  }

  /// Convert this SdkMessage into a Map suitable for storage or transport.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userMessages': userMessages,
      'systemMessage': systemMessage,
      'modelResponse': modelResponse,
      'modelGeneratedAudio': modelGeneratedAudio,
      'modelGeneratedImage': modelGeneratedImage,
      'toolCalls': toolCalls,
      'toolResult': toolResult,
      'filePath': filePath,
      'fileType': fileType,
      'audioOutTranscript': audioOutTranscript,
      'chatSummery': chatSummery,
    };
  }
}