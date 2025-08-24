import 'package:hori/atri_core/core/database/tool.dart';
import 'package:openai_dart/openai_dart.dart';



Future<FunctionObject> toolMaker(ToolObject toolObj) async {
  final toolOb = ToolObject.fromToolObj(toolObj);
  toolOb.parameters.toMap();
  final tool = FunctionObject(
    name: toolOb.name,
    description: toolOb.description,
    parameters: toolOb.parameters.toMap(),
  );
  return tool;
}
