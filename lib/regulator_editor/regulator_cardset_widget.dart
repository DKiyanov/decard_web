import 'package:flutter/material.dart';

import '../db_mem.dart';
import '../decardj.dart';
import '../pack_editor/desc_json.dart';
import '../pack_editor/pack_style_widget.dart';
import '../pack_editor/pack_widgets.dart';
import '../pack_editor/values_json.dart';
import '../regulator.dart';

class RegulatorCardSetWidget extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;
  final DbSourceMem  dbSource;
  final int jsonFileID;

  const RegulatorCardSetWidget({
    required this.json,
    required this.path,
    required this.fieldDesc,
    this.ownerDelegate,
    required this.dbSource,
    required this.jsonFileID,

    Key? key
  }) : super(key: key);

  @override
  State<RegulatorCardSetWidget> createState() => _RegulatorCardSetWidgetState();
}

class _RegulatorCardSetWidgetState extends State<RegulatorCardSetWidget> {
  late Map<String, String>  difficultyMap;
  late Map<String, FieldDesc> _descMap;

  @override
  void initState() {
    super.initState();

    difficultyMap = getJsonFieldValues(DjfCard.difficulty);
    _descMap = loadDescFromMap(descJson);
  }

  @override
  Widget build(BuildContext context) {
    return JsonExpansionFieldGroup(
      json             : widget.json,
      path             : widget.path,
      fieldName        : '',
      fieldDesc        : widget.fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      ownerDelegate    : widget.ownerDelegate,
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

    if (['cardFilter', 'setValues'].contains(fieldName)) {
      return JsonExpansionFieldGroup(
        json: json,
        path: path,
        fieldName: fieldName,
        fieldDesc: fieldDesc,
        onJsonFieldBuild: buildSubFiled,
      );
    }

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
        itemFieldType: FieldType.int,
        valuesGetter: (context)=> difficultyMap.keys.toList(),
        itemOut: (key)=> Text(difficultyMap[key]!),
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
        possibleValuesMap : difficultyMap,
        colorIfEmpty      : JsonTheme.colorIfEmpty,
      );
    }

    if (fieldName == DrfCardSet.style) {
      if (json[DrfCardSet.style] == null) {
        json[DrfCardSet.style] = <String, dynamic> {};
      }

      return PackStyleWidget(
        json        : json[DrfCardSet.style],
        path        : '$path/$fieldName',
        fieldDesc   : _descMap['cardStyle']!,
        hideIdField : true
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
    return widget.dbSource.tabCardTag.getFileTagList(jsonFileID: widget.jsonFileID);
  }

  Future<List<String>> getCardIdList(BuildContext context) async {
    return widget.dbSource.tabCardHead.getFileCardKeyList(jsonFileID: widget.jsonFileID);
  }

  Future<List<String>> getCardGroupList(BuildContext context) async {
    return widget.dbSource.tabCardHead.getFileGroupList(jsonFileID: widget.jsonFileID);
  }

  Future<List<String>> getStyleList(BuildContext context) async {
    return widget.dbSource.tabCardStyle.getStyleKeyList(jsonFileID: widget.jsonFileID);
  }
}