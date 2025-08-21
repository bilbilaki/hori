// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translator_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranslatorConfigAdapter extends TypeAdapter<TranslatorConfig> {
  @override
  final int typeId = 0;

  @override
  TranslatorConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranslatorConfig()
      ..apiKey = fields[0] as String
      ..baseUrl = fields[1] as String
      ..rateLimitReq = fields[2] as int
      ..rateLimitToken = fields[3] as int
      ..inputCost = fields[4] as double
      ..outputCost = fields[5] as double
      ..waitSec = fields[6] as int
      ..inputTokenCount = fields[7] as int
      ..outputTokenCount = fields[8] as int
      ..inputLang = fields[9] as String
      ..outputLang = fields[10] as String
      ..autoDetectInput = fields[11] as bool
      ..batchN = fields[12] as int
      ..outputFormat = fields[13] as String
      ..modelId = fields[14] as String
      ..systemPrompt = fields[15] as String
      ..temp = fields[16] as double;
  }

  @override
  void write(BinaryWriter writer, TranslatorConfig obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.apiKey)
      ..writeByte(1)
      ..write(obj.baseUrl)
      ..writeByte(2)
      ..write(obj.rateLimitReq)
      ..writeByte(3)
      ..write(obj.rateLimitToken)
      ..writeByte(4)
      ..write(obj.inputCost)
      ..writeByte(5)
      ..write(obj.outputCost)
      ..writeByte(6)
      ..write(obj.waitSec)
      ..writeByte(7)
      ..write(obj.inputTokenCount)
      ..writeByte(8)
      ..write(obj.outputTokenCount)
      ..writeByte(9)
      ..write(obj.inputLang)
      ..writeByte(10)
      ..write(obj.outputLang)
      ..writeByte(11)
      ..write(obj.autoDetectInput)
      ..writeByte(12)
      ..write(obj.batchN)
      ..writeByte(13)
      ..write(obj.outputFormat)
      ..writeByte(14)
      ..write(obj.modelId)
      ..writeByte(15)
      ..write(obj.systemPrompt)
      ..writeByte(16)
      ..write(obj.temp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslatorConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
