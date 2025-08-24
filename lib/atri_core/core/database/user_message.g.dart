// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserMessageAdapter extends TypeAdapter<UserMessage> {
  @override
  final int typeId = 3;

  @override
  UserMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserMessage(
      id: fields[0] as int,
      conversationId: fields[1] as int,
      content: fields[2] as String?,
      timestamp: fields[3] as DateTime,
      mediaType: fields[4] as String?,
      mediaPath: fields[5] as String?,
      mediaMetadata: fields[6] as String?,
      tokenCount: fields[7] as int?,
      isError: fields[8] as bool,
      errorMessage: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserMessage obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.mediaType)
      ..writeByte(5)
      ..write(obj.mediaPath)
      ..writeByte(6)
      ..write(obj.mediaMetadata)
      ..writeByte(7)
      ..write(obj.tokenCount)
      ..writeByte(8)
      ..write(obj.isError)
      ..writeByte(9)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
