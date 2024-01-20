import 'package:decard_web/regulator/regulator_difficulty_widget.dart';
import 'package:decard_web/regulator/regulator_options_widget.dart';
import 'package:flutter/material.dart';

import '../pack_editor/pack_widgets.dart';
import '../regulator.dart';

class RegulatorParams extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final Map<String, dynamic> descMap;
  const RegulatorParams({required this.json, required this.path, required this.descMap, Key? key}) : super(key: key);

  @override
  State<RegulatorParams> createState() => _RegulatorParamsState();
}

class _RegulatorParamsState extends State<RegulatorParams> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 20),
      child: ListView(
        controller: _scrollController,
        children: [
          _options(),
          _difficultyList(),
        ],
      ),
    );
  }

  Widget _options() {
    return RegulatorOptionsWidget(json: widget.json[DrfRegulator.options], path: widget.path, fieldDesc: widget.descMap[DrfRegulator.options]!);
  }

  Widget _difficultyList() {
    return JsonObjectArray(
      json: widget.json,
      path: widget.path,
      fieldName: DrfRegulator.difficultyList,
      fieldDesc: widget.descMap[DrfRegulator.difficultyList]!,
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
}
