import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/services.dart' show ByteData, rootBundle; // For loading assets in Flutter environment
import 'package:path_provider/path_provider.dart'; // For getting application directory
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart'; // Assuming Flutter context for Rect, Offset etc.

// Helper function to resolve file paths for interactive mode
Future<String> getFilePath(String fileName) async {
//  if (kIsWeb) {
    // For web, assets are accessed directly.
    // This example assumes files like 'input.pdf', 'arial.ttf' are in assets folder.
//    return 'assets/$fileName';
 // } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    // For desktop/mobile, resolve to a temporary directory or specific location
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
 // } else {
    // Fallback for other platforms or if path_provider is not suitable
  //  return fileName; // Use as is, might mean current working directory
 // }
}

// Helper to load asset bytes dynamically
Future<Uint8List> loadAssetBytes(String path) async {
  if (kIsWeb) {
    // On web, use rootBundle to load assets
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  } else {
    // On other platforms, read from file system
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException("File not found at path: $path");
    }
    return await file.readAsBytes();
  }
}



// Note: You need to add the 'file_picker' dependency to your pubspec.yaml file:
/*
dependencies:
  flutter:
    sdk: flutter
  syncfusion_flutter_pdf: any_version
  file_picker: ^x.y.z // Use the latest stable version
*/

Future<void> createSimplePdfFromText({
  required String text,
  String fontFamily = 'helvetica',
  double fontSize = 12,
  // The outputFileName parameter is removed as the function will now prompt the user
  int colorR = 0, int colorG = 0, int colorB = 0,
  double boundsX = 0, double boundsY = 0, double boundsWidth = 150, double boundsHeight = 20,
}) async {
  // 1. Prompt the user to select a save location and file name
  String? filePath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save PDF As...',
    fileName: 'document.pdf', // Suggest a default file name
    type: FileType.custom,
    allowedExtensions: ['pdf'], // Filter for PDF files
  );

  // If the user cancels the dialog, filePath will be null
  if (filePath == null) {
    print("PDF save operation cancelled by user.");
    return;
  }

  // Ensure the file path ends with .pdf extension
  if (!filePath.toLowerCase().endsWith('.pdf')) {
    filePath += '.pdf';
  }

  // 2. Create the PDF document
  final PdfDocument document = PdfDocument();
  document.pages.add().graphics.drawString(
      text, PdfStandardFont(_getFontFamily(fontFamily), fontSize),
      brush: PdfSolidBrush(PdfColor(colorR, colorG, colorB)),
      bounds: Rect.fromLTWH(boundsX, boundsY, boundsWidth, boundsHeight));

  // 3. Save the PDF to the chosen file path
  try {
    File(filePath).writeAsBytes(await document.save());
    print("PDF saved successfully to: $filePath");
  } catch (e) {
    print("Error saving PDF: $e");
    // You might want to show a user-friendly error message here (e.g., a SnackBar or AlertDialog)
  } finally {
    // Dispose the document to release resources
    document.dispose();
  }
}

// Helper function to get PdfFontFamily from a string name
PdfFontFamily _getFontFamily(String fontName) {
  switch (fontName.toLowerCase()) {
    case 'helvetica':
      return PdfFontFamily.helvetica;
    case 'timesroman':
      return PdfFontFamily.timesRoman;
    case 'courier':
      return PdfFontFamily.courier;
    case 'symbol':
      return PdfFontFamily.symbol;
    case 'zapfdingbats':
      return PdfFontFamily.zapfDingbats;
    default:
      return PdfFontFamily.helvetica; // Default to Helvetica if unknown
  }
}
// The getFilePath function would now be unnecessary for this specific function,
// as the full path is provided by the caller.

/// Adds text using TrueType fonts to a PDF document.
Future<void> addTrueTypeTextToPdf({
  required String text,
  required String fontFilePath,
  double fontSize = 12,
  required String outputFileName,
  double boundsX = 0, double boundsY = 0, double boundsWidth = 200, double boundsHeight = 50,
}) async {
  final String resolvedFontPath = await getFilePath(fontFilePath);
  final Uint8List fontData = await loadAssetBytes(resolvedFontPath);
  final PdfDocument document = PdfDocument();
  final PdfFont font = PdfTrueTypeFont(fontData, fontSize);
  document.pages.add().graphics.drawString(text, font,
      bounds: Rect.fromLTWH(boundsX, boundsY, boundsWidth, boundsHeight));
  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Adds images to a PDF document.
Future<void> addImagesToPdf({
  required String imageFilePath,
  required String outputFileName,
  double boundsX = 0, double boundsY = 0, double boundsWidth = 500, double boundsHeight = 200,
}) async {
  final String resolvedImagePath = await getFilePath(imageFilePath);
  final Uint8List imageData = await loadAssetBytes(resolvedImagePath);
  final PdfDocument document = PdfDocument();
  final PdfBitmap image = PdfBitmap(imageData);
  document.pages
      .add()
      .graphics
      .drawImage(image, Rect.fromLTWH(boundsX, boundsY, boundsWidth, boundsHeight));
  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Creates a PDF document with flow layout.
Future<void> createPdfWithFlowLayout({
  required String paragraphText,
  String fontFamily = 'helvetica',
  double fontSize = 12,
  required String outputFileName,
  int lineColorR = 255, int lineColorG = 0, int lineColorB = 0,
  double lineOffset = 10,
}) async {
  final String outputPath = await getFilePath(outputFileName);
  final PdfDocument document = PdfDocument();
  final PdfPage page = document.pages.add();
  final PdfLayoutResult layoutResult = PdfTextElement(
      text: paragraphText,
      font: PdfStandardFont(_getFontFamily(fontFamily), fontSize),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)))
      .draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 0, page.getClientSize().width, page.getClientSize().height),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate))!;
  page.graphics.drawLine(
      PdfPen(PdfColor(lineColorR, lineColorG, lineColorB)),
      Offset(0, layoutResult.bounds.bottom + lineOffset),
      Offset(page.getClientSize().width, layoutResult.bounds.bottom + lineOffset));
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Adds bullets and lists to a PDF document.
Future<void> addBulletsAndListsToPdf({
  required List<String> mainListItems,
  List<String> subListItems = const [],
  String fontFamily = 'helvetica',
  double fontSize = 12,
  double subFontSize = 10,
  required String outputFileName,
}) async {
  final String outputPath = await getFilePath(outputFileName);
  final PdfDocument document = PdfDocument();
  final PdfPage page = document.pages.add();
  final PdfOrderedList orderedList = PdfOrderedList(
      items: PdfListItemCollection(mainListItems),
      marker: PdfOrderedMarker(
          style: PdfNumberStyle.numeric,
          font: PdfStandardFont(_getFontFamily(fontFamily), fontSize)),
      markerHierarchy: true,
      format: PdfStringFormat(lineSpacing: 10),
      textIndent: 10);

  if (mainListItems.isNotEmpty && subListItems.isNotEmpty) {
    orderedList.items[0].subList = PdfUnorderedList(
        marker: PdfUnorderedMarker(
            font: PdfStandardFont(_getFontFamily(fontFamily), subFontSize),
            style: PdfUnorderedMarkerStyle.disk),
        items: PdfListItemCollection(subListItems),
        textIndent: 10,
        indent: 20);
  }

  orderedList.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 0, page.getClientSize().width, page.getClientSize().height));
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Adds tables to a PDF document.
Future<void> addTablesToPdf({
  required int columnCount,
  required List<String> headerNames,
  required List<List<String>> rowData,
  String headerFontFamily = 'helvetica',
  double headerFontSize = 10,
  required String outputFileName,
}) async {
  final String outputPath = await getFilePath(outputFileName);
  final PdfDocument document = PdfDocument();
  final PdfPage page = document.pages.add();
  final PdfGrid grid = PdfGrid();
  grid.columns.add(count: columnCount);

  if (headerNames.length == columnCount) {
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    for (int i = 0; i < columnCount; i++) {
      headerRow.cells[i].value = headerNames[i];
    }
    headerRow.style.font =
        PdfStandardFont(_getFontFamily(headerFontFamily), headerFontSize, style: PdfFontStyle.bold);
  }

  for (final List<String> rowValues in rowData) {
    if (rowValues.length == columnCount) {
      PdfGridRow row = grid.rows.add();
      for (int i = 0; i < columnCount; i++) {
        row.cells[i].value = rowValues[i];
      }
    }
  }

  grid.style.cellPadding = PdfPaddings(left: 5, top: 5);
  grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
          0, 0, page.getClientSize().width, page.getClientSize().height));
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Adds headers and footers to a PDF document.
Future<void> addHeadersAndFootersToPdf({
  required String headerText,
  required String footerText,
  String fontFamily = 'helvetica',
  double fontSize = 12,
  required String outputFileName,
  int numPages = 2,
  int headerColorR = 0, int headerColorG = 0, int headerColorB = 0,
  int footerColorR = 0, int footerColorG = 0, int footerColorB = 0,
}) async {
  final String outputPath = await getFilePath(outputFileName);
  final PdfDocument document = PdfDocument();

  final PdfPageTemplateElement headerTemplate =
      PdfPageTemplateElement(const Rect.fromLTWH(0, 0, 515, 50));
  headerTemplate.graphics.drawString(
      headerText, PdfStandardFont(_getFontFamily(fontFamily), fontSize),
      bounds: const Rect.fromLTWH(0, 15, 200, 20),
      brush: PdfSolidBrush(PdfColor(headerColorR, headerColorG, headerColorB)));
  document.template.top = headerTemplate;

  final PdfPageTemplateElement footerTemplate =
      PdfPageTemplateElement(const Rect.fromLTWH(0, 0, 515, 50));
  footerTemplate.graphics.drawString(
      footerText, PdfStandardFont(_getFontFamily(fontFamily), fontSize),
      bounds: const Rect.fromLTWH(0, 15, 200, 20),
      brush: PdfSolidBrush(PdfColor(footerColorR, footerColorG, footerColorB)));
  document.template.bottom = footerTemplate;

  for (int i = 0; i < numPages; i++) {
    document.pages.add();
  }

  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Loads and modifies an existing PDF document by adding text.
Future<void> loadAndModifyExistingPdf({
  required String inputFileName,
  required String outputFileName,
  int pageIndex = 0,
  required String textToAdd,
  String fontFamily = 'helvetica',
  double fontSize = 12,
  int colorR = 0, int colorG = 0, int colorB = 0,
  double boundsX = 0, double boundsY = 0, double boundsWidth = 150, double boundsHeight = 20,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  if (pageIndex >= 0 && pageIndex < document.pages.count) {
    final PdfPage page = document.pages[pageIndex];
    page.graphics.drawString(
        textToAdd, PdfStandardFont(_getFontFamily(fontFamily), fontSize),
        brush: PdfSolidBrush(PdfColor(colorR, colorG, colorB)),
        bounds: Rect.fromLTWH(boundsX, boundsY, boundsWidth, boundsHeight));
  } else {
    throw ArgumentError('Page index out of bounds: $pageIndex');
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Adds or removes a page from an existing PDF document.
Future<void> addRemovePageFromExistingPdf({
  required String inputFileName,
  required String outputFileName,
  int? removePageIndex, // Optional: if provided, remove a page
  String? addText, // Optional: if provided, add a new page with text
  String addFontFamily = 'helvetica',
  double addFontSize = 12,
  int addColorR = 0, int addColorG = 0, int addColorB = 0,
  double addBoundsX = 0, double addBoundsY = 0, double addBoundsWidth = 150, double addBoundsHeight = 20,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  if (removePageIndex != null && removePageIndex >= 0 && removePageIndex < document.pages.count) {
    document.pages.removeAt(removePageIndex);
  } else if (removePageIndex != null) {
    debugPrint('Warning: removePageIndex $removePageIndex is out of bounds or invalid for ${inputFileName}. No page removed.');
  }

  if (addText != null && addText.isNotEmpty) {
    document.pages.add().graphics.drawString(
        addText, PdfStandardFont(_getFontFamily(addFontFamily), addFontSize),
        brush: PdfSolidBrush(PdfColor(addColorR, addColorG, addColorB)),
        bounds: Rect.fromLTWH(addBoundsX, addBoundsY, addBoundsWidth, addBoundsHeight));
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Creates a new annotation in a PDF document.
Future<void> createAnnotationInPdf({
  required String inputFileName,
  required String outputFileName,
  int pageIndex = 0,
  double boundsX = 0, double boundsY = 0, double boundsWidth = 150, double boundsHeight = 100,
  required String annotationText,
  int colorR = 255, int colorG = 0, int colorB = 0,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  if (pageIndex >= 0 && pageIndex < document.pages.count) {
    document.pages[pageIndex].annotations.add(PdfRectangleAnnotation(
        Rect.fromLTWH(boundsX, boundsY, boundsWidth, boundsHeight), annotationText,
        color: PdfColor(colorR, colorG, colorB), setAppearance: true));
  } else {
    throw ArgumentError('Page index out of bounds: $pageIndex');
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Loads an existing annotation from a PDF document and modifies it.
Future<void> loadAndModifyAnnotation({
  required String inputFileName,
  required String outputFileName,
  int pageIndex = 0,
  int annotationIndex = 0,
  required String newAnnotationText,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  if (pageIndex >= 0 && pageIndex < document.pages.count) {
    if (annotationIndex >= 0 && annotationIndex < document.pages[pageIndex].annotations.count) {
      final PdfAnnotation annotation = document.pages[pageIndex].annotations[annotationIndex];
      // Only modify text annotations or those with a text property (like RectangleAnnotation)
      if (annotation is PdfRectangleAnnotation) {
        // Not all annotations have a settable 'text' property in the base class.
        // Cast to specific types if you know them.
        // For PdfRectangleAnnotation, it does have a 'text' property.
        (annotation).text = newAnnotationText;
      } else if (annotation is PdfRectangleAnnotation) {
        annotation.text = newAnnotationText;
      }
      // Add more specific casts if other annotation types need modification
      else {
        throw ArgumentError('Annotation at index $annotationIndex on page $pageIndex is not a modifiable text annotation type.');
      }
    } else {
      throw ArgumentError('Annotation index out of bounds: $annotationIndex on page $pageIndex');
    }
  } else {
    throw ArgumentError('Page index out of bounds: $pageIndex');
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Adds bookmarks to a PDF document.
Future<void> addBookmarksToPdf({
  required String inputFileName,
  required String outputFileName,
  required String bookmarkName,
  int destinationPageIndex = 0,
  double destinationX = 20, double destinationY = 20,
  int colorR = 255, int colorG = 0, int colorB = 0,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  if (destinationPageIndex >= 0 && destinationPageIndex < document.pages.count) {
    final PdfBookmark bookmark = document.bookmarks.add(bookmarkName);
    bookmark.destination = PdfDestination(document.pages[destinationPageIndex], Offset(destinationX, destinationY));
    bookmark.color = PdfColor(colorR, colorG, colorB);
  } else {
    throw ArgumentError('Destination page index out of bounds: $destinationPageIndex');
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Extracts text from all pages of a PDF document.
Future<String> extractTextFromAllPdfPages({
  required String inputFileName,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);
  String text = PdfTextExtractor(document).extractText();
  document.dispose();
  return text;
}

/// Extracts text from a specific page of a PDF document.
Future<String> extractTextFromSpecificPdfPage({
  required String inputFileName,
  int pageIndex = 0,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);
  if (pageIndex < 0 || pageIndex >= document.pages.count) {
    document.dispose();
    throw ArgumentError('Page index out of bounds: $pageIndex');
  }
  String text = PdfTextExtractor(document).extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
  document.dispose();
  return text;
}

/// Finds text in a PDF document.
Future<List<Map<String, dynamic>>> findTextInPdf({
  required String inputFileName,
  required List<String> textsToFind,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);
  List<MatchedItem> textCollection = PdfTextExtractor(document).findText(textsToFind);

  List<Map<String, dynamic>> results = [];
  for (var matchedText in textCollection) {
    results.add({
      'text': matchedText.text,
      'pageIndex': matchedText.pageIndex,
      'bounds': {
        'x': matchedText.bounds.left,
        'y': matchedText.bounds.top,
        'width': matchedText.bounds.width,
        'height': matchedText.bounds.height,
      }
    });
  }
  document.dispose();
  return results;
}

/// Encrypts an existing PDF document.
Future<void> encryptPdfDocument({
  required String inputFileName,
  required String outputFileName,
  required String userPassword,
  required String ownerPassword,
  String encryptionAlgorithm = 'aesx256Bit', // 'rc4_40Bit', 'rc4_128Bit', 'aesx128Bit', 'aesx256Bit'
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  final PdfSecurity security = document.security;
  security.userPassword = userPassword;
  security.ownerPassword = ownerPassword;

  switch (encryptionAlgorithm.toLowerCase()) {
    case 'rc4_40bit':
      security.algorithm = PdfEncryptionAlgorithm.rc4x40Bit;
      break;
    case 'rc4_128bit':
      security.algorithm = PdfEncryptionAlgorithm.rc4x128Bit;
      break;
    case 'aesx128bit':
      security.algorithm = PdfEncryptionAlgorithm.aesx128Bit;
      break;
    case 'aesx256bit':
    default:
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
      break;
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Creates a PDF conformance document.
Future<void> createPdfConformanceDocument({
  required String outputFileName,
  String conformanceLevel = 'a1b', // 'a1b', 'a2b', 'a2u', 'a3b', 'a3u'
  required String text,
  required String fontFilePath,
  double fontSize = 12,
  double boundsX = 20, double boundsY = 20, double boundsWidth = 200, double boundsHeight = 50,
  int brushR = 0, int brushG = 0, int brushB = 0,
}) async {
  final String outputPath = await getFilePath(outputFileName);
  final String resolvedFontPath = await getFilePath(fontFilePath);
  final Uint8List fontData = await loadAssetBytes(resolvedFontPath);

  PdfConformanceLevel level;
  switch (conformanceLevel.toLowerCase()) {
    case 'a1b':
      level = PdfConformanceLevel.a1b;
      break;
    case 'a2b':
      level = PdfConformanceLevel.a2b;
      break;
    case 'a3b':
      level = PdfConformanceLevel.a3b;
      break;
    default:
      level = PdfConformanceLevel.a1b;
      break;
  }

  final PdfDocument document = PdfDocument(conformanceLevel: level)
    ..pages.add().graphics.drawString(
        text,
        PdfTrueTypeFont(fontData, fontSize),
        bounds: Rect.fromLTWH(boundsX, boundsY, boundsWidth, boundsHeight),
        brush: PdfSolidBrush(PdfColor(brushR, brushG, brushB)));

  File(outputPath).writeAsBytesSync(await document.save());
  document.dispose();
}

/// Creates a PDF form with text box and checkbox fields.
Future<void> createPdfForm({
  required String outputFileName,
  required String textBoxFieldName,
  double textBoxBoundsX = 0, double textBoxBoundsY = 0, double textBoxBoundsWidth = 100, double textBoxBoundsHeight = 20,
  String textBoxText = '',
  required String checkBoxFieldName,
  double checkBoxBoundsX = 150, double checkBoxBoundsY = 0, double checkBoxBoundsWidth = 30, double checkBoxBoundsHeight = 30,
  bool isCheckBoxChecked = true,
}) async {
  final String outputPath = await getFilePath(outputFileName);
  PdfDocument document = PdfDocument();
  PdfPage page = document.pages.add();

  document.form.fields.add(PdfTextBoxField(
      page, textBoxFieldName, Rect.fromLTWH(textBoxBoundsX, textBoxBoundsY, textBoxBoundsWidth, textBoxBoundsHeight),
      text: textBoxText));

  document.form.fields.add(PdfCheckBoxField(
      page, checkBoxFieldName, Rect.fromLTWH(checkBoxBoundsX, checkBoxBoundsY, checkBoxBoundsWidth, checkBoxBoundsHeight),
      isChecked: isCheckBoxChecked));

  File(outputPath).writeAsBytesSync(await document.save());
  document.dispose();
}

/// Fills an existing PDF form.
Future<void> fillExistingPdfForm({
  required String inputFileName,
  required String outputFileName,
  int? textBoxFieldIndex, // index of the text box field to fill
  String? textBoxValue, // value to fill in the text box
  int? radioButtonListFieldIndex, // index of the radio button list field
  int? radioButtonSelectedIndex, // index of the radio button to select
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  PdfForm form = document.form;

  if (textBoxFieldIndex != null && textBoxValue != null && textBoxFieldIndex >= 0 && textBoxFieldIndex < form.fields.count) {
    if (form.fields[textBoxFieldIndex] is PdfTextBoxField) {
      (form.fields[textBoxFieldIndex] as PdfTextBoxField).text = textBoxValue;
    } else {
      debugPrint('Warning: Field at index $textBoxFieldIndex is not a PdfTextBoxField. Skipping.');
    }
  }

  if (radioButtonListFieldIndex != null && radioButtonSelectedIndex != null && radioButtonListFieldIndex >= 0 && radioButtonListFieldIndex < form.fields.count) {
    if (form.fields[radioButtonListFieldIndex] is PdfRadioButtonListField) {
      PdfRadioButtonListField gender = form.fields[radioButtonListFieldIndex] as PdfRadioButtonListField;
      if (radioButtonSelectedIndex >= 0 && radioButtonSelectedIndex < gender.items.count) {
        gender.selectedIndex = radioButtonSelectedIndex;
      } else {
        debugPrint('Warning: Radio button selection index $radioButtonSelectedIndex is out of bounds for field at index $radioButtonListFieldIndex. Skipping.');
      }
    } else {
      debugPrint('Warning: Field at index $radioButtonListFieldIndex is not a PdfRadioButtonListField. Skipping.');
    }
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytesSync(await document.save());
  document.dispose();
}

/// Flattens an existing PDF form.
Future<void> flattenExistingPdfForm({
  required String inputFileName,
  required String outputFileName,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  PdfForm form = document.form;
  form.flattenAllFields();

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytesSync(await document.save());
  document.dispose();
}

/// Digitally signs a new PDF document.
Future<void> signNewPdfDocument({
  required String outputFileName,
  required String signatureFieldName,
  double signatureBoundsX = 0, double signatureBoundsY = 0, double signatureBoundsWidth = 200, double signatureBoundsHeight = 50,
  required String certificateFilePath,
  required String certificatePassword,
}) async {
  final String outputPath = await getFilePath(outputFileName);
  final String resolvedCertPath = await getFilePath(certificateFilePath);
  final Uint8List certBytes = await loadAssetBytes(resolvedCertPath);

  PdfDocument document = PdfDocument();
  PdfPage page = document.pages.add();

  PdfSignatureField signatureField = PdfSignatureField(page, signatureFieldName,
      bounds: Rect.fromLTWH(signatureBoundsX, signatureBoundsY, signatureBoundsWidth, signatureBoundsHeight),
      signature: PdfSignature(
          certificate: PdfCertificate(certBytes, certificatePassword)));

  document.form.fields.add(signatureField);

  File(outputPath).writeAsBytes(await document.save());
  document.dispose();
}

/// Digitally signs an existing PDF document.
Future<void> signExistingPdfDocument({
  required String inputFileName,
  required String outputFileName,
  int signatureFieldIndex = 0,
  required String certificateFilePath,
  required String certificatePassword,
}) async {
  final String inputPath = await getFilePath(inputFileName);
  final Uint8List inputBytes = await loadAssetBytes(inputPath);
  final PdfDocument document = PdfDocument(inputBytes: inputBytes);

  final String resolvedCertPath = await getFilePath(certificateFilePath);
  final Uint8List certBytes = await loadAssetBytes(resolvedCertPath);

  if (signatureFieldIndex >= 0 && signatureFieldIndex < document.form.fields.count) {
    if (document.form.fields[signatureFieldIndex] is PdfSignatureField) {
      PdfSignatureField signatureField =
          document.form.fields[signatureFieldIndex] as PdfSignatureField;
      signatureField.signature = PdfSignature(
        certificate: PdfCertificate(certBytes, certificatePassword),
      );
    } else {
      throw ArgumentError('Field at index $signatureFieldIndex is not a PdfSignatureField.');
    }
  } else {
    throw ArgumentError('Signature field index out of bounds: $signatureFieldIndex');
  }

  final String outputPath = await getFilePath(outputFileName);
  File(outputPath).writeAsBytesSync(await document.save());
  document.dispose();
}

// --- Tool Definitions with interactive parameters ---

final createSimplePdfFromTextTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'createSimplePdfFromText',
      'Creates a simple PDF document with specified text, font, color, and bounds, saving it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'text': Schema(SchemaType.string, description: 'The text to draw on the PDF page.'),
          'fontFamily': Schema(SchemaType.string, description: 'The font family (e.g., "helvetica", "timesroman"). Defaults to "helvetica".', enumValues: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats']),
          'fontSize': Schema(SchemaType.number, description: 'The font size. Defaults to 12.0.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF file to create (e.g., "my_document.pdf").'),
          'colorR': Schema(SchemaType.integer, description: 'Red component of the text color (0-255). Defaults to 0.',),
          'colorG': Schema(SchemaType.integer, description: 'Green component of the text color (0-255). Defaults to 0.',),
          'colorB': Schema(SchemaType.integer, description: 'Blue component of the text color (0-255). Defaults to 0.',),
          'boundsX': Schema(SchemaType.number, description: 'X-coordinate of the text bounds. Defaults to 0.0.'),
          'boundsY': Schema(SchemaType.number, description: 'Y-coordinate of the text bounds. Defaults to 0.0.'),
          'boundsWidth': Schema(SchemaType.number, description: 'Width of the text bounds. Defaults to 150.0.'),
          'boundsHeight': Schema(SchemaType.number, description: 'Height of the text bounds. Defaults to 20.0.'),
        },
        requiredProperties: ['text', 'outputFileName'],
      ),
    ),
  ],
);

final addTrueTypeTextToPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'addTrueTypeTextToPdf',
      'Adds text using a custom TrueType font file to a new PDF document. Saves it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'text': Schema(SchemaType.string, description: 'The text to draw on the PDF page.'),
          'fontFilePath': Schema(SchemaType.string, description: 'The path to the TrueType font file (e.g., "arial.ttf", "Roboto-Regular.ttf"). This file must exist.'),
          'fontSize': Schema(SchemaType.number, description: 'The font size. Defaults to 12.0.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF file to create (e.g., "custom_font_doc.pdf").'),
          'boundsX': Schema(SchemaType.number, description: 'X-coordinate of the text bounds. Defaults to 0.0.'),
          'boundsY': Schema(SchemaType.number, description: 'Y-coordinate of the text bounds. Defaults to 0.0.'),
          'boundsWidth': Schema(SchemaType.number, description: 'Width of the text bounds. Defaults to 200.0.'),
          'boundsHeight': Schema(SchemaType.number, description: 'Height of the text bounds. Defaults to 50.0.'),
        },
        requiredProperties: ['text', 'fontFilePath', 'outputFileName'],
      ),
    ),
  ],
);

final addImagesToPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'addImagesToPdf',
      'Adds an image from a specified file path to a new PDF document with configurable bounds. Saves it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'imageFilePath': Schema(SchemaType.string, description: 'The path to the image file (e.g., "input.png", "my_image.jpg"). This file must exist.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF file to create (e.g., "image_doc.pdf").'),
          'boundsX': Schema(SchemaType.number, description: 'X-coordinate of the image bounds. Defaults to 0.0.'),
          'boundsY': Schema(SchemaType.number, description: 'Y-coordinate of the image bounds. Defaults to 0.0.'),
          'boundsWidth': Schema(SchemaType.number, description: 'Width of the image bounds. Defaults to 500.0.'),
          'boundsHeight': Schema(SchemaType.number, description: 'Height of the image bounds. Defaults to 200.0.'),
        },
        requiredProperties: ['imageFilePath', 'outputFileName'],
      ),
    ),
  ],
);

final createPdfWithFlowLayoutTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'createPdfWithFlowLayout',
      'Creates a PDF document with a specified paragraph text demonstrating flow layout, adding a line below it. Saves it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'paragraphText': Schema(SchemaType.string, description: 'The long paragraph text to layout in the PDF.'),
          'fontFamily': Schema(SchemaType.string, description: 'The font family for the paragraph (e.g., "helvetica"). Defaults to "helvetica".', enumValues: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats']),
          'fontSize': Schema(SchemaType.number, description: 'The font size for the paragraph. Defaults to 12.0.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF file to create (e.g., "flow_text_doc.pdf").'),
          'lineColorR': Schema(SchemaType.integer, description: 'Red component of the line color (0-255). Defaults to 255.'),
          'lineColorG': Schema(SchemaType.integer, description: 'Green component of the line color (0-255). Defaults to 0.'),
          'lineColorB': Schema(SchemaType.integer, description: 'Blue component of the line color (0-255). Defaults to 0.'),
          'lineOffset': Schema(SchemaType.number, description: 'Offset from the bottom of the text for the line. Defaults to 10.0.'),
        },
        requiredProperties: ['paragraphText', 'outputFileName'],
      ),
    ),
  ],
);

final addBulletsAndListsToPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'addBulletsAndListsToPdf',
      'Adds ordered and optionally unordered sub-lists to a new PDF document. Saves it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'mainListItems': Schema(SchemaType.array, items: Schema(SchemaType.string), description: 'A list of strings for the main ordered list items.'),
          'subListItems': Schema(SchemaType.array, items: Schema(SchemaType.string), description: 'An optional list of strings for the unordered sub-list items (added under the first main list item).'),
          'fontFamily': Schema(SchemaType.string, description: 'The font family for the main list (e.g., "helvetica"). Defaults to "helvetica".', enumValues: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats']),
          'fontSize': Schema(SchemaType.number, description: 'The font size for the main list. Defaults to 12.0.'),
          'subFontSize': Schema(SchemaType.number, description: 'The font size for the sub-list. Defaults to 10.0.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF file to create (e.g., "lists_doc.pdf").'),
        },
        requiredProperties: ['mainListItems', 'outputFileName'],
      ),
    ),
  ],
);

final addTablesToPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'addTablesToPdf',
      'Adds a table with specified column count, header names, and row data to a new PDF document. Saves it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'columnCount': Schema(SchemaType.integer, description: 'The number of columns in the table.'),
          'headerNames': Schema(SchemaType.array, items: Schema(SchemaType.string), description: 'A list of strings for the table header names. Must match `columnCount`.'),
          'rowData': Schema(SchemaType.array, items: Schema(SchemaType.array, items: Schema(SchemaType.string)), description: 'A list of lists, where each inner list represents a row of string data. Each inner list must match `columnCount`.'),
          'headerFontFamily': Schema(SchemaType.string, description: 'The font family for the header row. Defaults to "helvetica".', enumValues: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats']),
          'headerFontSize': Schema(SchemaType.number, description: 'The font size for the header row. Defaults to 10.0.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF file to create (e.g., "table_doc.pdf").'),
        },
        requiredProperties: ['columnCount', 'headerNames', 'rowData', 'outputFileName'],
      ),
    ),
  ],
);

final addHeadersAndFootersToPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'addHeadersAndFootersToPdf',
      'Adds specified headers and footers to a new PDF document across multiple pages. Saves it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'headerText': Schema(SchemaType.string, description: 'The text to display in the document header.'),
          'footerText': Schema(SchemaType.string, description: 'The text to display in the document footer.'),
          'fontFamily': Schema(SchemaType.string, description: 'The font family for header/footer text. Defaults to "helvetica".', enumValues: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats']),
          'fontSize': Schema(SchemaType.number, description: 'The font size for header/footer text. Defaults to 12.0.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF file to create (e.g., "header_footer_doc.pdf").'),
          'numPages': Schema(SchemaType.integer, description: 'The number of pages to create in the document. Defaults to 2.'),
          'headerColorR': Schema(SchemaType.integer, description: 'Red component of header text color (0-255). Defaults to 0.'),
          'headerColorG': Schema(SchemaType.integer, description: 'Green component of header text color (0-255). Defaults to 0.'),
          'headerColorB': Schema(SchemaType.integer, description: 'Blue component of header text color (0-255). Defaults to 0.'),
          'footerColorR': Schema(SchemaType.integer, description: 'Red component of footer text color (0-255). Defaults to 0.'),
          'footerColorG': Schema(SchemaType.integer, description: 'Green component of footer text color (0-255). Defaults to 0.'),
          'footerColorB': Schema(SchemaType.integer, description: 'Blue component of footer text color (0-255). Defaults to 0.'),
        },
        requiredProperties: ['headerText', 'footerText', 'outputFileName'],
      ),
    ),
  ],
);

final loadAndModifyExistingPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'loadAndModifyExistingPdf',
      'Loads an existing PDF document, adds specified text to a particular page, and saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "output.pdf").'),
          'pageIndex': Schema(SchemaType.integer, description: 'The 0-based index of the page to modify. Defaults to 0.'),
          'textToAdd': Schema(SchemaType.string, description: 'The text to add to the specified page.'),
          'fontFamily': Schema(SchemaType.string, description: 'The font family for the added text. Defaults to "helvetica".', enumValues: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats']),
          'fontSize': Schema(SchemaType.number, description: 'The font size for the added text. Defaults to 12.0.'),
          'colorR': Schema(SchemaType.integer, description: 'Red component of the added text color (0-255). Defaults to 0.'),
          'colorG': Schema(SchemaType.integer, description: 'Green component of the added text color (0-255). Defaults to 0.'),
          'colorB': Schema(SchemaType.integer, description: 'Blue component of the added text color (0-255). Defaults to 0.'),
          'boundsX': Schema(SchemaType.number, description: 'X-coordinate of the added text bounds. Defaults to 0.0.'),
          'boundsY': Schema(SchemaType.number, description: 'Y-coordinate of the added text bounds. Defaults to 0.0.'),
          'boundsWidth': Schema(SchemaType.number, description: 'Width of the added text bounds. Defaults to 150.0.'),
          'boundsHeight': Schema(SchemaType.number, description: 'Height of the added text bounds. Defaults to 20.0.'),
        },
        requiredProperties: ['inputFileName', 'outputFileName', 'textToAdd'],
      ),
    ),
  ],
);

final addRemovePageFromExistingPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'addRemovePageFromExistingPdf',
      'Loads an existing PDF document. It can optionally remove a page by index and/or add a new page with specified text. Saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "output.pdf").'),
          'removePageIndex': Schema(SchemaType.integer, description: 'Optional: The 0-based index of the page to remove.'),
          'addText': Schema(SchemaType.string, description: 'Optional: Text to add to a newly created page.'),
          'addFontFamily': Schema(SchemaType.string, description: 'Font family for the added text. Defaults to "helvetica".', enumValues: ['helvetica', 'timesroman', 'courier', 'symbol', 'dingbats']),
          'addFontSize': Schema(SchemaType.number, description: 'Font size for the added text. Defaults to 12.0.'),
          'addColorR': Schema(SchemaType.integer, description: 'Red component of added text color (0-255). Defaults to 0.'),
          'addColorG': Schema(SchemaType.integer, description: 'Green component of added text color (0-255). Defaults to 0.'),
          'addColorB': Schema(SchemaType.integer, description: 'Blue component of added text color (0-255). Defaults to 0.'),
          'addBoundsX': Schema(SchemaType.number, description: 'X-coordinate of added text bounds. Defaults to 0.0.'),
          'addBoundsY': Schema(SchemaType.number, description: 'Y-coordinate of added text bounds. Defaults to 0.0.'),
          'addBoundsWidth': Schema(SchemaType.number, description: 'Width of added text bounds. Defaults to 150.0.'),
          'addBoundsHeight': Schema(SchemaType.number, description: 'Height of added text bounds. Defaults to 20.0.'),
        },
        requiredProperties: ['inputFileName', 'outputFileName'],
      ),
    ),
  ],
);

final createAnnotationInPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'createAnnotationInPdf',
      'Loads an existing PDF document and adds a rectangle annotation with specified text, color, and bounds to a given page. Saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "annotations.pdf").'),
          'pageIndex': Schema(SchemaType.integer, description: 'The 0-based index of the page to add the annotation to. Defaults to 0.'),
          'boundsX': Schema(SchemaType.number, description: 'X-coordinate of the annotation bounds. Defaults to 0.0.'),
          'boundsY': Schema(SchemaType.number, description: 'Y-coordinate of the annotation bounds. Defaults to 0.0.'),
          'boundsWidth': Schema(SchemaType.number, description: 'Width of the annotation bounds. Defaults to 150.0.'),
          'boundsHeight': Schema(SchemaType.number, description: 'Height of the annotation bounds. Defaults to 100.0.'),
          'annotationText': Schema(SchemaType.string, description: 'The text for the annotation.'),
          'colorR': Schema(SchemaType.integer, description: 'Red component of the annotation color (0-255). Defaults to 255 (red).'),
          'colorG': Schema(SchemaType.integer, description: 'Green component of the annotation color (0-255). Defaults to 0.'),
          'colorB': Schema(SchemaType.integer, description: 'Blue component of the annotation color (0-255). Defaults to 0.'),
        },
        requiredProperties: ['inputFileName', 'outputFileName', 'annotationText'],
      ),
    ),
  ],
);

final loadAndModifyAnnotationTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'loadAndModifyAnnotation',
      'Loads an existing PDF document, finds a specific annotation by page and index, and modifies its text. Saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist and contain the annotation.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "modified_annotations.pdf").'),
          'pageIndex': Schema(SchemaType.integer, description: 'The 0-based index of the page containing the annotation. Defaults to 0.'),
          'annotationIndex': Schema(SchemaType.integer, description: 'The 0-based index of the annotation to modify on the specified page. Defaults to 0.'),
          'newAnnotationText': Schema(SchemaType.string, description: 'The new text to set for the annotation.'),
        },
        requiredProperties: ['inputFileName', 'outputFileName', 'newAnnotationText'],
      ),
    ),
  ],
);

final addBookmarksToPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'addBookmarksToPdf',
      'Loads an existing PDF document and adds a bookmark linking to a specific page and location. Saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "bookmark.pdf").'),
          'bookmarkName': Schema(SchemaType.string, description: 'The name for the new bookmark.'),
          'destinationPageIndex': Schema(SchemaType.integer, description: 'The 0-based index of the page the bookmark should link to. Defaults to 0.'),
          'destinationX': Schema(SchemaType.number, description: 'The X-coordinate on the destination page. Defaults to 20.0.'),
          'destinationY': Schema(SchemaType.number, description: 'The Y-coordinate on the destination page. Defaults to 20.0.'),
          'colorR': Schema(SchemaType.integer, description: 'Red component of the bookmark color (0-255). Defaults to 255 (red).'),
          'colorG': Schema(SchemaType.integer, description: 'Green component of the bookmark color (0-255). Defaults to 0.'),
          'colorB': Schema(SchemaType.integer, description: 'Blue component of the bookmark color (0-255). Defaults to 0.'),
        },
        requiredProperties: ['inputFileName', 'outputFileName', 'bookmarkName'],
      ),
    ),
  ],
);

final extractTextFromAllPdfPagesTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'extractTextFromAllPdfPages',
      'Loads an existing PDF document and extracts all text from all its pages. Returns the concatenated extracted text.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist.'),
        },
        requiredProperties: ['inputFileName'],
      ),
    ),
  ],
);

final extractTextFromSpecificPdfPageTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'extractTextFromSpecificPdfPage',
      'Loads an existing PDF document and extracts text from a specific page by its index. Returns the extracted text.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist.'),
          'pageIndex': Schema(SchemaType.integer, description: 'The 0-based index of the page from which to extract text. Defaults to 0.'),
        },
        requiredProperties: ['inputFileName'],
      ),
    ),
  ],
);

final findTextInPdfTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'findTextInPdf',
      'Loads an existing PDF document and finds occurrences of specified texts within it. Returns a list of matched items including text, page index, and bounds.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist.'),
          'textsToFind': Schema(SchemaType.array, items: Schema(SchemaType.string), description: 'A list of strings to search for within the PDF.'),
        },
        requiredProperties: ['inputFileName', 'textsToFind'],
      ),
    ),
  ],
);

final encryptPdfDocumentTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'encryptPdfDocument',
      'Loads an existing PDF document, encrypts it with specified user and owner passwords and encryption algorithm. Saves the secured document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to encrypt (e.g., "input.pdf"). This file must exist.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the encrypted PDF file to save (e.g., "secured.pdf").'),
          'userPassword': Schema(SchemaType.string, description: 'The user password for the PDF. Cannot be empty.'),
          'ownerPassword': Schema(SchemaType.string, description: 'The owner password for the PDF. Cannot be empty.'),
          'encryptionAlgorithm': Schema(SchemaType.string, description: 'The encryption algorithm to use (e.g., "aesx256Bit", "rc4_128Bit"). Defaults to "aesx256Bit".', enumValues: ['rc4_40Bit', 'rc4_128Bit', 'aesx128Bit', 'aesx256Bit']),
        },
        requiredProperties: ['inputFileName', 'outputFileName', 'userPassword', 'ownerPassword'],
      ),
    ),
  ],
);

final createPdfConformanceDocumentTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'createPdfConformanceDocument',
      'Creates a new PDF document adhering to a specified PDF/A conformance level, with given text and font. Saves it to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF conformance file to create (e.g., "conformance.pdf").'),
          'conformanceLevel': Schema(SchemaType.string, description: 'The PDF/A conformance level (e.g., "a1b", "a2u"). Defaults to "a1b".', enumValues: ['a1b', 'a2b', 'a2u', 'a3b', 'a3u']),
          'text': Schema(SchemaType.string, description: 'The text to draw on the PDF page.'),
          'fontFilePath': Schema(SchemaType.string, description: 'The path to the TrueType font file for conformance (e.g., "Roboto-Regular.ttf"). This file must exist.'),
          'fontSize': Schema(SchemaType.number, description: 'The font size. Defaults to 12.0.'),
          'boundsX': Schema(SchemaType.number, description: 'X-coordinate of the text bounds. Defaults to 20.0.'),
          'boundsY': Schema(SchemaType.number, description: 'Y-coordinate of the text bounds. Defaults to 20.0.'),
          'boundsWidth': Schema(SchemaType.number, description: 'Width of the text bounds. Defaults to 200.0.'),
          'boundsHeight': Schema(SchemaType.number, description: 'Height of the text bounds. Defaults to 50.0.'),
          'brushR': Schema(SchemaType.integer, description: 'Red component of the brush color (0-255). Defaults to 0.'),
          'brushG': Schema(SchemaType.integer, description: 'Green component of the brush color (0-255). Defaults to 0.'),
          'brushB': Schema(SchemaType.integer, description: 'Blue component of the brush color (0-255). Defaults to 0.'),
        },
        requiredProperties: ['outputFileName', 'text', 'fontFilePath'],
      ),
    ),
  ],
);

final createPdfFormTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'createPdfForm',
      'Creates a new PDF document with an interactive form, including a text box and a checkbox, with customizable fields and initial values. Saves the document to a given file name.',
      Schema(
        SchemaType.object,
        properties: {
          'outputFileName': Schema(SchemaType.string, description: 'The name of the PDF form file to create (e.g., "my_form.pdf").'),
          'textBoxFieldName': Schema(SchemaType.string, description: 'The name of the text box field.'),
          'textBoxBoundsX': Schema(SchemaType.number, description: 'X-coordinate of the text box bounds. Defaults to 0.0.'),
          'textBoxBoundsY': Schema(SchemaType.number, description: 'Y-coordinate of the text box bounds. Defaults to 0.0.'),
          'textBoxBoundsWidth': Schema(SchemaType.number, description: 'Width of the text box bounds. Defaults to 100.0.'),
          'textBoxBoundsHeight': Schema(SchemaType.number, description: 'Height of the text box bounds. Defaults to 20.0.'),
          'textBoxText': Schema(SchemaType.string, description: 'The initial text content for the text box. Defaults to empty string.'),
          'checkBoxFieldName': Schema(SchemaType.string, description: 'The name of the checkbox field.'),
          'checkBoxBoundsX': Schema(SchemaType.number, description: 'X-coordinate of the checkbox bounds. Defaults to 150.0.'),
          'checkBoxBoundsY': Schema(SchemaType.number, description: 'Y-coordinate of the checkbox bounds. Defaults to 0.0.'),
          'checkBoxBoundsWidth': Schema(SchemaType.number, description: 'Width of the checkbox bounds. Defaults to 30.0.'),
          'checkBoxBoundsHeight': Schema(SchemaType.number, description: 'Height of the checkbox bounds. Defaults to 30.0.'),
          'isCheckBoxChecked': Schema(SchemaType.boolean, description: 'Whether the checkbox is initially checked. Defaults to true.'),
        },
        requiredProperties: ['outputFileName', 'textBoxFieldName', 'checkBoxFieldName'],
      ),
    ),
  ],
);

final fillExistingPdfFormTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'fillExistingPdfForm',
      'Loads an existing PDF form and fills specific text box and/or radio button fields by index with provided values. Saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF form file to load (e.g., "input.pdf"). This file must exist and contain the form fields.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "output.pdf").'),
          'textBoxFieldIndex': Schema(SchemaType.integer, description: 'Optional: The 0-based index of the text box field to fill.'),
          'textBoxValue': Schema(SchemaType.string, description: 'Optional: The value to set for the text box field. Required if `textBoxFieldIndex` is provided.'),
          'radioButtonListFieldIndex': Schema(SchemaType.integer, description: 'Optional: The 0-based index of the radio button list field.'),
          'radioButtonSelectedIndex': Schema(SchemaType.integer, description: 'Optional: The 0-based index of the radio button to select within the list. Required if `radioButtonListFieldIndex` is provided.'),
        },
        requiredProperties: ['inputFileName', 'outputFileName'],
      ),
    ),
  ],
);

final flattenExistingPdfFormTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'flattenExistingPdfForm',
      'Loads an existing PDF form and flattens all its form fields, making them non-editable. Saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF form file to load (e.g., "input.pdf"). This file must exist and contain form fields.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "output.pdf").'),
        },
        requiredProperties: ['inputFileName', 'outputFileName'],
      ),
    ),
  ],
);

final signNewPdfDocumentTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'signNewPdfDocument',
      'Creates a new PDF document with a digital signature field, signed using a specified certificate and password. Saves the signed document.',
      Schema(
        SchemaType.object,
        properties: {
          'outputFileName': Schema(SchemaType.string, description: 'The name of the signed PDF file to create (e.g., "signed.pdf").'),
          'signatureFieldName': Schema(SchemaType.string, description: 'The name of the digital signature field.'),
          'signatureBoundsX': Schema(SchemaType.number, description: 'X-coordinate of the signature field bounds. Defaults to 0.0.'),
          'signatureBoundsY': Schema(SchemaType.number, description: 'Y-coordinate of the signature field bounds. Defaults to 0.0.'),
          'signatureBoundsWidth': Schema(SchemaType.number, description: 'Width of the signature field bounds. Defaults to 200.0.'),
          'signatureBoundsHeight': Schema(SchemaType.number, description: 'Height of the signature field bounds. Defaults to 50.0.'),
          'certificateFilePath': Schema(SchemaType.string, description: 'The path to the PFX certificate file (e.g., "certificate.pfx"). This file must exist.'),
          'certificatePassword': Schema(SchemaType.string, description: 'The password for the certificate file.'),
        },
        requiredProperties: ['outputFileName', 'signatureFieldName', 'certificateFilePath', 'certificatePassword'],
      ),
    ),
  ],
);

final signExistingPdfDocumentTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'signExistingPdfDocument',
      'Loads an existing PDF document with a signature field and digitally signs it using a specified certificate and password. Saves the modified document.',
      Schema(
        SchemaType.object,
        properties: {
          'inputFileName': Schema(SchemaType.string, description: 'The name of the existing PDF file to load (e.g., "input.pdf"). This file must exist and contain a signature field.'),
          'outputFileName': Schema(SchemaType.string, description: 'The name of the modified PDF file to save (e.g., "output.pdf").'),
          'signatureFieldIndex': Schema(SchemaType.integer, description: 'The 0-based index of the signature field to sign. Defaults to 0.'),
          'certificateFilePath': Schema(SchemaType.string, description: 'The path to the PFX certificate file (e.g., "certificate.pfx"). This file must exist.'),
          'certificatePassword': Schema(SchemaType.string, description: 'The password for the certificate file.'),
        },
        requiredProperties: ['inputFileName', 'outputFileName', 'certificateFilePath', 'certificatePassword'],
      ),
    ),
  ],
);

// --- Dialers for PDF Generation Functions ---

/// Dialer for [createSimplePdfFromText].
Future<Map<String, dynamic>> createSimplePdfFromTextToolCall(Map<String, dynamic> args) async {
  try {
    await createSimplePdfFromText(
      text: args['text'] as String,
      fontFamily: (args['fontFamily'] as String?) ?? 'helvetica',
      fontSize: (args['fontSize'] as double?) ?? 12.0,
    //  outputFileName: args['outputFileName'] as String,
      colorR: (args['colorR'] as int?) ?? 0,
      colorG: (args['colorG'] as int?) ?? 0,
      colorB: (args['colorB'] as int?) ?? 0,
      boundsX: (args['boundsX'] as double?) ?? 0.0,
      boundsY: (args['boundsY'] as double?) ?? 0.0,
      boundsWidth: (args['boundsWidth'] as double?) ?? 150.0,
      boundsHeight: (args['boundsHeight'] as double?) ?? 20.0,
    );
    debugPrint("createSimplePdfFromText: Successfully created '${args['outputFileName']}'");
    return {
      'success': true,
      'message': "PDF document '${args['outputFileName']}' created successfully."
    };
  } catch (e) {
    debugPrint("Error in createSimplePdfFromText: $e");
    return {
      'error': true,
      'message': "Failed to create simple PDF: $e. Ensure necessary permissions."
    };
  }
}

/// Dialer for [addTrueTypeTextToPdf].
Future<Map<String, dynamic>> addTrueTypeTextToPdfToolCall(Map<String, dynamic> args) async {
  try {
    await addTrueTypeTextToPdf(
      text: args['text'] as String,
      fontFilePath: args['fontFilePath'] as String,
      fontSize: (args['fontSize'] as double?) ?? 12.0,
      outputFileName: args['outputFileName'] as String,
      boundsX: (args['boundsX'] as double?) ?? 0.0,
      boundsY: (args['boundsY'] as double?) ?? 0.0,
      boundsWidth: (args['boundsWidth'] as double?) ?? 200.0,
      boundsHeight: (args['boundsHeight'] as double?) ?? 50.0,
    );
    debugPrint("addTrueTypeTextToPdf: Successfully created '${args['outputFileName']}' with TrueType font text.");
    return {
      'success': true,
      'message':
          "PDF document '${args['outputFileName']}' with TrueType font text created successfully. (Requires '${args['fontFilePath']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in addTrueTypeTextToPdf: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['fontFilePath']}' exists and has read permissions."
    };
  } catch (e) {
    debugPrint("Error in addTrueTypeTextToPdf: $e");
    return {
      'error': true,
      'message': "Failed to add TrueType text to PDF: $e."
    };
  }
}

/// Dialer for [addImagesToPdf].
Future<Map<String, dynamic>> addImagesToPdfToolCall(Map<String, dynamic> args) async {
  try {
    await addImagesToPdf(
      imageFilePath: args['imageFilePath'] as String,
      outputFileName: args['outputFileName'] as String,
      boundsX: (args['boundsX'] as double?) ?? 0.0,
      boundsY: (args['boundsY'] as double?) ?? 0.0,
      boundsWidth: (args['boundsWidth'] as double?) ?? 500.0,
      boundsHeight: (args['boundsHeight'] as double?) ?? 200.0,
    );
    debugPrint("addImagesToPdf: Successfully created '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "PDF document '${args['outputFileName']}' with image added successfully. (Requires '${args['imageFilePath']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in addImagesToPdf: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['imageFilePath']}' exists and has read permissions."
    };
  } catch (e) {
    debugPrint("Error in addImagesToPdf: $e");
    return {
      'error': true,
      'message': "Failed to add image to PDF: $e."
    };
  }
}

/// Dialer for [createPdfWithFlowLayout].
Future<Map<String, dynamic>> createPdfWithFlowLayoutToolCall(Map<String, dynamic> args) async {
  try {
    await createPdfWithFlowLayout(
      paragraphText: args['paragraphText'] as String,
      fontFamily: (args['fontFamily'] as String?) ?? 'helvetica',
      fontSize: (args['fontSize'] as double?) ?? 12.0,
      outputFileName: args['outputFileName'] as String,
      lineColorR: (args['lineColorR'] as int?) ?? 255,
      lineColorG: (args['lineColorG'] as int?) ?? 0,
      lineColorB: (args['lineColorB'] as int?) ?? 0,
      lineOffset: (args['lineOffset'] as double?) ?? 10.0,
    );
    debugPrint("createPdfWithFlowLayout: Successfully created '${args['outputFileName']}' with flow layout.");
    return {
      'success': true,
      'message': "PDF document '${args['outputFileName']}' with flow layout created successfully."
    };
  } catch (e) {
    debugPrint("Error in createPdfWithFlowLayout: $e");
    return {
      'error': true,
      'message': "Failed to create PDF with flow layout: $e. Ensure necessary permissions."
    };
  }
}

/// Dialer for [addBulletsAndListsToPdf].
Future<Map<String, dynamic>> addBulletsAndListsToPdfToolCall(Map<String, dynamic> args) async {
  try {
    await addBulletsAndListsToPdf(
      mainListItems: (args['mainListItems'] as List<dynamic>).map((e) => e as String).toList(),
      subListItems: (args['subListItems'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      fontFamily: (args['fontFamily'] as String?) ?? 'helvetica',
      fontSize: (args['fontSize'] as double?) ?? 12.0,
      subFontSize: (args['subFontSize'] as double?) ?? 10.0,
      outputFileName: args['outputFileName'] as String,
    );
    debugPrint("addBulletsAndListsToPdf: Successfully created '${args['outputFileName']}' with bullets and lists.");
    return {
      'success': true,
      'message': "PDF document '${args['outputFileName']}' with bullets and lists created successfully."
    };
  } catch (e) {
    debugPrint("Error in addBulletsAndListsToPdf: $e");
    return {
      'error': true,
      'message': "Failed to add bullets and lists to PDF: $e. Ensure necessary permissions."
    };
  }
}

/// Dialer for [addTablesToPdf].
Future<Map<String, dynamic>> addTablesToPdfToolCall(Map<String, dynamic> args) async {
  try {
    await addTablesToPdf(
      columnCount: args['columnCount'] as int,
      headerNames: (args['headerNames'] as List<dynamic>).map((e) => e as String).toList(),
      rowData: (args['rowData'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((f) => f as String).toList())
          .toList(),
      headerFontFamily: (args['headerFontFamily'] as String?) ?? 'helvetica',
      headerFontSize: (args['headerFontSize'] as double?) ?? 10.0,
      outputFileName: args['outputFileName'] as String,
    );
    debugPrint("addTablesToPdf: Successfully created '${args['outputFileName']}' with a table.");
    return {
      'success': true,
      'message': "PDF document '${args['outputFileName']}' with table created successfully."
    };
  } catch (e) {
    debugPrint("Error in addTablesToPdf: $e");
    return {
      'error': true,
      'message': "Failed to add table to PDF: $e. Ensure necessary permissions."
    };
  }
}

/// Dialer for [addHeadersAndFootersToPdf].
Future<Map<String, dynamic>> addHeadersAndFootersToPdfToolCall(Map<String, dynamic> args) async {
  try {
    await addHeadersAndFootersToPdf(
      headerText: args['headerText'] as String,
      footerText: args['footerText'] as String,
      fontFamily: (args['fontFamily'] as String?) ?? 'helvetica',
      fontSize: (args['fontSize'] as double?) ?? 12.0,
      outputFileName: args['outputFileName'] as String,
      numPages: (args['numPages'] as int?) ?? 2,
      headerColorR: (args['headerColorR'] as int?) ?? 0,
      headerColorG: (args['headerColorG'] as int?) ?? 0,
      headerColorB: (args['headerColorB'] as int?) ?? 0,
      footerColorR: (args['footerColorR'] as int?) ?? 0,
      footerColorG: (args['footerColorG'] as int?) ?? 0,
      footerColorB: (args['footerColorB'] as int?) ?? 0,
    );
    debugPrint("addHeadersAndFootersToPdf: Successfully created '${args['outputFileName']}' with headers and footers.");
    return {
      'success': true,
      'message': "PDF document '${args['outputFileName']}' with headers and footers created successfully."
    };
  } catch (e) {
    debugPrint("Error in addHeadersAndFootersToPdf: $e");
    return {
      'error': true,
      'message': "Failed to add headers and footers to PDF: $e. Ensure necessary permissions."
    };
  }
}

/// Dialer for [loadAndModifyExistingPdf].
Future<Map<String, dynamic>> loadAndModifyExistingPdfToolCall(Map<String, dynamic> args) async {
  try {
    await loadAndModifyExistingPdf(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      pageIndex: (args['pageIndex'] as int?) ?? 0,
      textToAdd: args['textToAdd'] as String,
      fontFamily: (args['fontFamily'] as String?) ?? 'helvetica',
      fontSize: (args['fontSize'] as double?) ?? 12.0,
      colorR: (args['colorR'] as int?) ?? 0,
      colorG: (args['colorG'] as int?) ?? 0,
      colorB: (args['colorB'] as int?) ?? 0,
      boundsX: (args['boundsX'] as double?) ?? 0.0,
      boundsY: (args['boundsY'] as double?) ?? 0.0,
      boundsWidth: (args['boundsWidth'] as double?) ?? 150.0,
      boundsHeight: (args['boundsHeight'] as double?) ?? 20.0,
    );
    debugPrint(
        "loadAndModifyExistingPdf: Successfully modified '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Existing PDF '${args['inputFileName']}' modified and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in loadAndModifyExistingPdf: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } on ArgumentError catch (e) {
    debugPrint("Argument error in loadAndModifyExistingPdf: $e");
    return {
      'error': true,
      'message': "Invalid argument: $e. Please check page index."
    };
  } catch (e) {
    debugPrint("Error in loadAndModifyExistingPdf: $e");
    return {
      'error': true,
      'message': "Failed to load and modify existing PDF: $e."
    };
  }
}

/// Dialer for [addRemovePageFromExistingPdf].
Future<Map<String, dynamic>> addRemovePageFromExistingPdfToolCall(Map<String, dynamic> args) async {
  try {
    await addRemovePageFromExistingPdf(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      removePageIndex: args['removePageIndex'] as int?,
      addText: args['addText'] as String?,
      addFontFamily: (args['addFontFamily'] as String?) ?? 'helvetica',
      addFontSize: (args['addFontSize'] as double?) ?? 12.0,
      addColorR: (args['addColorR'] as int?) ?? 0,
      addColorG: (args['addColorG'] as int?) ?? 0,
      addColorB: (args['addColorB'] as int?) ?? 0,
      addBoundsX: (args['addBoundsX'] as double?) ?? 0.0,
      addBoundsY: (args['addBoundsY'] as double?) ?? 0.0,
      addBoundsWidth: (args['addBoundsWidth'] as double?) ?? 150.0,
      addBoundsHeight: (args['addBoundsHeight'] as double?) ?? 20.0,
    );
    debugPrint(
        "addRemovePageFromExistingPdf: Successfully processed pages in '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Pages processed in existing PDF '${args['inputFileName']}' and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in addRemovePageFromExistingPdf: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } catch (e) {
    debugPrint("Error in addRemovePageFromExistingPdf: $e");
    return {
      'error': true,
      'message': "Failed to add/remove page from existing PDF: $e."
    };
  }
}

/// Dialer for [createAnnotationInPdf].
Future<Map<String, dynamic>> createAnnotationInPdfToolCall(Map<String, dynamic> args) async {
  try {
    await createAnnotationInPdf(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      pageIndex: (args['pageIndex'] as int?) ?? 0,
      boundsX: (args['boundsX'] as double?) ?? 0.0,
      boundsY: (args['boundsY'] as double?) ?? 0.0,
      boundsWidth: (args['boundsWidth'] as double?) ?? 150.0,
      boundsHeight: (args['boundsHeight'] as double?) ?? 100.0,
      annotationText: args['annotationText'] as String,
      colorR: (args['colorR'] as int?) ?? 255,
      colorG: (args['colorG'] as int?) ?? 0,
      colorB: (args['colorB'] as int?) ?? 0,
    );
    debugPrint(
        "createAnnotationInPdf: Successfully added annotation to '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Annotation added to '${args['inputFileName']}' and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in createAnnotationInPdf: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } on ArgumentError catch (e) {
    debugPrint("Argument error in createAnnotationInPdf: $e");
    return {
      'error': true,
      'message': "Invalid argument: $e. Please check page index or bounds."
    };
  } catch (e) {
    debugPrint("Error in createAnnotationInPdf: $e");
    return {
      'error': true,
      'message': "Failed to create annotation in PDF: $e."
    };
  }
}

/// Dialer for [loadAndModifyAnnotation].
Future<Map<String, dynamic>> loadAndModifyAnnotationToolCall(Map<String, dynamic> args) async {
  try {
    await loadAndModifyAnnotation(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      pageIndex: (args['pageIndex'] as int?) ?? 0,
      annotationIndex: (args['annotationIndex'] as int?) ?? 0,
      newAnnotationText: args['newAnnotationText'] as String,
    );
    debugPrint(
        "loadAndModifyAnnotation: Successfully modified annotation in '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Existing annotation in '${args['inputFileName']}' modified and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist and contain at least one annotation)"
    };
  } on ArgumentError catch (e) {
    debugPrint("Argument error in loadAndModifyAnnotation: $e");
    return {
      'error': true,
      'message':
          "Failed to modify annotation: $e. The PDF might not contain an annotation at the specified index or it's not a modifiable type. (Requires '${args['inputFileName']}' to exist and contain at least one annotation)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in loadAndModifyAnnotation: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } catch (e) {
    debugPrint("Error in loadAndModifyAnnotation: $e");
    return {
      'error': true,
      'message': "Failed to load and modify annotation: $e."
    };
  }
}

/// Dialer for [addBookmarksToPdf].
Future<Map<String, dynamic>> addBookmarksToPdfToolCall(Map<String, dynamic> args) async {
  try {
    await addBookmarksToPdf(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      bookmarkName: args['bookmarkName'] as String,
      destinationPageIndex: (args['destinationPageIndex'] as int?) ?? 0,
      destinationX: (args['destinationX'] as double?) ?? 20.0,
      destinationY: (args['destinationY'] as double?) ?? 20.0,
      colorR: (args['colorR'] as int?) ?? 255,
      colorG: (args['colorG'] as int?) ?? 0,
      colorB: (args['colorB'] as int?) ?? 0,
    );
    debugPrint(
        "addBookmarksToPdf: Successfully added bookmark to '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Bookmark added to '${args['inputFileName']}' and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist and have enough pages)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in addBookmarksToPdf: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } on ArgumentError catch (e) {
    debugPrint("Argument error in addBookmarksToPdf: $e");
    return {
      'error': true,
      'message':
          "Failed to add bookmark: $e. The PDF might not have enough pages for the destination. (Requires '${args['inputFileName']}' to exist and have enough pages)"
    };
  } catch (e) {
    debugPrint("Error in addBookmarksToPdf: $e");
    return {
      'error': true,
      'message': "Failed to add bookmark to PDF: $e."
    };
  }
}

/// Dialer for [extractTextFromAllPdfPages].
Future<Map<String, dynamic>> extractTextFromAllPdfPagesToolCall(Map<String, dynamic> args) async {
  try {
    final String extractedText = await extractTextFromAllPdfPages(
      inputFileName: args['inputFileName'] as String,
    );
    debugPrint(
        "extractTextFromAllPdfPages: Successfully extracted text from all pages of '${args['inputFileName']}'.");
    return {
      'success': true,
      'message':
          "Text extracted from '${args['inputFileName']}' successfully.",
      'extractedText': extractedText, // Include extracted text in the result
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in extractTextFromAllPdfPages: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read permissions."
    };
  } catch (e) {
    debugPrint("Error in extractTextFromAllPdfPages: $e");
    return {
      'error': true,
      'message': "Failed to extract text from all PDF pages: $e."
    };
  }
}

/// Dialer for [extractTextFromSpecificPdfPage].
Future<Map<String, dynamic>> extractTextFromSpecificPdfPageToolCall(Map<String, dynamic> args) async {
  try {
    final String extractedText = await extractTextFromSpecificPdfPage(
      inputFileName: args['inputFileName'] as String,
      pageIndex: (args['pageIndex'] as int?) ?? 0,
    );
    debugPrint(
        "extractTextFromSpecificPdfPage: Successfully extracted text from specific page of '${args['inputFileName']}'.");
    return {
      'success': true,
      'message':
          "Text extracted from specific page of '${args['inputFileName']}' successfully.",
      'extractedText': extractedText, // Include extracted text in the result
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in extractTextFromSpecificPdfPage: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read permissions."
    };
  } on ArgumentError catch (e) {
    debugPrint("Argument error in extractTextFromSpecificPdfPage: $e");
    return {
      'error': true,
      'message': "Invalid argument: $e. Please check page index."
    };
  } catch (e) {
    debugPrint("Error in extractTextFromSpecificPdfPage: $e");
    return {
      'error': true,
      'message': "Failed to extract text from specific PDF page: $e."
    };
  }
}

/// Dialer for [findTextInPdf].
Future<Map<String, dynamic>> findTextInPdfToolCall(Map<String, dynamic> args) async {
  try {
    final List<Map<String, dynamic>> results = await findTextInPdf(
      inputFileName: args['inputFileName'] as String,
      textsToFind: (args['textsToFind'] as List<dynamic>).map((e) => e as String).toList(),
    );
    debugPrint("findTextInPdf: Successfully performed text search in '${args['inputFileName']}'.");
    return {
      'success': true,
      'message':
          "Text search performed in '${args['inputFileName']}' successfully.",
      'foundTexts': results, // Include search results
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in findTextInPdf: $e");
    return {
      'error': true,
      'message': "File system error: $e. Ensure '${args['inputFileName']}' exists and has read permissions."
    };
  } catch (e) {
    debugPrint("Error in findTextInPdf: $e");
    return {
      'error': true,
      'message': "Failed to find text in PDF: $e."
    };
  }
}

/// Dialer for [encryptPdfDocument].
Future<Map<String, dynamic>> encryptPdfDocumentToolCall(Map<String, dynamic> args) async {
  try {
    await encryptPdfDocument(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      userPassword: args['userPassword'] as String,
      ownerPassword: args['ownerPassword'] as String,
      encryptionAlgorithm: (args['encryptionAlgorithm'] as String?) ?? 'aesx256Bit',
    );
    debugPrint(
        "encryptPdfDocument: Successfully encrypted '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "PDF document '${args['inputFileName']}' encrypted and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in encryptPdfDocument: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } catch (e) {
    debugPrint("Error in encryptPdfDocument: $e");
    return {
      'error': true,
      'message': "Failed to encrypt PDF: $e."
    };
  }
}

/// Dialer for [createPdfConformanceDocument].
Future<Map<String, dynamic>> createPdfConformanceDocumentToolCall(Map<String, dynamic> args) async {
  try {
    await createPdfConformanceDocument(
      outputFileName: args['outputFileName'] as String,
      conformanceLevel: (args['conformanceLevel'] as String?) ?? 'a1b',
      text: args['text'] as String,
      fontFilePath: args['fontFilePath'] as String,
      fontSize: (args['fontSize'] as double?) ?? 12.0,
      boundsX: (args['boundsX'] as double?) ?? 20.0,
      boundsY: (args['boundsY'] as double?) ?? 20.0,
      boundsWidth: (args['boundsWidth'] as double?) ?? 200.0,
      boundsHeight: (args['boundsHeight'] as double?) ?? 50.0,
      brushR: (args['brushR'] as int?) ?? 0,
      brushG: (args['brushG'] as int?) ?? 0,
      brushB: (args['brushB'] as int?) ?? 0,
    );
    debugPrint(
        "createPdfConformanceDocument: Successfully created '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "PDF conformance document '${args['outputFileName']}' created successfully. (Requires '${args['fontFilePath']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in createPdfConformanceDocument: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['fontFilePath']}' exists and has read permissions, and write permissions for '${args['outputFileName']}'."
    };
  } catch (e) {
    debugPrint("Error in createPdfConformanceDocument: $e");
    return {
      'error': true,
      'message': "Failed to create PDF conformance document: $e."
    };
  }
}

/// Dialer for [createPdfForm].
Future<Map<String, dynamic>> createPdfFormToolCall(Map<String, dynamic> args) async {
  try {
    await createPdfForm(
      outputFileName: args['outputFileName'] as String,
      textBoxFieldName: args['textBoxFieldName'] as String,
      textBoxBoundsX: (args['textBoxBoundsX'] as double?) ?? 0.0,
      textBoxBoundsY: (args['textBoxBoundsY'] as double?) ?? 0.0,
      textBoxBoundsWidth: (args['textBoxBoundsWidth'] as double?) ?? 100.0,
      textBoxBoundsHeight: (args['textBoxBoundsHeight'] as double?) ?? 20.0,
      textBoxText: (args['textBoxText'] as String?) ?? '',
      checkBoxFieldName: args['checkBoxFieldName'] as String,
      checkBoxBoundsX: (args['checkBoxBoundsX'] as double?) ?? 150.0,
      checkBoxBoundsY: (args['checkBoxBoundsY'] as double?) ?? 0.0,
      checkBoxBoundsWidth: (args['checkBoxBoundsWidth'] as double?) ?? 30.0,
      checkBoxBoundsHeight: (args['checkBoxBoundsHeight'] as double?) ?? 30.0,
      isCheckBoxChecked: (args['isCheckBoxChecked'] as bool?) ?? true,
    );
    debugPrint("createPdfForm: Successfully created '${args['outputFileName']}'.");
    return {
      'success': true,
      'message': "PDF form '${args['outputFileName']}' created successfully."
    };
  } catch (e) {
    debugPrint("Error in createPdfForm: $e");
    return {
      'error': true,
      'message': "Failed to create PDF form: $e. Ensure necessary permissions."
    };
  }
}

/// Dialer for [fillExistingPdfForm].
Future<Map<String, dynamic>> fillExistingPdfFormToolCall(Map<String, dynamic> args) async {
  try {
    await fillExistingPdfForm(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      textBoxFieldIndex: args['textBoxFieldIndex'] as int?,
      textBoxValue: args['textBoxValue'] as String?,
      radioButtonListFieldIndex: args['radioButtonListFieldIndex'] as int?,
      radioButtonSelectedIndex: args['radioButtonSelectedIndex'] as int?,
    );
    debugPrint(
        "fillExistingPdfForm: Successfully filled existing form in '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Existing PDF form '${args['inputFileName']}' filled and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist and contain appropriate form fields)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in fillExistingPdfForm: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } on TypeError catch (e) {
    debugPrint("Type error in fillExistingPdfForm (likely wrong field type or index): $e");
    return {
      'error': true,
      'message':
          "Failed to fill existing PDF form: $e. The PDF might not contain form fields as expected or they are of the wrong type."
    };
  } catch (e) {
    debugPrint("Error in fillExistingPdfForm: $e");
    return {
      'error': true,
      'message': "Failed to fill existing PDF form: $e."
    };
  }
}

/// Dialer for [flattenExistingPdfForm].
Future<Map<String, dynamic>> flattenExistingPdfFormToolCall(Map<String, dynamic> args) async {
  try {
    await flattenExistingPdfForm(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
    );
    debugPrint(
        "flattenExistingPdfForm: Successfully flattened existing form in '${args['inputFileName']}' and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Existing PDF form '${args['inputFileName']}' flattened and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist and contain form fields)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in flattenExistingPdfForm: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' exists and has read/write permissions."
    };
  } catch (e) {
    debugPrint("Error in flattenExistingPdfForm: $e");
    return {
      'error': true,
      'message': "Failed to flatten existing PDF form: $e."
    };
  }
}

/// Dialer for [signNewPdfDocument].
Future<Map<String, dynamic>> signNewPdfDocumentToolCall(Map<String, dynamic> args) async {
  try {
    await signNewPdfDocument(
      outputFileName: args['outputFileName'] as String,
      signatureFieldName: args['signatureFieldName'] as String,
      signatureBoundsX: (args['signatureBoundsX'] as double?) ?? 0.0,
      signatureBoundsY: (args['signatureBoundsY'] as double?) ?? 0.0,
      signatureBoundsWidth: (args['signatureBoundsWidth'] as double?) ?? 200.0,
      signatureBoundsHeight: (args['signatureBoundsHeight'] as double?) ?? 50.0,
      certificateFilePath: args['certificateFilePath'] as String,
      certificatePassword: args['certificatePassword'] as String,
    );
    debugPrint(
        "signNewPdfDocument: Successfully digitally signed new PDF document and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "New PDF document digitally signed and saved as '${args['outputFileName']}' successfully. (Requires '${args['certificateFilePath']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in signNewPdfDocument: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['certificateFilePath']}' exists and has read permissions, and write permissions for '${args['outputFileName']}'."
    };
  } catch (e) {
    debugPrint("Error in signNewPdfDocument: $e");
    return {
      'error': true,
      'message': "Failed to sign new PDF document: $e."
    };
  }
}

/// Dialer for [signExistingPdfDocument].
Future<Map<String, dynamic>> signExistingPdfDocumentToolCall(Map<String, dynamic> args) async {
  try {
    await signExistingPdfDocument(
      inputFileName: args['inputFileName'] as String,
      outputFileName: args['outputFileName'] as String,
      signatureFieldIndex: (args['signatureFieldIndex'] as int?) ?? 0,
      certificateFilePath: args['certificateFilePath'] as String,
      certificatePassword: args['certificatePassword'] as String,
    );
    debugPrint(
        "signExistingPdfDocument: Successfully digitally signed existing PDF document and saved as '${args['outputFileName']}'.");
    return {
      'success': true,
      'message':
          "Existing PDF document '${args['inputFileName']}' digitally signed and saved as '${args['outputFileName']}' successfully. (Requires '${args['inputFileName']}' to exist and contain a signature field, and '${args['certificateFilePath']}' to exist)"
    };
  } on FileSystemException catch (e) {
    debugPrint("File system error in signExistingPdfDocument: $e");
    return {
      'error': true,
      'message':
          "File system error: $e. Ensure '${args['inputFileName']}' and '${args['certificateFilePath']}' exist and have read/write permissions."
    };
  } on ArgumentError catch (e) {
    debugPrint("Argument error in signExistingPdfDocument: $e");
    return {
      'error': true,
      'message':
          "Failed to sign existing PDF document: $e. The PDF might not contain a signature field as expected or index is out of bounds."
    };
  } catch (e) {
    debugPrint("Error in signExistingPdfDocument: $e");
    return {
      'error': true,
      'message': "Failed to sign existing PDF document: $e."
    };
  }
}