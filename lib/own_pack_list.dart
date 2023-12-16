import 'package:decard_web/simple_menu.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
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
        leading: popupMenu(icon: const Icon(Icons.menu), menuItemList: [
          SimpleMenuItem(
              child: const Text('Создать новый пакет'),
              onPress: () {
                Routemaster.of(context).push('/pack_editor');
              }
          )
        ]),
        actions: widget.actions
      ),
      body: const Center(child: Text('Пожитки')),
    );
  }
}
