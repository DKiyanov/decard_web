import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../dk_expansion_tile.dart';
import '../simple_menu.dart';
import '../simple_events.dart' as event;

Map<String, FieldDesc> loadDescFromMap(Map<String, dynamic> json) {
  final result = <String, FieldDesc>{};

  for (var element in json.entries) {
    final fieldMap = element.value as Map<String, dynamic>;

    final title = fieldMap['title'];
    if ( title != null && title is String) {
      result[element.key] = FieldDesc.fromMap(fieldMap);
    } else {

      final link = <String, FieldDesc>{};

      for (var subElement in fieldMap.entries) {
        link[subElement.key] = FieldDesc.fromMap(subElement.value);
      }

      FieldDesc._linkMap[element.key] = link;
    }

  }

  return result;
}

class JsonTheme {
  static const colorIfEmpty = Colors.deepOrangeAccent;
}

class FieldDesc {
  static final _linkMap = <String, Map<String, FieldDesc>>{};

  final String title;
  final String? help;
  final String? hint;
  final String? helperText;

  final Map<String, FieldDesc>? body;
  final String? link;

  Map<String, FieldDesc>? get subFields {
    if (body != null) return body;
    if (link != null) return _linkMap[link];
    return null;
  }

  FieldDesc({required this.title, this.help, this.hint, this.helperText, this.body, this.link});

  factory FieldDesc.fromMap(Map<String, dynamic> json) {
    Map<String, FieldDesc>? body;
    String? link;

    final bodyMap = json['body'] as Map<String, dynamic>?;
    if (bodyMap != null) {
      body = {};
      for (var element in bodyMap.entries) {
        body[element.key] = FieldDesc.fromMap(element.value);
      }
    } else {
      link = json['link'];
    }

    return FieldDesc(
      title : json['title'],
      help  : json['help'],
      hint  : json['hint'],
      helperText : json['helperText'],
      body  : body,
      link  : link,
    );
  }
}

class JsonWidgetChangeListener extends StatefulWidget {
  final Widget child;
  final VoidCallback onChange;
  const JsonWidgetChangeListener({required this.child, required this.onChange, Key? key}) : super(key: key);

  @override
  State<JsonWidgetChangeListener> createState() => JsonWidgetChangeListenerState();

  static JsonWidgetChangeListenerState? of(BuildContext context){
    return context.findAncestorStateOfType<JsonWidgetChangeListenerState>();
  }
}

class JsonWidgetChangeListenerState extends State<JsonWidgetChangeListener> {
  void setChanged(){
    widget.onChange.call();
    JsonWidgetChangeListener.of(context)?.setChanged(); // resend to UP
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

typedef JsonFieldBuild = Widget Function(
  BuildContext context,
  Map<String, dynamic> json,
  String path,
  String fieldName,
  FieldDesc fieldDesc,
);

enum JsonExpansionFieldGroupMode{
  initialExpanded,
  initialCollapsed,
  alwaysExpanded,
  noHead
}

typedef JsonChanged = void Function(Map<String, dynamic> json);

class JsonExpansionFieldGroup extends StatefulWidget {
  static const String keyBodyName = "bodyName";

  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final JsonFieldBuild onJsonFieldBuild;
  final JsonExpansionFieldGroupMode mode;
  final OwnerDelegate? ownerDelegate;
  final Widget Function(BuildContext context, FieldDesc fieldDesc, String title, Map<String, dynamic> json)? titleBuilder;
  final JsonChanged? onSubFiledChanged;

  const JsonExpansionFieldGroup({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    required this.onJsonFieldBuild,
    this.mode = JsonExpansionFieldGroupMode.initialExpanded,
    this.ownerDelegate,
    this.titleBuilder,
    this.onSubFiledChanged,

    Key? key
  }) : super(key: key);

  @override
  State<JsonExpansionFieldGroup> createState() => _JsonExpansionFieldGroupState();
}

String joinPath(String str1, String str2) {
  if (str1.isEmpty) return str2;
  if (str2.isEmpty) return str1;
  return '$str1/$str2';
}

bool pathInPath(String path, String subPath, [String fixChar = '/']) {
  if (subPath.isEmpty) return true;
  if (subPath.length > path.length) return false;
  if (path.startsWith(subPath)) {
    if (subPath.length == path.length) return true;
    if (path.substring(subPath.length, subPath.length + 1) == fixChar) return true;
  }
  return false;
}

class _JsonExpansionFieldGroupState extends State<JsonExpansionFieldGroup> {
  String _title = '';
  late FieldDesc _titleFieldDesc;
  final _titleKeyList = <String>[];

  final _titleWidgetKey = GlobalKey();

  event.Listener? _selectPathListener;

  final controller = DkExpansionTileController();

  @override
  void initState() {
    super.initState();
    _titleFieldDesc = widget.fieldDesc.subFields![JsonExpansionFieldGroup.keyBodyName]?? widget.fieldDesc;
    _getTitleKey();
    _title = _buildTitle();
    widget.ownerDelegate?.title = _title;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectPathListener ??= JsonOwner.of(context)?.onSelectPath.subscribe((listener, path) => _onSelectPath(path??''));
  }


  @override
  void dispose() {
    _selectPathListener?.dispose();
    super.dispose();
  }

  void _onSelectPath(String path) {
    final inPath = pathInPath(path, joinPath(widget.path, widget.fieldName));
    if (inPath) {
      controller.expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return JsonWidgetChangeListener(
      onChange: _onSubFieldChanged,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final children = <Widget>[];

    final path = joinPath(widget.path, widget.fieldName);

    for (var subField in widget.fieldDesc.subFields!.entries) {
      if (subField.key == JsonExpansionFieldGroup.keyBodyName) {
        continue;
      }

      children.add(Padding(
        padding: const EdgeInsets.only(left: 30),
        child: widget.onJsonFieldBuild.call(
          context,
          widget.json,
          path,
          subField.key,
          subField.value,
        ),
      ));
    }

    if (widget.mode == JsonExpansionFieldGroupMode.noHead) {
      return Column(children: children);
    }

    children.add(Container(height: 8));

    final titleWidget = StatefulBuilder(
      key:  _titleWidgetKey,
      builder: (context,  setState) {
        if (widget.titleBuilder != null) {
          return widget.titleBuilder!.call(context, _titleFieldDesc, _title, widget.json);
        }

        Widget? prevTitleWidget;
        if (_title.isNotEmpty) {
          prevTitleWidget = Text(_title);
        }
        if (prevTitleWidget == null && _titleFieldDesc.hint != null) {
          prevTitleWidget = Text(_titleFieldDesc.hint!, style: const TextStyle(color: Colors.grey));
        }

        final titleWidget = JsonTitle(_titleFieldDesc, titleWidget: prevTitleWidget);
        if (widget.ownerDelegate?.titleEnd != null) {
          return Row(children: [
            Expanded(child: titleWidget),
            widget.ownerDelegate!.titleEnd!
          ]);
        }
        return titleWidget;
      },
    );

    Widget? subTitle;

    if (widget.fieldDesc.helperText != null) {
      subTitle = Text(widget.fieldDesc.helperText!, style: const TextStyle(color: Colors.grey));
    }

    if (widget.mode == JsonExpansionFieldGroupMode.alwaysExpanded) {
      children.insert(0, ListTile(
        title:  titleWidget,
        subtitle: subTitle,
        contentPadding: EdgeInsets.zero,
      ));

      return Column(children: children);
    }

    return DkExpansionTile(
      controller: controller,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: titleWidget,
      subtitle: subTitle,
      initiallyExpanded : widget.mode == JsonExpansionFieldGroupMode.initialExpanded,
      children: children,
      onTap: (){},
    );
  }

  _onSubFieldChanged() {
    widget.onSubFiledChanged?.call(widget.json);

    if (widget.titleBuilder != null) {
      _titleWidgetKey.currentState?.setState(() {});
      return;
    }

    final newTitle = _buildTitle();
    if (_title != newTitle) {
      _title = newTitle;
      widget.ownerDelegate?.title = _title;
      _titleWidgetKey.currentState?.setState(() {});
    }
  }

  void _getTitleKey() {
    _titleKeyList.addAll( getParamList(_titleFieldDesc.title) );
  }

  String _buildTitle() {
    String title = _titleFieldDesc.title;
    for (var key in _titleKeyList) {
      title = title.replaceAll('<@$key@>', (widget.json[key]??'').toString() );
    }
    return title;
  }
}

class JsonRowFieldGroup extends StatelessWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final JsonFieldBuild onJsonFieldBuild;
  final int labelFlex;
  final int inputFlex;

  const JsonRowFieldGroup({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    required this.onJsonFieldBuild,
    this.inputFlex = 1,
    this.labelFlex = 1,

    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    final newPath = joinPath(path, fieldName);

    for (var subField in fieldDesc.subFields!.entries) {
      children.add(Expanded(
        child: onJsonFieldBuild.call(
          context,
          json,
          newPath,
          subField.key,
          subField.value,
        ),
      ));
    }

    final result = Row(children: children);

    if (fieldDesc.helperText != null && fieldDesc.helperText!.isNotEmpty) {
      return Column(children: [
        result,
        Align(alignment: Alignment.centerLeft, child: Text(fieldDesc.helperText!)),
      ]);
    }

    return result;
  }
}

class JsonTitle extends StatelessWidget {
  final FieldDesc fieldDesc;
  final Widget? titleWidget;
  const JsonTitle(this.fieldDesc, {this.titleWidget, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? child;

    if (titleWidget != null) {
      child = titleWidget;
    } else {
      child = Text(fieldDesc.title);
    }

    if (fieldDesc.help == null) return child!;

    return Tooltip(
      message: fieldDesc.help,
      child: child
    );
  }
}

enum FieldType {
  text,
//  boolean,
  int,
  double,
  signedInt,
  signedDouble,
//  dropDown,
}

typedef FixBuilder = Widget? Function(TextEditingController controller);
typedef TextValidate = String Function(String value);

class JsonTextField extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final FieldType fieldType;
  final String defaultValue;
  final TextAlign align;
  final bool readOnly;
  final Color? color;
  final Color? colorIfEmpty;
  final FixBuilder? prefix;
  final FixBuilder? suffix;
  final TextValidate? onValidate;
  final bool changeOnSubmit;

  const JsonTextField({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    this.fieldType = FieldType.text,
    this.defaultValue = '',
    this.align = TextAlign.left,
    this.color,
    this.colorIfEmpty,
    this.readOnly = false,
    this.prefix,
    this.suffix,
    this.onValidate,
    this.changeOnSubmit = true,

    Key? key
  }) : super(key: key);

  @override
  State<JsonTextField> createState() => _JsonTextFieldState();
}

class _JsonTextFieldState extends State<JsonTextField> {
  final controller = TextEditingController();

  bool _isEmpty = false;
  String _errorText = '';

  String _prevValue = '';

  @override
  void initState() {
    super.initState();

    _prevValue = widget.json[widget.fieldName]?.toString()??widget.defaultValue;
    controller.text = _prevValue;
    _isEmpty = controller.text.isEmpty;
    _errorText = widget.onValidate?.call(controller.text)??"";

    if (!widget.changeOnSubmit) {
      controller.addListener(() {
        onChange(controller.text);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextInputType? keyboardType;
    List<TextInputFormatter>? inputFormatters;

    if (widget.fieldType == FieldType.int) {
      keyboardType = TextInputType.number;
      inputFormatters = [FilteringTextInputFormatter.digitsOnly];
    }

    if (widget.fieldType == FieldType.double) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
      inputFormatters = [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))];
    }

    if (widget.fieldType == FieldType.signedInt) {
      keyboardType = const TextInputType.numberWithOptions(signed: true);
      inputFormatters = [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))];
    }

    if (widget.fieldType == FieldType.signedDouble) {
      keyboardType = const TextInputType.numberWithOptions(signed: true, decimal: true);
      inputFormatters = [FilteringTextInputFormatter.allow(RegExp(r'^-?(\d+\.?\d*)?'))];
    }

    final color = _isEmpty && widget.colorIfEmpty != null ? widget.colorIfEmpty : widget.color;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: widget.align,
      readOnly: widget.readOnly,
      showCursor: true,
      decoration: InputDecoration(
        fillColor: color,
        filled: color != null,
        prefix: widget.prefix?.call(controller),
        suffix: widget.suffix?.call(controller),
        hintText: widget.fieldDesc.hint,
        helperText: widget.fieldDesc.helperText,
        errorText: _errorText.isEmpty ? null : _errorText,
      ),
      onChanged: (value) {
        onChange(value);
      },
    );
  }

  void onChange(String value) {
    if (_prevValue == value) return;
    _prevValue = value;

    widget.json[widget.fieldName] = getJsonValue(widget.fieldType, value);
    JsonWidgetChangeListener.of(context)?.setChanged();

    bool setStateNeed = false;

    final newErrorText = widget.onValidate?.call(value)??"";
    if (_errorText != newErrorText) {
      _errorText = newErrorText;
      setStateNeed = true;
    }

    final newIsEmpty = value.isEmpty;
    if (_isEmpty != newIsEmpty) {
      _isEmpty = newIsEmpty;
      setStateNeed = true;
    }

    if (setStateNeed) {
      setState((){});
    }
  }
}

dynamic getJsonValue(FieldType fieldType, String value){
  if (fieldType == FieldType.int || fieldType == FieldType.signedInt) {
    return int.tryParse(value)??0;
  }

  if (fieldType == FieldType.double || fieldType == FieldType.signedDouble) {
    return double.tryParse(value)??0.0;
  }

  if (value.isEmpty) return null;

  return value;
}

class JsonBooleanField extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final bool defaultValue;
  final TextAlign align;
  final bool readOnly;
  final Color? color;

  const JsonBooleanField({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    this.defaultValue = false,
    this.align = TextAlign.center,
    this.readOnly = false,
    this.color,

    Key? key
  }) : super(key: key);

  @override
  State<JsonBooleanField> createState() => _JsonBooleanFieldState();
}

class _JsonBooleanFieldState extends State<JsonBooleanField> {
  @override
  Widget build(BuildContext context) {
    AlignmentGeometry? alignment;

    if (widget.align == TextAlign.left) {
      alignment = Alignment.centerLeft;
    }
    if (widget.align == TextAlign.center) {
      alignment = Alignment.center;
    }
    if (widget.align == TextAlign.right) {
      alignment = Alignment.centerRight;
    }

    return InputDecorator(
      decoration:  InputDecoration(
        fillColor: widget.color,
        filled: widget.color != null,
        hintText: widget.fieldDesc.hint,
        helperText: widget.fieldDesc.helperText,
        contentPadding: EdgeInsets.zero
      ),

      child: Container(
        alignment: alignment,
        child: Switch(
          value: widget.json[widget.fieldName]??widget.defaultValue,
          onChanged: widget.readOnly? null : (bool value) {
            widget.json[widget.fieldName] = value;

            JsonWidgetChangeListener.of(context)?.setChanged();

            setState(() {});
          },
        ),
      ),
    );
  }
}

class JsonDropdown extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final FieldType fieldType;
  final String defaultValue;
  final TextAlign align;
  final bool readOnly;
  final Color? color;
  final Color? colorIfEmpty;
  final List<String>? possibleValues;
  final Map<String, String>? possibleValuesMap; // key - internal value; value - visible value
  final Widget Function(String key, String value)? itemBuilder;

  JsonDropdown({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    this.defaultValue = "",
    this.fieldType = FieldType.text,
    this.align = TextAlign.left,
    this.readOnly = false,
    this.color,
    this.colorIfEmpty,
    this.possibleValues,
    this.possibleValuesMap,
    this.itemBuilder,

    Key? key
  }) : super(key: key) {
    assert(possibleValues != null || possibleValuesMap != null);
    assert(possibleValues == null || possibleValuesMap == null);
  }

  @override
  State<JsonDropdown> createState() => _JsonDropdownState();
}

class _JsonDropdownState extends State<JsonDropdown> {
  String _value = '';
  final _values = <String>[];

  @override
  void initState() {
    super.initState();

    _value = widget.json[widget.fieldName]?.toString()??widget.defaultValue;

    if (widget.possibleValues != null){
      _values.addAll(widget.possibleValues!);
    }
    if (widget.possibleValuesMap != null){
      _value = widget.possibleValuesMap![_value]??_value;
      _values.addAll(widget.possibleValuesMap!.values);
    }

    if (!_values.contains(_value) && _value.isNotEmpty) {
      _values.add(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    AlignmentGeometry alignment = AlignmentDirectional.centerStart;

    if (widget.align == TextAlign.left) {
      alignment = Alignment.centerLeft;
    }
    if (widget.align == TextAlign.center) {
      alignment = Alignment.center;
    }
    if (widget.align == TextAlign.right) {
      alignment = Alignment.centerRight;
    }

    final color = _value.isEmpty && widget.colorIfEmpty != null ? widget.colorIfEmpty : widget.color;

    return InputDecorator(
      decoration:  InputDecoration(
        fillColor: color,
        filled: color != null,
        hintText: widget.fieldDesc.hint,
        helperText: widget.fieldDesc.helperText,
        contentPadding: EdgeInsets.zero
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _value.isEmpty? null : _value,
          isExpanded: true,
          hint: Text(widget.fieldDesc.hint??''),

          onChanged: (String? value) {
            if (value == null) return;

            _value = value;

            if (widget.possibleValuesMap != null) {
              for (var element in widget.possibleValuesMap!.entries) {
                if (element.value == _value) {
                  widget.json[widget.fieldName] = getJsonValue(widget.fieldType, element.key);
                  break;
                }
              }
            } else {
              widget.json[widget.fieldName] = getJsonValue(widget.fieldType, _value);
            }

            JsonWidgetChangeListener.of(context)?.setChanged();

            setState(() {});
          },

          items: _values.map<DropdownMenuItem<String>>((String value) {
            String keyValue;
            if (widget.possibleValuesMap != null) {
              keyValue = widget.possibleValuesMap!.entries.firstWhere((entry) => entry.value == value).key;
            } else {
              keyValue = value;
            }

            return DropdownMenuItem<String>(
              value: value,
              alignment : alignment,
              child: widget.itemBuilder == null? Text(value) : widget.itemBuilder!.call(keyValue, value),
            );
          }).toList(),
        ),
      )
    );

  }
}

class JsonTitleRow extends StatefulWidget {
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final Widget child;
  final bool labelExpand;
  final EdgeInsetsGeometry? labelPadding;
  final int labelFlex;
  final int childFlex;
  final Widget? titleWidget;
  final Widget Function(Widget child)? labelDecorator;
  final Widget Function(Widget child)? fieldDecorator;

  const JsonTitleRow({
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    required this.child,
    this.labelExpand = true,
    this.labelPadding,
    this.labelFlex = 1,
    this.childFlex = 1,
    this.titleWidget,
    this.labelDecorator,
    this.fieldDecorator,

    Key? key
  }) : super(key: key);

  @override
  State<JsonTitleRow> createState() => _JsonTitleRowState();
}

class _JsonTitleRowState extends State<JsonTitleRow> {
  JsonOwnerState? _jsonOwner;
  event.Listener? _selectPathListener;
  bool _selected = false;
  bool _waitSelected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _jsonOwner = JsonOwner.of(context);
    _selectPathListener ??= _jsonOwner?.onSelectPath.subscribe((listener, path) => _onSelectPath(path??''));
  }

  @override
  void dispose() {
    _selectPathListener?.dispose();
    super.dispose();
  }

  void _onSelectPath(String path) {
    final newSelected = joinPath(widget.path, widget.fieldName) == path;
    if (_selected != newSelected) {
      setState(() {
        _waitSelected = true;
        _selected = newSelected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget label;

    if (widget.labelExpand) {
      label = Expanded(flex: widget.labelFlex,child: JsonTitle(widget.fieldDesc, titleWidget: widget.titleWidget));
    } else {
      label = JsonTitle(widget.fieldDesc, titleWidget: widget.titleWidget);
    }

    if (widget.labelPadding != null) {
      label = Container(
        padding: widget.labelPadding,
        child  : label,
      );
    }

    if (_waitSelected) {
      _waitSelected = false;
      _jsonOwner?.confirmPathSelection(joinPath(widget.path, widget.fieldName), context);
    }

    final labelDecorator = widget.labelDecorator ?? _defaultDecorator;
    final fieldDecorator = widget.fieldDecorator ?? _defaultDecorator;

    return Container(
      color: _selected? Colors.yellow : null,
      child: Row(children: [
        labelDecorator(label),
        Expanded(flex: widget.childFlex, child: fieldDecorator(widget.child)),
      ]),
    );
  }

  Widget _defaultDecorator(Widget child) {
    return child;
  }
}

enum ConvertDirection {
  input,
  output
}

typedef InputOutputConverter = dynamic Function(dynamic value, ConvertDirection direction);
typedef JsonMultiValueFieldItemBuilder = Widget Function(BuildContext context, String value, bool readOnly, VoidCallback onDelete, Function(String newValue) onChange);
typedef OnTextFiledFocusChangeCallback = Function(TextEditingController controller, bool hasFocus);

class JsonMultiValueField extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final bool readOnly;
  final Color? color;
  final Color? colorIfEmpty;
  final String? separator;
  final InputOutputConverter? converter; // convert json value to values array and back
  final FieldType? itemFieldType;
  final Widget Function(String value)? itemOut;
  final bool wrap; // displays result items in multiple horizontal runs
  final StringValueListGetter? valuesGetter;
  final StringValueListGetterAsync? valuesGetterAsync;
  final bool valuesGetOnce;
  final bool? manualInput;
  final FixBuilder? manualInputPrefix;
  final FixBuilder? manualInputSuffix;
  final TextValidate? onManualInputValidate;
  final JsonMultiValueFieldItemBuilder? itemBuilder;
  final ValueChanged<bool>? onExpansionChanged;
  final OnTextFiledFocusChangeCallback? onManualInputFocusChange;
  final void Function(String value)? onItemPressed;
  final bool reorderIcon;
  final bool singleValueSelect;


  const JsonMultiValueField({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    this.readOnly = false,
    this.color,
    this.colorIfEmpty,
    this.separator,
    this.converter,
    this.itemFieldType,
    this.itemOut,
    this.wrap = true,
    this.valuesGetter,
    this.valuesGetterAsync,
    this.valuesGetOnce = true,
    this.manualInput,

    this.manualInputPrefix,
    this.manualInputSuffix,
    this.onManualInputValidate,
    this.itemBuilder,
    this.onExpansionChanged,
    this.onManualInputFocusChange,
    this.onItemPressed,
    this.reorderIcon = false,
    this.singleValueSelect = false,

    Key? key
  }) : super(key: key);

  @override
  State<JsonMultiValueField> createState() => _JsonMultiValueFieldState();
}

class _JsonMultiValueFieldState extends State<JsonMultiValueField> {
  final _valueList = <String>[];
  bool _valueIsString = false;
  final _scrollControllerCheckBoxList = ScrollController();
  final _scrollControllerWrap = ScrollController();
  bool _checkBoxListOn = false;
  final _manualInputTextController = TextEditingController();

  bool _wrap = false;
  bool _readOnly = false;
  bool _checkBoxListGetterOn = false;
  bool _checkBoxValuesReceived = false;
  final _checkBoxValueList = <String>[];
  bool _expanded = false;

  InputOutputConverter? _converter;

  String _errorText = '';

  FocusNode? _manualInputFocus;

  String? _editableValue;

  bool? _noCheckBoxValues;

  @override
  void initState() {
    super.initState();
    _wrap = widget.wrap;
    _readOnly = widget.readOnly;
    _checkBoxListGetterOn = widget.valuesGetter != null || widget.valuesGetterAsync != null;
    _getInitValues();

    if (widget.onManualInputFocusChange != null) {
      _manualInputFocus = FocusNode();
      _manualInputFocus!.addListener(_onManualInputFocusChange);
    }

    _manualInputTextController.addListener(() {
      _onManualInputChange(_manualInputTextController.text);
    });
  }

  @override
  void dispose() {
    _scrollControllerCheckBoxList.dispose();
    _scrollControllerWrap.dispose();
    _manualInputTextController.dispose();
    _manualInputFocus?.removeListener(_onManualInputFocusChange);
    super.dispose();
  }

  void _onManualInputFocusChange() {
    widget.onManualInputFocusChange?.call(_manualInputTextController, _manualInputFocus!.hasFocus);
  }

  void _onManualInputChange(value) {
    final newErrorText = widget.onManualInputValidate ?.call(value)??"";
    if (_errorText != newErrorText) {
      _errorText = newErrorText;
      setState(() {});
    }
  }

  void _getInitValues() {
    if (widget.separator != null) {
      assert(widget.separator!.isNotEmpty);
      assert(widget.converter == null);

      _valueIsString = true;
      _converter = _separatorConverter;
    }

    if (widget.converter != null) {
      _valueIsString = true;
      _converter = widget.converter;
    }

    if (widget.singleValueSelect) {
      _valueIsString = true;
      _converter = _singleValueConverter;
    }

    final values = widget.json[widget.fieldName];
    if (values == null) return;

    if (values is List) {
      assert(!_valueIsString);

      for (var value in values) {
        _valueList.add(value.toString());
      }
      return;
    }

    if (values is String) {
      assert(_valueIsString);
      _valueList.addAll(_converter!(values, ConvertDirection.output));
      return;
    }

    assert(false);
  }

  void _setResult() {

    if (_valueIsString) {
      widget.json[widget.fieldName] = (_converter!.call(_valueList, ConvertDirection.input) as String);

      JsonWidgetChangeListener.of(context)?.setChanged();

      return;
    }


    if (widget.itemFieldType == null || widget.itemFieldType == FieldType.text) {
      widget.json[widget.fieldName] = _valueList;
    } else {
      widget.json[widget.fieldName] = _valueList.map((value) => getJsonValue(widget.itemFieldType!, value)).toList();
    }

    JsonWidgetChangeListener.of(context)?.setChanged();
  }

  dynamic _singleValueConverter(dynamic value, ConvertDirection direction) {
    assert(value != null);

    if (direction == ConvertDirection.output) {
      return [value as String];
    }

    final strList = value as List<String>;
    if (strList.isEmpty) return '';
    return strList.first;
  }

  dynamic _separatorConverter(dynamic value, ConvertDirection direction) {
    assert(value != null);

    if (direction == ConvertDirection.output) {
      final str = value as String;
      return str.split(widget.separator!);
    }

    final strList = value as List<String>;
    strList.join(widget.separator!);
  }

  @override
  Widget build(BuildContext context) {
    if (_wrap && _readOnly) {
      return Container(
        decoration: const BoxDecoration( border: Border(bottom: BorderSide(color: Colors.grey))),
        child: _wrapWidget()
      );
    }

    Widget? title;

    if (_valueList.isEmpty && !_expanded && widget.fieldDesc.hint != null) {
      title = Text(widget.fieldDesc.hint!);
    }

    if (title == null && _checkBoxListOn && !_wrap) {
      title = _checkBoxListWidget();
    }

    if (title == null && _wrap) {
      title = _wrapWidget();
    }

    if (title == null && !_wrap && !_expanded) {
      title = _firstValue();
    }

    if (title == null && !_wrap && _expanded) {
      title = _valueListWidget();
    }

    title ??= Container();

    final color = _valueList.isEmpty && widget.colorIfEmpty != null ? widget.colorIfEmpty : widget.color;

    final result = Container(
      decoration: const BoxDecoration( border: Border(bottom: BorderSide(color: Colors.grey))),

      child: DkExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        collapsedIconColor: _valueList.length > 1 && !_wrap? Colors.red : null,
        collapsedBackgroundColor : color,

        onTap: (){},

        onExpansionChanged: (expanded) async {
          bool setStateNeed = false;

          _expanded = expanded;

          if (!_wrap) {
            setStateNeed = true;
          }

          if (expanded) {
            if (_checkBoxValueList.isEmpty && _checkBoxListGetterOn){
              _checkBoxListOn = true;
              await _getCheckBoxValueList();
              _noCheckBoxValues = _checkBoxValueList.isEmpty;
              setStateNeed = true;
            } else {
              if (_checkBoxValueList.isNotEmpty) {
                _checkBoxListOn = true;
              }
            }
          }

          if (!expanded) {
            _checkBoxListOn = false;
            _manualInputTextController.clear();
            _errorText = "";
            widget.onManualInputFocusChange?.call(_manualInputTextController, false);

            setStateNeed = true;
          }

          if (setStateNeed) {
            setState((){});
          }

          widget.onExpansionChanged?.call(expanded);
        },

        title: title,

        children: [
          if (!_wrap && !_checkBoxListOn && !_readOnly && _checkBoxListGetterOn && _expanded) ...[
            _buttonShowCheckBoxList(),
          ],

          if (!_wrap && !_checkBoxListOn && !_readOnly && _editableValue == null && widget.manualInput != false) ...[
            if (widget.manualInput == true || (!_checkBoxListGetterOn && widget.manualInput == null)) ...[
              _manualInputRow(),
            ]
          ],

          if (_checkBoxListGetterOn && _wrap) ...[
            _checkBoxListWidget(),
          ],

          if (!_wrap && _valueList.isNotEmpty && _checkBoxListOn) ...[
            _buttonShowSelectedValues(),
          ],

          if (_wrap && !_readOnly && widget.manualInput != false) ...[
            if (widget.manualInput == true || (!_checkBoxListGetterOn && widget.manualInput == null)) ...[
              _manualInputRow(),
            ]
          ]
        ],
      ),
    );

    if (widget.fieldDesc.helperText != null) {
      return Column(children: [
        result,
        Align(alignment: Alignment.centerLeft, child: Text(widget.fieldDesc.helperText!)),
      ]);
    }

    return result;
  }

  Widget _getValueWidget(String value) {
    return widget.itemOut == null? Text(value) : widget.itemOut!.call(value);
  }

  Widget _getChip(String value, {bool readOnly = false}) {
    if (widget.itemBuilder != null) {
      return widget.itemBuilder!.call(context, value, _readOnly, ()=> _onDeleteItem(value), (newValue)=> _onChangeItemValue(value, newValue));
    }

    if (_readOnly || readOnly) {
      return InkWell(
        child: Chip(
          label: _getValueWidget(value),
        ),
        onTap: () {
          widget.onItemPressed?.call(value);
        },
      );
    }

    return InputChip(
      label: _getValueWidget(value),
      onDeleted: ()=> _onDeleteItem(value),
      onPressed: () {
        widget.onItemPressed?.call(value);
      },
    );
  }

  void _onDeleteItem(String value) {
    setState(() {
      _valueList.remove(value);
      _setResult();
    });
  }

  void _onChangeItemValue(String oldValue, String newValue) {
    setState(() {
      final index = _valueList.indexOf(oldValue);
      if (index < 0) return;
      _valueList.removeAt(index);
      _valueList.insert(index, newValue);

      _setResult();
    });
  }

  Widget _wrapWidget() {
    final screenHeight = MediaQuery.of(context).size.height;

    return LimitedBox(
      maxHeight: screenHeight * 1 / 3,
      child: Scrollbar(
        controller: _scrollControllerWrap,
        thumbVisibility: true,

        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SingleChildScrollView(
            controller: _scrollControllerWrap,
            child: Wrap(
              spacing: 6.0,
              runSpacing: 3,
              children: _valueList.map((value) => _getChip(value)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _firstValue() {
    if (_valueList.isEmpty) return Container();
    return Container(
      alignment: Alignment.centerLeft,
      child: _getChip(_valueList.first, readOnly: true),
    );
  }

  Widget _buttonShowCheckBoxList() {
    if (_noCheckBoxValues != null && _noCheckBoxValues!) {
      return Container();
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await _getCheckBoxValueList();
              _checkBoxListOn = true;
              setState(() {});
            },
            child: const Text('показать возможные значения'),
          ),
        ),
      ],
    );
  }

  Future<void> _getCheckBoxValueList() async {
    if (_checkBoxValuesReceived && widget.valuesGetOnce) {
      return;
    }

    _checkBoxValueList.clear();
    if (widget.valuesGetter != null) {
      _checkBoxValueList.addAll(widget.valuesGetter!.call(context));
    }
    if (widget.valuesGetterAsync != null) {
      _checkBoxValueList.addAll(await widget.valuesGetterAsync!.call(context));
    }

    _checkBoxValuesReceived = true;
  }

  Widget _buttonShowSelectedValues() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _checkBoxListOn = false;
              setState(() {});
            },
            child: const Text('показать выбранные значения'),
          ),
        ),
      ],
    );
  }

  Widget _manualInputRow() {
    final suffix = widget.manualInputSuffix?.call(_manualInputTextController);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: _manualInputTextController,
        focusNode: _manualInputFocus,
        decoration: InputDecoration(
          filled: true,

          errorText: _errorText.isEmpty ? null : _errorText,

          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 3, color: Colors.blue),
            borderRadius: BorderRadius.circular(15),
          ),

          prefix: widget.manualInputPrefix == null? null : widget.manualInputPrefix!.call(_manualInputTextController),

          suffix: Row(mainAxisSize: MainAxisSize.min,
            children: [
              if (suffix != null) ...[
                suffix,
              ],

              InkWell(
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  child: Icon(Icons.check, color: Colors.green),
                ),
                onTap: () {
                  final newValue = _manualInputTextController.text;
                  if (newValue.isEmpty) return;

                  final errorText = widget.onManualInputValidate ?.call(_manualInputTextController.text)??"";
                  if (errorText.isNotEmpty) {
                    _errorText = errorText;
                    setState(() {});
                    return;
                  }

                  if (_editableValue != null) {
                    if (_editableValue == newValue) {
                      _editableValue = null;
                      _manualInputTextController.clear();
                      setState(() {});
                      return;
                    }

                    if (_valueList.contains(newValue)) {
                      _errorText = 'Значение уже присутствует в списке';
                      setState(() {});
                      return;
                    }

                    final index = _valueList.indexOf(_editableValue!);
                    _valueList.removeAt(index);
                    _valueList.insert(index,  newValue);
                    _setResult();

                    _editableValue = null;
                    _manualInputTextController.clear();
                    setState(() {});
                    return;
                  }

                  if (_valueList.contains(newValue)) {
                    _errorText = 'Значение уже присутствует в списке';
                    setState(() {});
                    return;
                  }

                  _valueList.add(newValue);
                  _manualInputTextController.clear();
                  setState(() {});
                }
              ),
            ],
          )
        ),
      ),
    );
  }

  Widget _checkBoxListWidget() {
    if (_checkBoxValueList.isEmpty) {
      return const Text('Возможные значения не найдены', style: TextStyle(color: Colors.deepOrangeAccent),);
    }

    final screenHeight = MediaQuery.of(context).size.height;

    final result = LimitedBox(
      maxHeight: screenHeight * 2 / 3,
      child: Scrollbar(
        controller: _scrollControllerCheckBoxList,
        thumbVisibility: true,

        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SingleChildScrollView(
            controller: _scrollControllerCheckBoxList,
            child: Column(
                children: _checkBoxValueList.map((value) {
                  return Row(children: [

                    if (!widget.singleValueSelect) ...[
                      Checkbox(
                          value: _valueList.contains(value),
                          onChanged: (bool? newMarkValue) {
                            if (newMarkValue == null) return;
                            if (!newMarkValue) {
                              _valueList.remove(value);
                            } else {
                              _valueList.add(value);
                            }
                            _setResult();
                            setState(() {});
                          }
                      ),
                    ],

                    if (widget.singleValueSelect) ...[
                      Radio<String>(
                        value: value,
                        groupValue: _valueList.isEmpty? null : _valueList.first,
                        onChanged: (value) {
                          if (value == null) return;
                          _valueList.clear();
                          _valueList.add(value);
                          _setResult();
                          setState(() {});
                        }
                      )
                    ],

                    _getValueWidget(value),
                  ]);
                }).toList()
            ),
          ),
        ),
      ),
    );

    if (_wrap) {
      return Container(
        decoration: const BoxDecoration( border: Border(top: BorderSide(color: Colors.grey))),
        child: result,
      );
    }

    return result;
  }

  Widget _valueListWidget() {
    final screenHeight = MediaQuery.of(context).size.height;

    final children = <Widget>[];

    for (var index = 0; index < _valueList.length; index ++) {
      final value = _valueList[index];

      if (_editableValue == value) {
        _manualInputTextController.text = value;
        children.add(
          Container(
            key: ValueKey<String>(value),
            child: _manualInputRow()
          )
        );
        continue;
      }

      children.add(Slidable(
        key: ValueKey<String>(value),

        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              flex: 2,
              onPressed: (context) {
                _editableValue = value;
                setState(() {});
              },
              foregroundColor: Colors.blue,
              icon: Icons.edit,
            ),
          ],
        ),

        child: Row(
          children: [
            _getChip(value),

            if (widget.reorderIcon) ...[
              Expanded(child: Container()),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              )
            ],
          ],
        ),
      ));
    }

    return LimitedBox(
      maxHeight: screenHeight * 2 / 3,
      child: Scrollbar(
        controller: _scrollControllerCheckBoxList,
        thumbVisibility: true,

        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ReorderableListView(
            scrollController: _scrollControllerCheckBoxList,
            shrinkWrap: true,
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _valueList.removeAt(oldIndex);
                _valueList.insert(newIndex, item);
              });
            },
            children: children
          ),
        ),
      ),
    );
  }
}

typedef JsonObjectBuild = Widget Function(
  Map<String, dynamic> json,
  String path,
  FieldDesc fieldDesc,
  OwnerDelegate? ownerDelegate,
);

class OwnerDelegate {
  int? indexInArray;
  Widget? titleEnd;
  String? title;
}

class JsonObjectArray extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final JsonObjectBuild objectWidgetCreator;
  final bool initiallyExpanded;
  final bool Function(dynamic rowObject)? onFilter;
  final void Function(dynamic rowObject)? onNewRowObjectInit;

  const JsonObjectArray({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    required this.objectWidgetCreator,
    this.initiallyExpanded = true,
    this.onFilter,
    this.onNewRowObjectInit,

    Key? key
  }) : super(key: key);

  @override
  State<JsonObjectArray> createState() => _JsonObjectArrayState();
}

class _JsonObjectArrayState extends State<JsonObjectArray> {
  final _objectList = <Map<String, dynamic>>[];

  event.Listener? _selectPathListener;

  final controller = DkExpansionTileController();

  @override
  void initState() {
    super.initState();

    final objectList = widget.json[widget.fieldName];
    if (objectList != null) {
      assert(objectList is List);
      for (var element in (objectList as List)) {
        assert (element is Map<String, dynamic>);
        _objectList.add(element);
      }
    }

    widget.json[widget.fieldName] = _objectList;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectPathListener ??= JsonOwner.of(context)?.onSelectPath.subscribe((listener, path) => _onSelectPath(path??''));
  }

  void _onSelectPath(String path) {
    final inPath = pathInPath(path, joinPath(widget.path, widget.fieldName), '[');
    if (inPath) {
      controller.expand();
    }
  }

  @override
  void dispose() {
    _selectPathListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var index = 0; index < _objectList.length; index++){
      final object = _objectList[index];

      if (widget.onFilter != null) {
        if (!widget.onFilter!.call(object)) continue;
      }

      final path = '${joinPath(widget.path, widget.fieldName)}[$index]';

      final delegate = OwnerDelegate();
      delegate.indexInArray = index;
      delegate.titleEnd = popupMenu(
        icon: const Icon(Icons.menu),
        menuItemList: [
          SimpleMenuItem(
              child: const Text('Удалить'),
              onPress: ()=> _deleteSubObject(index, delegate)
          )
        ]
      );

      children.add(
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: widget.objectWidgetCreator.call(object, path, widget.fieldDesc, delegate),
          )
      );
    }

    Widget? subTitle;

    if (widget.fieldDesc.helperText != null) {
      subTitle = Text(widget.fieldDesc.helperText!, style: const TextStyle(color: Colors.grey));
    }

    if (children.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Expanded(child: JsonTitle(widget.fieldDesc)),
            IconButton(
                onPressed: _addSubObject,
                icon: const Icon(Icons.add)
            ),
            Container(width: 40),
          ],
        ),
        subtitle: subTitle,
      );
    }

    return DkExpansionTile(
      controller: controller,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: widget.initiallyExpanded,
      title: Row(
        children: [
          Expanded(child: JsonTitle(widget.fieldDesc)),
          IconButton(
            onPressed: _addSubObject,
            icon: const Icon(Icons.add)
          ),
        ],
      ),
      subtitle: subTitle,
      children: children,
      onTap: (){},
    );
  }

  _addSubObject() {
    final object = <String,dynamic>{};
    widget.onNewRowObjectInit?.call(object);
    _objectList.add(object);

    JsonWidgetChangeListener.of(context)?.setChanged();

    setState(() {});
  }

  _deleteSubObject(int index, OwnerDelegate delegate) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удаление объекта'),
          content: Text('Удалит ${delegate.title??''} ?'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == null || !result) return;

    _objectList.removeAt(index);

    if (!mounted) return;

    JsonWidgetChangeListener.of(context)?.setChanged();

    setState(() {});
  }
}

Widget suffixDropdown(TextEditingController controller, List<String> values) {
  return popupMenu(
      icon: const Icon(Icons.arrow_drop_down,),
      menuItemList: values.map((value) => SimpleMenuItem(
          child: Text(value),
          onPress: () {
            controller.text = value;
          }
      )).toList()
  );
}

class JsonOwner extends StatefulWidget {
  final Map<String, dynamic> json;
  final Widget child;
  final VoidCallback onDataChanged;

  const JsonOwner({required this.json, required this.child, required this.onDataChanged, Key? key}) : super(key: key);

  @override
  State<JsonOwner> createState() => JsonOwnerState();

  static JsonOwnerState? of(BuildContext context){
    return context.findAncestorStateOfType<JsonOwnerState>();
  }
}

class JsonOwnerState extends State<JsonOwner> {
  final onSelectPath = event.SimpleEvent<String>();
  Timer? _selectPathTimer;
  int _tickCount = 0;

  @override
  Widget build(BuildContext context) {
    return JsonWidgetChangeListener(
      onChange: onChange,
      child: widget.child
    );
  }

  void onChange() {
    widget.onDataChanged.call();
  }

  void selectPath(String path) {
    onSelectPath.send(path);
    _tickCount = 0;
    _selectPathTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      _tickCount ++;
      if (_tickCount > 40) {
        _selectPathTimer?.cancel();
        _selectPathTimer = null;
      }

      onSelectPath.send(path);
    });
  }

  Future<void> confirmPathSelection(String path, BuildContext context) async {
    _selectPathTimer!.cancel();
    _selectPathTimer = null;
    Future.delayed(const Duration(milliseconds: 300), (){
      Scrollable.ensureVisible(context);
    });
  }
}

typedef StringValueListGetter = List<String> Function(BuildContext context);
typedef StringValueListGetterAsync = Future<List<String>> Function(BuildContext context);

class JsonDropdownAsync extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final FieldType fieldType;
  final TextAlign align;
  final bool readOnly;
  final Color? color;
  final Color? colorIfEmpty;

  final StringValueListGetter? valuesGetter;
  final StringValueListGetterAsync? valuesGetterAsync;

  const JsonDropdownAsync({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    this.valuesGetter,
    this.valuesGetterAsync,
    this.fieldType = FieldType.text,
    this.align = TextAlign.left,
    this.readOnly = false,
    this.color,
    this.colorIfEmpty,

    Key? key
  }) : super(key: key);

  @override
  State<JsonDropdownAsync> createState() => _JsonDropdownAsyncState();
}

class _JsonDropdownAsyncState extends State<JsonDropdownAsync> {
  String _value = '';

  @override
  void initState() {
    super.initState();
    _value = widget.json[widget.fieldName]??"";
  }

  @override
  Widget build(BuildContext context) {

    Widget? child;

    if (_value.isNotEmpty) {
      child = Text(_value);
    }

    if (child == null && widget.fieldDesc.hint != null) {
       child = Text(widget.fieldDesc.hint!, style: const TextStyle(color: Colors.grey));
    }

    final color = _value.isEmpty && widget.colorIfEmpty != null ? widget.colorIfEmpty : widget.color;

    return InputDecorator(
      decoration:  InputDecoration(
        fillColor:  color,
        filled: color != null,
        hintText: widget.fieldDesc.hint,
        helperText: widget.fieldDesc.helperText,
        suffix: InkWell(
          child: const Icon(Icons.arrow_drop_down),
          onTap: () {
            _selectValue();
          }
        )
      ),

      child:  child??Container()
    );
  }

  void _selectValue() async {
    if (!mounted) return;

    List<String>? valueList;
    if (widget.valuesGetter != null) {
      valueList = widget.valuesGetter!.call(context);
    }
    if (widget.valuesGetterAsync != null) {
      valueList = await widget.valuesGetterAsync!.call(context);
    }

    if (valueList == null || valueList.isEmpty) return;

    if (!mounted) return;

    final render = context.findRenderObject() as RenderBox;
    final pos = render.localToGlobal(Offset.zero);
    final size = render.size;

    final dlgResult = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (BuildContext context) {
        return AlertDialog(
          alignment: Alignment.topLeft,
          insetPadding: EdgeInsets.only(left: pos.dx, top: pos.dy + size.height),
          content: SingleChildScrollView(
            child: ListBody(
              children: valueList!.map((value) => SizedBox(
                width: size.width - 100,
                child: ListTile(
                  title: Text(value),
                  onTap: () {
                    _value = value;
                    Navigator.of(context).pop(true);
                  },
                ),
              )).toList()
            ),
          ),
        );
      },
    );

    if (dlgResult == null || !dlgResult) return;

    widget.json[widget.fieldName] = getJsonValue(widget.fieldType, _value);

    if (!mounted) return;

    JsonWidgetChangeListener.of(context)?.setChanged();

    setState(() {});
  }
}

List<String> getParamList(String str) {
  final result = <String>[];

  final regexp = RegExp(r'<@(.*?)@>');
  final matches = regexp.allMatches(str);
  for (var match in matches) {
    final value = match.group(1)!;
    if (!result.contains(value)) {
      result.add(value);
    }
  }

  return result;
}