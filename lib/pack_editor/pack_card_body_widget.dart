import 'package:decard_web/pack_editor/pack_editor.dart';
import 'package:flutter/material.dart';

import '../card_model.dart';
import '../decardj.dart';
import '../simple_menu.dart';
import 'pack_style_widget.dart';
import 'pack_widgets.dart';

class PackCardBodyWidget extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const PackCardBodyWidget({required this.json, required this.path, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  State<PackCardBodyWidget> createState() => _PackCardBodyWidgetState();
}

class _PackCardBodyWidgetState extends State<PackCardBodyWidget> {
  bool _questionDataSelectContentTypeVisible = false;

  @override
  Widget build(BuildContext context) {
    var expandMode = JsonExpansionFieldGroupMode.initialCollapsed;
    if (widget.json.isEmpty) {
      expandMode = JsonExpansionFieldGroupMode.initialExpanded;
    }

    return JsonExpansionFieldGroup(
      json             : widget.json,
      path             : widget.path,
      fieldName        : '',
      fieldDesc        : widget.fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      mode             : expandMode,
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

    if (fieldName == DjfCardBody.style) {
      return PackStyleWidget(json: json, path: path, fieldDesc: fieldDesc, hideIdField: true);
    }

    if (fieldName == DjfCardBody.styleIdList) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        manualInput: true,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getStyleIdList(),
      );
    }

    if (fieldName == DjfCardBody.questionData) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        reorderIcon : false,
        onManualInputFocusChange: (controller, hasFocus) {
          PackEditor.of(context)?.setNeedFileSourceController(controller, hasFocus, []);
        },
        onItemPressed: (value){
          PackEditor.of(context)?.setSelectedFileSource(value);
        },
        onManualInputValidate: (value) {
          if (value.isEmpty) {
            _questionDataSelectContentTypeVisible = false;
            return '';
          }

          final contentType = FileExt.getContentType(value);
          if (contentType == FileExt.contentUnknown) {
            _questionDataSelectContentTypeVisible = true;
            return 'Укажите тип контента';
          }
          _questionDataSelectContentTypeVisible = false;
          return '';
        },
        onExpansionChanged: (expanded) {
          if (!expanded) {
            _questionDataSelectContentTypeVisible = false;
          }
        },
        manualInputPrefix: (controller) {
          if (_questionDataSelectContentTypeVisible) {
            return popupMenu(
              icon: const Icon(Icons.select_all),
              menuItemList: FileExt.contentValues.map((contentType) => SimpleMenuItem(
                  child: Text(contentType),
                  onPress: () {
                    controller.text = '$contentType:${controller.text}';
                  }
              )).toList()
            );
          }
          return null;
        },
      );
    }

    if (fieldName == DjfCardBody.answerList) {
      input = JsonMultiValueField(
        json      : json,
        path      : path,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        manualInput: true,
        valuesGetterAsync: (context)=> _getAnswerVariantList(context),
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

  Future<List<String>> _getAnswerVariantList(BuildContext context) async {
    final answerVariantList = widget.json[DjfCardBody.style]?[DjfCardStyle.answerVariantList];

    if (answerVariantList != null) {
      return (answerVariantList as List).map((value) => value as String).toList();
    }

    final styleList = (widget.json[DjfCardBody.styleIdList]) as List?;

    if (styleList == null) return [];

    final packEditor =  PackEditor.of(context)!;

    for (var index = styleList.length - 1; index >= 0; index --) {
      final style = styleList[index];
      final answerVariantList = await packEditor.getStyleAnswerVariantList(style);
      if (answerVariantList != null) return answerVariantList;
    }

    return [];
  }

}

