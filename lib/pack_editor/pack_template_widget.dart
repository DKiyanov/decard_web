import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../decardj.dart';
import 'pack_card_widget.dart';
import 'pack_widgets.dart';
import 'package:simple_events/simple_events.dart' as event;

class PackTemplateWidget extends StatefulWidget {
  final Map<String, dynamic> json;
  final FieldDesc fieldDesc;
  final OwnerDelegate? ownerDelegate;

  const PackTemplateWidget({required this.json, required this.fieldDesc, this.ownerDelegate, Key? key}) : super(key: key);

  @override
  State<PackTemplateWidget> createState() => _PackTemplateWidgetState();
}

class _PackTemplateWidgetState extends State<PackTemplateWidget> {
  static const String keyParameters = "parameters";
  final _paramList = <String>[];
  final _onParamsChange = event.SimpleEvent();

  var _paramKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _paramList.addAll(_getParameters());
  }

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = false;
    if (widget.json.isEmpty) {
      initiallyExpanded = true;
      widget.json[DjfCardTemplate.templateName] = "";
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

    if (fieldName == keyParameters) {
      input = event.EventReceiverWidget(
        builder: (_) {
          return JsonMultiValueField(
            key       : _paramKey,
            json      : json,
            fieldName : fieldName,
            fieldDesc : fieldDesc,
            wrap      : true,
            readOnly  : true,
          );
        },
        events: [_onParamsChange],
        onEventCallback: (listener, object){
          _paramKey = GlobalKey();
          return true;
        },
      );
    }

    if (fieldName == DjfCardTemplate.cardTemplateList) {
      return JsonWidgetChangeListener(
        onChange: _onChange,
        child: JsonObjectArray(
          json                : json,
          fieldName           : fieldName,
          fieldDesc           : fieldDesc,
          objectWidgetCreator : _getCardWidget,
        ),
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

  Widget _getCardWidget(
      Map<String, dynamic> json,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
  ){
    return PackCardWidget(json: json, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  void _onChange() {
    final newParamList = _getParameters();
    if (listEquals(_paramList, newParamList)) return;

    _paramList.clear();
    _paramList.addAll(newParamList);

    _onParamsChange.send();
  }

  List<String> _getParameters() {
    widget.json[keyParameters] = null;
    final jsonStr = jsonEncode(widget.json);
    widget.json[keyParameters] = _paramList;

    final resultParamList = getParamList(jsonStr);

    resultParamList.sort((a, b) => a.compareTo(b));

    return resultParamList;
  }
}

