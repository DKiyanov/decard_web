import 'package:flutter/material.dart';
import 'common.dart';

class ChildList extends StatefulWidget {
  final List<Widget>? actions;
  const ChildList({this.actions, Key? key}) : super(key: key);

  @override
  State<ChildList> createState() => _ChildListState();
}

class _ChildListState extends State<ChildList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtChildList ),
        actions: widget.actions,
      ),
      body: const Center(child: Text('Дети')),
    );
  }
}
