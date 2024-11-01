import 'package:decard_web/app_state.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/regulator_editor/regulator_desc_json.dart';
import 'package:decard_web/web_child.dart';
import 'package:flutter/material.dart';

import '../common.dart';
import '../decardj.dart';
import '../pack_editor/pack_widgets.dart';
import '../regulator.dart';
import 'regulator_cardset_widget.dart';

class RegulatorCardSetPage extends StatefulWidget {
  final String childID;
  final String packId;
  const RegulatorCardSetPage({required this.childID, required this.packId, Key? key}) : super(key: key);

  @override
  State<RegulatorCardSetPage> createState() => _RegulatorCardSetPageState();
}

class _RegulatorCardSetPageState extends State<RegulatorCardSetPage> {
  bool _isStarting = true;

  late WebChild _child;
  late Map<String, dynamic> _regulatorJson;
  late Map<String, FieldDesc> _descMap;

  final String _rootPath = '';

  final _scrollController = ScrollController();

  bool _changed = false;

  late int _jsonFileID;
  late String _packTitle;
  late String _packFileGuid;
  late int    _packFileVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    if (!_isStarting) return;

    _child = appState.childManager!.childList.firstWhere((child) => child.childID == widget.childID);
    _regulatorJson =  _child.regulator.toJson();

    _descMap = loadDescFromMap(regulatorDescJson);

    final packId = int.parse(widget.packId);

    _jsonFileID = (await loadWebPackEx(dbSource: appState.dbSource, packId: packId))!;

    final packInfoData = (await appState.dbSource.tabJsonFile.getRow(jsonFileID: _jsonFileID))!;
    _packTitle       = packInfoData[DjfFile.title]!;
    _packFileGuid    = packInfoData[DjfFile.guid];
    _packFileVersion = packInfoData[DjfFile.version];

    setState(() {
      _isStarting = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    return PopScope(
      onPopInvoked: (didPop) async {
        if (_changed) _save();
      },

      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Настройка пакета "$_packTitle" \nдля ${_child.childName}', textAlign: TextAlign.center),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    return JsonOwner(
      json: _regulatorJson,
      onDataChanged: () {
        _changed = true;
      },

      child: SingleChildScrollView(
        controller: _scrollController,
        child: JsonObjectArray(
          json: _regulatorJson,
          path: _rootPath,
          fieldName: DrfRegulator.setList,
          fieldDesc: _descMap[DrfRegulator.setList]!,
          objectWidgetCreator: _getCardSetWidget,
          onFilter: (object) {
            final setMap = object as Map<String, dynamic>;
            final fileGuid    = setMap[DrfCardSet.fileGUID] as String;
            final fileVersion = setMap[DrfCardSet.version]  as int;
            return fileGuid == _packFileGuid && fileVersion == _packFileVersion;
          },
          onNewRowObjectInit: (object) {
            final setMap = object as Map<String, dynamic>;
            setMap[DrfCardSet.fileGUID] = _packFileGuid;
            setMap[DrfCardSet.version]  = _packFileVersion;
          },
        ),
      ),
    );
  }

  Widget _getCardSetWidget(
      Map<String, dynamic> json,
      path,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return RegulatorCardSetWidget(json: json, path: path, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate, dbSource: appState.dbSource, jsonFileID: _jsonFileID);
  }

  Future<void> _save() async {
    await _child.regulatorChange(_regulatorJson);
  }
}
