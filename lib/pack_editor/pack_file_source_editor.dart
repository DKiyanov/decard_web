import 'package:flutter/material.dart';

import '../card_model.dart';
import '../media_widgets.dart';
import '../parse_pack_info.dart';
import '../simple_dialog.dart';
import '../simple_text_editor_page.dart';
import 'package:path/path.dart' as path_util;

import '../text_constructor_editor/text_constructor_editor_page.dart';

class SourceFileEditor extends StatefulWidget {
  final int packId;
  final String rootPath;
  final String filename;
  final String url;
  final String? Function(String fileName) onPrepareFileUrl;
  final VoidCallback tryExitCallback;
  final void Function(String filename, String url) onAddNewFile;

  const SourceFileEditor({
    required this.packId,
    required this.rootPath,
    required this.filename,
    required this.url,
    required this.onPrepareFileUrl,
    required this.tryExitCallback,
    required this.onAddNewFile,

    Key? key
  }) : super(key: key);

  @override
  State<SourceFileEditor> createState() => _SourceFileEditorState();

  static Future<void> returnResult(String inFileName, String result, BuildContext context, void Function(String fileName, String? jsonStr) resultCallback) async {
    String filename;

    final baseName = path_util.basenameWithoutExtension(inFileName);
    if (baseName == 'new') {
      if (result.isEmpty) {
        resultCallback.call(inFileName, null);
        return;
      }

      String newFilename = '';

      final dlgResult = await simpleDialog(
          context: context,
          title: const Text('Введите имя для нового файла'),
          content: StatefulBuilder(builder: (context, setState) {
            return TextField(
              onChanged: (value){
                newFilename = value;
              },
            );
          })
      )??false;
      if (!dlgResult) return;

      filename = '${path_util.basenameWithoutExtension(newFilename)}${path_util.extension(inFileName)}';
      final fileDir = path_util.dirname(inFileName);
      if (fileDir.isNotEmpty && fileDir != '.') {
        filename = path_util.join(fileDir, filename);
      }
    } else {
      filename = inFileName;
    }

    resultCallback.call(filename, result);
  }
}

class _SourceFileEditorState extends State<SourceFileEditor> {
  bool _isStarting = true;

  late String fileExt;
  late bool isNew;
  late String content;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    fileExt = FileExt.getFileExt(widget.filename);
    isNew = widget.url.isEmpty;

    if (isNew){
      content = "";
    } else {
      content = (await getTextFromUrl(widget.url))??"";
    }

    setState(() {
      _isStarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) return const Center(child: CircularProgressIndicator());

    if (fileExt == FileExt.contentTextConstructor) {
      return _textConstructor(content);
    }
    if (fileExt == FileExt.contentTxt) {
      return _simpleTextEditor(content);
    }

    return Container();
  }

  Widget _textConstructor(String jsonStr) {
    return TextConstructorEditorPage(
      jsonStr        : jsonStr,
      filename       : widget.filename,
      resultCallback : (saveFilename, newJsonStr) async {
        if (newJsonStr != null) {
          final path = path_util.join(widget.rootPath, saveFilename);
          final url = await addTextFileToPack(widget.packId, path, newJsonStr);
          if (isNew) {
            widget.onAddNewFile.call(saveFilename, url);
          }
        }

        widget.tryExitCallback.call();
      },
      onPrepareFileUrl: widget.onPrepareFileUrl,
    );
  }

  Widget _simpleTextEditor(String content) {
    return SimpleTextEditor(
      content        : content,
      filename       : widget.filename,
      resultCallback : (saveFilename, newContent) async {
        if (newContent != null) {
          final path = path_util.join(widget.rootPath, saveFilename);
          final url = await addTextFileToPack(widget.packId, path, newContent);
          if (isNew) {
            widget.onAddNewFile.call(saveFilename, url);
          }
        }

        widget.tryExitCallback.call();
      },
    );
  }
}
