// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sdk_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SdkMessageAdapter extends TypeAdapter<SdkMessage> {
  @override
  final int typeId = 8;

  @override
  SdkMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SdkMessage(
      id: fields[0] as int,
      userMessages: fields[1] as String?,
      systemMessage: fields[2] as String?,
      modelResponse: fields[3] as String?,
      modelGeneratedAudio: fields[4] as String?,
      modelGeneratedImage: fields[5] as String?,
      toolCalls: (fields[6] as Map?)?.cast<String, dynamic>(),
      toolResult: (fields[7] as Map?)?.cast<String, dynamic>(),
      filePath: fields[8] as String?,
      fileType: fields[9] as String?,
      audioOutTranscript: fields[10] as String?,
      chatSummery: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SdkMessage obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userMessages)
      ..writeByte(2)
      ..write(obj.systemMessage)
      ..writeByte(3)
      ..write(obj.modelResponse)
      ..writeByte(4)
      ..write(obj.modelGeneratedAudio)
      ..writeByte(5)
      ..write(obj.modelGeneratedImage)
      ..writeByte(6)
      ..write(obj.toolCalls)
      ..writeByte(7)
      ..write(obj.toolResult)
      ..writeByte(8)
      ..write(obj.filePath)
      ..writeByte(9)
      ..write(obj.fileType)
      ..writeByte(10)
      ..write(obj.audioOutTranscript)
      ..writeByte(11)
      ..write(obj.chatSummery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SdkMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
