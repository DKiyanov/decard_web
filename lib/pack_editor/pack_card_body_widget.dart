import 'package:decard_web/pack_editor/pack_editor.dart';
import 'package:flutter/material.dart';

import '../card_model.dart';
import '../decardj.dart';
import '../simple_menu.dart';
import 'pack_card_widget.dart';
import 'pack_style_widget.dart';
import 'pack_widgets.dart';

class PackCardBodyWidget extends StatefulWidget {
  final Map<String, dynamic> json;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const PackCardBodyWidget({required this.json, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  State<PackCardBodyWidget> createState() => _PackCardBodyWidgetState();
}

class _PackCardBodyWidgetState extends State<PackCardBodyWidget> {
  bool _questionDataSelectContentTypeVisible = false;

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = false;
    if (widget.json.isEmpty) {
      initiallyExpanded = true;
    }

    return JsonExpansionFieldGroup(
      json             : widget.json,
      fieldDesc        : widget.fieldDesc,
      onJsonFieldBuild : buildSubFiled,
      initiallyExpanded: initiallyExpanded,
      ownerDelegate    : widget.ownerDelegate,
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

    if (fieldName == DjfCardBody.style) {
      return PackStyleWidget(json: json, fieldDesc: fieldDesc, hideIdField: true);
    }

    if (fieldName == DjfCardBody.styleIdList) {
      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getStyleIdList(),
      );
    }

    if (fieldName == DjfCardBody.questionData) {
      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        reorderIcon : false,
        onManualInputFocusChange: (controller, hasFocus) {
          PackEditor.of(context)?.setCardBodyQuestionDataManualInputFocus(controller, hasFocus);
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
      final cardWidget = context.findAncestorWidgetOfExactType<PackCardWidget>();
      final cardID = cardWidget!.json[DjfCard.id]??'';
      final bodyNum = widget.ownerDelegate?.indexInArray??0;


      input = JsonMultiValueField(
        json      : json,
        fieldName : fieldName,
        fieldDesc : fieldDesc,
        wrap      : false,
        valuesGetterAsync: (context)=> PackEditor.of(context)!.getBodyAnswerList(cardID, bodyNum),
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

