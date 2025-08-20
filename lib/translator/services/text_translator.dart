
import 'package:openai_dart/openai_dart.dart';

/// Service for handling translation via OpenAI API.
class TranslationService {
  OpenAIClient? _client;
////TODO Creating field with default value openai.com and complete customizable by user with shared prefs too can save value 
  void setApiKey(String apiKey) {
    if (apiKey.isNotEmpty) {
      _client = OpenAIClient(
        apiKey: apiKey,
        baseUrl: "https://api.avalai.org/v1",
      );
    } else {
      _client = null;
    }
  }

  Future<String> _translateTextChunk(String text, String targetLanguage) async {
    if (_client == null) {
      throw Exception(
        'API Key not set. Please provide a valid OpenAI API key.',
      );
    }
    if (text.trim().isEmpty) {
      return text;
    }

    final prompt =
        'Translate the following text to $targetLanguage. Return only the translated text, without any introductory phrases or explanations.';
////TODO add model and model params salector and save that per user device by Shared Prefs
    try {
      final res = await _client!.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: const ChatCompletionModel.modelId('gemini-2.5-flash-lite'),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '$prompt\n\nText: """$text"""',
              ),
            ),
          ],
          temperature: 0.2,
        ),
      );
      return res.choices.first.message.content?.trim() ??
          '[Translation Failed: Empty Response]';
    } catch (e) {
      return '[Translation Error: ${e.toString()}]';
    }
  }

  Future<void> translateChunksConcurrently({
    required List<String> chunks,
    required String targetLanguage,
    required Function(int index, String translatedChunk) onChunkTranslated,
    int batchSize = 5,
    ////TODO add customizable number of batch t user configuration item 
  }) async {
    if (_client == null) {
      throw Exception('API Key not set before starting translation.');
    }

    for (int i = 0; i < chunks.length; i += batchSize) {
      int end = (i + batchSize > chunks.length) ? chunks.length : i + batchSize;
      List<String> batchChunks = chunks.sublist(i, end);

      List<Future<String>> batchFutures = batchChunks
          .map((chunk) => _translateTextChunk(chunk, targetLanguage))
          .toList();

      List<String> translatedBatch = await Future.wait(batchFutures);

      for (int j = 0; j < translatedBatch.length; j++) {
        onChunkTranslated(i + j, translatedBatch[j]);
      }
    }
  }
}
