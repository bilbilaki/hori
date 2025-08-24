import 'package:openai_dart/openai_dart.dart';

FunctionObject function = FunctionObject(
  name: 'talking_tool',
  description: 'by calling this tool you can ask question or telling a fact to who you chat with that . like before performing task asking some question or telling what you want t do',
  parameters: {
    'type': 'object',
    'properties': {
      'isquestion': {
        'type': 'bool',
        'description': 'is this message content question <true> or fact<false>',
      },
      'content': {
        'type': 'string',
        'description': 'content who you chat with that most see ',
      },
    },
    'required': ['isquestion','content'],
  },
);
ChatCompletionTool tool = ChatCompletionTool(
  type: ChatCompletionToolType.function,
  function: function,
);
FunctionObject audioToolToToolRunner = FunctionObject(
  name: 'calling_tool_model',
  description: 'you are audio chat model .if based on requests or message from who you talking with that you find need to using tool just trigger this tool to calling tool model for task',
  parameters: {
    'type': 'object',
    'properties': {
      'call': {
        'type': 'bool',
        'description': '',
      },
    },
    'required': [],
  },
);
ChatCompletionTool atttr = ChatCompletionTool(
  type: ChatCompletionToolType.function,
  function: audioToolToToolRunner,
);