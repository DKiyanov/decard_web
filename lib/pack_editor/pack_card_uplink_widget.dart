import 'package:flutter/material.dart';

import '../decardj.dart';
import 'pack_widgets.dart';

class PackCardUpLinkWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const PackCardUpLinkWidget({required this.json, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = false;
    if (json.isEmpty) {
      initiallyExpanded = true;
    }

    return JsonExpansionFieldGroup(
      json             : json,
      fieldDesc        : fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      initiallyExpanded: initiallyExpanded,
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
    var fieldType = FieldType.text;
    var align = TextAlign.left;
    var readOnly  = false;
    FixBuilder? prefix;
    FixBuilder? suffix;

    if (fieldName == DjfUpLink.qualityName) {
      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetter: (_)=> JsonOwner.of(context)!.getQualityNameList(),
      );
    }

    if (fieldName == DjfUpLink.tags) {
      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetter: (_)=> JsonOwner.of(context)!.getTagList(),
      );
    }

    if (fieldName == DjfUpLink.cards) {
      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetter: (_)=> JsonOwner.of(context)!.getCardIdList(),
      );
    }

    if (fieldName == DjfUpLink.groups) {
      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetter: (_)=> JsonOwner.of(context)!.getCardGroupList(),
      );
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

