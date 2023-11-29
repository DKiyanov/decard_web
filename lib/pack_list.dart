import 'package:decard_web/app_state.dart';
import 'package:decard_web/simple_menu.dart';
import 'package:flutter/material.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:routemaster/routemaster.dart';

import 'common.dart';

class PackList extends StatefulWidget {
  final PackListManager packInfoManager;
  const PackList({required this.packInfoManager, Key? key}) : super(key: key);

  @override
  State<PackList> createState() => _PackListState();
}

class _PackListState extends State<PackList> {
  bool _isStarting = true;
  late List<PackInfo> packInfoList;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await widget.packInfoManager.init();
    packInfoList =  await widget.packInfoManager.getPackList();

    setState(() {
      _isStarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtLoading),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtPackFileList),
          actions: [
            popupMenu(icon: const Icon(Icons.menu), menuItemList: [
              if (!appState.serverConnect.isLoggedIn) ...[
                SimpleMenuItem(
                    child: Text(TextConst.txtEntry),
                    onPress: () {
                      Routemaster.of(context).push('/login', queryParameters: {'redirectTo': '/'});
                    }
                ),
              ],

              if (appState.serverConnect.isLoggedIn) ...[
                SimpleMenuItem(
                    child: Text(TextConst.txtUploadFile),
                    onPress: () {
                      Routemaster.of(context).push('/upload_file');
                    }
                ),
              ]

            ]),
          ],
        ),
        body: ListView(
          children: packInfoList.map((packInfo) => ListTile(
            title: Text(packInfo.title),
            onTap: (){
              Routemaster.of(context).push('/pack/${packInfo.packId}');
            },
          )).toList()
        ),

    );
  }
}
