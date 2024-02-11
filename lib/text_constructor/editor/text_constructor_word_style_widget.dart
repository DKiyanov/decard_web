import 'package:collection/collection.dart';
import 'package:decard_web/text_constructor/editor/text_constructor_desc_json.dart';
import 'package:flutter/material.dart';

import '../../pack_editor/pack_widgets.dart';
import '../word_panel_model.dart';

class TextConstructorWordStyleWidget extends StatefulWidget {
  final String styleStr;
  final FieldDesc fieldDesc;
  final void Function(String styleStr) onChange;

  const TextConstructorWordStyleWidget({required this.styleStr, required this.fieldDesc, required this.onChange, Key? key}) : super(key: key);

  @override
  State<TextConstructorWordStyleWidget> createState() => _TextConstructorWordStyleWidgetState();
}

class _TextConstructorWordStyleWidgetState extends State<TextConstructorWordStyleWidget> {
  final Map<String, dynamic> _json = {};
  int keyIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshJson();
  }

  @override
  void didUpdateWidget(covariant TextConstructorWordStyleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.styleStr == widget.styleStr) return;
    _refreshJson();
    keyIndex ++;
  }

  void _refreshJson() {
    final styleInfo = StyleInfo.fromStyleStr(widget.styleStr);
    _json.clear();
    _json.addAll(styleInfo.toMap());
  }

  @override
  Widget build(BuildContext context) {
    return JsonExpansionFieldGroup(
      json             : _json,
      path             : '',
      fieldName        : '',
      fieldDesc        : widget.fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      mode             : JsonExpansionFieldGroupMode.noHead,

      onSubFiledChanged: (json) {
        final styleInfo = StyleInfo.fromMap(json);
        final styleStr = styleInfo.toString();
        widget.onChange.call(styleStr);
      },

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

    final widgetKey = ValueKey('$fieldName/$keyIndex');

    if ([JrfStyleInfo.charColor, JrfStyleInfo.backgroundColor, JrfStyleInfo.frameColor, JrfStyleInfo.lineColor].contains(fieldName)) {
      input = JsonDropdown(
        key               : widgetKey,
        json              : json,
        path              : path,
        fieldName         : fieldName,
        fieldDesc         : fieldDesc,
        defaultValue      : "noValue",
        possibleValuesMap : textConstructorFieldValues["color"],
        itemBuilder       : (key, value) {
          final color = StyleInfo.colorNameToColor(key);
          return Container(
            decoration: BoxDecoration(
              color        : color,
              border       : Border.all(color: color),
              borderRadius : const BorderRadius.all(Radius.circular(10))
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [ Text(value) ]),
            ),
          );
        },
      );
    }

    if ([JrfStyleInfo.fontBold, JrfStyleInfo.fontItalic].contains(fieldName)) {
      input = JsonBooleanField(
        key       : widgetKey,
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
      );
    }

    if ([JrfStyleInfo.linePos].contains(fieldName)) {
      input = JsonDropdown(
        key               : widgetKey,
        json              : json,
        path              : path,
        fieldName         : fieldName,
        fieldDesc         : fieldDesc,
        defaultValue      : "noValue",
        possibleValuesMap : textConstructorFieldValues["linePos"],
        itemBuilder       : (key, value) {

          final linePos = StyleInfo.linePosNameMap[key];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(value,
                style: linePos == null ? null : TextStyle(
                  decoration     : linePos,
                  decorationColor: Colors.black,
                  decorationStyle: TextDecorationStyle.solid,
                )
            ),
          );
        },
      );
    }

    if ([JrfStyleInfo.lineStyle].contains(fieldName)) {
      input = JsonDropdown(
        key               : widgetKey,
        json              : json,
        path              : path,
        fieldName         : fieldName,
        fieldDesc         : fieldDesc,
        defaultValue      : "noValue",
        possibleValuesMap : textConstructorFieldValues["lineStyle"],
        itemBuilder       : (key, value) {

          final lineStyle = TextDecorationStyle.values.firstWhereOrNull((lineStyle) => lineStyle.name == key);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(value,
                style: lineStyle == null ? null : TextStyle(
                decoration     : TextDecoration.underline,
                decorationColor: Colors.black,
                decorationStyle: lineStyle,
              )
            ),
          );
        },
      );
    }

    input ??= JsonTextField(
      key          : widgetKey,
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
