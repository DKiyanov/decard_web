import 'dart:convert';

import 'package:flutter/material.dart';

import '../text_constructor.dart';
import '../word_panel_model.dart';

class TextConstructorPreview extends StatefulWidget {
  final String jsonStr;
  final String? Function(String fileName) onPrepareFileUrl;
  const TextConstructorPreview({
    required this.jsonStr,
    required this.onPrepareFileUrl,

    Key? key
  }) : super(key: key);

  @override
  State<TextConstructorPreview> createState() => _TextConstructorPreviewState();
}

class _TextConstructorPreviewState extends State<TextConstructorPreview> {
  late Map<String, dynamic> _jsonMap;
  late TextConstructorData _textConstructorData;

  @override
  void initState() {
    super.initState();

    _jsonMap = jsonDecode(widget.jsonStr);
    _textConstructorData = TextConstructorData.fromMap(_jsonMap);
  }

  @override
  Widget build(BuildContext context) {
    return TextConstructorWidget(
      textConstructor: _textConstructorData,
      viewOnly: true,
      onPrepareFileUrl: widget.onPrepareFileUrl,
    );
  }
}
