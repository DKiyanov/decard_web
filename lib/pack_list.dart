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

  PackListResult? _packListResult;

  final _selAuthorList = <String>[];
  final _selTagList    = <String>[];
  int _selTargetAge = 0;
  final _selTargetValueController = TextEditingController() ;
  final _selTitleController = TextEditingController() ;

  String _selTitle = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await widget.packInfoManager.init();
    await _refresh();

    setState(() {
      _isStarting = false;
    });
  }

  @override
  void dispose() {
    _selTargetValueController.dispose();
    _selTitleController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    int? sendTargetAge;

    if (_packListResult != null) {
      if (_selTargetAge >= _packListResult!.targetAgeLow && _selTargetAge <= _packListResult!.targetAgeHigh) {
        sendTargetAge = _selTargetAge;
      }
    }

    _packListResult = await widget.packInfoManager.getPackList(
      title     : _selTitle,
      authorList: _selAuthorList,
      tagList   : _selTagList,
      targetAge : sendTargetAge,
    );

    if (_selTargetAge < _packListResult!.targetAgeLow) {
      _selTargetAge = _packListResult!.targetAgeLow;
    }

    if (_selTargetAge > _packListResult!.targetAgeHigh) {
      _selTargetAge = _packListResult!.targetAgeHigh;
    }

    if (_isStarting) return;
    setState(() { });
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
        body: _getBody(),
    );
  }

  Widget _getBody() {
    return Row(children: [
      Flexible(child: _getFilerPanel()),
      Flexible(child: _getPackList())
    ]);
  }

  Widget _getPackList() {
    return ListView(
        children: _packListResult!.packInfoList.map((packInfo) => ListTile(
          title: Text(packInfo.title),
          subtitle: Text(packInfo.tags),
          onTap: (){
            Routemaster.of(context).push('/pack/${packInfo.packId}');
          },
        )).toList()
    );
  }

  Widget _getFilerPanel() {
    return ListView(
      children: [
        ExpansionTile(
          title: const Text('Название'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _selTitleController,
                decoration: InputDecoration(
                  suffixIcon: InkWell(
                    child: const Icon(Icons.clear),
                    onTap: () {
                      _selTitleController.text = '';
                    }
                  )
                ),
                onSubmitted: (value) {
                  if (value != _selTitle) {
                    _selTitle = value;
                    _refresh();
                  }
                },
              ),
            )
          ],
        ),

        ExpansionTile(
          title: const Text('Возраст'),
          initiallyExpanded: true,
          children: [
            SizedBox( width: 60,
              child: TextField(
                textAlign: TextAlign.center,
                onSubmitted: (value) {
                  final newValue = int.tryParse(value);
                  if (newValue != null &&  newValue != _selTargetAge) {
                    _selTargetAge = newValue;
                    _refresh();
                  }
                },
                keyboardType: TextInputType.number,
                controller: _selTargetValueController,
              ),
            ),

            Row(
              children: [
                Container(width: 10),

                Text(_packListResult!.targetAgeLow.toString()),

                Expanded(
                  child: Slider(
                    value: _selTargetAge.toDouble(),
                    min: _packListResult!.targetAgeLow.toDouble(),
                    max: _packListResult!.targetAgeHigh.toDouble(),
                    onChanged: (value) {
                      _selTargetAge = value.round();
                      _selTargetValueController.text = _selTargetAge.toString();
                      _refresh();
                    },
                  ),
                ),

                Text(_packListResult!.targetAgeHigh.toString()),
              ],
            )
          ],
        ),

        _getCheckBoxListFilter(title: 'Автор', valueList: _packListResult!.authorList, selValueList: _selAuthorList),
        _getCheckBoxListFilter(title: 'Теги', valueList: _packListResult!.tagList, selValueList: _selTagList),
      ],
    );
  }

  Widget _getCheckBoxListFilter ({
    required String title,
    required List<MapEntry<String, int>> valueList,
    required List<String> selValueList,
  }) {
    return ExpansionTile(
      title: Text(title),
      initiallyExpanded: true,
      children: [
        LimitedBox(
          maxHeight: 200,
          child: SingleChildScrollView(
            child: Column(
                children: valueList.map((value) {
                  return Row(children: [

                    Checkbox(
                        value: selValueList.contains(value.key),
                        onChanged: (bool? newMarkValue) {
                          if (newMarkValue == null) return;
                          if (!newMarkValue) {
                            selValueList.remove(value.key);
                          } else {
                            selValueList.add(value.key);
                          }
                          _refresh();
                        }
                    ),

                    Text(value.key),

                    Expanded(child: Text('${value.value}', textAlign: TextAlign.right))
                  ]);
                }).toList()
            ),
          ),
        )
      ],
    );
  }

}
