import 'dart:convert';

import 'package:decard_web/dk_expansion_tile.dart';
import 'package:decard_web/text_constructor/editor/text_constructor_options_widget.dart';
import 'package:flutter/material.dart';

import '../../simple_dialog.dart';
import '../text_constructor.dart';
import '../word_panel.dart';
import 'text_constructor_desc_json.dart';
import 'text_constructor_word_style_widget.dart';

import '../../pack_editor/pack_widgets.dart';
import '../word_panel_model.dart';
import 'package:path/path.dart' as path_util;

class AnswerTextConstructor {
  GlobalKey<TextConstructorWidgetState> key;
  final TextConstructorData textConstructorData;
  bool viewOnly = true;
  AnswerTextConstructor(this.key, this.textConstructorData);
}

class TextConstructorEditorPage extends StatefulWidget {
  final String filename;
  final String jsonStr;
  final void Function(String fileName, String? jsonStr) resultCallback;
  const TextConstructorEditorPage({required this.filename, required this.jsonStr, required this.resultCallback, Key? key}) : super(key: key);

  @override
  State<TextConstructorEditorPage> createState() => _TextConstructorEditorPageState();
}

class _TextConstructorEditorPageState extends State<TextConstructorEditorPage> {
  late Color _panelColor;
  
  late Map<String, dynamic> _jsonMap;
  final Map<String, dynamic> _styleJson = {};

  late Map<String, FieldDesc> _descMap;

  final _rootPath = '';

  final _scrollController   = ScrollController();

  late TextConstructorData _textConstructorData;
  var _constructorKey = GlobalKey<TextConstructorWidgetState>();
  TextConstructorWidgetState get _constructor => _constructorKey.currentState!;

  final _objectEditorKey = GlobalKey();
  String _selLabel = '';
  LabelInfo? _selLabelInfo;
  int    _selPos = -1;
  bool _objectExpanded = false;

  final _styleListKey = GlobalKey();

  final _stylePanelKey = GlobalKey();
  bool _styleExpanded = false;
  StyleInfo? _selStyleInfo;
  int        _selStyleIndex = -1;

  final _answersPanelKey = GlobalKey();
  bool _answersExpanded = false;

  final _answerList = <AnswerTextConstructor>[];

  final _markStylePanelKey = GlobalKey();

  double _fontSize = 0;

  bool _isStarting = true;
  bool _shaker = false;

  @override
  void initState() {
    super.initState();
    
    _panelColor = Colors.grey.shade200;

    _descMap = loadDescFromMap(textConstructorDescJson);

    if (widget.jsonStr.isNotEmpty) {
      _jsonMap = jsonDecode(widget.jsonStr);
    } else {
      _jsonMap = {};
    }

    final Map<String, dynamic> setJsonMap = {};

    for (var field in [
      JrfTextConstructor.text,
      JrfTextConstructor.objects,
      JrfTextConstructor.styles,
      JrfTextConstructor.markStyle,
      JrfTextConstructor.basement,
      JrfTextConstructor.answerList,
      JrfTextConstructor.fontSize,
      JrfTextConstructor.boxHeight,
    ]) {
      final value = _jsonMap[field];
      if (value == null) continue;
      setJsonMap[field] = value;
    }

    _textConstructorData = TextConstructorData.fromMap(setJsonMap);

    _fontSize = _textConstructorData.fontSize;

    // move default values back to _jsonMap if its was not set
    final tcJson = _textConstructorData.toJson();
    for (var tcEntry in tcJson.entries) {
      if (tcEntry.value == null) continue;
      if (_jsonMap[tcEntry.key] != null) continue;
      _jsonMap[tcEntry.key] = tcEntry.value;
    }

    final answerList = _textConstructorData.answerList;
    if (answerList != null) {
      for (var answer in answerList) {
        _addAnswer(answer);
      }
    }

    _styleJson[JrfTextConstructor.styles] = _convertStyleListIn(_textConstructorData.styles);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isStarting) return;
      _starting();
    });
  }

  void _starting() {
    _isStarting = false;
    _shake();
  }

  void _shake() {
    setState(() { // a strange issue with drawing
      _shaker = !_shaker;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filename),
        leading: InkWell(
          onTap: _returnResult,
          child: const Icon(Icons.arrow_back_outlined),
        ),
        actions: [
          IconButton(
              onPressed: () {
                widget.resultCallback.call(widget.filename, null);
              },
              icon: Icon(Icons.cancel_outlined, color: Colors.red.shade900)
          )
        ],
      ),

      body: _body(),
    );
  }

  Widget _body() {
    return ListView(
      controller: _scrollController,
      children: [
        _textConstructor(),

        if (_shaker) ...[
          Container(height: 1),
        ],

        _objectEditor(),
        Container(height: 6),
        _stylePanel(),
        Container(height: 6),
        _markStylePanel(),
        Container(height: 6),
        _answersPanel(),
        Container(height: 6),
        _optionsPanel(),
      ],
    );
  }

  Widget _answersPanel() {
    return StatefulBuilder(
      key:  _answersPanelKey,
      builder: (context, setState) {
        final title = Row(
          children: [
            const Expanded(child: Text('Ответы')),

            if (_answersExpanded || _answerList.isEmpty) ...[
              IconButton(
                  onPressed: () {
                    setState((){
                      _addAnswer();
                      _answersExpanded = true;
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.blue)
              )
            ],
          ],
        );

        if (_answerList.isEmpty) {
          return ListTile(
            title: title,
            tileColor: _panelColor,
            contentPadding: const EdgeInsets.only(left: 16, right: 4),
          );
        }

        return DkExpansionTile(
          title: title,

          collapsedBackgroundColor: _panelColor,
          backgroundColor: _panelColor,

          initiallyExpanded: _answersExpanded,

          children: _answerList.map((answer) {
            return StatefulBuilder(builder: (context, setState) {
              final answerWidget = Container(
                decoration: answer.viewOnly? null : const BoxDecoration(
                  border: Border(
                    bottom: BorderSide( color:  Colors.blue, width: 3)
                  )
                ),

                child: TextConstructorWidget(
                  key: answer.key,
                  textConstructor: answer.textConstructorData,
                  wordPanelDecorator: _wordPanelDefaultDecorator,
                  basementPanelDecorator: _basementPanelDefaultDecorator,
                  viewOnly: answer.viewOnly,
                  toolbarTrailing: [
                      IconButton(
                          onPressed: () {
                            answer.viewOnly = true;
                            setState((){});
                          },
                          icon: const Icon(Icons.check, color: Colors.lightGreenAccent)
                      ),

                      IconButton(
                          onPressed: () {
                            _answerList.remove(answer);
                            _answersPanelRefresh();
                          },
                          icon: const Icon(Icons.delete, color: Colors.redAccent)
                      ),
                    ],
                ),
              );

              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: answerWidget),

                    if (answer.viewOnly) ...[
                      IconButton(
                          onPressed: () {
                            answer.viewOnly = false;
                            setState((){});
                          },
                          icon: const Icon(Icons.edit, color: Colors.blue)
                      )
                    ]

                  ],
                ),
              );
            });
          }).toList(),

          onExpansionChanged: (expanded) {
            setState((){
              _answersExpanded = expanded;
            });
          },
        );
      }
    );
  }

  void _answersPanelRebuild([Map<String, dynamic>? setJsonMap]) {
    for (var answer in _answerList) {
      if (setJsonMap != null) {
        answer.textConstructorData.setFromMap(setJsonMap);
        if (answer.key.currentState != null) {
          answer.textConstructorData.text = answer.key.currentState!.panelController.text;
        }
      }
      answer.key = GlobalKey();
    }
  }

  void _answersPanelRefresh([Map<String, dynamic>? setJsonMap]) {
    for (var answer in _answerList) {
      if (setJsonMap != null) {
        answer.textConstructorData.setFromMap(setJsonMap);
      }
      answer.key.currentState?.refresh();
    }
    _answersPanelKey.currentState?.setState(() {});
  }

  Widget _optionsPanel() {
    final fieldDesc = _descMap["options"]!;

    return Container(
      color: _panelColor,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: TextConstructorOptionsWidget(
          json: _jsonMap,
          path: _rootPath,
          fieldDesc: fieldDesc,
          onChange: (jsonMap){
            final Map<String, dynamic> setJsonMap = {};

            for (var field in [
              JrfTextConstructor.fontSize,
              JrfTextConstructor.boxHeight,
            ]) {
              final value = _jsonMap[field];
              if (value == null) continue;
              setJsonMap[field] = value;
            }

            _textConstructorData.setFromMap(setJsonMap);

            if (_fontSize != _textConstructorData.fontSize) {
              _fontSize != _textConstructorData.fontSize;
              _textConstructorData.text = _constructor.panelController.text;
              _constructorKey = GlobalKey();
              _answersPanelRebuild(setJsonMap);
              setState(() { });
            } else {
              _constructorKey.currentState?.refresh();
              _objectEditorKey.currentState?.setState(() {});
              _stylePanelKey.currentState?.setState(() {});

              _answersPanelRefresh(setJsonMap);
            }
          },
        ),
      ),
    );
  }

  Widget _textConstructor() {
    return TextConstructorWidget(
      key             : _constructorKey,
      textConstructor : _textConstructorData,
      wordPanelDecorator: _wordPanelDefaultDecorator,
      basementPanelDecorator: _basementPanelDefaultDecorator,
      onTapLabel: (pos, label) {
        label = LabelInfo.unSelect(label);

        if (_selPos == pos && _selLabel == label) {
          _selPos = -1;
        } else {
          _selPos   = pos;
        }

        if (_selLabel != label) {
          _selLabel = label;
          _selLabelInfo  =  LabelInfo(_selLabel);
          if (_selLabelInfo!.isObject){
            final object = _textConstructorData.objects.firstWhere((object) => object.name == _selLabelInfo!.objectName);
            final viewIndex = _selLabelInfo!.viewIndex;
            final viewInfo = object.views[viewIndex];
            _selStyleIndex = viewInfo.styleIndex;
            _selStyleInfo  = _textConstructorData.styles[_selStyleIndex];
            _stylePanelKey.currentState?.setState(() {});
          }

          _objectEditorKey.currentState?.setState(() {});
        }
      },
      onChangeHeight: (newHeight) {
        _shake();
      },
    );
  }

  Widget _dropdownStyle({
    required String outStr,
    required int styleIndex,
    required void Function(int?) onChange,
    Widget? noStyleItem
  }) {
    if (_constructorKey.currentState == null) return Container();

    final styleItems = <DropdownMenuItem<int>>[];

    styleItems.add(DropdownMenuItem<int>(
      value: -1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: noStyleItem ?? _constructor.getObjectViewWidget(context,
            label      : outStr,
            styleIndex : -1
        ),
      ),
    ));

    for (int styleIndex = 0; styleIndex < _textConstructorData.styles.length; styleIndex ++) {
      styleItems.add(DropdownMenuItem<int>(
        value: styleIndex,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _constructor.getObjectViewWidget(context,
              label      : outStr,
              styleIndex : styleIndex
          ),
        ),
      ));
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: styleIndex,
        items: styleItems,
        onChanged: onChange,
        isExpanded: true,
      ),
    );
  }

  Widget _objectEditor() {
    return StatefulBuilder(
      key: _objectEditorKey,
      builder: (context, setState) {

        if (_selPos < 0) {
          return ListTile(
            title: const Text('Слово не выбрано'),
            contentPadding: const EdgeInsets.only(left: 16),
            tileColor: _panelColor,
          );
        }

        WordObject? object;

        if (_selLabelInfo!.isObject) {
          object = _constructor.getWordObject(_selLabelInfo!.objectName);
        }

        final title = Row(children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _constructor.labelWidget(context, _selLabel, DragBoxSpec.none),
            ),
          ),

          if (object == null || _objectExpanded) ...[
            IconButton(
                onPressed: (){
                  if (object != null){
                    object.views.add(ViewInfo(''));
                  } else {
                    _replaceWordToObject();
                    _objectExpanded = true;
                    _constructorKey.currentState?.refresh();
                  }
                  setState((){});
                },
                icon: const Icon(Icons.add, color: Colors.blue)
            ),
          ],

        ]);

        if (object != null) {
          final children = <Widget>[];
          for (int viewIndex = 0; viewIndex < object.views.length; viewIndex ++) {
            final viewInfo = object.views[viewIndex];

            String outStr     = viewInfo.text;
            String menuText   = viewInfo.menuText;
            int    styleIndex = viewInfo.styleIndex;

            if (outStr.isEmpty) {
              outStr = object.name;
            }

            bool menuSwitchValue = menuText != ViewInfo.menuSkipText;

            children.add(Row(
              children: [
                Expanded(
                  child: DkExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _constructor.getObjectViewWidget(context,
                                objectName: object.name,
                                viewInfo: viewInfo
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () async {
                            if (! await _deleteObjectView(object!, viewIndex)) return;
                            setState((){});
                            _constructorKey.currentState?.refresh();
                          },
                          icon: const Icon(Icons.delete, color: Colors.blue),
                        )
                      ],
                    ),
                    childrenPadding: const EdgeInsets.only(left: 40, right: 16),
                    children: [

                      _paramLabel(
                        title: 'Стиль',
                        child: _dropdownStyle(
                          outStr: outStr,
                          styleIndex: styleIndex,
                          onChange: (value) {
                            if (value == null) return;
                            object!.views[viewIndex] = ViewInfo.fromComponents(value, menuText, outStr);
                            setState((){});
                            _constructorKey.currentState?.refresh();
                          }
                        ),
                      ),

                      // Текст
                      _paramLabel(
                        title: 'Текст',
                        child: TextFormField(
                          initialValue: outStr,
                          onFieldSubmitted: (text){
                            object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, menuText, text);
                            setState((){});
                            _constructorKey.currentState?.refresh();
                          },
                        )
                      ),

                      //Текст меню
                      _paramLabel(
                          title : 'Текст в меню',
                          help  : 'Текст отображемый в выпадающем меню, иногда нужно что бы он отличался от значения которое будет выведено после выбора этого пункта меню',
                          child : Row( children: [
                            Switch(
                                value: menuSwitchValue,
                                onChanged: (value){
                                  String menuText = '';
                                  if (!value) {
                                    menuText = '-';
                                  }
                                  object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, menuText, outStr);
                                  setState((){});
                                  _constructorKey.currentState?.refresh();
                                }
                            ),

                            if (menuSwitchValue) ...[
                              Expanded(
                                child: TextFormField(
                                  initialValue: outStr,
                                  onFieldSubmitted: (text){
                                    object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, text, outStr);
                                    setState((){});
                                    _constructorKey.currentState?.refresh();
                                  },
                                ),
                              )
                            ] else ...[
                              const Expanded(child: Center(child: Text('в выпадающем меню этот пункт не выводится')))
                            ]
                          ])
                      ),
                    ],


                  ),
                ),
              ],
            ));
          }

          return DkExpansionTile(
            title: title,
            initiallyExpanded: _objectExpanded,
            childrenPadding: const EdgeInsets.only(left: 40),
            collapsedBackgroundColor: _panelColor,
            backgroundColor: _panelColor,
            onExpansionChanged: (expanded){
              _objectExpanded = expanded;
              setState((){});
            },
            children: children,
          );
        }

        return ListTile(
          title: title,
          contentPadding: const EdgeInsets.only(left: 16, right: 4),
          tileColor: _panelColor,
        );
      }
    );
  }

  Widget _paramLabel({required String title, String? help, required Widget child}){
    Widget label;

    if (help != null) {
      label = Tooltip(message: help, child: Text(title));
    } else {
      label = Text(title);
    }

    return Row(children: [
      Expanded(child: label),
      Expanded(child: child)
    ]);
  }

  Widget _stylePanel() {
    return StatefulBuilder(
      key: _stylePanelKey,
      builder: (context, setState) {
        if (_textConstructorData.styles.isEmpty) {
          return ListTile(
            title: Row(
              children: [
                const Expanded(child: Text('Стили')),
                IconButton(
                    onPressed: () {
                      _addStyleNew();
                      _styleExpanded = true;
                      setState(() {});
                    },
                    icon: const Icon(Icons.add, color: Colors.blue)
                )
              ],
            ),
            contentPadding: const EdgeInsets.only(left: 16, right: 4),
            tileColor: _panelColor,
          );
        }

        return DkExpansionTile(
          title: Row(
            children: [
              const Expanded(child: Text('Стили')),
              if (_styleExpanded) ...[
                IconButton(
                    onPressed: _selStyleInfo == null ? null : () async {
                      if (! await _deleteSelStyle()) return;
                      setState(() {});
                      _constructorKey.currentState?.refresh();
                      _objectEditorKey.currentState?.setState(() {});
                    },
                    icon: const Icon(Icons.delete)
                ),

                IconButton(
                    onPressed: (){
                      _addStyleNew();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add)
                )
              ],
            ],
          ),

          onExpansionChanged: (expanded) {
            _styleExpanded = expanded;
            _stylePanelKey.currentState?.setState(() {});
          },

          initiallyExpanded: _styleExpanded,

          collapsedBackgroundColor: _panelColor,
          backgroundColor: _panelColor,

          children: [
            Row(
              children: [
                Expanded(flex: 1, child: _styleList()),
                Expanded(flex: 2, child: _selStyleTuner(_selStyleIndex, _selStyleInfo.toString()))
              ],
            )
          ],
        );
      }
    );
  }

  Widget _styleList() {
    return StatefulBuilder(
      key: _styleListKey,
      builder: (context, setState) {
        final children = <Widget>[];

        for(int styleIndex = 0; styleIndex < _textConstructorData.styles.length; styleIndex ++) {
          children.add(
            InkWell(
              child: Container(
                color: styleIndex != _selStyleIndex? null : Colors.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      _constructor.getObjectViewWidget(context,
                          label      : 'Стиль',
                          styleIndex : styleIndex
                      ),
                    ],
                  ),
                ),
              ),

              onTap: () {
                _selStyleIndex = styleIndex;
                _selStyleInfo = _textConstructorData.styles[_selStyleIndex];
                _stylePanelKey.currentState?.setState(() {});
              },
            ),
          );
        }

        return ListView(
          shrinkWrap: true,
          children: children,
        );
      }
    );
  }

  Widget _selStyleTuner(int styleIndex, String styleStr) {
    if (_selStyleIndex < 0) return Container();
    return TextConstructorWordStyleWidget(
      key: ValueKey(styleIndex),
      styleStr: styleStr,
      fieldDesc: _descMap["style"]!,
      onChange: (newStyleStr){
        _selStyleInfo = StyleInfo.fromStyleStr(newStyleStr) ;
        _textConstructorData.styles[_selStyleIndex] = _selStyleInfo!;
        _styleListKey.currentState?.setState(() {});
        _constructorKey.currentState?.refresh();
        _objectEditorKey.currentState?.setState(() { });
        _answersPanelKey.currentState?.setState(() { });
        _markStylePanelKey.currentState?.setState(() { });
      },
    );
  }

  void _addStyleNew() {
    _textConstructorData.styles.add(StyleInfo());
    _selStyleIndex = _textConstructorData.styles.length - 1;
    _selStyleInfo = _textConstructorData.styles[_selStyleIndex];
  }

  Future<bool> _deleteSelStyle() async {
    final dlgResult = await simpleDialog(
      context: context,
      title: const Text('Удалить стиль?'),
      barrierDismissible: true
    )?? false;
    if (!dlgResult) return false;

    for (var object in _textConstructorData.objects) {
      for (int viewIndex = 0; viewIndex < object.views.length; viewIndex ++) {
        final view = object.views[viewIndex];
        if (view.styleIndex == _selStyleIndex) {
          final newView = ViewInfo.fromComponents(-1, view.menuText, view.text);
          object.views[viewIndex] = newView;
        }
      }
    }

    _textConstructorData.styles.removeAt(_selStyleIndex);

    return true;
  }

  List<Map<String, dynamic>> _convertStyleListIn(List<StyleInfo> styleList) {
    final result = <Map<String, dynamic>>[];

    for (var style in styleList) {
      result.add(style.toMap());
    }

    return result;
  }

  Widget _markStylePanel() {
    return StatefulBuilder(
      key: _markStylePanelKey,
      builder: (context, setState) {
        return ListTile(
          title: Row(
            children: [
              const Expanded(child: Text('Стиль для выделения')),
              Expanded(
                child: _dropdownStyle(
                    outStr: 'Стиль',
                    styleIndex: _textConstructorData.markStyle,
                    noStyleItem: const Text('стиль не выбран'),
                    onChange: (value) {
                      if (value == null) return;
                      _textConstructorData.markStyle = value;
                      setState((){});
                      _constructorKey.currentState?.refresh();
                      _answersPanelRefresh();
                    }
                ),
              )
            ],
          ),
          contentPadding: const EdgeInsets.only(left: 16, right: 16),
          tileColor: _panelColor,
        );
      }
    );

  }

  void _replaceWordToObject() {
    final pos = _constructor.panelController.getFocusPos();
    var word =  _constructor.panelController.getWord(pos);
    word = LabelInfo.unSelect(word);

    _textConstructorData.objects.add(
        WordObject(name: word, nonRemovable: false, views: [ViewInfo('')])
    );

    _constructor.panelController.deleteWord(pos);

    word = '#$word';
    _constructor.panelController.insertWord(pos, word);

    _constructor.panelController.setFocusPos(pos);

    _selPos       = pos;
    _selLabel     = word;
    _selLabelInfo = LabelInfo(_selLabel);
  }

  void _replaceObjectToWord(WordObject object) {
    final wordList = _constructor.panelController.getWordList();

    final focusPos = _constructor.panelController.getFocusPos();

    final wordListLength = wordList.length;

    for (int pos = 0; pos < wordListLength; pos ++) {
      final label = wordList[pos];
      final labelInfo = LabelInfo(label);

      if (!labelInfo.isObject) continue;
      if (labelInfo.objectName != object.name) continue;


      var word = object.name;
      final viewInfo = object.views[labelInfo.viewIndex];
      if (viewInfo.text.isNotEmpty) {
        word = viewInfo.text;
      }

      _constructor.panelController.deleteWord(pos);
      _constructor.panelController.insertWord(pos, word);

      if (pos == focusPos) {
        _selPos       = focusPos;
        _selLabel     = word;
        _selLabelInfo = LabelInfo(_selLabel);
      }
    }

    _textConstructorData.objects.remove(object);

    _constructor.panelController.setFocusPos(focusPos);
  }

  Future<bool> _deleteObjectView(WordObject object, int delViewIndex) async {
    final dlgResult = await simpleDialog(
      context: context,
      title: const Text('Предупреждение'),
      content: const Text('Удалить эту настройку визуализации?')
    )??false;

    if (!dlgResult) return false;

    if (object.views.length == 1) {
      _replaceObjectToWord(object);
      return true;
    }

    final wordList = _constructor.panelController.getWordList();
    final wordListLength = wordList.length;

    for (int pos = 0; pos < wordListLength; pos ++) {
      final label = wordList[pos];
      final labelInfo = LabelInfo(label);

      if (!labelInfo.isObject) continue;
      if (labelInfo.objectName != object.name) continue;

      if (labelInfo.viewIndex <= delViewIndex) continue;

      final newViewIndex = labelInfo.viewIndex - 1;

      wordList[pos] = '#$newViewIndex|${object.name}';
    }

    object.views.removeAt(delViewIndex);
    return true;
  }

  void _addAnswer([String? text]) {
    final textConstructorData = TextConstructorData(
      text    : text ?? _constructor.panelController.text,
      styles  : _textConstructorData.styles,
      objects : _textConstructorData.objects,
      btnKeyboard: false,
      btnClear: false,
    );

    final widgetKey = GlobalKey<TextConstructorWidgetState>();

    _answerList.add(AnswerTextConstructor(widgetKey, textConstructorData));
  }

  Widget _wordPanelDefaultDecorator(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
      child: child,
    );
  }
  Widget _basementPanelDefaultDecorator(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
      child: Column(
        children: [
          const Divider(
            color: Colors.black,
          ),
          child,
        ],
      ),
    );
  }

  String getResult() {
    _textConstructorData.text = _constructor.panelController.text;
    //_textConstructorData.basement = _constructor.basementController.; TODO надо получить текст описывающий подвал

    final jsonMap = _textConstructorData.toJson();

    final fieldDesc = _descMap["options"]!;
    for (var field in fieldDesc.subFields!.keys) {
      final value = _jsonMap[field];
      if (value == null) continue;
      jsonMap[field] = value;
    }

    final answerList = <String>[];

    for (var answer in _answerList) {
      if (answer.key.currentState != null) {
        answerList.add(answer.key.currentState!.panelController.text);
      } else {
        answerList.add(answer.textConstructorData.text);
      }
    }

    jsonMap[JrfTextConstructor.answerList] = answerList;

    return jsonEncode(jsonMap);
  }

  Future<void> _returnResult() async {
    final result = getResult();

    String filename;

    final baseName = path_util.basenameWithoutExtension(widget.filename);
    if (baseName == 'new') {
      if (_textConstructorData.text.isEmpty) {
        widget.resultCallback.call(widget.filename, null);
        return;
      }

      String newFilename = '';

      final dlgResult = await simpleDialog(
          context: context,
          title: const Text('Введите имя для нового файла'),
          content: StatefulBuilder(builder: (context, setState) {
            return TextField(
              onChanged: (value){
                newFilename = value;
              },
            );
          })
      )??false;
      if (!dlgResult) return;

      filename = '${path_util.basenameWithoutExtension(newFilename)}${path_util.extension(widget.filename)}';
      final fileDir = path_util.dirname(widget.filename);
      if (fileDir.isNotEmpty && fileDir != '.') {
        filename = path_util.join(fileDir, filename);
      }
    } else {
      filename = widget.filename;
    }

    widget.resultCallback.call(filename, result);
  }
}
