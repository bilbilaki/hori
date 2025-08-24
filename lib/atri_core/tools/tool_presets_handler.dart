import 'dart:convert';

import 'package:hori/atri_core/core/database/tool.dart';
import 'package:hori/atri_core/memory/schema.dart';
import 'package:hori/atri_core/tools/future.dart';
import 'package:hori/atri_core/tools/tool_functions.dart';
import 'package:openai_dart/openai_dart.dart';

////TODO  this is fake tool and just for demo . I most implant real tool later
Future<Map<String, dynamic>> TalkingToolHandles(
  dynamic isQuestion,
  dynamic content,
) async {
  try {
    // If content is a JSON string, attempt to parse it into a Map
    if (content is String) {
      try {
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return {'success': true, 'isquestion': isQuestion, 'parsed': decoded};
        } else {
          return {
            'success': true,
            'isquestion': isQuestion,
            'content': content,
          };
        }
      } catch (_) {
        // Not JSON — return raw string content
        return {'success': true, 'isquestion': isQuestion, 'content': content};
      }
    }
    // If content is a Map (or Map-like), normalize and return it
    if (content is Map) {
      return Map<String, dynamic>.from(content);
    }
    // Fallback: return a simple map with stringified content
    return {
      'success': true,
      'isquestion': isQuestion,
      'content': content?.toString(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

Future<Map<String, dynamic>> toolMakerHandler(Map<String, dynamic> args) async {
  final ToolObject tookbake = ToolObject(
    name: args['name'],
    description: args['description'],
    parameters: args['parameters'],
  );
  try {
    await toolMaker(tookbake);
    return {'success': true};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

Future<Map<String, dynamic>> callToolRunner(
  ChatCompletionMessage messages,
) async {
  final memBox = MemoryBox(
    historyMessages: [messages],
    systemMessage:
        "this message is forwarded to tool runner model . you are tool runner model and should read this last message is sended to you , find tool calls need to do . then starting just doing tool calls until task succefully done .",
  );
  await memBox.addNonNullValuesToHistory();
  int d = 0;
  void callback() async {
    d = 0;
  }

  final res = await toolStarter(memBox,postCallback: callback);
  while (d == 0) {
     }
final result = memBox.toolResult;

    return result;
 
}
