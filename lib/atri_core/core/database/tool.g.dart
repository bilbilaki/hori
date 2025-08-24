// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PropertySpecAdapter extends TypeAdapter<PropertySpec> {
  @override
  final int typeId = 7;

  @override
  PropertySpec read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PropertySpec(
      name: fields[0] as String,
      type: fields[1] as String,
      description: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PropertySpec obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertySpecAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ToolParametersAdapter extends TypeAdapter<ToolParameters> {
  @override
  final int typeId = 6;

  @override
  ToolParameters read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToolParameters(
      type: fields[0] as String,
      properties: (fields[1] as List).cast<PropertySpec>(),
      required: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ToolParameters obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.properties)
      ..writeByte(2)
      ..write(obj.required);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolParametersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ToolObjectAdapter extends TypeAdapter<ToolObject> {
  @override
  final int typeId = 5;

  @override
  ToolObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToolObject(
      name: fields[0] as String,
      description: fields[1] as String,
      parameters: fields[2] as ToolParameters,
    );
  }

  @override
  void write(BinaryWriter writer, ToolObject obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.parameters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
