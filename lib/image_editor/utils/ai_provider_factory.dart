import 'package:flutter/widgets.dart';
import 'package:hori/image_editor/ai_tools/enums/ai_provider.dart';
import 'package:hori/image_editor/ai_tools/providers/ai_base_provider.dart';
import 'package:hori/image_editor/ai_tools/providers/gemini_provider.dart';
import 'package:hori/image_editor/ai_tools/providers/openai_provider.dart';

/// Factory class to create AI message providers based on the selected type.
class AiProviderFactory {
  /// Creates an AI message provider for the given context, type, and API key.
  static AiBaseProvider create({
    required BuildContext context,
    required AiProvider provider,
    required String apiKey,
  }) {
    switch (provider) {
      case AiProvider.gemini:
        return GeminiProvider(
          apiKey: apiKey,
          context: context,
        );
      case AiProvider.openAi:
        return OpenAiProvider(
          apiKey: apiKey,
          context: context,
        );
    }
  }
}
