import 'dart:convert';
import 'package:hori/atri_core/core/clients.dart';
import 'package:hori/atri_core/memory/schema.dart';
import 'package:hori/atri_core/platforms/input_helpers.dart';
import 'package:hori/atri_core/tools/tool_presets.dart';
import 'package:hori/atri_core/tools/tool_presets_handler.dart';
import 'package:openai_dart/openai_dart.dart';

class ModalityModels {
  final List<ChatCompletionModality> modalityList;
  ModalityModels(this.modalityList);
}

class AudioOptions {
  final ChatCompletionAudioOptions audioOptions;
  AudioOptions(this.audioOptions);
}

Future<ChatCompletionAudioOptions> setAudioOptions(String voice) async {
  var audOpt = ChatCompletionAudioOptions(
    voice: getOpenAIVoice(voice),
    format: ChatCompletionAudioFormat.wav,
  );

  return audOpt;
}

var modalList = [ChatCompletionModality.text, ChatCompletionModality.audio];
var listModal = ModalityModels(modalList);

Future<void> audioOutput(MemoryBox messages, String voice) async {
  var optAud = AudioOptions(await setAudioOptions(voice));

  final res = await client2.createChatCompletion(
    request: CreateChatCompletionRequest(
      model: ChatCompletionModel.model(ChatCompletionModels.gpt4oAudioPreview),
      modalities: listModal.modalityList,
      audio: optAud.audioOptions,
      messages: messages.historyMessages,
      tools: [atttr],
    ),
  );
  final choice = res.choices.first;
  final audio = choice.message.audio;
      messages = MemoryBox(
      historyMessages: messages.historyMessages,
      modelGeneratedAudio: base64Encode(audio?.data.codeUnits ?? [0]),
      audioOutTranscript: audio?.transcript,
    );
        await messages.addNonNullValuesToHistory();

  print(audio?.id);
  print(audio?.expiresAt);
  print(audio?.transcript);
  print(audio?.data);
  if (res.choices.first.message.toolCalls != null &&
      res.choices.first.message.toolCalls != '' &&
      res.choices.first.message.toolCalls!.isNotEmpty) {
    final toolCall = res.choices.first.message.toolCalls!.first;
    final functionCall = toolCall.function;
    final arguments =
        json.decode(functionCall.arguments) as Map<String, dynamic>;
    Map<String, dynamic> functionResult = await callToolRunner(
      messages.historyMessages.last,
    );

    final messagesfake = MemoryBox(
      historyMessages: messages.historyMessages,
      toolResult: functionResult,
    );
    await messagesfake.addNonNullValuesToHistory();
    final res2 = await client2.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.model(
          ChatCompletionModels.gpt4oAudioPreview,
        ),
        modalities: listModal.modalityList,
        audio: optAud.audioOptions,
        messages: messagesfake.historyMessages,
        tools: [atttr],
      ),
    );
    final choice2 = res2.choices.first;
    final audio2 = choice2.message.audio;
    print(audio?.id);
    print(audio?.expiresAt);
    print(audio?.transcript);
    print(audio?.data);
    if (res2.choices.first.message.toolCalls != null &&
        res2.choices.first.message.toolCalls != '' &&
        res2.choices.first.message.toolCalls!.isNotEmpty) {
      final toolCall = res2.choices.first.message.toolCalls!.first;
      final functionCall = toolCall.function;
      final arguments =
          json.decode(functionCall.arguments) as Map<String, dynamic>;
      Map<String, dynamic> functionResult = await callToolRunner(
        messages.historyMessages.last,
      );
      // Convert the tool result into the MemoryBox history so downstream code
      // can consume it (keeps behaviour consistent with other tool flows).
      ////TODO  sync this model for audio chatting if want tool calling gets more steps I most create tool to switch model type here and show this change in user ui ,,,, and some other handles. this audio models a bit slow
      //   messages = MemoryBox(historyMessages: messages.historyMessages, toolResult: functionResult);
      // await messages.addNonNullValuesToHistory();
      // If you need to forward this back into the original messages or take
      // additional actions, do so here. For now we simply return after adding
      // the tool result into history so the caller can continue.
      return;
    }

    messages = MemoryBox(
      historyMessages: messages.historyMessages,
      modelGeneratedAudio: base64Encode(audio2?.data.codeUnits ?? [0]),
      audioOutTranscript: audio2?.transcript,
    );
    await messages.addNonNullValuesToHistory();
  }
}
