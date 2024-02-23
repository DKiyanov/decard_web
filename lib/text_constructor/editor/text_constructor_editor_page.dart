import 'dart:convert';
import 'dart:math' as math;

import 'package:decard_web/dk_expansion_tile.dart';
import 'package:decard_web/text_constructor/drag_box_widget.dart';
import 'package:decard_web/text_constructor/editor/text_constructor_options_widget.dart';
import 'package:flutter/material.dart';

import '../../card_model.dart';
import '../../pack_editor/pack_editor.dart';
import '../../pack_editor/pack_file_source_editor.dart';
import '../../simple_dialog.dart';
import '../text_constructor.dart';
import '../word_grid.dart';
import 'text_constructor_desc_json.dart';
import 'text_constructor_word_style_widget.dart';

import '../../pack_editor/pack_widgets.dart';
import '../word_panel_model.dart';

class AnswerTextConstructor {
  GlobalKey<TextConstructorWidgetState> key;
  final TextConstructorData textConstructorData;
  bool viewOnly = true;
  AnswerTextConstructor(this.key, this.textConstructorData);
}

class TextConstructorEditorPage extends StatefulWidget {
  final String filename;
  final String jsonStr;
  final String? Function(String fileName) onPrepareFileUrl;
  final void Function(String fileName, String? jsonStr) resultCallback;
  const TextConstructorEditorPage({
    required this.filename,
    required this.jsonStr,
    required this.onPrepareFileUrl,
    required this.resultCallback,

    Key? key
  }) : super(key: key);

  @override
  State<TextConstructorEditorPage> createState() => _TextConstructorEditorPageState();
}

class _ObjectControllers {
  final objectTextInputController = TextEditingController();
  final menuTextInputController = TextEditingController();
  final imageInputController = TextEditingController();
  final imageInputFocus = FocusNode();
  final audioInputController = TextEditingController();
  final audioInputFocus = FocusNode();

  _ObjectControllers(PackEditorState packEditor) {
    imageInputFocus.addListener(() {
      if (imageInputFocus.hasFocus && imageInputController.text.isNotEmpty) {
        packEditor.setSelectedFileSource(imageInputController.text);
      }
      packEditor.setNeedFileSourceController(imageInputController, imageInputFocus.hasFocus, FileExt.imageExtList);
    });

    audioInputFocus.addListener(() {
      if (audioInputFocus.hasFocus && audioInputController.text.isNotEmpty) {
        packEditor.setSelectedFileSource(audioInputController.text);
      }
      packEditor.setNeedFileSourceController(audioInputController, audioInputFocus.hasFocus, FileExt.audioExtList);
    });
  }

  void dispose() {
    imageInputController.dispose();
    imageInputFocus.dispose();
    audioInputController.dispose();
    audioInputFocus.dispose();
  }}

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

  final _basementTunerPanelKey = GlobalKey();
  bool _basementTunerExpanded = false;
  final _basementWordList = <WordGridInfo>[];
  int _selBasmentIndex = -1;

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

  final _controllersList = <_ObjectControllers>[];
  
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
    for (var objectControllers in _controllersList) {
      objectControllers.dispose();
    }
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
        _basementTunerPanel(),
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
                  onPrepareFileUrl: widget.onPrepareFileUrl,
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
      onChangeBasement: () {
        _getBasementList();
      },
      onTapLabel: (pos, label) {
        label = LabelInfo.unSelect(label);

        if (_selPos == pos && _selLabel == label) {
          _selPos = -1;
        } else {
          _selPos   = pos;
        }

        _selectLabel(label);
      },
      onChangeHeight: (newHeight) {
        _shake();
        _getBasementList();
      },
      onPrepareFileUrl: widget.onPrepareFileUrl,
      onBasementTap: (boxInfo, boxInfoIndex, pos, globalPos) {
        _constructor.basementController!.setFocus(boxInfoIndex);
        _selectLabel(boxInfo.data.ext.label);
        _selBasmentIndex = boxInfoIndex;
        _basementTunerPanelKey.currentState?.setState(() {});
      },
    );
  }

  void _getBasementList() {
    _basementWordList.clear();
    _basementWordList.addAll(_constructor.basementController!.getWordList()??[]);
    _basementTunerPanelKey.currentState?.setState(() {});
  }

  void _selectLabel(String label) {
    if (_selLabel == label) return;
    _selLabel = label;

    if (_selLabel.isEmpty) {
      _selLabelInfo = null;
      _selPos = -1;
      _objectExpanded = false;
      _stylePanelKey.currentState?.setState(() {});
      _objectEditorKey.currentState?.setState(() {});
      return;
    }

    _selLabelInfo  =  LabelInfo(_selLabel);
    if (_selLabelInfo!.isObject){
      final object = _textConstructorData.objects.firstWhere((object) => object.name == _selLabelInfo!.objectName);
      final viewIndex = _selLabelInfo!.viewIndex;
      final viewInfo = object.views[viewIndex];
      _selStyleIndex = viewInfo.styleIndex;
      if (_selStyleIndex >= 0) {
        _selStyleInfo = _textConstructorData.styles[_selStyleIndex];
      }
      _stylePanelKey.currentState?.setState(() {});
    }

    _objectEditorKey.currentState?.setState(() {});
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

        if (_selLabel.isEmpty) {
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

          IconButton(
              onPressed: () {
                _basementWordList.add(WordGridInfo(label: _selLabel, isGroup: false, visible: true));
                _basementTunerExpanded = true;
                _constructor.basementController!.setWordList(_basementWordList);
              },
              icon: Transform.rotate(
                angle: math.pi,
                child: const Icon(Icons.upload),
              ),
          ),

          IconButton(
              onPressed: () {
                _constructor.panelController.appendWord(_selLabel);
                _constructor.refresh();
              },
              icon: const Icon(Icons.upload)
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

            if (_controllersList.length == viewIndex) {
              final packEditor = PackEditor.of(context)!;
              _controllersList.add(_ObjectControllers(packEditor));
            }

            final objectControllers = _controllersList[viewIndex];

            String str        = viewInfo.text;
            String menuText   = viewInfo.menuText;
            int    styleIndex = viewInfo.styleIndex;

            if (str.isEmpty) {
              str = object.name;
            }

            final textInfo = TextInfo(str);

            if (menuText.isEmpty) {
              menuText = textInfo.text;
            }

            objectControllers.objectTextInputController.text = textInfo.text;
            objectControllers.menuTextInputController.text   = menuText;
            objectControllers.imageInputController.text      = textInfo.image;
            objectControllers.audioInputController.text      = textInfo.audio;

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
                          outStr: textInfo.string,
                          styleIndex: styleIndex,
                          onChange: (newStyleIndex) {
                            if (newStyleIndex == null) return;
                            object!.views[viewIndex] = ViewInfo.fromComponents(newStyleIndex, menuText, textInfo.string);
                            setState((){});
                            _constructorKey.currentState?.refresh();
                          }
                        ),
                      ),

                      // Текст
                      _paramLabel(
                        title: 'Текст',
                        child: TextField(
                          controller: objectControllers.objectTextInputController,
                          onSubmitted: (newText){
                            object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, menuText, textInfo.getStringWith(text: newText));
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
                                object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, menuText, textInfo.string);
                                setState((){});
                                _constructorKey.currentState?.refresh();
                              }
                          ),

                          if (menuSwitchValue) ...[
                            Expanded(
                              child: TextField(
                                controller: objectControllers.menuTextInputController,
                                //initialValue: outStr,
                                onSubmitted: (newMenuText){
                                  object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, newMenuText, textInfo.string);
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

                      //Путь к файлу картики
                      _paramLabel(
                        title: 'Картинка',
                        child: TextField(
                          controller: objectControllers.imageInputController,
                          focusNode: objectControllers.imageInputFocus,
                          onSubmitted: (newImage){
                            object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, menuText, textInfo.getStringWith(image: newImage));
                            setState((){});

                            _constructorKey.currentState?.refresh();
                            Future.delayed(const Duration(milliseconds: 20), (){ // needs additional refresh when image changed
                              _constructorKey.currentState?.refresh();
                            });
                          },
                        )
                      ),

                      //Путь к аудио файлу
                      _paramLabel(
                          title: 'Аудио файл',
                          child: TextField(
                            controller: objectControllers.audioInputController,
                            focusNode: objectControllers.audioInputFocus,
                            onSubmitted: (newAudio){
                              object!.views[viewIndex] = ViewInfo.fromComponents(styleIndex, menuText, textInfo.getStringWith(audio: newAudio));
                              setState((){});
                              _constructorKey.currentState?.refresh();
                            },
                          )
                      ),
                      
                      Container(height: 4),

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

  Widget _basementTunerPanel() {
    if (_constructorKey.currentState == null) return Container();

    return StatefulBuilder(
      key: _basementTunerPanelKey,
      builder: (context, setState) {
        if (_basementWordList.isEmpty) {
          return ListTile(
            title: const Text('Настройка подвала (пусто)'),
            contentPadding: const EdgeInsets.only(left: 16, right: 4),
            tileColor: _panelColor,
          );
        }

        return DkExpansionTile(
          title: Row(
            children: [
              const Expanded(child: Text('Настройка подвала')),
              if (_basementTunerExpanded) ...[
                IconButton(
                    onPressed: () {
                      _basementAddWordFromKeyboard();
                    },
                    icon: const Icon(Icons.keyboard_alt_outlined)
                ),
                IconButton(
                    onPressed: () async {
                      if (_selBasmentIndex < 0) return;

                      final dlgResult = await simpleDialog(
                        context: context,
                        title: const Text('Удалить выбанное слово из подвала?'),
                        barrierDismissible: true,
                      ) ?? false;
                      if (!dlgResult) return;

                      _basementWordList.removeAt(_selBasmentIndex);
                      _constructor.basementController!.setWordList(_basementWordList);
                      _selBasmentIndex = -1;
                      setState((){});
                      _constructorKey.currentState?.setState(() {});
                    },
                    icon: const Icon(Icons.delete)
                ),
              ]
            ],
          ),
          initiallyExpanded: false,

          collapsedBackgroundColor: _panelColor,
          backgroundColor: _panelColor,

          onExpansionChanged: (expanded) {
            _basementTunerExpanded = expanded;
            setState(() {});
          },

          children: [
            _basementItemsList()
          ],
        );

      }
    );
  }

  Widget _basementItemsList() {
    final screenHeight = MediaQuery.of(context).size.height;
    final children = <Widget>[];

    for (int index = 0; index < _basementWordList.length; index ++) {
      final wordInfo = _basementWordList[index];

      if (wordInfo.isGroup) {
        children.add(
          Padding(
            key: ValueKey(index),
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text(wordInfo.label, style: Theme.of(context).textTheme.headline6)),
          )
        );
        continue;
      }

      children.add(
        Padding(
          key: ValueKey(index),

          padding: const EdgeInsets.only(left: 16, right: 4, bottom: 4),
          child: Container(
            color: _selBasmentIndex != index ? null : Colors.yellow,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _constructor.labelWidget(context, wordInfo.label, DragBoxSpec.none),
                    ),
                    onTap: () {
                      _selBasmentIndex = index;
                      _constructor.basementController!.setFocus(index);
                      _basementTunerPanelKey.currentState?.setState(() {});
                    },
                  ),
                ),
                Checkbox(
                  value: wordInfo.visible,
                  onChanged: (newVisible) {
                    if (newVisible == null) return;
                    wordInfo.visible = newVisible;

                    final visibleWords = _basementWordList.where((wordInfo) => wordInfo.visible).map((wordInfo) => wordInfo.label).toList().join('\n');

                    _constructor.basementController!.setVisibleWords(visibleWords);

                    _getBasementList();
                  }
                )
              ]
            ),
          ),
        )
      );
    }

    return LimitedBox(
      maxHeight: screenHeight * 2 / 3,
      child: Scrollbar(
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ReorderableListView(
              shrinkWrap: true,
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _basementWordList.removeAt(oldIndex);
                _basementWordList.insert(newIndex, item);
                _selBasmentIndex = -1;

                _basementTunerPanelKey.currentState?.setState(() {});
                _constructor.basementController!.setWordList(_basementWordList);

              },
              children: children
          ),
        ),
      ),
    );
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

  void _basementAddWordFromKeyboard() async {
    String text = '';
    bool isGroup = false;

    final dlgResult = await simpleDialog(
      context: context,
      title: const Text('Добавление слова или группы в подвал'),
      content: StatefulBuilder(builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Текст')),
                Expanded(
                  child: TextField(
                    onChanged: (value){
                      text = value;
                    },
                  ),
                ),
              ],
            ),

            Row(children: [
              const Expanded(child: Text('Это группа')),
              Switch(
                value: isGroup,
                onChanged: (newValue) {
                  isGroup = newValue;
                  setState((){});
                }
              )
            ])
          ],
        );
      })
    ) ?? false;

    if (!dlgResult) return;

    _basementWordList.add(WordGridInfo(label: text, isGroup: isGroup, visible: true));
    _constructor.basementController!.setWordList(_basementWordList);
  }

  String getResult() {
    _textConstructorData.text = _constructor.panelController.text;
    _textConstructorData.basement = _constructor.basementController!.getText()!;

    if (_textConstructorData.text.isEmpty &&
        _textConstructorData.basement.isEmpty &&
        _textConstructorData.objects.isEmpty &&
        _textConstructorData.styles.isEmpty &&
        _answerList.isEmpty
    ) return '';

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
    SourceFileEditor.returnResult(widget.filename, getResult(), context, widget.resultCallback);
  }
}
