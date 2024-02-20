import 'package:flutter/material.dart';

import '../card_model.dart';
import '../media_widgets.dart';
import '../parse_pack_info.dart';
import '../text_constructor/editor/text_constructor_editor_page.dart';
import 'package:path/path.dart' as path_util;

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

    return Container();
  }

  Widget _textConstructor(String jsonStr) {
    return TextConstructorEditorPage(
      jsonStr        : jsonStr,
      filename       : widget.filename,
      resultCallback : (saveFilename, jsonStr) async {
        if (jsonStr != null) {
          final path = path_util.join(widget.rootPath, saveFilename);
          final url = await addTextFileToPack(widget.packId, path, jsonStr);
          if (isNew) {
            widget.onAddNewFile.call(saveFilename, url);
          }
        }

        widget.tryExitCallback.call();
      },
      onPrepareFileUrl: widget.onPrepareFileUrl,
    );
  }
}
