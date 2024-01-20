import 'package:decard_web/app_state.dart';
import 'package:decard_web/regulator/regulator_desc_json.dart';
import 'package:decard_web/web_child.dart';
import 'package:flutter/material.dart';

import '../pack_editor/pack_widgets.dart';
import '../regulator.dart';
import 'regulator_cardset_widget.dart';

class RegulatorCardSetPage extends StatefulWidget {
  final String childID;
  final String fileGuid;
  const RegulatorCardSetPage({required this.childID, required this.fileGuid, Key? key}) : super(key: key);

  @override
  State<RegulatorCardSetPage> createState() => _RegulatorCardSetPageState();
}

class _RegulatorCardSetPageState extends State<RegulatorCardSetPage> {
  late WebChild _child;
  late Map<String, dynamic> _regulatorJson;
  late Map<String, dynamic> _setJson;
  late Map<String, FieldDesc> _descMap;
  late String _path;

  bool _changed = false;

  @override
  void initState() {
    super.initState();

    _child = appState.childManager!.webChildList.firstWhere((child) => child.childID == widget.childID);
    _regulatorJson =  _child.regulator.toJson();

    final setList = _regulatorJson[DrfRegulator.setList] as List;

    for(int index = 0; index < setList.length; index ++) {
      final setMap = setList[index] as Map<String, dynamic>;
      final fileGuid =  setMap[DrfCardSet.fileGUID] as String;
      if (fileGuid == widget.fileGuid) {
        _setJson = setMap;
        _path = '${DrfRegulator.setList}[$index]';
        break;
      }
    }

    _descMap = loadDescFromMap(regulatorDescJson);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_changed) _save();
        return true;
      },

      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Настройка файл'),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    return JsonOwner(
      json: _setJson,
      onDataChanged: () {
        _changed = true;
      },

      child: SingleChildScrollView(
        child: RegulatorCardSetWidget(json: _setJson, path: _path, fieldDesc: _descMap['cardSet']!)
      ),
    );
  }

  Future<void> _save() async {
    await _child.regulatorChange(_regulatorJson);
  }
}
