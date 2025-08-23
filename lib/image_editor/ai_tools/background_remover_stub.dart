import 'package:flutter/material.dart';
import 'package:hori/image_editor/mixins/editor_page_mixin.dart';

// Project imports:

/// IMPORTANT:
/// This is just a stub class for the web implementation. The actual source code
/// is in the same folder, using the same name without 'stub' in the class name.
/// This file will not be directly used, but it's part of the original example structure for conditional imports.
/// For a real app, you'd use conditional imports in `ai_image_editor_page.dart` if supporting web.
/// Since this example is for a generated solution, I'll place the actual remover logic in ai_image_editor_page.dart.
class BackgroundRemoverExampleStub extends StatefulWidget {
  /// Stub-Constructor
  const BackgroundRemoverExampleStub({super.key});

  @override
  State<BackgroundRemoverExampleStub> createState() =>
      _BackgroundRemoverExampleStubState();
}

class _BackgroundRemoverExampleStubState extends State<BackgroundRemoverExampleStub>
    with EditorPageMixin<BackgroundRemoverExampleStub> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Background Remover is not fully supported on this platform in this simplified example.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}