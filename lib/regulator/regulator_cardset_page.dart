import 'package:decard_web/app_state.dart';
import 'package:decard_web/regulator/regulator_desc_json.dart';
import 'package:decard_web/web_child.dart';
import 'package:flutter/material.dart';

import '../pack_editor/pack_widgets.dart';
import 'regulator.dart';
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
  late Map<String, FieldDesc> _descMap;

  final String _rootPath = '';

  final _scrollController = ScrollController();

  bool _changed = false;

  @override
  void initState() {
    super.initState();

    _child = appState.childManager!.childList.firstWhere((child) => child.childID == widget.childID);
    _regulatorJson =  _child.regulator.toJson();

    _descMap = loadDescFromMap(regulatorDescJson);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            final fileGuid = setMap[DrfCardSet.fileGUID] as String;
            return fileGuid == widget.fileGuid;
          },
          onNewRowObjectInit: (object) {
            final setMap = object as Map<String, dynamic>;
            setMap[DrfCardSet.fileGUID] = widget.fileGuid;
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
    return RegulatorCardSetWidget(json: json, path: path, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Future<void> _save() async {
    await _child.regulatorChange(_regulatorJson);
  }
}