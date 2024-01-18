import 'package:flutter/material.dart';

import '../pack_editor/pack_widgets.dart';
import '../regulator.dart';


class RegulatorOptionsWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const RegulatorOptionsWidget({required this.json, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return JsonExpansionFieldGroup(
      json             : json,
      fieldDesc        : fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      initiallyExpanded: true,
      ownerDelegate    : ownerDelegate,
    );
  }

  Widget buildSubFiled(
      BuildContext         context,
      Map<String, dynamic> json,
      String               fieldName,
      FieldDesc            fieldDesc,
      ) {
    Widget? input;

    var labelExpand = true;
    EdgeInsetsGeometry? labelPadding;
    var fieldType = FieldType.int;
    var align = TextAlign.left;
    var readOnly  = false;
    FixBuilder? prefix;
    FixBuilder? suffix;

    if (fieldName == 'hotGroupDetermine') {
      input = JsonRowFieldGroup(
        json             : json,
        fieldDesc        : fieldDesc,
        onJsonFieldBuild : buildSubFiled,
      );
    }

    if (fieldName == DrfOptions.hotGroupAvgQualityTopLimit) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    if (fieldName == DrfOptions.hotGroupAvgQualityTopLimit) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(left: 10, right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    if (fieldName == 'lowParamQualityLimit') {
      input = JsonRowFieldGroup(
        json             : json,
        fieldDesc        : fieldDesc,
        onJsonFieldBuild : buildSubFiled,
      );
    }

    if (fieldName == DrfOptions.lowDayCount) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    if (fieldName == DrfOptions.lowTryCount) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(left: 10, right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    input ??= JsonTextField(
      json         : json,
      fieldName    : fieldName,
      fieldDesc    : fieldDesc,
      fieldType    : fieldType,
      align        : align,
      readOnly     : readOnly,
      prefix       : prefix,
      suffix       : suffix,
    );

    return JsonTitleRow(
      fieldDesc    : fieldDesc,
      labelExpand  : labelExpand,
      labelPadding : labelPadding,
      child        : input,
    );
  }
}