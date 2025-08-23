import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hori/main.dart';
import 'package:http/http.dart' as http;
import 'package:pro_image_editor/pro_image_editor.dart';

import '../enums/ai_provider.dart';
import 'ai_base_provider.dart';

/// Sends image editing commands using OpenAI's chat completions API.
class OpenAiProvider extends AiBaseProvider {
  /// Creates an instance with the given API key and context.
   OpenAiProvider({required super.apiKey, required super.context});

  @override
  final AiProvider provider = AiProvider.openAi;

  @override
  final bool isImageGenerationSupported = true;

  @override
  final String endpointCommand = '${translatorConfig.baseUrl}/chat/completions';
  @override
  final String endpointImageGeneration =
      '${translatorConfig.baseUrl}/images/generations';

  @override
  Future<void> sendCommand(ProImageEditorState editor, String command) async {
    final response = await http.post(
      Uri.parse(endpointCommand),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-5-mini',
        'messages': [
          {'role': 'system', 'content': buildSystemMessage(editor)},
          {'role': 'user', 'content': command},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['choices']?[0]?['message']?['content']?.toString();
      if (result != null) await handleAiResponse(editor, result);
    } else {
      debugPrint('❌ OpenAI error: ${response.statusCode} ${response.body}');
      if (response.statusCode == 401) showInvalidApiKeyWarning();
    }
  }

  @override
  Future<void> sendImageGenerationRequest(
    ProImageEditorState editor,
    String prompt,
  ) async {
    final response = await http.post(
      Uri.parse(endpointImageGeneration),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': '1024x1024',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final imageUrl = data['data']?[0]?['url'];
      if (imageUrl != null && imageUrl is String && context.mounted) {
        await precacheImage(NetworkImage(imageUrl), context);
        WidgetLayer layer = WidgetLayer(
          widget: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1, minHeight: 1),
            child: Image.network(imageUrl),
          ),
        );
        editor.addLayer(layer);
      }
    } else {
      debugPrint(
        '❌ Image generation failed: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 401) showInvalidApiKeyWarning();
    }
  }
}
