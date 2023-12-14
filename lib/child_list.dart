import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

import 'common.dart';

class ChildList extends StatefulWidget {
  const ChildList({Key? key}) : super(key: key);

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
        actions: [
          ElevatedButton(
              onPressed: () {
                Routemaster.of(context).replace('/view_pack_list');
              },
              child: Text(TextConst.txtShowcase)
          ),
          ElevatedButton(
              onPressed: () {
                Routemaster.of(context).replace('/own_pack_list');
              },
              child: Text(TextConst.txtOwnPackList)
          ),
        ],
      ),
      body: Container(),
    );
  }
}
