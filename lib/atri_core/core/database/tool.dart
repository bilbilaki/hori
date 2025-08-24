import 'dart:convert';
import 'package:hive/hive.dart';

part 'tool.g.dart';

@HiveType(typeId: 7)
class PropertySpec extends HiveObject {
 @HiveField(0)
 String name;

 @HiveField(1)
 String type;

 @HiveField(2)
 String description;

 PropertySpec({
 required this.name,
 required this.type,
 required this.description,
 });

 /// Create PropertySpec from a Map (tolerant to JSON strings or Map inputs).
 factory PropertySpec.fromMap(Map<String, dynamic> map) {
   return PropertySpec(
     name: map['name']?.toString() ?? '',
     type: map['type']?.toString() ?? '',
     description: map['description']?.toString() ?? '',
   );
 }

 /// Convert to a plain map.
 Map<String, dynamic> toMap() {
   return {
     'name': name,
     'type': type,
     'description': description,
   };
 }
}

@HiveType(typeId: 6)
class ToolParameters extends HiveObject {
 @HiveField(0)
 String type; // e.g., "object"

 @HiveField(1)
 List<PropertySpec> properties;

 @HiveField(2)
 List<String> required;

 ToolParameters({
 required this.type,
 required this.properties,
 required this.required,
 });

 /// Create ToolParameters from a dynamic source (Map, JSON string, or existing ToolParameters map).
 factory ToolParameters.fromMap(dynamic src) {
   if (src == null) {
     return ToolParameters(type: 'object', properties: [], required: []);
   }
   if (src is ToolParameters) {
     return ToolParameters(
       type: src.type,
       properties: List<PropertySpec>.from(src.properties),
       required: List<String>.from(src.required),
     );
   }
   Map<String, dynamic> map;
   if (src is String) {
     try {
       final decoded = Map<String, dynamic>.from(jsonDecode(src));
       map = decoded;
     } catch (_) {
       return ToolParameters(type: 'object', properties: [], required: []);
     }
   } else if (src is Map) {
     map = Map<String, dynamic>.from(src);
   } else {
     return ToolParameters(type: 'object', properties: [], required: []);
   }

   final propsRaw = map['properties'];
   List<PropertySpec> props = [];
   if (propsRaw is List) {
     for (final p in propsRaw) {
       if (p is Map) {
         props.add(PropertySpec.fromMap(Map<String, dynamic>.from(p)));
       } else if (p is PropertySpec) {
         props.add(p);
       }
     }
   }

   final reqRaw = map['required'];
   List<String> reqs = [];
   if (reqRaw is List) {
     reqs = List<String>.from(reqRaw.map((e) => e.toString()));
   }

   return ToolParameters(
     type: map['type']?.toString() ?? 'object',
     properties: props,
     required: reqs,
   );
 }

 /// Convert to Map
 Map<String, dynamic> toMap() {
   return {
     'type': type,
     'properties': properties.map((p) => p.toMap()).toList(),
     'required': required,
   };
 }
}

@HiveType(typeId: 5)
class ToolObject extends HiveObject {
 @HiveField(0)
 String name;

 @HiveField(1)
 String description;

 @HiveField(2)
 ToolParameters parameters;

 ToolObject({
 required this.name,
 required this.description,
 required this.parameters,
 });

 /// Create ToolObject from a Map or similar representation.
 factory ToolObject.fromMap(Map<String, dynamic> map) {
   final params = map['parameters'] ?? map['params'] ?? {};
   return ToolObject(
     name: map['name']?.toString() ?? '',
     description: map['description']?.toString() ?? '',
     parameters: ToolParameters.fromMap(params),
   );
 }

 /// Convert to a plain map for serialization/transport.
 Map<String, dynamic> toMap() {
   return {
     'name': name,
     'description': description,
     'parameters': parameters.toMap(),
   };
 }

 /// Helper to create a ToolObject from a ToolObj (application layer).
 /// Accepts a dynamic `obj` (Map, ToolObj, or any object with the expected fields).
 ToolObject.fromToolObj(dynamic obj)
     : name = (obj is Map) ? (obj['name']?.toString() ?? '') : (obj?.name?.toString() ?? ''),
       description = (obj is Map) ? (obj['description']?.toString() ?? '') : (obj?.description?.toString() ?? ''),
       parameters = ToolParameters.fromMap(
         (obj is Map)
             ? (obj['parameters'] ?? obj['params'] ?? {})
             : (obj?.parameters ?? obj?.params ?? {}),
       );
 }