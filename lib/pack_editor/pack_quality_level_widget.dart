import 'package:flutter/material.dart';

import '../decardj.dart';
import 'pack_widgets.dart';

class PackQualityLevelWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const PackQualityLevelWidget({required this.json, required this.path, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var expandMode = JsonExpansionFieldGroupMode.initialCollapsed;
    if (json.isEmpty) {
      expandMode = JsonExpansionFieldGroupMode.initialExpanded;
      json[DjfCardTemplate.templateName] = "";
    }

    return JsonExpansionFieldGroup(
      json             : json,
      path             : path,
      fieldDesc        : fieldDesc,
      fieldName        : '',
      onJsonFieldBuild : buildSubFiled,
      mode             : expandMode,
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

    if (fieldName == DjfQualityLevel.minQuality) {
      fieldType = FieldType.int;
    }

    if (fieldName == DjfQualityLevel.avgQuality) {
      fieldType = FieldType.int;
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