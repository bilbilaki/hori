import 'package:flutter/material.dart';
import 'package:hori/end2-1.dart';
import 'package:hori/end2-3-2.dart';
import 'package:hori/translator/interfaces/chunker_translator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToolBox'),
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

