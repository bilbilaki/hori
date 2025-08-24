import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hori/atri_core/core/database/app_settings.dart';
import 'package:hori/atri_core/core/database/assistant_message.dart';
import 'package:hori/atri_core/core/database/bookmark.dart';
import 'package:hori/atri_core/core/database/conversation.dart';
import 'package:hori/atri_core/core/database/core.dart';
import 'package:hori/atri_core/core/database/sdk_message.dart';
import 'package:hori/atri_core/core/database/tool.dart';
import 'package:hori/atri_core/core/database/user_message.dart';
import 'package:path_provider/path_provider.dart';


class DatabaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      Directory dir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(dir.path);
    } else {
      await Hive.initFlutter();
    }

    Hive
      ..registerAdapter(AppSettingsAdapter())
      ..registerAdapter(ConversationAdapter())
      ..registerAdapter(UserMessageAdapter())
      ..registerAdapter(AssistantMessageAdapter())
      ..registerAdapter(ToolObjectAdapter())
      ..registerAdapter(ToolParametersAdapter())
      ..registerAdapter(PropertySpecAdapter())
      ..registerAdapter(SdkMessageAdapter())
      ..registerAdapter(BookMarkAdapter());

    await Future.wait([
      Hive.openBox<AppSettings>(HiveBoxes.appSettings),
      Hive.openBox<Conversation>(HiveBoxes.conversations),
      Hive.openBox<UserMessage>(HiveBoxes.userMessages),
      Hive.openBox<AssistantMessage>(HiveBoxes.assistantMessages),
      Hive.openBox<ToolObject>(HiveBoxes.tools),
      Hive.openBox<SdkMessage>(HiveBoxes.sdkMessages),
      Hive.openBox<BookMark>(HiveBoxes.bookmarks),
    ]);

    _initialized = true;
  }

  static Box<AppSettings> get appSettingsBox => Hive.box<AppSettings>(HiveBoxes.appSettings);
  static Box<Conversation> get conversationsBox => Hive.box<Conversation>(HiveBoxes.conversations);
  static Box<UserMessage> get userMessagesBox => Hive.box<UserMessage>(HiveBoxes.userMessages);
  static Box<AssistantMessage> get assistantMessagesBox => Hive.box<AssistantMessage>(HiveBoxes.assistantMessages);
  static Box<ToolObject> get toolsBox => Hive.box<ToolObject>(HiveBoxes.tools);
  static Box<SdkMessage> get sdkMessagesBox => Hive.box<SdkMessage>(HiveBoxes.sdkMessages);
  static Box<BookMark> get bookmarksBox => Hive.box<BookMark>(HiveBoxes.bookmarks);

  // Helpers
  static int nextIntKey<T>(Box<T> box) {
    if (box.isEmpty) return 1;
    final keys = box.keys.whereType<int>();
    if (keys.isEmpty) return 1;
    return (keys.reduce((a, b) => a > b ? a : b)) + 1;
  }

  // AppSettings CRUD (usually single record with key = id)
  static Future<int> upsertAppSettings(AppSettings s) async {
    await appSettingsBox.put(s.id, s);
    return s.id;
  }

  static AppSettings? getAppSettings(int id) => appSettingsBox.get(id);

  // Conversations
  static Future<int> addConversation(Conversation c) async {
    final key = c.id;
    await conversationsBox.put(key, c);
    return key;
  }

  static Future<void> updateConversation(Conversation c) async => conversationsBox.put(c.id, c);

  static Future<void> deleteConversation(int id) async => conversationsBox.delete(id);

  // User Messages
  static Future<int> addUserMessage(UserMessage m) async {
    await userMessagesBox.put(m.id, m);
    return m.id;
  }

  static Future<void> updateUserMessage(UserMessage m) async => userMessagesBox.put(m.id, m);

  static Future<void> deleteUserMessage(int id) async => userMessagesBox.delete(id);

  // Assistant Messages
  static Future<int> addAssistantMessage(AssistantMessage m) async {
    await assistantMessagesBox.put(m.id, m);
    return m.id;
  }

  static Future<void> updateAssistantMessage(AssistantMessage m) async => assistantMessagesBox.put(m.id, m);

  static Future<void> deleteAssistantMessage(int id) async => assistantMessagesBox.delete(id);

  // Tools
  static Future<void> addTool(String key, ToolObject tool) async => toolsBox.put(key, tool);

  static ToolObject? getTool(String key) => toolsBox.get(key);

  static Future<void> deleteTool(String key) async => toolsBox.delete(key);

  // SDK Messages
  static Future<int> addSdkMessage(SdkMessage m) async {
    await sdkMessagesBox.put(m.id, m);
    return m.id;
  }

  static Future<void> updateSdkMessage(SdkMessage m) async => sdkMessagesBox.put(m.id, m);

  static Future<void> deleteSdkMessage(int id) async => sdkMessagesBox.delete(id);

  // Bookmarks
  static Future<int> addBookMark(BookMark b) async {
    await bookmarksBox.put(b.id, b);
    return b.id;
  }

  static Future<void> updateBookMark(BookMark b) async => bookmarksBox.put(b.id, b);

  static Future<void> deleteBookMark(int id) async => bookmarksBox.delete(id);

  // Utility: get messages for a conversation
  static List<UserMessage> getUserMessagesForConversation(int conversationId) {
    return userMessagesBox.values.where((m) => m.conversationId == conversationId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static List<AssistantMessage> getAssistantMessagesForConversation(int conversationId) {
    return assistantMessagesBox.values.where((m) => m.conversationId == conversationId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}