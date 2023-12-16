import 'package:flutter/material.dart';
import 'common.dart';

class OwnPackList extends StatefulWidget {
  final List<Widget>? actions;
  const OwnPackList({this.actions, Key? key}) : super(key: key);

  @override
  State<OwnPackList> createState() => _OwnPackListState();
}

class _OwnPackListState extends State<OwnPackList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtOwnPackList),
        actions: widget.actions
      ),
      body: const Center(child: Text('Пожитки')),
    );
  }
}
