import 'package:hive/hive.dart';

part 'conversation.g.dart';

@HiveType(typeId: 2)
class Conversation extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String providerUsed;

  @HiveField(5)
  String? modelUsed;

  @HiveField(6)
  String? initialPrompt;

  @HiveField(7)
  int totalTokens;

  @HiveField(8)
  bool isArchived;
  @HiveField(9)
  List<int> userMessageIds = [];

  @HiveField(10)
  List<int> assistantMessageIds = [];

  @HiveField(11)
  List<int> toolIds = [];

  @HiveField(12)
  List<int> sdkMessageIds = [];

  @HiveField(13)
  List<int> bookmarkIds = [];

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.providerUsed,
    this.modelUsed,
    this.initialPrompt,
    required this.totalTokens,
    required this.isArchived,
    this.userMessageIds = const [],
    this.assistantMessageIds = const [],
    this.toolIds = const [],
    this.sdkMessageIds = const [],
    this.bookmarkIds = const [],
  });
}