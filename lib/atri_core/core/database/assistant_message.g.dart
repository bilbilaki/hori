// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssistantMessageAdapter extends TypeAdapter<AssistantMessage> {
  @override
  final int typeId = 4;

  @override
  AssistantMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssistantMessage(
      id: fields[0] as int,
      conversationId: fields[1] as int,
      reasoning: fields[2] as String?,
      content: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      mediaType: fields[5] as String?,
      mediaPath: fields[6] as String?,
      mediaMetadata: fields[7] as String?,
      toolCalls: fields[8] as String?,
      tokenCount: fields[9] as int?,
      isError: fields[10] as bool,
      errorMessage: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AssistantMessage obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.reasoning)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.mediaType)
      ..writeByte(6)
      ..write(obj.mediaPath)
      ..writeByte(7)
      ..write(obj.mediaMetadata)
      ..writeByte(8)
      ..write(obj.toolCalls)
      ..writeByte(9)
      ..write(obj.tokenCount)
      ..writeByte(10)
      ..write(obj.isError)
      ..writeByte(11)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
