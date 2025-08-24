import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String? gptApiKey;

  @HiveField(2)
  late String? geminiApiKey;

  @HiveField(3)
  late String defaultLlmProvider;

  @HiveField(4)
  late DateTime lastUpdated;

  @HiveField(5)
  late String defaultModelGpt;

  @HiveField(6)
  late String defaultModelGemini;

  @HiveField(7)
  late double temperature;

  @HiveField(8)
  late double topP;

  @HiveField(9)
  late int maxTokens;

  @HiveField(10)
  late bool enableStreaming;

  @HiveField(11)
  late String voice;

  @HiveField(12)
  late bool enableTools;

  @HiveField(13)
  late String baseUrl;

  @HiveField(14)
  late String baseUrl2;

  @HiveField(15)
  late bool usingFallback;

  @HiveField(16)
  late bool usingFallbackModel;

  @HiveField(17)
  late String gptFallbackModel;

  @HiveField(18)
  late String geminiFallbackModel;

  @HiveField(19)
  late int defaultContextLimitbasedOnMessage;

  @HiveField(20)
  late String whereSouldSaveAppContents;

  @HiveField(21)
  late String defaultModality;

  @HiveField(22)
  late String safetySettingHarassment;

  @HiveField(23)
  late String safetySettingHateSpeech;

  @HiveField(24)
  late String safetySettingSexuallyExplicit;

  @HiveField(25)
  late String safetySettingDangerousContent;

  @HiveField(26)
  late int topK;

  @HiveField(27)
  late double presencePenalty;

  @HiveField(28)
  late double frequencyPenalty;

  AppSettings({
    required this.id,
    this.gptApiKey,
    this.geminiApiKey,
    required this.defaultLlmProvider,
    required this.lastUpdated,
    required this.defaultModelGpt,
    required this.defaultModelGemini,
    required this.temperature,
    required this.topP,
    required this.maxTokens,
    required this.enableStreaming,
    required this.voice,
    required this.enableTools,
    required this.baseUrl,
    required this.baseUrl2,
    required this.usingFallback,
    required this.usingFallbackModel,
    required this.gptFallbackModel,
    required this.geminiFallbackModel,
    required this.defaultContextLimitbasedOnMessage,
    required this.whereSouldSaveAppContents,
    required this.defaultModality,
    required this.safetySettingHarassment,
    required this.safetySettingHateSpeech,
    required this.safetySettingSexuallyExplicit,
    required this.safetySettingDangerousContent,
    required this.topK,
    required this.presencePenalty,
    required this.frequencyPenalty,
  });

  AppSettings.withDefaults() {
    id = 1;
    gptApiKey = null;
    geminiApiKey = null;
    defaultLlmProvider = 'openai';
    lastUpdated = DateTime.now();
    defaultModelGpt = 'gpt-5-nano';
    defaultModelGemini = 'gemini-2.5-flash-lite';
    temperature = 1.0;
    topP = 0.96;
    maxTokens = 0;
    enableStreaming = true;
    voice = 'alloy';
    enableTools = true;
    baseUrl = 'https://api.openai.com/v1';
    baseUrl2 = 'https://generativelanguage.googleapis.com';
    usingFallback = false;
    usingFallbackModel = false;
    gptFallbackModel = 'gpt-5-mini';
    geminiFallbackModel = 'gemini-2.5-flash';
    defaultContextLimitbasedOnMessage = 10;
    whereSouldSaveAppContents = "";
    defaultModality = 'text';
    safetySettingHarassment = 'BLOCK_NONE';
    safetySettingHateSpeech = 'BLOCK_NONE';
    safetySettingSexuallyExplicit = 'BLOCK_NONE';
    safetySettingDangerousContent = 'BLOCK_NONE';
    topK = 40;
    presencePenalty = 0.0;
    frequencyPenalty = 0.0;
  }
}
