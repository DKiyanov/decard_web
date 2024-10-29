import 'regulator_desc_json.dart';
import 'regulator_difficulty_widget.dart';
import 'regulator_options_widget.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../pack_editor/pack_widgets.dart';
import '../regulator.dart';
import '../web_child.dart';

class RegulatorParamsPage extends StatefulWidget {
  final String childID;
  const RegulatorParamsPage({required this.childID, Key? key}) : super(key: key);

  @override
  State<RegulatorParamsPage> createState() => _RegulatorParamsPageState();
}

class _RegulatorParamsPageState extends State<RegulatorParamsPage> {
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
    return PopScope(
      onPopInvoked: (didPop) async {
        if (_changed) _save();
      },

      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Настройка индивидуальных параметров ребёнка'),
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

      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 20),
        child: ListView(
          controller: _scrollController,
          children: [
            _options(),
            _difficultyList(),
          ],
        ),
      ),
    );
  }

  Widget _options() {
    return RegulatorOptionsWidget(json: _regulatorJson[DrfRegulator.options], path: _rootPath, fieldDesc: _descMap[DrfRegulator.options]!);
  }

  Widget _difficultyList() {
    return JsonObjectArray(
      json: _regulatorJson,
      path: _rootPath,
      fieldName: DrfRegulator.difficultyList,
      fieldDesc: _descMap[DrfRegulator.difficultyList]!,
      objectWidgetCreator: _getDifficultyWidget,
    );
  }

  Widget _getDifficultyWidget(
      Map<String, dynamic> json,
      String path,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return RegulatorDifficultyWidget(json: json, path: path, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Future<void> _save() async {
    await _child.regulatorChange(_regulatorJson);
  }
}
