import 'package:decard_web/media_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../card_model.dart';
import '../text_constructor/editor/text_constructor_preview_page.dart';

class PackFileSourcePreview extends StatefulWidget {
  final String fileName;
  final String url;

  const PackFileSourcePreview({required this.fileName, required this.url, Key? key}) : super(key: key);

  @override
  State<PackFileSourcePreview> createState() => _PackFileSourcePreviewState();
}

class _PackFileSourcePreviewState extends State<PackFileSourcePreview> {
  bool _isStarting = true;
  
  String fileExt = "";
  String content = "";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    fileExt = FileExt.getFileExt(widget.fileName);
    content = "";
    
    if (FileExt.txtExtList.contains(fileExt)) {
      content = (await getTextFromUrl(widget.url))??"";
    }
    
    setState(() {
      _isStarting = false;
    });    
  }

  @override
  void didUpdateWidget(covariant PackFileSourcePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName == widget.fileName) return;
    _isStarting = true;
    _starting();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) return const Center(child: CircularProgressIndicator());

    if (fileExt == FileExt.contentTextConstructor) {
      return TextConstructorPreview(jsonStr: content);
    }

    if (fileExt == FileExt.contentMarkdown) {
      return MarkdownBody(data: content);
    }

    if (fileExt == FileExt.contentHtml) {
      return htmlView(content);
    }

    if (FileExt.imageExtList.contains(fileExt)) {
      return imageFromUrl(widget.url);
    }

    if (FileExt.audioExtList.contains(fileExt)) {
      return audioPanelFromUrl(widget.url , ValueKey(widget.url));
    }

    if (content.isNotEmpty) {
      return Text(content);
    }

    return Container();
  }

}
