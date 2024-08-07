import 'package:flutter/material.dart';

import '../decardj.dart';
import 'pack_editor.dart';
import 'pack_widgets.dart';

class PackCardUpLinkWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const PackCardUpLinkWidget({required this.json, required this.path, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var expandMode = JsonExpansionFieldGroupMode.initialCollapsed;
    if (json.isEmpty) {
      expandMode = JsonExpansionFieldGroupMode.initialExpanded;
    }

    return JsonExpansionFieldGroup(
      json             : json,
      path             : path,
      fieldName        : '',
      fieldDesc        : fieldDesc,
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

    if (fieldName == DjfUpLink.qualityName) {
      input = JsonDropdownAsync(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getQualityNameList(),
      );
    }

    if (fieldName == DjfUpLink.tags) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getTagList(),
        manualInput : true,
      );
    }

    if (fieldName == DjfUpLink.cards) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getCardIdList(),
        manualInput : true,
      );
    }

    if (fieldName == DjfUpLink.groups) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getCardGroupList(),
        manualInput : true,
      );
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

