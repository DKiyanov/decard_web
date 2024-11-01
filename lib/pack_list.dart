import 'package:decard_web/web_spec/web_spec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:routemaster/routemaster.dart';

import 'common.dart';
import 'dk_expansion_tile.dart';

enum _SortMode {
  title,
  starsCount,
  publicationMoment
}

class WebPackList extends StatefulWidget {
  final List<Widget>? actions;

  final WebPackListManager packInfoManager;
  const WebPackList({required this.packInfoManager, this.actions, Key? key}) : super(key: key);

  @override
  State<WebPackList> createState() => _WebPackListState();
}

class _WebPackListState extends State<WebPackList> {
  bool _isStarting = true;

  WebPackListResult? _packListResult;

  final _selAuthorList = <String>[];
  final _selTagList    = <String>[];
  int? _selTargetAge;
  final _selTargetValueController = TextEditingController() ;
  final _selTitleController = TextEditingController() ;

  String _selTitle = '';

  final _scrollController = ScrollController();

  final _packGuidList = <MapEntry<String, List<WebPackInfo> >>[];

  var _sortMode = _SortMode.starsCount;

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
      if (_selTargetAge != null) {
        if (_selTargetAge! >= _packListResult!.targetAgeLow && _selTargetAge! <= _packListResult!.targetAgeHigh) {
          sendTargetAge = _selTargetAge;
        }
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

    if (_selTargetAge != null && _selTargetAge! < _packListResult!.targetAgeLow) {
      _selTargetAge = _packListResult!.targetAgeLow;
    }

    if (_selTargetAge != null && _selTargetAge! > _packListResult!.targetAgeHigh) {
      _selTargetAge = _packListResult!.targetAgeHigh;
    }

    if (_selTargetAge == null) {
      _selTargetValueController.clear();
    } else {
      _selTargetValueController.text = _selTargetAge.toString();
    }

    if (_isStarting) return;
    setState(() { });
  }

  void _sortPackList() {
    if (_sortMode == _SortMode.title) {
      _packGuidList.sort((a, b) => a.value.first.title.compareTo(b.value.first.title));
    }

    if (_sortMode == _SortMode.starsCount) {
      _packGuidList.sort((a, b) => b.value.first.starsCount.compareTo(a.value.first.starsCount));
    }

    if (_sortMode == _SortMode.publicationMoment) {
      _packGuidList.sort((a, b) => b.value.first.publicationMoment!.compareTo(a.value.first.publicationMoment!));
    }
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
            child: _getFilterPanel(),
          ),
        );
      }

      return Scaffold(
        drawer: drawer,
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtPackFileList),
          actions: widget.actions,
        ),
        body: _getBody(isMobile, drawerPanelWidth),
      );
    });
  }

  Widget _getBody(bool isMobile, double? width) {
    if (isMobile) {
      return _getPackList();
    }

    return Container(
      color: Colors.grey,
      child: MultiSplitView(
        initialAreas: [Area(weight: 0.25)],
        children: [
          _getFilterPanel(width),
          _getPackList(),
        ],
      ),
    );
  }

  Widget _getPackList() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 4, bottom: 2),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.white,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5))
        ),
        child: ListView(
            children: _packGuidList.map((guidPack) {
              final packInfo = guidPack.value.first;

              if (guidPack.value.length == 1) {
                return packInfo.getListTile(context,
                  onTap: (context) {
                    _routePushPackId(context, packInfo.packId);
                  }
                );
              }

              final children = <Widget>[];
              for (var i = 1; i < guidPack.value.length; i++) {
                final packInfo = guidPack.value[i];
                children.add(packInfo.getListTile(context,
                  onTap: (context) {
                    _routePushPackId(context, packInfo.packId);
                  }
                ));
              }

              return DkExpansionTile(
                title    : packInfo.getTitle(context),
                subtitle : packInfo.getSubtitle(context),
                onTap    : (){
                  _routePushPackId(context, packInfo.packId);
                },
                children : children,
              );
            }).toList()
        ),
      ),
    );
  }

  void _routePushPackId(BuildContext context, int packId) {
    final path = '/pack/$packId';
    if (kIsWeb) {
      webOpenNewTab(path);
    } else {
      Routemaster.of(context).push(path);
    }
  }

  Widget _getFilterPanel([double? width]) {
    return Scrollbar(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 2),
        child: ListView(
          controller: _scrollController,
          children: [
            filterWrapperContainer(
              DkExpansionTile(
                title: const Text('Сортировка'),
                borderColor: Colors.transparent,
                initiallyExpanded: true,
                controlAffinity: ListTileControlAffinity.leading,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<_SortMode>(
                        value: _sortMode,
                        isExpanded: true,
                        items: _SortMode.values.map((sortMode) => DropdownMenuItem<_SortMode>(
                          value: sortMode,
                          child: Text(sortMode.name)
                        )).toList(),
                        onChanged: (_SortMode? value){
                          if (value == null) return;
                          _sortMode = value;
                          _sortPackList();
                          setState(() {});
                        }
                    ),
                  )
                ],
              ),
            ),

            Container(height: 8),

            filterWrapperContainer(
              DkExpansionTile(
                title: const Text('Название'),
                borderColor: Colors.transparent,
                initiallyExpanded: true,
                controlAffinity: ListTileControlAffinity.leading,
                trailing: InkWell(
                    child: const Icon(Icons.clear),
                    onTap: () {
                      _selTitleController.clear();
                      _refresh();
                    }
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: TextField(
                      controller: _selTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по наименованию',
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
            ),

            Container(height: 8),

            filterWrapperContainer(
              DkExpansionTile(
                title: const Text('Возраст'),
                borderColor: Colors.transparent,
                initiallyExpanded: true,
                controlAffinity: ListTileControlAffinity.leading,
                trailing: InkWell(
                    child: const Icon(Icons.clear),
                    onTap: () {
                      _selTargetValueController.clear();
                      _selTargetAge = null;
                      _refresh();
                    }
                ),
                children: [
                  SizedBox( width: 60,
                    child: TextField(
                      textAlign: TextAlign.center,
                      onSubmitted: (value) {
                        final newValue = int.tryParse(value);
                        if (newValue != _selTargetAge) {
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
                          value: _selTargetAge?.toDouble()??0,
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
            ),

            Container(height: 8),

            filterWrapperContainer(
              _getCheckBoxListFilter(title: 'Автор', valueList: _packListResult!.authorList, selValueList: _selAuthorList)
            ),

            Container(height: 8),

            filterWrapperContainer(
              _getCheckBoxListFilter(title: 'Теги', valueList: _packListResult!.tagList, selValueList: _selTagList)
            ),

          ],
        ),
      ),
    );
  }

  Widget filterWrapperContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.white,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(5))
      ),

      child: child,
    );
  }

  Widget _getCheckBoxListFilter ({
    required String title,
    required List<MapEntry<String, int>> valueList,
    required List<String> selValueList,
  }) {

    final scrollController = ScrollController();

    return DkExpansionTile(
      title: Text(title),
      borderColor: Colors.transparent,
      initiallyExpanded: true,
      controlAffinity: ListTileControlAffinity.leading,
      trailing: InkWell(
          child: const Icon(Icons.clear),
          onTap: () {
            selValueList.clear();
            _refresh();
          }
      ),
      children: [
        LimitedBox(
          maxHeight: 200,
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,

            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SingleChildScrollView(
                controller: scrollController,
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
            ),
          ),
        )
      ],
    );
  }

}
