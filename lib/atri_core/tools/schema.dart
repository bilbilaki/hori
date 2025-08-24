import 'dart:convert';

import 'package:hori/atri_core/core/database/tool.dart';
import 'package:openai_dart/openai_dart.dart';



class ToolObj {
  String name;
  String description;
  Map<String, dynamic> parameters;
  ToolObj({
    required this.name,
    required this.description,
    required this.parameters,
  });



  factory ToolObj.fromMap(Map<String, dynamic> map) {
    return ToolObj(
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      parameters: _mapFromDynamic(map['parameters']),
    );
  }

  factory ToolObj.fromJson(String source) => ToolObj.fromMap(jsonDecode(source));

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'parameters': parameters,
    };
  }

  String toJson() => jsonEncode(toMap());

  ToolObj copyWith({
    String? name,
    String? description,
    Map<String, dynamic>? parameters,
  }) {
    return ToolObj(
      name: name ?? this.name,
      description: description ?? this.description,
      parameters: parameters ?? Map<String, dynamic>.from(this.parameters),
    );
  }

  @override
  String toString() => 'ToolObj(name: $name, description: $description, parameters: $parameters)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolObj &&
        other.name == name &&
        other.description == description &&
        _deepEquals(other.parameters, parameters);
  }

  @override
  int get hashCode => name.hashCode ^ description.hashCode ^ _deepHash(parameters);

  // Create from a FunctionObject (from openai_dart)
  factory ToolObj.fromFunctionObject(FunctionObject function) {
    return ToolObj(
      name: function.name,
      description: function.description ?? '',
      parameters: _mapFromDynamic(function.parameters),
    );
  }

  // Create from a ChatCompletionTool (from openai_dart)
  factory ToolObj.fromChatCompletionTool(ChatCompletionTool tool) {
    if (tool.type == ChatCompletionToolType.function) {
      final func = tool.function;
      return ToolObj.fromFunctionObject(func);
    } else {
      // For non-function tool types, attempt to extract available fields generically:
      return ToolObj(
        name: tool.runtimeType.toString(),
        description: '',
        parameters: tool.toString().isNotEmpty ? {'raw': tool.toString()} : {},
      );
    }
  }

  // Create from a ToolObject (database layer) and convert back.
  factory ToolObj.fromToolObject(ToolObject obj) {
  return ToolObj(
  name: obj.name,
  description: obj.description,
  parameters: _mapFromDynamic(obj.parameters.toMap()),
  );
  }
  
  /// Convert this ToolObj into a database ToolObject instance.
  ToolObject toToolObject() {
  return ToolObject.fromMap({
  'name': name,
  'description': description,
  'parameters': parameters,
  });
  }
  
  // Helpers
  static Map<String, dynamic> _mapFromDynamic(dynamic src) {
  if (src == null) return {};
  if (src is Map<String, dynamic>) return Map<String, dynamic>.from(src);
  if (src is Map) {
  return src.map((k, v) => MapEntry(k.toString(), v));
  }
  try {
  // If it's JSON string
  if (src is String) {
  final decoded = jsonDecode(src);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  } catch (_) {}
  return {'value': src};
  }

  static bool _deepEquals(Map a, Map b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final va = a[key];
      final vb = b[key];
      if (va is Map && vb is Map) {
        if (!_deepEquals(va, vb)) return false;
      } else if (va != vb) {
        return false;
      }
    }
    return true;
  }

  static int _deepHash(Map map) {
    var result = 0;
    for (final entry in map.entries) {
      final hKey = entry.key.hashCode;
      final value = entry.value;
      final hVal = value is Map ? _deepHash(value) : value.hashCode;
      result ^= hKey ^ hVal;
    }
    return result;
  }
}

