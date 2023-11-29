import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'context_extension.dart';
import 'html_widget_web.dart';
import 'media_widgets.dart';
import 'text_constructor/text_constructor.dart';
import 'text_constructor/word_panel_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'card_model.dart';
import 'common.dart';
import 'decardj.dart';
import 'html_widget.dart';

class CardWidget extends StatefulWidget {
  final CardData card;

  const CardWidget({required this.card, Key? key}) : super(key: key);

  @override
  State<CardWidget> createState() => CardWidgetState();
}

class CardWidgetState extends State<CardWidget> {


  @override
  Widget build(BuildContext context) {
    final widgetList = <Widget>[];

    if (widget.card.body.questionData.image != null) {
      final fileUrl = getFileUrl(widget.card.body.questionData.image!);
      final maxHeight = context.screenSize.height * widget.card.style.imageMaxHeight / 100;

      widgetList.add(
          LimitedBox(maxHeight: maxHeight, child: imageFromUrl(fileUrl))
      );
    }

    if (widget.card.body.questionData.audio != null) {
      final fileUrl = getFileUrl(widget.card.body.questionData.audio!);
      widgetList.add(
          audioPanelFromUrl(fileUrl, ValueKey(widget.card.head.cardKey)),
      );
    }

    if (widget.card.body.questionData.text != null) {
      widgetList.add(
        AutoSizeText(
          widget.card.body.questionData.text!,
          style: TextStyle(fontSize: context.textTheme.headlineMedium!.fontSize),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (widget.card.body.questionData.html != null) {
      widgetList.add(
        htmlViewer(widget.card.body.questionData.html!),
      );
    }

    if (widget.card.body.questionData.markdown != null) {
      widgetList.add(
        markdownViewer(widget.card.body.questionData.markdown!)
      );
    }

    if (widget.card.body.questionData.textConstructor != null) {
      widgetList.add(
        textConstructor(widget.card.body.questionData.textConstructor!)
      );
    }

    widgetList.add(
      Container(
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              color: Colors.lightGreenAccent
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: _answerLine(TextConst.txtAnswerIs),
          )
      )
    );

    return Column(children: [
      Expanded( child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child:  Stack(
          children: [
            ListView(
              children: widgetList,
            )
          ],
        )
      )),

    ]);
  }

  Widget _answerLine(String label){
    final answerList = <Widget>[];
    answerList.add(Text('$label '));

    for (int i = 0; i < widget.card.body.answerList.length; i++){
      final answerValue = widget.card.body.answerList[i];
      answerList.add(_valueWidget(answerValue));

      if ((widget.card.body.answerList.length > 1) && ((i + 1) < widget.card.body.answerList.length)){
        answerList.add(const Text("; "));
      }
    }

    return Row(children: answerList);
  }

  Widget _valueWidget(String str){
    if (str.isEmpty) return Container();
    if (str.indexOf(DjfCardStyle.buttonImagePrefix) == 0) {
      final imagePath = str.substring(DjfCardStyle.buttonImagePrefix.length);
      final fileUrl = getFileUrl(imagePath);

      var maxWidth  = double.infinity;
      var maxHeight = double.infinity;

      if (widget.card.style.buttonImageWidth > 0) {
        maxWidth = widget.card.style.buttonImageWidth.toDouble();
      }

      if (widget.card.style.buttonImageHeight > 0) {
        maxHeight = widget.card.style.buttonImageHeight.toDouble();
      }

      return LimitedBox(
          maxWidth  : maxWidth,
          maxHeight : maxHeight,
          child     : imageFromUrl(fileUrl)
      );
    }

    // Serif - in this font, the letters "I" and "l" look different, it is important
    return Text(str, style: const TextStyle(fontFamily: 'Serif'));
  }

  Widget htmlViewer(String html) {
    final newHtml = FileExt.prepareHtml(widget.card, html);
    if (kIsWeb) {
      return const HtmlViewWidgetWeb();
    }
    return HtmlViewWidget(html: newHtml, filesDir: widget.card.pacInfo.sourceFileID);
  }

  Widget markdownViewer(String markdown) {
    final newMarkdown = FileExt.prepareMarkdown(widget.card, markdown);
    return MarkdownBody(data: newMarkdown);
  }

  Widget textConstructor(String jsonStr) {
    final textConstructor = TextConstructorData.fromMap(jsonDecode(jsonStr));

    return TextConstructorWidget(
        textConstructor   : textConstructor,
        onPrepareFileUrl : getFileUrl,
        randomPercent     : 0,
    );
  }

  String getFileUrl(String fileName) {
    return widget.card.dbSource.getFileUrl(widget.card.pacInfo.jsonFileID, fileName);
  }
}




