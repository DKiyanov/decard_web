import 'pack_editor.dart';
import 'values_json.dart';
import 'package:flutter/material.dart';

import '../decardj.dart';
import 'pack_card_body_widget.dart';
import 'pack_card_uplink_widget.dart';
import 'pack_widgets.dart';

class PackCardWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const PackCardWidget({required this.json, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = false;
    if (json.isEmpty) {
      initiallyExpanded = true;
      json[DjfCard.id] = "";
      json[DjfCard.title] = "";
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
    Color? colorIfEmpty;
    var align = TextAlign.left;
    var readOnly  = false;
    FixBuilder? prefix;
    FixBuilder? suffix;

    if (fieldName == DjfCard.id) {
      colorIfEmpty = JsonTheme.colorIfEmpty;
    }

    if (fieldName == DjfCard.difficulty) {
      input = JsonDropdown(
          json              : json,
          fieldName         : fieldName,
          fieldDesc         : fieldDesc,
          fieldType         : FieldType.int,
          defaultValue      : "0",
          possibleValuesMap : getJsonFieldValues(fieldName),
          colorIfEmpty      : JsonTheme.colorIfEmpty,
      );
    }

    if (fieldName == DjfCard.group) {
      final String cardID = json[DjfCard.id]??'';

      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getNearGroupList(cardID),
        singleValueSelect: true,
        manualInput: true,
      );
    }

    if (fieldName == DjfCard.tags) {
      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : true,
      );
    }

    if (fieldName == DjfCard.notShowIfLearned) {
      input = JsonBooleanField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
      );
    }

    if (fieldName == DjfCard.upLinks) {
      return JsonObjectArray(
        json                : json,
        fieldName           : fieldName,
        fieldDesc           : fieldDesc,
        objectWidgetCreator : _getCardUpLinkWidget,
      );
    }

    if (fieldName == DjfCard.bodyList) {
      return JsonObjectArray(
        json                : json,
        fieldName           : fieldName,
        fieldDesc           : fieldDesc,
        objectWidgetCreator : _getCardBodyWidget,
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
      colorIfEmpty : colorIfEmpty,
    );

    return JsonTitleRow(
      fieldDesc    : fieldDesc,
      labelExpand  : labelExpand,
      labelPadding : labelPadding,
      child        : input,
    );
  }

  Widget _getCardBodyWidget(
      Map<String, dynamic> json,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
  ){
    return PackCardBodyWidget(json: json, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Widget _getCardUpLinkWidget(
      Map<String, dynamic> json,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
  ){
    return PackCardUpLinkWidget(json: json, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }
}