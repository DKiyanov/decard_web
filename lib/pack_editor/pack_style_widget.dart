import 'values_json.dart';
import 'package:flutter/material.dart';

import '../decardj.dart';
import 'pack_widgets.dart';

class PackStyleWidget extends StatelessWidget {
  static const String _newLine = '|»';

  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;
  final bool hideIdField;

  const PackStyleWidget({
    required this.json,
    required this.path,
    required this.fieldDesc,
    this.ownerDelegate,
    this.hideIdField = false,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = false;
    if (hideIdField) {
      json[DjfCardStyle.id] = "";
    }
    if (json.isEmpty) {
      initiallyExpanded = true;
      json[DjfCardStyle.id] = "";
    }

    return JsonExpansionFieldGroup(
      json             : json,
      path             : path,
      fieldName        : '',
      fieldDesc        : fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      initiallyExpanded: initiallyExpanded,
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

    if (fieldName == DjfCardStyle.id) {
      if (hideIdField) return Container();
    }

    if ([
      DjfCardStyle.dontShowAnswer,
      DjfCardStyle.dontShowAnswerOnDemo,
      DjfCardStyle.answerVariantListRandomize,
      DjfCardStyle.answerVariantMultiSel,
      DjfCardStyle.answerCaseSensitive,

    ].contains(fieldName)) {
      input = JsonBooleanField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
      );
    }

    if (fieldName == DjfCardStyle.answerVariantCount) {
      fieldType = FieldType.int;
    }

    if (fieldName == DjfCardStyle.answerVariantList) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
      );
    }

    if (fieldName == DjfCardStyle.answerVariantAlign) {
      input = JsonDropdown(
          json              : json,
          path              : path,
          fieldName         : fieldName,
          fieldDesc         : fieldDesc,
          defaultValue      : "left",
          possibleValuesMap : getJsonFieldValues(fieldName)
      );
    }

    if (fieldName == DjfCardStyle.answerInputMode) {
      input = JsonDropdown(
          json              : json,
          path              : path,
          fieldName         : fieldName,
          fieldDesc         : fieldDesc,
          defaultValue      : "",
          possibleValuesMap : getJsonFieldValues(fieldName)
      );
    }

    if (fieldName == DjfCardStyle.widgetKeyboard) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        converter : _widgetKeyboardConverter,
        manualInputSuffix: (TextEditingController controller){
          return InkWell(
            child: const Padding(
              padding: EdgeInsets.only(left: 8, right: 8),
              child: Icon(Icons.subdirectory_arrow_left),
            ),
            onTap: (){
              controller.text = _newLine;
            },
          );
        },
      );
    }

    if (fieldName == "buttonImageSize") {
      input = JsonRowFieldGroup(
        json             : json,
        path             : path,
        fieldName        : '',
        fieldDesc        : fieldDesc,
        onJsonFieldBuild : buildSubFiled,
      );
    }

    if (fieldName == DjfCardStyle.buttonImageWidth) {
      labelExpand  = false;
      labelPadding = const EdgeInsets.only(right: 10);
      fieldType    = FieldType.int;
      align        = TextAlign.center;
    }

    if (fieldName == DjfCardStyle.buttonImageHeight) {
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
//      titleWidget  : Text('$path/$fieldName'), // TODO убрать
      child        : input,
    );
  }

  dynamic _widgetKeyboardConverter(dynamic value, ConvertDirection direction) {
    if (direction == ConvertDirection.output) {
      var str = value as String;
      str = str.replaceAll('\n', '\t$_newLine\t');
      return str.split('\t');
    }

    final strList = value as List<String>;
    var str = strList.join('\t');
    str = str.replaceAll('\t$_newLine\t', '\n');
    return str;
  }
}

