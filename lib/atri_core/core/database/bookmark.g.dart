// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookMarkAdapter extends TypeAdapter<BookMark> {
  @override
  final int typeId = 9;

  @override
  BookMark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookMark(
      id: fields[0] as int,
      conversationIds: (fields[1] as List).cast<int>(),
      userMessageIds: (fields[2] as List).cast<int>(),
      assistantMessageIds: (fields[3] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, BookMark obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationIds)
      ..writeByte(2)
      ..write(obj.userMessageIds)
      ..writeByte(3)
      ..write(obj.assistantMessageIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookMarkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
