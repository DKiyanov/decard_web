import 'package:flutter/material.dart';

import '../pack_editor/pack_widgets.dart';
import '../pack_editor/values_json.dart';
import '../regulator.dart';

class RegulatorCardSetWidget extends StatelessWidget {
  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const RegulatorCardSetWidget({required this.json, required this.path, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

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


    if (fieldName == DrfCardSet.cards) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : true,
        valuesGetterAsync: (context)=> getCardIdList(context),
      );
    }

    if (fieldName == DrfCardSet.groups) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : true,
        valuesGetterAsync: (context)=> getCardGroupList(context),
      );
    }

    if (fieldName == DrfCardSet.tags) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : true,
        valuesGetterAsync: (context)=> getTagList(context),
      );
    }

    if (fieldName == DrfCardSet.andTags) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : true,
        valuesGetterAsync: (context)=> getTagList(context),
      );
    }

    if (fieldName == DrfCardSet.difficultyLevels) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : true,
        valuesGetterAsync: (context)=> getDifficultyLevelList(context),
      );
    }

    if (fieldName == DrfCardSet.exclude) {
      input = JsonBooleanField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
      );
    }

    if (fieldName == DrfCardSet.difficultyLevel) {
      input = JsonDropdown(
        json              : json,
        path              : path,
        fieldName         : fieldName,
        fieldDesc         : fieldDesc,
        fieldType         : FieldType.int,
        defaultValue      : "0",
        possibleValuesMap : getJsonFieldValues(fieldName),
        colorIfEmpty      : JsonTheme.colorIfEmpty,
      );
    }

    if (fieldName == DrfCardSet.style) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        singleValueSelect: true,
        valuesGetterAsync: (context)=> getStyleList(context),
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

  Future<List<String>> getTagList(BuildContext context) async {
    // TODO getTagList
    return [];
  }

  Future<List<String>> getCardIdList(BuildContext context) async {
    // TODO getCardIdList
    return [];
  }

  Future<List<String>> getCardGroupList(BuildContext context) async {
    // TODO getCardIdList
    return [];
  }

  Future<List<String>> getDifficultyLevelList(BuildContext context) async {
    // TODO getDifficultyLevelList
    return [];
  }

  Future<List<String>> getStyleList(BuildContext context) async {
    // TODO getStyleList
    return [];
  }
}