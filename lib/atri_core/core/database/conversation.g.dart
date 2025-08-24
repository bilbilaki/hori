// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 2;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation(
      id: fields[0] as int,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      providerUsed: fields[4] as String,
      modelUsed: fields[5] as String?,
      initialPrompt: fields[6] as String?,
      totalTokens: fields[7] as int,
      isArchived: fields[8] as bool,
      userMessageIds: (fields[9] as List).cast<int>(),
      assistantMessageIds: (fields[10] as List).cast<int>(),
      toolIds: (fields[11] as List).cast<int>(),
      sdkMessageIds: (fields[12] as List).cast<int>(),
      bookmarkIds: (fields[13] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.providerUsed)
      ..writeByte(5)
      ..write(obj.modelUsed)
      ..writeByte(6)
      ..write(obj.initialPrompt)
      ..writeByte(7)
      ..write(obj.totalTokens)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.userMessageIds)
      ..writeByte(10)
      ..write(obj.assistantMessageIds)
      ..writeByte(11)
      ..write(obj.toolIds)
      ..writeByte(12)
      ..write(obj.sdkMessageIds)
      ..writeByte(13)
      ..write(obj.bookmarkIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
