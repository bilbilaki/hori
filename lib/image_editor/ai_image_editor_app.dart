import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:hori/image_editor/ai_tools/ai_replace_background_toolbar.dart';
import 'package:hori/image_editor/ai_tools/ai_setup_dialog.dart';
import 'package:hori/image_editor/ai_tools/ai_text_commands_toolbar.dart';
import 'package:hori/image_editor/ai_tools/enums/ai_generation_mode.dart';
import 'package:hori/image_editor/ai_tools/enums/ai_provider.dart';
import 'package:hori/image_editor/ai_tools/providers/ai_base_provider.dart';
import 'package:hori/image_editor/ai_tools/providers/openai_provider.dart';
import 'package:hori/image_editor/mixins/editor_page_mixin.dart';
import 'package:hori/image_editor/utils/ai_provider_factory.dart';
import 'package:hori/image_editor/widgets/loading_indicator.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import 'config/app_constants.dart';

enum AiEditorMode { none, textCommands, replaceBackground, removeBackground }

class AiImageEditorApp extends StatefulWidget {
  const AiImageEditorApp({super.key});

  @override
  State<AiImageEditorApp> createState() => _AiImageEditorAppState();
}

class _AiImageEditorAppState extends State<AiImageEditorApp>
    with EditorPageMixin<AiImageEditorApp> {
  AiEditorMode _currentAiMode = AiEditorMode.none;

  // For AI Text Commands
  final _alignTopNotifierText = ValueNotifier(false);
  final _isProcessingNotifierText = ValueNotifier(false);
  final _generationModeNotifier = ValueNotifier(AiGenerationMode.text);
  final _inputCtrlText = TextEditingController();
  final _inputFocusText = FocusNode();
  AiBaseProvider? _aiTextProvider;

  // For AI Replace Background
  final _alignTopNotifierReplace = ValueNotifier(false);
  final _isProcessingNotifierReplace = ValueNotifier(false);
  final _inputCtrlReplace = TextEditingController();
  final _inputFocusReplace = FocusNode();
  String? _openAiApiKeyForImageGeneration; // DALL-E requires OpenAI key

  late final ProImageEditorConfigs _editorConfigs = ProImageEditorConfigs(
    designMode: platformDesignMode,
    imageGeneration: const ImageGenerationConfigs(
      outputFormat: OutputFormat.png,
    ),
    mainEditor: MainEditorConfigs(
      enableCloseButton: !isDesktopMode(context),
      widgets: MainEditorWidgets(
        bodyItems: _buildBodyItems,
        bottomBar: _buildBottomNavigationBar,
      ),
    ),
  );

  late final ProImageEditorCallbacks _editorCallbacks = ProImageEditorCallbacks(
    onImageEditingStarted: onImageEditingStarted,
    onImageEditingComplete: onImageEditingComplete,
    onCloseEditor: (editorMode) => onCloseEditor(editorMode: editorMode),
    mainEditorCallbacks: MainEditorCallbacks(
      helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
      onTap: () {
        if (_currentAiMode == AiEditorMode.textCommands) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
    ),
  );

  @override
  void initState() {
    super.initState();
    preCacheImage(assetPath: AppConstants.defaultImageAsset);
  }

  @override
  void dispose() {
    _alignTopNotifierText.dispose();
    _isProcessingNotifierText.dispose();
    _generationModeNotifier.dispose();
    _inputCtrlText.dispose();
    _inputFocusText.dispose();

    _alignTopNotifierReplace.dispose();
    _isProcessingNotifierReplace.dispose();
    _inputCtrlReplace.dispose();
    _inputFocusReplace.dispose();

    super.dispose();
  }

  // --- AI Text Commands Logic ---
  void _setupAiTextProvider(String apiKey, AiProvider provider) {
    _aiTextProvider = AiProviderFactory.create(
      apiKey: apiKey,
      provider: provider,
      context: context,
    );
    if (provider == AiProvider.openAi) {
      _openAiApiKeyForImageGeneration = apiKey; // Store OpenAI key for DALL-E
    }
    setState(() {});
  }

  void _sendCommand() async {
    final command = _inputCtrlText.value.text.trim();
    if (command.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _isProcessingNotifierText.value = true;
    final editor = editorKey.currentState!;

    if (_generationModeNotifier.value == AiGenerationMode.image) {
      await _aiTextProvider!.sendImageGenerationRequest(editor, command);
    } else {
      await _aiTextProvider!.sendCommand(editor, command);
    }

    if (!mounted) return;
    _inputCtrlText.value = TextEditingValue.empty;
    _isProcessingNotifierText.value = false;
    if (isDesktop) _inputFocusText.requestFocus();
  }

  // --- AI Replace Background Logic ---
  void _generateBackgroundImage() async {
    final prompt = _inputCtrlReplace.value.text.trim();
    if (prompt.isEmpty) return;
    if (_openAiApiKeyForImageGeneration == null ||
        _openAiApiKeyForImageGeneration!.isEmpty) {
      _showApiKeyMissingDialog();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isProcessingNotifierReplace.value = true;
    final editor = editorKey.currentState!;

    // Using OpenAI provider directly for image generation for background
    final openAiProvider = OpenAiProvider(
      apiKey: _openAiApiKeyForImageGeneration!,
      context: context,
    );
    await openAiProvider.sendImageGenerationRequest(editor, prompt);
    // After generating the image, the image will be added as a layer.
    // To replace the background, we need to take the generated image layer
    // and set it as the new background image.

    // A more sophisticated implementation would involve:
    // 1. DALL-E generating an image *without* adding it as a layer.
    // 2. Downloading that image as bytes.
    // 3. Calling `editor.updateBackgroundImage(EditorImage(byteArray: newImageBytes));`
    // For simplicity in this example, `sendImageGenerationRequest` from OpenAI
    // provider adds it as a layer. We would then need to manually convert it
    // to background or extend the AI provider to directly return bytes for this use case.
    // For now, it adds a layer. To make it truly replace the background, we'll
    // assume a mechanism to get the image bytes from the last added layer.
    // This is a simplification; a full implementation would require more direct control
    // over DALL-E output and how it integrates with `updateBackgroundImage`.

    if (!mounted) return;
    _inputCtrlReplace.value = TextEditingValue.empty;
    _isProcessingNotifierReplace.value = false;
    if (isDesktop) _inputFocusReplace.requestFocus();
  }

  // --- Background Remover Logic ---
  // void _removeBackground() async {
  //   final editor = editorKey.currentState!;

  //   LoadingDialog dialog = LoadingDialog.instance
  //     ..show(
  //       context,
  //       configs: const ProImageEditorConfigs(),
  //     );

  //   try {
  //     final imageBytes = await editor.editorImage!.safeByteArray();
  //     if (!mounted) return;

  //     // final resultImage = await BackgroundRemover.instance.removeBg(
  //     //   imageBytes,
  //     //   threshold: 0.5,
  //     //   enhanceEdges: true,
  //     //   smoothMask: true,
  //     // );
  //     if (!mounted) return;

  //    // var resultBytes = await ImageConverter.instance.uiImageToImageBytes(
  //     //  resultImage,
  //     //  context: context,
  //    // );
  //     if (!mounted) return;

  //     await editor.updateBackgroundImage(EditorImage(byteArray: resultBytes));
  //   } catch (e) {
  //     debugPrint('Background removal failed: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Background removal failed: $e')),
  //       );
  //     }
  //   } finally {
  //     dialog.hide();
  //   }
  // }

  void _showApiKeyMissingDialog() {
    BotToast.showText(
      text:
          'Please enter an OpenAI API key in the AI Text Commands setup to use DALL-E for background generation.',
    );
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    if (_aiTextProvider == null && _currentAiMode != AiEditorMode.none) {
      return AiSetupDialog(
        onChanged: _setupAiTextProvider,
        enableGemini: true, // Allow Gemini for text commands
        enableChatGpt: true,
      );
    } else if (!isPreCached) {
      return const LoadingIndicator();
    }

    return ProImageEditor.asset(
      AppConstants.defaultImageAsset,
      key: editorKey,
      callbacks: _editorCallbacks,
      configs: _editorConfigs,
    );
  }

  List<ReactiveWidget> _buildBodyItems(
    ProImageEditorState editor,
    Stream<void> rebuildStream,
  ) {
    return [
      ReactiveWidget(
        stream: rebuildStream,
        builder: (_) {
          // Hide AI toolbars when layers are being transformed or sub-editors are open
          if (editor.isLayerBeingTransformed || editor.isSubEditorOpen) {
            return SizedBox.shrink(key: UniqueKey());
          }

          if (_currentAiMode == AiEditorMode.textCommands &&
              _aiTextProvider != null) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: max(
                  0,
                  MediaQuery.viewInsetsOf(context).bottom -
                      kBottomNavigationBarHeight,
                ),
              ),
              child: AiTextCommandsToolbar(
                isProcessingNotifier: _isProcessingNotifierText,
                alignTopNotifier: _alignTopNotifierText,
                generationModeNotifier: _generationModeNotifier,
                isImageGenerationSupported:
                    _aiTextProvider!.isImageGenerationSupported,
                inputCtrl: _inputCtrlText,
                inputFocus: _inputFocusText,
                onSend: _sendCommand,
              ),
            );
          } else if (_currentAiMode == AiEditorMode.replaceBackground) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: max(
                  0,
                  MediaQuery.viewInsetsOf(context).bottom -
                      kBottomNavigationBarHeight,
                ),
              ),
              child: AiReplaceBackgroundToolbar(
                alignTopNotifier: _alignTopNotifierReplace,
                isProcessingNotifier: _isProcessingNotifierReplace,
                inputCtrl: _inputCtrlReplace,
                inputFocus: _inputFocusReplace,
                onSend: _generateBackgroundImage,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ];
  }

  ReactiveWidget<Widget> _buildBottomNavigationBar(
    ProImageEditorState editor,
    Stream<void> rebuildStream,
    Key key,
  ) {
    return ReactiveWidget(
      key: key,
      // Assuming ReactiveWidget constructor takes 'editor' and 'stream' directly,
      // and a 'builder' callback which provides BuildContext.
      // This is a common pattern for reactive widgets that manage state and rebuilding.
      stream: rebuildStream,
      builder: (context) {
        return BottomAppBar(
          height: kBottomNavigationBarHeight,
          color: Theme.of(context).bottomAppBarTheme.color,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAiToolButton(
                  label: 'Ai commands',
                  icon: Icons.chat_bubble_outline,
                  mode: AiEditorMode.textCommands,
                ),
                _buildAiToolButton(
                  label: 'Rplave Bg',
                  icon: Icons.image_search,
                  mode: AiEditorMode.replaceBackground,
                ),
                // _buildAiToolButton(
                // label: 'Remove BG',
                // icon: Icons.cut,
                // mode: AiEditorMode.removeBackground,
                // onTap: _removeBackground,
                // ),
                const VerticalDivider(width: 20),
                _buildEditorToolButton(
                  label: 'Paint',
                  icon: Icons.edit,
                  onTap: editor.openPaintEditor,
                ),
                _buildEditorToolButton(
                  label: 'Text',
                  icon: Icons.text_fields,
                  onTap: editor.openTextEditor,
                ),
                _buildEditorToolButton(
                  label: 'Emoji',
                  icon: Icons.emoji_emotions,
                  onTap: editor.openEmojiEditor,
                ),
                _buildEditorToolButton(
                  label: 'Filter',
                  icon: Icons.filter_vintage,
                  onTap: editor.openFilterEditor,
                ),
                _buildEditorToolButton(
                  label: 'Tune',
                  icon: Icons.tune,
                  onTap: editor.openTuneEditor,
                ),
                _buildEditorToolButton(
                  label: 'Crop',
                  icon: Icons.crop,
                  onTap: editor.openCropRotateEditor,
                ),
                _buildEditorToolButton(
                  label: 'Blur',
                  icon: Icons.blur_on,
                  onTap: editor.openBlurEditor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiToolButton({
    required String label,
    required IconData icon,
    required AiEditorMode mode,
    VoidCallback? onTap,
  }) {
    bool isSelected = _currentAiMode == mode;
    return TextButton(
      onPressed: () {
        if (onTap != null) {
          onTap.call();
        }
        setState(() {
          _currentAiMode = isSelected ? AiEditorMode.none : mode;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0),
          Text(label, style: TextStyle(fontSize: 12.0)),
        ],
      ),
    );
  }

  Widget _buildEditorToolButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: () {
        setState(() {
          _currentAiMode =
              AiEditorMode.none; // Close AI tools when opening editor tools
        });
        onTap.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0),
          Text(label, style: TextStyle(fontSize: 12.0)),
        ],
      ),
    );
  }
}
