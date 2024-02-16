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

class TextConstructorEditorPage extends StatefulWidget {
  const TextConstructorEditorPage({Key? key}) : super(key: key);

  @override
  State<TextConstructorEditorPage> createState() => _TextConstructorEditorPageState();
}

class AnswerTextConstructor {
  final GlobalKey<TextConstructorWidgetState> key;
  final TextConstructorData textConstructorData;
  bool viewOnly = true;
  AnswerTextConstructor(this.key, this.textConstructorData);
}

class _TextConstructorEditorPageState extends State<TextConstructorEditorPage> {
  late Color _panelColor;
  
  late Map<String, dynamic> _json;
  final Map<String, dynamic> _styleJson = {};

  late Map<String, FieldDesc> _descMap;

  final _rootPath = '';

  final _scrollController   = ScrollController();

  final TextConstructorData _textConstructorData = TextConstructorData.fromMap(testTextConstructorJson);
  final _constructorKey = GlobalKey<TextConstructorWidgetState>();
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

  @override
  void initState() {
    super.initState();
    
    _panelColor = Colors.grey.shade200;

    _json = <String, dynamic>{};

    _descMap = loadDescFromMap(textConstructorDescJson);

    _styleJson[JrfTextConstructor.styles] = _convertStyleListIn(_textConstructorData.styles);
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
        title: const Text('Конструктор текстов'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                _startTest();
              },
              icon: const Icon(Icons.ac_unit)
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
        _objectEditor(),
        Container(height: 6),
        _stylePanel(),
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
                            _answersPanelKey.currentState?.setState((){});
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

  Widget _optionsPanel() {
    return Container(
      color: _panelColor,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: TextConstructorOptionsWidget(json: _json, path: _rootPath, fieldDesc: _descMap["options"]!),
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
            final object = _constructor.textConstructorData.objects.firstWhere((object) => object.name == _selLabelInfo!.objectName);
            final viewIndex = _selLabelInfo!.viewIndex;
            final viewInfo = object.views[viewIndex];
            _selStyleIndex = viewInfo.styleIndex;
            _selStyleInfo  = _constructor.textConstructorData.styles[_selStyleIndex];
            _stylePanelKey.currentState?.setState(() {});
          }

          _objectEditorKey.currentState?.setState(() {});
        }
      },
    );
  }

  Widget _objectEditor() {
    return StatefulBuilder(
      key: _objectEditorKey,
      builder: (context, setState) {

        if (_selPos < 0) return Container();

        WordObject? object;

        if (_selLabelInfo!.isObject) {
          object = _constructor.getWordObject(_selLabelInfo!.objectName);
        }

        final title = Row(children: [
          _constructor.labelWidget(context, _selLabel, DragBoxSpec.none),

          if (object == null || _objectExpanded) ...[
            Expanded(child: Container()),

            IconButton(
                onPressed: (){
                  if (object != null){
                    object.views.add(ViewInfo(''));
                  } else {
                    _replaceWordToObject();
                    _objectExpanded = true;
                    _constructorKey.currentState?.setState(() {});
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

            final styleItems = <DropdownMenuItem<int>>[];

            styleItems.add(DropdownMenuItem<int>(
              value: -1,
              child: _constructor.getObjectViewWidget(context,
                  objectName : object.name,
                  label      : outStr,
                  styleIndex : -1
              ),
            ));

            for (int styleIndex = 0; styleIndex < _constructor.textConstructorData.styles.length; styleIndex ++) {
              styleItems.add(DropdownMenuItem<int>(
                value: styleIndex,
                child: _constructor.getObjectViewWidget(context,
                    objectName : object.name,
                    label      : outStr,
                    styleIndex : styleIndex
                ),
              ));
            }


            children.add(Row(
              children: [
                Expanded(
                  child: DkExpansionTile(
                    title: Row(
                      children: [
                        _constructor.getObjectViewWidget(context,
                            objectName: object.name,
                            viewInfo: viewInfo
                        ),

                        Expanded(child: Container()),

                        IconButton(
                          onPressed: () async {
                            if (! await _deleteObjectView(object!, viewIndex)) return;
                            setState((){});
                            _constructorKey.currentState?.setState(() {});
                          },
                          icon: const Icon(Icons.delete, color: Colors.blue),
                        )
                      ],
                    ),
                    childrenPadding: const EdgeInsets.only(left: 40, right: 16),
                    children: [

                      _paramLabel(
                        title: 'Стиль',
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                              value: styleIndex,
                              items: styleItems,
                              onChanged: (value) {
                                if (value == null) return;
                                object!.views[viewIndex] = ViewInfo.formComponents(value, menuText, outStr);
                                setState((){});
                                _constructorKey.currentState?.setState(() {});
                              }
                          ),
                        )
                      ),

                      // Текст
                      _paramLabel(
                        title: 'Текст',
                        child: TextFormField(
                          initialValue: outStr,
                          onFieldSubmitted: (text){
                            object!.views[viewIndex] = ViewInfo.formComponents(styleIndex, menuText, text);
                            setState((){});
                            _constructorKey.currentState?.setState(() {});
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
                                  object!.views[viewIndex] = ViewInfo.formComponents(styleIndex, menuText, outStr);
                                  setState((){});
                                  _constructorKey.currentState?.setState(() {});
                                }
                            ),

                            if (menuSwitchValue) ...[
                              Expanded(
                                child: TextFormField(
                                  initialValue: outStr,
                                  onFieldSubmitted: (text){
                                    object!.views[viewIndex] = ViewInfo.formComponents(styleIndex, text, outStr);
                                    setState((){});
                                    _constructorKey.currentState?.setState(() {});
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
        return DkExpansionTile(
          title: Row(
            children: [
              const Expanded(child: Text('Стили')),
              if (_styleExpanded) ...[
                IconButton(
                    onPressed: _selStyleInfo == null ? null : () async {
                      if (! await _deleteSelStyle()) return;
                      _stylePanelKey.currentState?.setState(() {});
                      _constructorKey.currentState?.setState(() {});
                      _objectEditorKey.currentState?.setState(() {});
                    },
                    icon: const Icon(Icons.delete)
                ),

                IconButton(
                    onPressed: (){
                      _addStyleNew();
                      _stylePanelKey.currentState?.setState(() {});
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

          collapsedBackgroundColor: _panelColor,
          backgroundColor: _panelColor,

          children: [
            Row(
              children: [
                Expanded(flex: 1, child: _styleList()),
                Expanded(flex: 2, child: _selStyleTuner(_selStyleInfo.toString()))
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

        for(int styleIndex = 0; styleIndex < _constructor.textConstructorData.styles.length; styleIndex ++) {
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
                _selStyleInfo = _constructor.textConstructorData.styles[_selStyleIndex];
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

  Widget _selStyleTuner(String styleStr) {
    return TextConstructorWordStyleWidget(
      styleStr: styleStr,
      fieldDesc: _descMap["style"]!,
      onChange: (newStyleStr){
        _selStyleInfo = StyleInfo.fromStyleStr(newStyleStr) ;
        _constructor.textConstructorData.styles[_selStyleIndex] = _selStyleInfo!;
        _styleListKey.currentState?.setState(() {});
        _constructor.setState(() {});
      },
    );
  }

  void _addStyleNew() {
    _constructor.textConstructorData.styles.add(StyleInfo());
  }

  Future<bool> _deleteSelStyle() async {
    final dlgResult = await simpleDialog(
      context: context,
      title: const Text('Удалить стиль?'),
      barrierDismissible: true
    )?? false;
    if (!dlgResult) return false;

    for (var object in _constructor.textConstructorData.objects) {
      for (int viewIndex = 0; viewIndex < object.views.length; viewIndex ++) {
        final view = object.views[viewIndex];
        if (view.styleIndex == _selStyleIndex) {
          final newView = ViewInfo.formComponents(-1, view.menuText, view.text);
          object.views[viewIndex] = newView;
        }
      }
    }

    _constructor.textConstructorData.styles.removeAt(_selStyleIndex);

    return true;
  }

  List<Map<String, dynamic>> _convertStyleListIn(List<StyleInfo> styleList) {
    final result = <Map<String, dynamic>>[];

    for (var style in styleList) {
      result.add(style.toMap());
    }

    return result;
  }

  void _replaceWordToObject() {
    final pos = _constructor.panelController.getFocusPos();
    var word =  _constructor.panelController.getWord(pos);
    word = LabelInfo.unSelect(word);

    _constructor.textConstructorData.objects.add(
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

    _constructor.textConstructorData.objects.remove(object);

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

  void _addAnswer() {
    final textConstructorData = TextConstructorData(
      text    : _constructor.panelController.text,
      styles  : _constructor.textConstructorData.styles,
      objects : _constructor.textConstructorData.objects,
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

  void _startTest() {

  }


}
