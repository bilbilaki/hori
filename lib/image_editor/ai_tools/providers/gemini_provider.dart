import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pro_image_editor/pro_image_editor.dart';

import '../enums/ai_provider.dart';
import '../schemas/gemini_response_schema.dart';
import 'ai_base_provider.dart';

/// Sends image editing commands using the Gemini AI provider.
class GeminiProvider extends AiBaseProvider {
  /// Creates an instance with the given API key and context.
  const GeminiProvider({
    required super.apiKey,
    required super.context,
  });

  @override
  final AiProvider provider = AiProvider.gemini;

  @override
  final String endpointCommand =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Add the url to your model. As example imagen-3
  @override
  final String endpointImageGeneration = '';
  @override
  final bool isImageGenerationSupported = false;

  @override
  Future<void> sendCommand(
    ProImageEditorState editor,
    String command,
  ) async {
    final response = await http.post(
      Uri.parse(endpointCommand),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '${buildSystemMessage(editor)}\nUser Message: $command'}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'responseSchema': geminiResponseSchema,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result =
          data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString();
      if (result != null) await handleAiResponse(editor, result);
    } else {
      debugPrint('❌ Gemini error: ${response.statusCode} ${response.body}');
      if (response.statusCode == 400) showInvalidApiKeyWarning();
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
        'Content-Type': 'application/json',
        'X-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final imageBase64 = data['candidates']?[0]?['content']?['parts']?[0]
          ?['inlineData']?['data'];

      if (imageBase64 != null && imageBase64 is String && context.mounted) {
        final image = Image.memory(
          base64Decode(imageBase64),
          fit: BoxFit.contain,
        );

        WidgetLayer layer = WidgetLayer(
          widget: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1, minHeight: 1),
            child: image,
          ),
        );
        editor.addLayer(layer);
      }
    } else {
      debugPrint(
        '❌ Image generation failed: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 400) showInvalidApiKeyWarning();
    }
  }
}