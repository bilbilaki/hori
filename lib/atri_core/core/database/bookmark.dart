import 'package:hive/hive.dart';

part 'bookmark.g.dart';

@HiveType(typeId: 9)
class BookMark extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  List<int> conversationIds;

  @HiveField(2)
  List<int> userMessageIds;

  @HiveField(3)
  List<int> assistantMessageIds;

  BookMark({
    required this.id,
    this.conversationIds = const [],
    this.userMessageIds = const [],
    this.assistantMessageIds = const [],
  });
}