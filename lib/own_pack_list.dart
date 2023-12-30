import 'package:decard_web/simple_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'common.dart';
import 'pack_upload_file.dart';

class OwnPackList extends StatefulWidget {
  final List<Widget>? actions;
  const OwnPackList({this.actions, Key? key}) : super(key: key);

  @override
  State<OwnPackList> createState() => _OwnPackListState();
}

class _OwnPackListState extends State<OwnPackList> {
  bool _uploadPanelVisible = false;

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
          ),

          if (kIsWeb) ...[
            SimpleMenuItem(
                child: const Text('Загрузить пакет'),
                onPress: () {
                  setState(() {
                    _uploadPanelVisible = true;
                  });
                }
            ),
          ],
        ]),
        actions: widget.actions
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(children: [
      Expanded(child: _mainPanel()),

      if (_uploadPanelVisible) ...[
        Expanded(child: _uploadPanel()),
      ],
    ]);
  }

  Widget _mainPanel() {
    return const Center(child: Text('Пожитки'));
  }

  Widget _uploadPanel() {
    return PackUploadFile(
      onFileUpload: (filePath, url) {
        // TODO add uploaded files to own file list above
      },

      onClearFileUploadList: () {
        _uploadPanelVisible = false;
        setState(() {});
      },

    );
  }
}
