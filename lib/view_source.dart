import 'package:decard_web/media_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'card_model.dart';

class ViewContent extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, CardData card, String content, String title) async {
    return Navigator.push(context, MaterialPageRoute( builder: (_) => ViewContent(card: card, content: content, title: title)));
  }

  final CardData card;
  final String content;
  final String title;
  const ViewContent({required this.card, required this.content, required this.title, Key? key}) : super(key: key);

  @override
  State<ViewContent> createState() => _ViewContentState();
}

class _ViewContentState extends State<ViewContent> {
  late String contentExt;
  late String content;

  @override
  void initState() {
    super.initState();

    contentExt = FileExt.getContentExt(widget.content);

    if (contentExt.isEmpty) {
      content = widget.content;
      return;
    }

    final str = widget.content.substring(contentExt.length + 1);

    if (contentExt == FileExt.contentText) {
      content = str;
      return;
    }

    if (contentExt == FileExt.contentMarkdown) {
      content = FileExt.prepareMarkdown(widget.card, str);
      return;
    }

    if (contentExt == FileExt.contentHtml) {
      content = FileExt.prepareHtml(widget.card, str);
      return;
    }

    content = str;
  }

  @override
  Widget build(BuildContext context) {
    Widget? body;

    if (contentExt == FileExt.contentMarkdown) {
      body = MarkdownBody(data: content);
    }

    if (contentExt == FileExt.contentHtml) {
      body = htmlView(content, widget.card.pacInfo.sourceDir);
    }

    if (FileExt.imageExtList.contains(contentExt)) {
      final fileUrl = getFileUrl(content);
      body = imageFromUrl(fileUrl);
    }

    if (FileExt.audioExtList.contains(contentExt)) {
      final fileUrl = getFileUrl(content);
      body = audioPanelFromUrl(fileUrl, ValueKey(fileUrl));
    }

    if (body == null && content.isNotEmpty) {
      body = Center(child: Text(content));
    }

    body ??= Container();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: body
    );
  }

  String getFileUrl(String fileName) {
    return widget.card.dbSource.getFileUrl(widget.card.pacInfo.jsonFileID, fileName);
  }
}
