import 'values_json.dart';
import 'package:flutter/material.dart';

import '../decardj.dart';
import 'pack_widgets.dart';

class PackHeadWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;

  const PackHeadWidget({required this.json, required this.path, required this.fieldDesc, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return JsonExpansionFieldGroup(
      json             : json,
      path             : path,
      fieldName        : '',
      fieldDesc        : fieldDesc,
      onJsonFieldBuild : buildSubFiled,
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
    TextValidate? onValidate;

    if (fieldName == DjfFile.version) {
      fieldType = FieldType.int;
    }

    if (fieldName == DjfFile.license) {
      input = JsonDropdown(
        json              : json,
        path              : path,
        fieldName         : fieldName,
        fieldDesc         : fieldDesc,
        defaultValue      : "",
        possibleValuesMap : getJsonFieldValues(DjfFile.license)
      );
    }

    if (fieldName == 'targetAge') {
      input = JsonRowFieldGroup(
        json             : json,
        path             : path,
        fieldName        : '',
        fieldDesc        : fieldDesc,
        onJsonFieldBuild : buildSubFiled,
      );
    }

    if (fieldName == DjfFile.targetAgeLow) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    if (fieldName == DjfFile.targetAgeHigh) {
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
      onValidate   : onValidate,
    );

    return JsonTitleRow(
      path         : path,
      fieldName    : fieldName,
      fieldDesc    : fieldDesc,
      labelExpand  : labelExpand,
      labelPadding : labelPadding,
//      titleWidget  : Text('$path/$fieldName'), // TODO убрать
      child        : input,
    );
  }
}