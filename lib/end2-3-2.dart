// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hori/end2-3.dart';

class PdfToolkitApp extends StatelessWidget {
  const PdfToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Toolkit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PdfHomeScreen(),
    );
  }
}

class PdfHomeScreen extends StatefulWidget {
  const PdfHomeScreen({super.key});

  @override
  _PdfHomeScreenState createState() => _PdfHomeScreenState();
}

class _PdfHomeScreenState extends State<PdfHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('PDF Toolkit'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Create'),
              Tab(text: 'Modify'),
              Tab(text: 'Extract & Find'),
              Tab(text: 'Security & Forms'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CreatePdfTab(),
            ModifyPdfTab(),
            ExtractFindTab(),
            SecurityFormsTab(),
          ],
        ),
      ),
    );
  }
}

class CreatePdfTab extends StatelessWidget {
  const CreatePdfTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CreateSimplePdfCard(),
          AddTrueTypeTextPdfCard(),
          AddImagesToPdfCard(),
          CreatePdfWithFlowLayoutCard(),
          AddBulletsAndListsToPdfCard(),
          AddTablesToPdfCard(),
        ],
      ),
    );
  }
}

class ModifyPdfTab extends StatelessWidget {
  const ModifyPdfTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          LoadAndModifyExistingPdfCard(),
          AddRemovePageCard(),
          AddHeadersAndFootersToPdfCard(),
        ],
      ),
    );
  }
}

class ExtractFindTab extends StatelessWidget {
  const ExtractFindTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ExtractTextFromAllPdfPagesCard(),
          ExtractTextFromSpecificPdfPageCard(),
          FindTextInPdfCard(),
        ],
      ),
    );
  }
}

class SecurityFormsTab extends StatelessWidget {
  const SecurityFormsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          EncryptPdfDocumentCard(),
          CreatePdfFormCard(),
          FillExistingPdfFormCard(),
          FlattenExistingPdfFormCard(),
          SignNewPdfDocumentCard(),
        ],
      ),
    );
  }
}

class CreateSimplePdfCard extends StatefulWidget {
  const CreateSimplePdfCard({super.key});

  @override
  _CreateSimplePdfCardState createState() => _CreateSimplePdfCardState();
}

class _CreateSimplePdfCardState extends State<CreateSimplePdfCard> {
  final _formKey = GlobalKey<FormState>();
  String _text = '';
  String _outputFileName = '';
  String _fontFamily = 'helvetica';
  double _fontSize = 12;
  Color _textColor = Colors.black;
  double _boundsX = 0;
  double _boundsY = 0;
  double _boundsWidth = 150;
  double _boundsHeight = 20;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Simple Text PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text'),
                validator: (value) => value!.isEmpty ? 'Text is required' : null,
                onSaved: (value) => _text = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              DropdownButtonFormField<String>(
                value: _fontFamily,
                decoration: InputDecoration(labelText: 'Font Family'),
                items: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _fontFamily = value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Font Size'),
                keyboardType: TextInputType.number,
                initialValue: _fontSize.toString(),
                onSaved: (value) => _fontSize = double.tryParse(value!) ?? 12,
              ),
              BlockPicker(
                pickerColor: _textColor,
                onColorChanged: (color) => setState(() => _textColor = color),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds X'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsX.toString(),
                      onSaved: (value) => _boundsX = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Y'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsY.toString(),
                      onSaved: (value) => _boundsY = double.tryParse(value!) ?? 0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Width'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsWidth.toString(),
                      onSaved: (value) => _boundsWidth = double.tryParse(value!) ?? 150,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Height'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsHeight.toString(),
                      onSaved: (value) => _boundsHeight = double.tryParse(value!) ?? 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await createSimplePdfFromText(
                      text: _text,
                      fontFamily: _fontFamily,
                      fontSize: _fontSize,
                 //     outputFileName: _outputFileName,
                      colorR: _textColor.red,
                      colorG: _textColor.green,
                      colorB: _textColor.blue,
                      boundsX: _boundsX,
                      boundsY: _boundsY,
                      boundsWidth: _boundsWidth,
                      boundsHeight: _boundsHeight,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF created successfully!')));

                  }
                },
                child: Text('Generate PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTrueTypeTextPdfCard extends StatefulWidget {
  const AddTrueTypeTextPdfCard({super.key});

  @override
  _AddTrueTypeTextPdfCardState createState() => _AddTrueTypeTextPdfCardState();
}

class _AddTrueTypeTextPdfCardState extends State<AddTrueTypeTextPdfCard> {
  final _formKey = GlobalKey<FormState>();
  String _text = '';
  String _fontFilePath = '';
  String _outputFileName = '';
  double _fontSize = 12;
  double _boundsX = 0;
  double _boundsY = 0;
  double _boundsWidth = 200;
  double _boundsHeight = 50;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TrueType Font Text PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text'),
                validator: (value) => value!.isEmpty ? 'Text is required' : null,
                onSaved: (value) => _text = value!,
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ttf']);
                  if (result != null) {
                    setState(() => _fontFilePath = result.files.single.path!);
                  }
                },
                child: Text('Pick Font File'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Font Size'),
                keyboardType: TextInputType.number,
                initialValue: _fontSize.toString(),
                onSaved: (value) => _fontSize = double.tryParse(value!) ?? 12,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds X'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsX.toString(),
                      onSaved: (value) => _boundsX = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Y'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsY.toString(),
                      onSaved: (value) => _boundsY = double.tryParse(value!) ?? 0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Width'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsWidth.toString(),
                      onSaved: (value) => _boundsWidth = double.tryParse(value!) ?? 200,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Height'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsHeight.toString(),
                      onSaved: (value) => _boundsHeight = double.tryParse(value!) ?? 50,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await addTrueTypeTextToPdf(
                      text: _text,
                      fontFilePath: _fontFilePath,
                      fontSize: _fontSize,
                      outputFileName: _outputFileName,
                      boundsX: _boundsX,
                      boundsY: _boundsY,
                      boundsWidth: _boundsWidth,
                      boundsHeight: _boundsHeight,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF created successfully!')));

                  }
                },
                child: Text('Generate PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddImagesToPdfCard extends StatefulWidget {
  const AddImagesToPdfCard({super.key});

  @override
  _AddImagesToPdfCardState createState() => _AddImagesToPdfCardState();
}

class _AddImagesToPdfCardState extends State<AddImagesToPdfCard> {
  final _formKey = GlobalKey<FormState>();
  String _imageFilePath = '';
  String _outputFileName = '';
  double _boundsX = 0;
  double _boundsY = 0;
  double _boundsWidth = 500;
  double _boundsHeight = 200;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Images to PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    setState(() => _imageFilePath = result.files.single.path!);
                  }
                },
                child: Text('Pick Image File'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds X'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsX.toString(),
                      onSaved: (value) => _boundsX = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Y'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsY.toString(),
                      onSaved: (value) => _boundsY = double.tryParse(value!) ?? 0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Width'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsWidth.toString(),
                      onSaved: (value) => _boundsWidth = double.tryParse(value!) ?? 500,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Height'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsHeight.toString(),
                      onSaved: (value) => _boundsHeight = double.tryParse(value!) ?? 200,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await addImagesToPdf(
                      imageFilePath: _imageFilePath,
                      outputFileName: _outputFileName,
                      boundsX: _boundsX,
                      boundsY: _boundsY,
                      boundsWidth: _boundsWidth,
                      boundsHeight: _boundsHeight,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF created successfully!')));

                  }
                },
                child: Text('Generate PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreatePdfWithFlowLayoutCard extends StatefulWidget {
  const CreatePdfWithFlowLayoutCard({super.key});

  @override
  _CreatePdfWithFlowLayoutCardState createState() => _CreatePdfWithFlowLayoutCardState();
}

class _CreatePdfWithFlowLayoutCardState extends State<CreatePdfWithFlowLayoutCard> {
  final _formKey = GlobalKey<FormState>();
  String _paragraphText = '';
  String _outputFileName = '';
  String _fontFamily = 'helvetica';
  Color _lineColor = Colors.red;
  double _lineOffset = 10;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flow Layout PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Paragraph Text'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Paragraph Text is required' : null,
                onSaved: (value) => _paragraphText = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              DropdownButtonFormField<String>(
                value: _fontFamily,
                decoration: InputDecoration(labelText: 'Font Family'),
                items: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _fontFamily = value!),
              ),
              BlockPicker(
                pickerColor: _lineColor,
                onColorChanged: (color) => setState(() => _lineColor = color),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Line Offset'),
                keyboardType: TextInputType.number,
                initialValue: _lineOffset.toString(),
                onSaved: (value) => _lineOffset = double.tryParse(value!) ?? 10,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await createPdfWithFlowLayout(
                      paragraphText: _paragraphText,
                      fontFamily: _fontFamily,
                      outputFileName: _outputFileName,
                      lineColorR: _lineColor.red,
                      lineColorG: _lineColor.green,
                      lineColorB: _lineColor.blue,
                      lineOffset: _lineOffset,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF created successfully!')));

                  }
                },
                child: Text('Generate PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddBulletsAndListsToPdfCard extends StatefulWidget {
  const AddBulletsAndListsToPdfCard({super.key});

  @override
  _AddBulletsAndListsToPdfCardState createState() => _AddBulletsAndListsToPdfCardState();
}

class _AddBulletsAndListsToPdfCardState extends State<AddBulletsAndListsToPdfCard> {
  final _formKey = GlobalKey<FormState>();
  List<String> _mainListItems = [];
  List<String> _subListItems = [];
  String _outputFileName = '';
  String _fontFamily = 'helvetica';
  double _fontSize = 12;
  double _subFontSize = 10;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bullets & Lists PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              DropdownButtonFormField<String>(
                value: _fontFamily,
                decoration: InputDecoration(labelText: 'Font Family'),
                items: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _fontFamily = value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Font Size'),
                keyboardType: TextInputType.number,
                initialValue: _fontSize.toString(),
                onSaved: (value) => _fontSize = double.tryParse(value!) ?? 12,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Sub Font Size'),
                keyboardType: TextInputType.number,
                initialValue: _subFontSize.toString(),
                onSaved: (value) => _subFontSize = double.tryParse(value!) ?? 10,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _mainListItems.add('');
                  });
                },
                child: Text('Add Main List Item'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _mainListItems.length,
                itemBuilder: (context, index) {
                  return TextFormField(
                    decoration: InputDecoration(labelText: 'Main List Item ${index + 1}'),
                    initialValue: _mainListItems[index],
                    onChanged: (value) {
                      setState(() {
                        _mainListItems[index] = value;
                      });
                    },
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _subListItems.add('');
                  });
                },
                child: Text('Add Sub List Item'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _subListItems.length,
                itemBuilder: (context, index) {
                  return TextFormField(
                    decoration: InputDecoration(labelText: 'Sub List Item ${index + 1}'),
                    initialValue: _subListItems[index],
                    onChanged: (value) {
                      setState(() {
                        _subListItems[index] = value;
                      });
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await addBulletsAndListsToPdf(
                      mainListItems: _mainListItems,
                      subListItems: _subListItems,
                      fontFamily: _fontFamily,
                      fontSize: _fontSize,
                      subFontSize: _subFontSize,
                      outputFileName: _outputFileName,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF created successfully!')));

                  }
                },
                child: Text('Generate PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTablesToPdfCard extends StatefulWidget {
  const AddTablesToPdfCard({super.key});

  @override
  _AddTablesToPdfCardState createState() => _AddTablesToPdfCardState();
}

class _AddTablesToPdfCardState extends State<AddTablesToPdfCard> {
  final _formKey = GlobalKey<FormState>();
  int _columnCount = 0;
  List<String> _headerNames = [];
  List<List<String>> _rowData = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tables to PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Column Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Column Count is required' : null,
                onSaved: (value) => _columnCount = int.tryParse(value!) ?? 0,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _headerNames.add('');
                  });
                },
                child: Text('Add Header Name'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _headerNames.length,
                itemBuilder: (context, index) {
                  return TextFormField(
                    decoration: InputDecoration(labelText: 'Header Name ${index + 1}'),
                    initialValue: _headerNames[index],
                    onChanged: (value) {
                      setState(() {
                        _headerNames[index] = value;
                      });
                    },
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _rowData.add(List.generate(_columnCount, (index) => ''));
                  });
                },
                child: Text('Add Row'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _rowData.length,
                itemBuilder: (context, rowIndex) {
                  return Column(
                    children: List.generate(_columnCount, (colIndex) {
                      return TextFormField(
                        decoration: InputDecoration(labelText: 'Row ${rowIndex + 1}, Col ${colIndex + 1}'),
                        initialValue: _rowData[rowIndex][colIndex],
                        onChanged: (value) {
                          setState(() {
                            _rowData[rowIndex][colIndex] = value;
                          });
                        },
                      );
                    }),
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await addTablesToPdf(
                      columnCount: _columnCount,
                      headerNames: _headerNames,
                      rowData: _rowData,
                      outputFileName: 'tables.pdf',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF created successfully!')));

                  }
                },
                child: Text('Generate PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadAndModifyExistingPdfCard extends StatefulWidget {
  const LoadAndModifyExistingPdfCard({super.key});

  @override
  _LoadAndModifyExistingPdfCardState createState() => _LoadAndModifyExistingPdfCardState();
}

class _LoadAndModifyExistingPdfCardState extends State<LoadAndModifyExistingPdfCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  String _outputFileName = '';
  int _pageIndex = 0;
  String _textToAdd = '';
  String _fontFamily = 'helvetica';
  double _fontSize = 12;
  Color _textColor = Colors.black;
  double _boundsX = 0;
  double _boundsY = 0;
  double _boundsWidth = 150;
  double _boundsHeight = 20;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modify Existing PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Page Index'),
                keyboardType: TextInputType.number,
                initialValue: _pageIndex.toString(),
                onSaved: (value) => _pageIndex = int.tryParse(value!) ?? 0,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text to Add'),
                validator: (value) => value!.isEmpty ? 'Text to Add is required' : null,
                onSaved: (value) => _textToAdd = value!,
              ),
              DropdownButtonFormField<String>(
                value: _fontFamily,
                decoration: InputDecoration(labelText: 'Font Family'),
                items: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _fontFamily = value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Font Size'),
                keyboardType: TextInputType.number,
                initialValue: _fontSize.toString(),
                onSaved: (value) => _fontSize = double.tryParse(value!) ?? 12,
              ),
              BlockPicker(
                pickerColor: _textColor,
                onColorChanged: (color) => setState(() => _textColor = color),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds X'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsX.toString(),
                      onSaved: (value) => _boundsX = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Y'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsY.toString(),
                      onSaved: (value) => _boundsY = double.tryParse(value!) ?? 0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Width'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsWidth.toString(),
                      onSaved: (value) => _boundsWidth = double.tryParse(value!) ?? 150,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Height'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsHeight.toString(),
                      onSaved: (value) => _boundsHeight = double.tryParse(value!) ?? 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await loadAndModifyExistingPdf(
                      inputFileName: _inputFileName,
                      outputFileName: _outputFileName,
                      pageIndex: _pageIndex,
                      textToAdd: _textToAdd,
                      fontFamily: _fontFamily,
                      fontSize: _fontSize,
                      colorR: _textColor.red,
                      colorG: _textColor.green,
                      colorB: _textColor.blue,
                      boundsX: _boundsX,
                      boundsY: _boundsY,
                      boundsWidth: _boundsWidth,
                      boundsHeight: _boundsHeight,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF modified successfully!')));

                  }
                },
                child: Text('Modify PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddRemovePageCard extends StatefulWidget {
  const AddRemovePageCard({super.key});

  @override
  _AddRemovePageCardState createState() => _AddRemovePageCardState();
}

class _AddRemovePageCardState extends State<AddRemovePageCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  String _outputFileName = '';
  int? _removePageIndex;
  String? _addText;
  String _fontFamily = 'helvetica';
  double _fontSize = 12;
  Color _textColor = Colors.black;
  double _boundsX = 0;
  double _boundsY = 0;
  double _boundsWidth = 150;
  double _boundsHeight = 20;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add/Remove Page', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Page Index to Remove (optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _removePageIndex = int.tryParse(value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text to Add to New Page (optional)'),
                onSaved: (value) => _addText = value,
              ),
              DropdownButtonFormField<String>(
                value: _fontFamily,
                decoration: InputDecoration(labelText: 'Font Family'),
                items: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _fontFamily = value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Font Size'),
                keyboardType: TextInputType.number,
                initialValue: _fontSize.toString(),
                onSaved: (value) => _fontSize = double.tryParse(value!) ?? 12,
              ),
              BlockPicker(
                pickerColor: _textColor,
                onColorChanged: (color) => setState(() => _textColor = color),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds X'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsX.toString(),
                      onSaved: (value) => _boundsX = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Y'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsY.toString(),
                      onSaved: (value) => _boundsY = double.tryParse(value!) ?? 0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Width'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsWidth.toString(),
                      onSaved: (value) => _boundsWidth = double.tryParse(value!) ?? 150,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Bounds Height'),
                      keyboardType: TextInputType.number,
                      initialValue: _boundsHeight.toString(),
                      onSaved: (value) => _boundsHeight = double.tryParse(value!) ?? 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await addRemovePageFromExistingPdf(
                      inputFileName: _inputFileName,
                      outputFileName: _outputFileName,
                      removePageIndex: _removePageIndex,
                      addText: _addText,
                      addFontFamily: _fontFamily,
                      addFontSize: _fontSize,
                      addColorR: _textColor.red,
                      addColorG: _textColor.green,
                      addColorB: _textColor.blue,
                      addBoundsX: _boundsX,
                      addBoundsY: _boundsY,
                      addBoundsWidth: _boundsWidth,
                      addBoundsHeight: _boundsHeight,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF processed successfully!')));

                  }
                },
                child: Text('Process PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddHeadersAndFootersToPdfCard extends StatefulWidget {
  const AddHeadersAndFootersToPdfCard({super.key});

  @override
  _AddHeadersAndFootersToPdfCardState createState() => _AddHeadersAndFootersToPdfCardState();
}

class _AddHeadersAndFootersToPdfCardState extends State<AddHeadersAndFootersToPdfCard> {
  final _formKey = GlobalKey<FormState>();
  String _headerText = '';
  String _footerText = '';
  String _outputFileName = '';
  int _numPages = 2;
  String _fontFamily = 'helvetica';
  double _fontSize = 12;
  Color _headerColor = Colors.black;
  Color _footerColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Headers & Footers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Header Text'),
                validator: (value) => value!.isEmpty ? 'Header Text is required' : null,
                onSaved: (value) => _headerText = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Footer Text'),
                validator: (value) => value!.isEmpty ? 'Footer Text is required' : null,
                onSaved: (value) => _footerText = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Number of Pages'),
                keyboardType: TextInputType.number,
                initialValue: _numPages.toString(),
                onSaved: (value) => _numPages = int.tryParse(value!) ?? 2,
              ),
              DropdownButtonFormField<String>(
                value: _fontFamily,
                decoration: InputDecoration(labelText: 'Font Family'),
                items: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _fontFamily = value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Font Size'),
                keyboardType: TextInputType.number,
                initialValue: _fontSize.toString(),
                onSaved: (value) => _fontSize = double.tryParse(value!) ?? 12,
              ),
              BlockPicker(
                pickerColor: _headerColor,
                onColorChanged: (color) => setState(() => _headerColor = color),
              ),
              BlockPicker(
                pickerColor: _footerColor,
                onColorChanged: (color) => setState(() => _footerColor = color),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await addHeadersAndFootersToPdf(
                      headerText: _headerText,
                      footerText: _footerText,
                      outputFileName: _outputFileName,
                      numPages: _numPages,
                      fontFamily: _fontFamily,
                      fontSize: _fontSize,
                      headerColorR: _headerColor.red,
                      headerColorG: _headerColor.green,
                      headerColorB: _headerColor.blue,
                      footerColorR: _footerColor.red,
                      footerColorG: _footerColor.green,
                      footerColorB: _footerColor.blue,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF created successfully!')));

                  }
                },
                child: Text('Create PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtractTextFromAllPdfPagesCard extends StatefulWidget {
  const ExtractTextFromAllPdfPagesCard({super.key});

  @override
  _ExtractTextFromAllPdfPagesCardState createState() => _ExtractTextFromAllPdfPagesCardState();
}

class _ExtractTextFromAllPdfPagesCardState extends State<ExtractTextFromAllPdfPagesCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  String _extractedText = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Extract All Text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _extractedText = await extractTextFromAllPdfPages(inputFileName: _inputFileName);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Extracted Text'),
                        content: SingleChildScrollView(
                          child: Text(_extractedText),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text('Extract Text'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtractTextFromSpecificPdfPageCard extends StatefulWidget {
  const ExtractTextFromSpecificPdfPageCard({super.key});

  @override
  _ExtractTextFromSpecificPdfPageCardState createState() => _ExtractTextFromSpecificPdfPageCardState();
}

class _ExtractTextFromSpecificPdfPageCardState extends State<ExtractTextFromSpecificPdfPageCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  int _pageIndex = 0;
  String _extractedText = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Extract Text from Page', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Page Index'),
                keyboardType: TextInputType.number,
                initialValue: _pageIndex.toString(),
                onSaved: (value) => _pageIndex = int.tryParse(value!) ?? 0,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _extractedText = await extractTextFromSpecificPdfPage(inputFileName: _inputFileName, pageIndex: _pageIndex);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Extracted Text'),
                        content: SingleChildScrollView(
                          child: Text(_extractedText),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text('Extract Text'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FindTextInPdfCard extends StatefulWidget {
  const FindTextInPdfCard({super.key});

  @override
  _FindTextInPdfCardState createState() => _FindTextInPdfCardState();
}

class _FindTextInPdfCardState extends State<FindTextInPdfCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  List<String> _textsToFind = [];
  List<Map<String, dynamic>> _results = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find Text in PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _textsToFind.add('');
                  });
                },
                child: Text('Add Text to Find'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _textsToFind.length,
                itemBuilder: (context, index) {
                  return TextFormField(
                    decoration: InputDecoration(labelText: 'Text ${index + 1} to Find'),
                    initialValue: _textsToFind[index],
                    onChanged: (value) {
                      setState(() {
                        _textsToFind[index] = value;
                      });
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _results = await findTextInPdf(inputFileName: _inputFileName, textsToFind: _textsToFind);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Found Texts'),
                        content: SingleChildScrollView(
                          child: Column(
                            children: _results.map((result) {
                              return ListTile(
                                title: Text(result['text']),
                                subtitle: Text('Page: ${result['pageIndex']}, Bounds: ${result['bounds']}'),
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text('Find Text'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EncryptPdfDocumentCard extends StatefulWidget {
  const EncryptPdfDocumentCard({super.key});

  @override
  _EncryptPdfDocumentCardState createState() => _EncryptPdfDocumentCardState();
}

class _EncryptPdfDocumentCardState extends State<EncryptPdfDocumentCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  String _outputFileName = '';
  String _userPassword = '';
  String _ownerPassword = '';
  String _encryptionAlgorithm = 'aesx256Bit';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Encrypt PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'User Password'),
                validator: (value) => value!.isEmpty ? 'User Password is required' : null,
                onSaved: (value) => _userPassword = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Owner Password'),
                validator: (value) => value!.isEmpty ? 'Owner Password is required' : null,
                onSaved: (value) => _ownerPassword = value!,
              ),
              DropdownButtonFormField<String>(
                value: _encryptionAlgorithm,
                decoration: InputDecoration(labelText: 'Encryption Algorithm'),
                items: ['rc4_40Bit', 'rc4_128Bit', 'aesx128Bit', 'aesx256Bit'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _encryptionAlgorithm = value!),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await encryptPdfDocument(
                      inputFileName: _inputFileName,
                      outputFileName: _outputFileName,
                      userPassword: _userPassword,
                      ownerPassword: _ownerPassword,
                      encryptionAlgorithm: _encryptionAlgorithm,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF encrypted successfully!')));

                  }
                },
                child: Text('Encrypt PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreatePdfFormCard extends StatefulWidget {
  const CreatePdfFormCard({super.key});

  @override
  _CreatePdfFormCardState createState() => _CreatePdfFormCardState();
}

class _CreatePdfFormCardState extends State<CreatePdfFormCard> {
  final _formKey = GlobalKey<FormState>();
  String _outputFileName = '';
  String _textBoxFieldName = '';
  String _textBoxText = '';
  String _checkBoxFieldName = '';
  bool _isCheckBoxChecked = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create PDF Form', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text Box Field Name'),
                validator: (value) => value!.isEmpty ? 'Text Box Field Name is required' : null,
                onSaved: (value) => _textBoxFieldName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text Box Text'),
                onSaved: (value) => _textBoxText = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Check Box Field Name'),
                validator: (value) => value!.isEmpty ? 'Check Box Field Name is required' : null,
                onSaved: (value) => _checkBoxFieldName = value!,
              ),
              SwitchListTile(
                title: Text('Check Box Is Checked'),
                value: _isCheckBoxChecked,
                onChanged: (value) => setState(() => _isCheckBoxChecked = value),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await createPdfForm(
                      outputFileName: _outputFileName,
                      textBoxFieldName: _textBoxFieldName,
                      textBoxText: _textBoxText,
                      checkBoxFieldName: _checkBoxFieldName,
                      isCheckBoxChecked: _isCheckBoxChecked,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF form created successfully!')));

                  }
                },
                child: Text('Create Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FillExistingPdfFormCard extends StatefulWidget {
  const FillExistingPdfFormCard({super.key});

  @override
  _FillExistingPdfFormCardState createState() => _FillExistingPdfFormCardState();
}

class _FillExistingPdfFormCardState extends State<FillExistingPdfFormCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  String _outputFileName = '';
  int? _textBoxFieldIndex;
  String? _textBoxValue;
  int? _radioButtonListFieldIndex;
  int? _radioButtonSelectedIndex;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fill Existing Form', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF Form'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text Box Field Index (optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _textBoxFieldIndex = int.tryParse(value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Text Box Value (optional)'),
                onSaved: (value) => _textBoxValue = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Radio Button List Field Index (optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _radioButtonListFieldIndex = int.tryParse(value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Radio Button Selected Index (optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _radioButtonSelectedIndex = int.tryParse(value!),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await fillExistingPdfForm(
                      inputFileName: _inputFileName,
                      outputFileName: _outputFileName,
                      textBoxFieldIndex: _textBoxFieldIndex,
                      textBoxValue: _textBoxValue,
                      radioButtonListFieldIndex: _radioButtonListFieldIndex,
                      radioButtonSelectedIndex: _radioButtonSelectedIndex,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF form filled successfully!')));

                  }
                },
                child: Text('Fill Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlattenExistingPdfFormCard extends StatefulWidget {
  const FlattenExistingPdfFormCard({super.key});

  @override
  _FlattenExistingPdfFormCardState createState() => _FlattenExistingPdfFormCardState();
}

class _FlattenExistingPdfFormCardState extends State<FlattenExistingPdfFormCard> {
  final _formKey = GlobalKey<FormState>();
  String _inputFileName = '';
  String _outputFileName = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flatten Form', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null) {
                    setState(() => _inputFileName = result.files.single.path!);
                  }
                },
                child: Text('Pick Input PDF Form'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await flattenExistingPdfForm(
                      inputFileName: _inputFileName,
                      outputFileName: _outputFileName,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF form flattened successfully!')));

                  }
                },
                child: Text('Flatten Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignNewPdfDocumentCard extends StatefulWidget {
  const SignNewPdfDocumentCard({super.key});

  @override
  _SignNewPdfDocumentCardState createState() => _SignNewPdfDocumentCardState();
}

class _SignNewPdfDocumentCardState extends State<SignNewPdfDocumentCard> {
  final _formKey = GlobalKey<FormState>();
  String _outputFileName = '';
  String _certificateFilePath = '';
  String _certificatePassword = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: 'Output File Name'),
                validator: (value) => value!.isEmpty ? 'Output File Name is required' : null,
                onSaved: (value) => _outputFileName = value!,
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pfx']);
                  if (result != null) {
                    setState(() => _certificateFilePath = result.files.single.path!);
                  }
                },
                child: Text('Pick Certificate File'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Certificate Password'),
                validator: (value) => value!.isEmpty ? 'Certificate Password is required' : null,
                onSaved: (value) => _certificatePassword = value!,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await signNewPdfDocument(
                      outputFileName: _outputFileName,
                      certificateFilePath: _certificateFilePath,
                      certificatePassword: _certificatePassword, signatureFieldName: '',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF signed successfully!')));

                  }
                },
                child: Text('Sign PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}