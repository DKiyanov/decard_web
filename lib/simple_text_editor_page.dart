import 'package:flutter/material.dart';
import 'pack_editor/pack_file_source_editor.dart';

class SimpleTextEditor extends StatefulWidget {
  final String filename;
  final String content;
  final void Function(String fileName, String? jsonStr) resultCallback;

  const SimpleTextEditor({
    required this.filename,
    required this.content,
    required this.resultCallback,

    Key? key
  }) : super(key: key);

  @override
  State<SimpleTextEditor> createState() => _SimpleTextEditorState();
}

class _SimpleTextEditorState extends State<SimpleTextEditor> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.content;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filename),
        leading: InkWell(
          onTap: _returnResult,
          child: const Icon(Icons.arrow_back_outlined),
        ),
        actions: [
          IconButton(
              onPressed: () {
                widget.resultCallback.call(widget.filename, null);
              },
              icon: Icon(Icons.cancel_outlined, color: Colors.red.shade900)
          )
        ],
      ),

      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
          ),
        ),
      ],
    );
  }

  Future<void> _returnResult() async {
    SourceFileEditor.returnResult(widget.filename, _textController.text, context, widget.resultCallback);
  }
}
