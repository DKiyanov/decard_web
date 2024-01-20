import 'package:flutter/material.dart';

import '../pack_editor/pack_widgets.dart';
import '../regulator.dart';


class RegulatorDifficultyWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const RegulatorDifficultyWidget({required this.json, required this.path, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return JsonExpansionFieldGroup(
      json             : json,
      path             : path,
      fieldName        : '',
      fieldDesc        : fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      initiallyExpanded: true,
      ownerDelegate    : ownerDelegate,
    );
  }

  Widget buildSubFiled(
      BuildContext         context,
      Map<String, dynamic> json,
      String               path,
      String               fieldName,
      FieldDesc            fieldDesc,
      ) {
    Widget? input;

    var labelExpand = true;
    EdgeInsetsGeometry? labelPadding;
    var fieldType = FieldType.text;
    var align = TextAlign.left;
    var readOnly  = false;
    FixBuilder? prefix;
    FixBuilder? suffix;

    if (['cost', 'penalty', 'tryCount', 'duration', 'durationLowCostPercent'].contains(fieldName)) {
      input = JsonRowFieldGroup(
        json             : json,
        path             : path,
        fieldName        : '',
        fieldDesc        : fieldDesc,
        onJsonFieldBuild : buildSubFiled,
      );
    }

    if ([DrfDifficulty.maxCost, DrfDifficulty.maxPenalty, DrfDifficulty.maxTryCount, DrfDifficulty.maxDuration, DrfDifficulty.maxDurationLowCostPercent].contains(fieldName)) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    if ([DrfDifficulty.minCost, DrfDifficulty.minPenalty, DrfDifficulty.minTryCount, DrfDifficulty.minDuration, DrfDifficulty.minDurationLowCostPercent].contains(fieldName)) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(left: 10, right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    input ??= JsonTextField(
      json         : json,
      path         : path,
      fieldName    : fieldName,
      fieldDesc    : fieldDesc,
      fieldType    : fieldType,
      align        : align,
      readOnly     : readOnly,
      prefix       : prefix,
      suffix       : suffix,
    );

    return JsonTitleRow(
      path         : path,
      fieldName    : fieldName,
      fieldDesc    : fieldDesc,
      labelExpand  : labelExpand,
      labelPadding : labelPadding,
      child        : input,
    );
  }
}