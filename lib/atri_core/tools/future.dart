import 'dart:convert';

import 'package:hori/atri_core/core/clients.dart';
import 'package:hori/atri_core/memory/schema.dart';
import 'package:hori/atri_core/tools/tool_presets.dart';
import 'package:hori/atri_core/tools/tool_presets_handler.dart';
import 'package:openai_dart/openai_dart.dart';
// Helper: handle the talking tool function call payload.
// Returns a Map<String, dynamic> result. Attempts to parse JSON strings,
// accepts Map inputs, and otherwise echoes the content.
// This is intentionally lightweight — replace with your actual tool logic as needed.


Future<void> toolStarter(MemoryBox messages,{void Function()? postCallback}) async {
  CreateChatCompletionResponse res1 = await client.createChatCompletion(
    request: CreateChatCompletionRequest(
      model: ChatCompletionModel.model(ChatCompletionModels.gpt5Mini),
      messages: messages.historyMessages,
      tools: [tool],
    ),
  );
  final answer = res1.choices.first.message.content;
  if (res1.choices.first.message.toolCalls != null) {
    if (res1.choices.first.message.toolCalls != '') {
      if (res1.choices.first.message.toolCalls!.isNotEmpty) {
        final toolCall = res1.choices.first.message.toolCalls!.first;
        final functionCall = toolCall.function;
        final arguments =
            json.decode(functionCall.arguments) as Map<String, dynamic>;
        Map<String, dynamic> functionResult = await TalkingToolHandles(
          arguments['isquestion'],
          arguments['content'],
        );
messages = MemoryBox(historyMessages:messages.historyMessages, modelResponse: answer, toolResult: functionResult.toString());
  await messages.addNonNullValuesToHistory();
        toolResumer(toolCall, functionResult, messages);
      
        return;
      }
    }
  }
  messages = MemoryBox(historyMessages:messages.historyMessages, modelResponse: answer);
  await messages.addNonNullValuesToHistory();
    if (postCallback != null) {
          postCallback();
        }
}

Future<void> toolResumer(
  ChatCompletionMessageToolCall toolCall,
  Map<String, dynamic> functionResult,
MemoryBox messages
,{void Function()? postCallback}
) async {
  final mem = MemoryBox(
    historyMessages: [],
    toolResult: functionResult.toString(),
  );
  await mem.addNonNullValuesToHistory();
  final res2 = await client.createChatCompletion(
    request: CreateChatCompletionRequest(
      model: ChatCompletionModel.modelId('gpt-5-mini'),
      messages: mem.historyMessages,
      tools: [tool],
    ),
  );
  final answer = res2.choices.first.message.content;
  if (res2.choices.first.message.toolCalls != null) {
    if (res2.choices.first.message.toolCalls != '') {
      if (res2.choices.first.message.toolCalls!.isNotEmpty) {
        final toolCall = res2.choices.first.message.toolCalls!.first;
        final functionCall = toolCall.function;
        final arguments =
            json.decode(functionCall.arguments) as Map<String, dynamic>;
        Map<String, dynamic> functionResult = await TalkingToolHandles(
          arguments['isquestion'],
          arguments['content'],
        );

        messages = MemoryBox(historyMessages:messages.historyMessages, modelResponse: answer, toolResult: functionResult.toString());
  await messages.addNonNullValuesToHistory();

        toolResumerClone(toolCall, functionResult, messages);
        return;
      }
    }
  }
  messages = MemoryBox(historyMessages:messages.historyMessages, modelResponse: answer);
  await messages.addNonNullValuesToHistory();
    if (postCallback != null) {
          postCallback();
        }
}

Future<void> toolResumerClone(
  ChatCompletionMessageToolCall toolCall,
  Map<String, dynamic> functionResult,
MemoryBox messages
,{void Function()? postCallback}
) async {
  final mem = MemoryBox(
    historyMessages: [],
    toolResult: functionResult.toString(),
  );
  await mem.addNonNullValuesToHistory();
  final res3 = await client.createChatCompletion(
    request: CreateChatCompletionRequest(
      model: ChatCompletionModel.modelId('gpt-5-mini'),
      messages: mem.historyMessages,
      tools: [tool],
    ),
  );
  final answer = res3.choices.first.message.content;
  if (res3.choices.first.message.toolCalls != null) {
    if (res3.choices.first.message.toolCalls != '') {
      if (res3.choices.first.message.toolCalls!.isNotEmpty) {
        final toolCall = res3.choices.first.message.toolCalls!.first;
        final functionCall = toolCall.function;
        final arguments =
            json.decode(functionCall.arguments) as Map<String, dynamic>;
        Map<String, dynamic> functionResult = await TalkingToolHandles(
          arguments['isquestion'],
          arguments['content'],
        );
        messages = MemoryBox(historyMessages:messages.historyMessages, modelResponse: answer, toolResult: functionResult.toString());
  await messages.addNonNullValuesToHistory();

        toolResumer(toolCall, functionResult, messages);
        return;
      }
    }
  }
  messages = MemoryBox(historyMessages:messages.historyMessages, modelResponse: answer);
  await messages.addNonNullValuesToHistory();
    if (postCallback != null) {
          postCallback();
        }
}
