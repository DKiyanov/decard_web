import 'package:flutter/material.dart';

import '../../pack_editor/pack_widgets.dart';
import '../text_constructor/word_panel_model.dart';

class TextConstructorOptionsWidget extends StatelessWidget {
  static const Map<String, IconData> _fieldIconMap = {
    JrfTextConstructor.btnKeyboard : Icons.keyboard_alt_outlined,
    JrfTextConstructor.btnUndo     : Icons.undo_outlined,
    JrfTextConstructor.btnRedo     : Icons.redo_outlined,
    JrfTextConstructor.btnBackspace: Icons.backspace_outlined,
    JrfTextConstructor.btnDelete   : Icons.delete_outline,
    JrfTextConstructor.btnClear    : Icons.clear_outlined,
  };

  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final JsonChanged onChange;

  const TextConstructorOptionsWidget({required this.json, required this.path, required this.fieldDesc, required this.onChange, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return JsonExpansionFieldGroup(
      json             : json,
      path             : path,
      fieldName        : '',
      fieldDesc        : fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      mode             : JsonExpansionFieldGroupMode.initialCollapsed,
      onSubFiledChanged: onChange,
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

    if ([JrfTextConstructor.fontSize, JrfTextConstructor.boxHeight].contains(fieldName) ) {
      fieldType = FieldType.double;
    } else {
      input = JsonBooleanField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
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
      onValidate   : onValidate,
    );

    return JsonTitleRow(
      path         : path,
      fieldName    : fieldName,
      fieldDesc    : fieldDesc,
      labelExpand  : labelExpand,
      labelPadding : labelPadding,
      child        : input,
      labelDecorator : (child) {
        final icon = _fieldIconMap[fieldName];
        if (icon == null) return child;
        return Expanded(child: Row(children: [child, Icon(icon), Container(width: 16)]));
      },
    );
  }
}
