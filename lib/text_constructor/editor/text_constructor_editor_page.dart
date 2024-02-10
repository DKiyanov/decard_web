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

class _TextConstructorEditorPageState extends State<TextConstructorEditorPage> {
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
  String _selStyleStr = '';
  int    _selStyleIndex = -1;

  @override
  void initState() {
    super.initState();

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
        _stylePanel(),
        TextConstructorOptionsWidget(json: _json, path: _rootPath, fieldDesc: _descMap["options"]!),
      ],
    );
  }

  Widget _textConstructor() {
    return TextConstructorWidget(
      key             : _constructorKey,
      textConstructor : _textConstructorData,
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
            final viewIndex = _selLabelInfo!.viewIndex??object.viewIndex;
            final viewStr = object.views[viewIndex];
            final viewInfo = ViewInfo(viewStr);
            _selStyleIndex = viewInfo.styleIndex;
            _selStyleStr   = _constructor.textConstructorData.styles[_selStyleIndex];
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
                    object.views.add('');
                    setState((){});
                  } else {
                    _replaceWordToObject();
                    _selLabel = '#${_selLabelInfo!.word}';
                    _objectExpanded = true;
                    setState((){});
                  }
                },
                icon: const Icon(Icons.add)
            ),
          ],

        ]);

        if (object != null) {
          final children = <Widget>[];
          for (int viewIndex = 0; viewIndex < object.views.length; viewIndex ++) {
            final viewStr = object.views[viewIndex];
            final viewInfo = ViewInfo(viewStr);

            String outStr     = viewInfo.text;
            String menuText   = viewInfo.menuText;
            int    styleIndex = viewInfo.styleIndex;

            if (outStr.isEmpty) {
              outStr = object.name;
            }

            bool menuSwitchValue = menuText != ViewInfo.menuSkipText;

            final styleItems = <DropdownMenuItem<int>>[];

            for (int styleIndex = -1; styleIndex < _constructor.textConstructorData.styles.length; styleIndex ++) {
              styleItems.add(DropdownMenuItem<int>(
                value: styleIndex,
                child: _constructor.getObjectViewWidget(context,
                    objectName: object.name,
                    label     : outStr,
                    styleIndex: styleIndex
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
                            viewStr: viewStr
                        ),

                        Expanded(child: Container()),

                        IconButton(
                          onPressed: (){
                            _deleteObjectView(object!, viewIndex);
                            _selLabel = object.name;
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
                                object!.views[viewIndex] = ViewInfo.getViewStr(value, menuText, outStr);
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
                            object!.views[viewIndex] = ViewInfo.getViewStr(styleIndex, menuText, text);
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
                                  object!.views[viewIndex] = ViewInfo.getViewStr(styleIndex, menuText, outStr);
                                  setState((){});
                                  _constructorKey.currentState?.setState(() {});
                                }
                            ),

                            if (menuSwitchValue) ...[
                              Expanded(
                                child: TextFormField(
                                  initialValue: outStr,
                                  onFieldSubmitted: (text){
                                    object!.views[viewIndex] = ViewInfo.getViewStr(styleIndex, text, outStr);
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
            children: children,
            onExpansionChanged: (expanded){
              _objectExpanded = expanded;
              setState((){});
            },
          );
        }


        return ListTile(title: title);
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
          title: const Text('Стили'),
          children: [
            Row(
              children: [
                Expanded(flex: 1, child: _styleList()),
                Expanded(flex: 2, child: _selStyleTuner(_selStyleStr))
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
                _selStyleStr = _constructor.textConstructorData.styles[_selStyleIndex];
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
    if (styleStr.isEmpty) return Container();

    return TextConstructorWordStyleWidget(
      styleStr: styleStr,
      fieldDesc: _descMap["style"]!,
      onChange: (newStyleStr){
        _selStyleStr = newStyleStr;
        _constructor.textConstructorData.styles[_selStyleIndex] = newStyleStr;
        _styleListKey.currentState?.setState(() {});
        _constructor.setState(() {});
      },
    );
  }

  List<Map<String, dynamic>> _convertStyleListIn(List<dynamic> styleList) {
    final result = <Map<String, dynamic>>[];

    for (var style in styleList) {
      result.add(_convertStyleIn(style as String));
    }

    return result;
  }

  Map<String, dynamic> _convertStyleIn(String styleStr) {
    final styleInfo = StyleInfo.fromStyleStr(styleStr);
    return styleInfo.toMap();
  }

  void _replaceWordToObject() {
    final pos = _constructor.panelController.getFocusPos();
    var word =  _constructor.panelController.getWord(pos);
    word = LabelInfo.unSelect(word);

    _constructor.textConstructorData.objects.add(
        WordObject(name: word, viewIndex: 0, nonRemovable: false, views: [''])
    );

    _constructor.panelController.deleteWord(pos);
    _constructor.panelController.insertWord(pos, '#$word');

    _constructor.panelController.setFocusPos(pos);

    _constructor.panelController.refreshPanel();
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

      final viewIndex = labelInfo.viewIndex??object.viewIndex;

      var word = object.name;
      if (viewIndex >= 0) {
        final viewStr = object.views[viewIndex];
        if (viewStr.isNotEmpty) {
          word = viewStr.split('|').last;
        }
      }

      _constructor.panelController.deleteWord(pos);
      _constructor.panelController.insertWord(pos, word);
    }

    _constructor.textConstructorData.objects.remove(object);

    _constructor.panelController.setFocusPos(focusPos);
    //constructor.panelController.refreshPanel();
  }

  void _deleteObjectView(WordObject object, int delViewIndex) async {
    final dlgResult = await simpleDialog(
      context: context,
      title: const Text('Предупреждение'),
      content: const Text('Удалить эту настройку визуализации?')
    )??false;

    if (!dlgResult) return;

    if (object.views.length == 1) {
      _replaceObjectToWord(object);
      return;
    }

    final wordList = _constructor.panelController.getWordList();
    final wordListLength = wordList.length;

    for (int pos = 0; pos < wordListLength; pos ++) {
      final label = wordList[pos];
      final labelInfo = LabelInfo(label);

      if (!labelInfo.isObject) continue;
      if (labelInfo.objectName != object.name) continue;

      var viewIndex = labelInfo.viewIndex??object.viewIndex;

      if (viewIndex <= delViewIndex) continue;

      final newViewIndex = viewIndex - 1;

      wordList[pos] = '#$newViewIndex|${object.name}';
    }

    object.views.removeAt(delViewIndex);
  }

  void _startTest() {
    //_textConstructorData.styles[2] = 'ccg,bcb';
    //constructor.panelController.insertText(1, '#1|символ');

    final pos = _constructor.panelController.getFocusPos();
    var word = _constructor.panelController.getWord(pos);
    word = LabelInfo.unSelect(word);

    _constructor.textConstructorData.objects.add(
      WordObject(name: word, viewIndex: 0, nonRemovable: false, views: [
        '0|$word',
        '1|$word',
        '2|$word',
      ])
    );

    _constructor.panelController.deleteWord(pos);
    _constructor.panelController.insertWord(pos, '#$word');

    _constructor.panelController.refreshPanel();
  }


}
