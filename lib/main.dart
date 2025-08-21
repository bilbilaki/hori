import 'package:flutter/material.dart';
import 'package:hori/end2-1.dart';
import 'package:hori/end2-3-2.dart';
import 'package:hori/translator/configuration/translator_config.dart';
import 'package:hori/translator/interfaces/chunker_translator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hori/translator/interfaces/configuration_interface.dart';

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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark, // Awesome style often includes dark theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.black12,
        ),
        scaffoldBackgroundColor: Colors.black87,
        cardColor: Colors.black26, // For cards/sections
        textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white70, displayColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          hintStyle: TextStyle(color: Colors.white30),
          labelStyle: TextStyle(color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.tealAccent;
            }
            return Colors.grey[600];
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.tealAccent.withOpacity(0.5);
            }
            return Colors.grey[700];
          }),
        ),
        sliderTheme: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: Colors.tealAccent,
          inactiveTrackColor: Colors.white.withOpacity(0.3),
          thumbColor: Colors.tealAccent,
          overlayColor: Colors.tealAccent.withOpacity(0.2),
          valueIndicatorColor: Colors.tealAccent,
          valueIndicatorTextStyle: TextStyle(color: Colors.black),
          showValueIndicator: ShowValueIndicator.always,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // Button background color
            foregroundColor: Colors.white, // Button text color
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: MyHomePage(),
         routes: {
        '/config': (_) => const ConfigPage(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  

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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfToolkitApp())),
              child: Text('pdf tools'),
            ),
          ],
        ),
      ),
    );
  }
}

