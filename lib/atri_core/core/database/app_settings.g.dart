// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      id: fields[0] as int,
      gptApiKey: fields[1] as String?,
      geminiApiKey: fields[2] as String?,
      defaultLlmProvider: fields[3] as String,
      lastUpdated: fields[4] as DateTime,
      defaultModelGpt: fields[5] as String,
      defaultModelGemini: fields[6] as String,
      temperature: fields[7] as double,
      topP: fields[8] as double,
      maxTokens: fields[9] as int,
      enableStreaming: fields[10] as bool,
      voice: fields[11] as String,
      enableTools: fields[12] as bool,
      baseUrl: fields[13] as String,
      baseUrl2: fields[14] as String,
      usingFallback: fields[15] as bool,
      usingFallbackModel: fields[16] as bool,
      gptFallbackModel: fields[17] as String,
      geminiFallbackModel: fields[18] as String,
      defaultContextLimitbasedOnMessage: fields[19] as int,
      whereSouldSaveAppContents: fields[20] as String,
      defaultModality: fields[21] as String,
      safetySettingHarassment: fields[22] as String,
      safetySettingHateSpeech: fields[23] as String,
      safetySettingSexuallyExplicit: fields[24] as String,
      safetySettingDangerousContent: fields[25] as String,
      topK: fields[26] as int,
      presencePenalty: fields[27] as double,
      frequencyPenalty: fields[28] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.gptApiKey)
      ..writeByte(2)
      ..write(obj.geminiApiKey)
      ..writeByte(3)
      ..write(obj.defaultLlmProvider)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.defaultModelGpt)
      ..writeByte(6)
      ..write(obj.defaultModelGemini)
      ..writeByte(7)
      ..write(obj.temperature)
      ..writeByte(8)
      ..write(obj.topP)
      ..writeByte(9)
      ..write(obj.maxTokens)
      ..writeByte(10)
      ..write(obj.enableStreaming)
      ..writeByte(11)
      ..write(obj.voice)
      ..writeByte(12)
      ..write(obj.enableTools)
      ..writeByte(13)
      ..write(obj.baseUrl)
      ..writeByte(14)
      ..write(obj.baseUrl2)
      ..writeByte(15)
      ..write(obj.usingFallback)
      ..writeByte(16)
      ..write(obj.usingFallbackModel)
      ..writeByte(17)
      ..write(obj.gptFallbackModel)
      ..writeByte(18)
      ..write(obj.geminiFallbackModel)
      ..writeByte(19)
      ..write(obj.defaultContextLimitbasedOnMessage)
      ..writeByte(20)
      ..write(obj.whereSouldSaveAppContents)
      ..writeByte(21)
      ..write(obj.defaultModality)
      ..writeByte(22)
      ..write(obj.safetySettingHarassment)
      ..writeByte(23)
      ..write(obj.safetySettingHateSpeech)
      ..writeByte(24)
      ..write(obj.safetySettingSexuallyExplicit)
      ..writeByte(25)
      ..write(obj.safetySettingDangerousContent)
      ..writeByte(26)
      ..write(obj.topK)
      ..writeByte(27)
      ..write(obj.presencePenalty)
      ..writeByte(28)
      ..write(obj.frequencyPenalty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
