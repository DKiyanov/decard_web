import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

import 'common.dart';

class OwnPackList extends StatefulWidget {
  const OwnPackList({Key? key}) : super(key: key);

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
        actions: [
          ElevatedButton(
              onPressed: () {
                Routemaster.of(context).replace('/view_pack_list');
              },
              child: Text(TextConst.txtShowcase)
          ),
          ElevatedButton(
              onPressed: () {
                Routemaster.of(context).replace('/child_list');
              },
              child: Text(TextConst.txtChildList)
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
          onPressed: () {

          },
          child: const Icon(Icons.add),
      ),

      body: Container(),
    );
  }
}
