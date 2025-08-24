import 'package:hive/hive.dart';

part 'assistant_message.g.dart';

@HiveType(typeId: 4)
class AssistantMessage extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int conversationId;

  @HiveField(2)
  String? reasoning;

  @HiveField(3)
  String? content;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  String? mediaType;

  @HiveField(6)
  String? mediaPath;

  @HiveField(7)
  String? mediaMetadata;

  @HiveField(8)
  String? toolCalls;

  @HiveField(9)
  int? tokenCount;

  @HiveField(10)
  bool isError;

  @HiveField(11)
  String? errorMessage;

  AssistantMessage({
    required this.id,
    required this.conversationId,
    this.reasoning,
    this.content,
    required this.timestamp,
    this.mediaType,
    this.mediaPath,
    this.mediaMetadata,
    this.toolCalls,
    this.tokenCount,
    required this.isError,
    this.errorMessage,
  });
}