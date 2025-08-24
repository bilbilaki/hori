import 'package:hive/hive.dart';

part 'user_message.g.dart';

@HiveType(typeId: 3)
class UserMessage extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int conversationId;

  @HiveField(2)
  String? content;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  String? mediaType;

  @HiveField(5)
  String? mediaPath;

  @HiveField(6)
  String? mediaMetadata;

  @HiveField(7)
  int? tokenCount;

  @HiveField(8)
  bool isError;

  @HiveField(9)
  String? errorMessage;

  UserMessage({
    required this.id,
    required this.conversationId,
    this.content,
    required this.timestamp,
    this.mediaType,
    this.mediaPath,
    this.mediaMetadata,
    this.tokenCount,
    required this.isError,
    this.errorMessage,
  });
}