import 'package:flutter/material.dart';
import 'package:hori/end2-1.dart';
import 'package:hori/end2-3-2.dart';
import 'package:hori/image_editor/ai_image_editor_app.dart';
import 'package:hori/translator/configuration/translator_config.dart';
import 'package:hori/translator/interfaces/chunker_translator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hori/translator/interfaces/configuration_interface.dart';
import 'package:hori/translator/utils/colors.dart';

late TranslatorConfig translatorConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 1. Register the adapter
  Hive.registerAdapter(TranslatorConfigAdapter());

  // 2. Open the box. It will store TranslatorConfig objects.
  final configBox = await Hive.openBox<TranslatorConfig>('app_config');

  // 3. The "Load or Create" logic
  if (configBox.isEmpty) {
    // Box is empty, this is the first run!
    print("First run: Creating default configuration...");
    translatorConfig = TranslatorConfig.withDefaults();
    configBox.put('config', translatorConfig); // Save the new default config
  } else {
    // Box has data, load the existing configuration
    print("Loading existing configuration...");
    translatorConfig = configBox.get('config')!; // Load it from the box
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.awesomeDarkTheme,
      home: MyHomePage(),
         routes: {
        '/config': (_) => const ConfigPage(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToolBox'),
          actions: [
          IconButton(
            tooltip: 'Configuration',
            onPressed: () => Navigator.pushNamed(context, '/config'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () =>     Navigator.push(context, MaterialPageRoute(builder: (_) => FileSearchScreen())),
              child: Text('directory file parser'),
            ),
            SizedBox(height: 20),
             ElevatedButton(
              onPressed: () =>     Navigator.push(context, MaterialPageRoute(builder: (_) => ChunkerInterfaceand())),
              child: Text('chuncker translator'),
            ),
              SizedBox(height: 20),
             ElevatedButton(
              onPressed: () =>     Navigator.push(context, MaterialPageRoute(builder: (_) => AiImageEditorApp())),
              child: Text('image editor'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfToolkitApp())),
              child: Text('pdf tools'),
            ),
          ],
        ),
      ),
    );
  }
}

