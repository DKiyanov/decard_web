import 'package:decard_web/app_state.dart';
import 'package:decard_web/simple_menu.dart';
import 'package:flutter/material.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:routemaster/routemaster.dart';

import 'common.dart';
import 'dk_expansion_tile.dart';

class WebPackList extends StatefulWidget {
  final WebPackListManager packInfoManager;
  const WebPackList({required this.packInfoManager, Key? key}) : super(key: key);

  @override
  State<WebPackList> createState() => _WebPackListState();
}

class _WebPackListState extends State<WebPackList> {
  bool _isStarting = true;

  WebPackListResult? _packListResult;

  final _selAuthorList = <String>[];
  final _selTagList    = <String>[];
  int _selTargetAge = 0;
  final _selTargetValueController = TextEditingController() ;
  final _selTitleController = TextEditingController() ;

  String _selTitle = '';

  static const Color _filterPanelColor = Colors.grey;

  final _scrollController = ScrollController();

  final _packGuidList = <MapEntry<String, List<WebPackInfo> >>[];

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
    _packGuidList.clear();

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

    final packGuidMap = <String, List<WebPackInfo> >{};
    for (var pack in _packListResult!.packInfoList) {
      final packList = packGuidMap[pack.guid];
      if (packList == null) {
        packGuidMap[pack.guid] = [pack];
        continue;
      }
      packList.add(pack);
    }

    _packGuidList.addAll(packGuidMap.entries);

    for (var packGuid in _packGuidList) {
      final packList = packGuid.value;
      if (packList.length == 1) continue;
      packList.sort((a, b) => b.version.compareTo(a.version));
    }

    _sortPackList();

    if (_selTargetAge < _packListResult!.targetAgeLow) {
      _selTargetAge = _packListResult!.targetAgeLow;
    }

    if (_selTargetAge > _packListResult!.targetAgeHigh) {
      _selTargetAge = _packListResult!.targetAgeHigh;
    }

    if (_isStarting) return;
    setState(() { });
  }

  void _sortPackList() {
    _packGuidList.sort((a, b) => a.value.first.title.compareTo(b.value.first.title));
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

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      var drawerPanelWidth = constraints.maxWidth / 3;
      if (drawerPanelWidth > 500) {
        drawerPanelWidth = 500;
      }

      Drawer? drawer;

      if (isMobile) {
        drawer = Drawer(
          child: Container(
            child: _getFilerPanel(),
          ),
        );
      }

      return Scaffold(
        drawer: drawer,
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
        body: _getBody(isMobile, drawerPanelWidth),
      );
    });
  }

  Widget _getBody(bool isMobile, double? width) {
    if (isMobile) {
      return _getPackList();
    }

    return Row(children: [
      _getFilerPanel(width),
      Expanded(child: _getPackList())
    ]);
  }

  Widget _getPackList() {
    return ListView(
        children: _packGuidList.map((guidPack) {
          final packInfo = guidPack.value.first;

          if (guidPack.value.length == 1) {
            return ListTile(
              title: Text(packInfo.title),
              subtitle: Text(packInfo.tags),
              onTap: (){
                Routemaster.of(context).push('/pack/${packInfo.packId}');
              },
            );
          }

          final children = <Widget>[];
          for (var i = 1; i < guidPack.value.length; i++) {
            final packInfo = guidPack.value[i];
            children.add(ListTile(
              title: Text(packInfo.title),
              subtitle: Text(packInfo.tags),
              onTap: (){
                Routemaster.of(context).push('/pack/${packInfo.packId}');
              },
            ));
          }

          return DkExpansionTile(
            title: Text(packInfo.title),
            subtitle: Text(packInfo.tags),
            onTap: (){
              Routemaster.of(context).push('/pack/${packInfo.packId}');
            },
            children: children,
          );
        }).toList()
    );
  }

  Widget _getFilerPanel([double? width]) {
    return Container(
      width: width,
      color: _filterPanelColor,
//      padding: const EdgeInsets.only(left: 8, right: 16),

      child: Scrollbar(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 16),
          child: ListView(
            controller: _scrollController,
            children: [
              ExpansionTile(
                title: const Text('Название'),
                initiallyExpanded: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: TextField(
                      controller: _selTitleController,
                      decoration: InputDecoration(
                        fillColor: Colors.white30,
                        filled: true,
                        labelText: 'Фильтр по наименованию',
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
                      decoration: const InputDecoration(
                        fillColor: Colors.white30,
                        filled: true,
                      ),
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
                      Container(width: 16),

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
          ),
        ),
      ),
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
