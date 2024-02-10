import 'dart:math';

import 'package:collection/collection.dart';
import '../media_widgets.dart';
import 'word_grid.dart';
import 'word_panel.dart';
import 'word_panel_model.dart';
import 'package:flutter/material.dart';

import 'package:simple_events/simple_events.dart';

import '../audio_button.dart';
import '../common.dart';
import 'drag_box_widget.dart';

class LabelInfo {
  static const String selectPrefix = '\$';

  final String label;
  late bool isSelected;
  late bool isObject;
  late int? viewIndex;
  late String _word;

  bool get isText => !isObject;

  String get word {
    if (isObject) return '#$_word';
    return _word;
  }

  String get objectName {
    assert(isObject == true);
    return _word;
  }

  LabelInfo(this.label) {
    String str = label;
    if (str.startsWith(selectPrefix)) {
      isSelected = true;
      str = str.substring(1);
    } else {
      isSelected = false;
    }

    if (str.startsWith('#')){
      isObject = true;
      if (str.substring(2,3) == '|') {
        _word = label.substring(3);
        viewIndex = int.parse(label.substring(1,2));
      } else {
        _word = label.substring(1);
        viewIndex = null;
      }
    } else {
      isObject = false;
      _word = str;
    }
  }

  static String unSelect(String label) {
    if (label.startsWith(selectPrefix)) return label.substring(1);
    return label;
  }
}

class ViewInfo {
  static const String menuSkipText = '-';

  final String viewStr;
  late  int    styleIndex;
  late  String menuText;
  late  String text;

  bool get skipMenu => menuText == '-';

  ViewInfo(this.viewStr){
    final viewSplit1 = viewStr.split('|');
    if (viewSplit1.length == 1) {
      text       = viewSplit1[0];
      styleIndex = -1;
      menuText   = '';
    } else {
      text = viewSplit1[1];

      final viewSplit2 = viewSplit1[0].split('/');
      final styleIndexStr = viewSplit2[0];
      if (styleIndexStr.isNotEmpty) {
        styleIndex = int.parse(styleIndexStr);
      } else {
        styleIndex = -1;
      }
      if (viewSplit2.length > 1) {
        menuText = viewSplit2[1];
      } else {
        menuText = '';
      }
    }
  }

  static String getViewStr(int styleIndex, String menuText, String text){
    return '$styleIndex/$menuText|$text';
  }
}

class StyleInfoField{
  static const charColor       = "charColor";
  static const backgroundColor = "backgroundColor";
  static const frameColor      = "frameColor";
  static const fontBold        = "fontBold";
  static const fontItalic      = "fontItalic";
  static const linePos         = "linePos";
  static const lineStyle       = "lineStyle";
  static const lineColor       = "lineColor";
}

class StyleInfo {
  static const Map<String, Color> colorKeyMap = {
    'r' : Colors.red,
    'g' : Colors.green,
    'b' : Colors.blue,
    'y' : Colors.yellow,
    'o' : Colors.orange,
    'd' : Colors.black,
    'w' : Colors.white,
  };

  static const Map<String, String> colorNameMap = {
    'r' : 'red',
    'g' : 'green',
    'b' : 'blue',
    'y' : 'yellow',
    'o' : 'orange',
    'd' : 'black',
    'w' : 'white',
  };

  static const Map<String, TextDecoration> linePosNameMap = {
    'underline'   : TextDecoration.underline,
    'lineThrough' : TextDecoration.lineThrough,
  };

  static const Map<String, TextDecoration> _linePosKeyMap = {
    'l' : TextDecoration.underline,
    'd' : TextDecoration.lineThrough,
  };

  static const Map<String, TextDecorationStyle> _lineStyleKeyMap = {
    '_' : TextDecorationStyle.solid,
    '~' : TextDecorationStyle.wavy,
    '=' : TextDecorationStyle.double,
    '-' : TextDecorationStyle.dashed,
    '.' : TextDecorationStyle.dotted,
  };

  final bool   fontBold;
  final bool   fontItalic;
  final Color? charColor;
  final Color? backgroundColor;
  final Color? frameColor;
  final TextDecoration?      linePos;
  final TextDecorationStyle? lineStyle;
  final Color?               lineColor;

  StyleInfo({
    this.fontBold = false,
    this.fontItalic = false,
    this.charColor,
    this.backgroundColor,
    this.frameColor,
    this.linePos,
    this.lineStyle,
    this.lineColor,
  });

  factory StyleInfo.fromStyleStr(String styleStr) {
    bool   fontBold = false;
    bool   fontItalic = false;
    Color? charColor;
    Color? backgroundColor;
    Color? frameColor;

    TextDecoration?      linePos;
    TextDecorationStyle? lineStyle;
    Color?               lineColor;

    final subStyleList = styleStr.split(',');

    for (var subStyle in subStyleList) {
      final subStyleStr = subStyle.trim().toLowerCase();
      final subStyleLen = subStyleStr.length;

      if (subStyleLen == 1) {
        if (subStyleStr == 'b') {
          fontBold = true;
        }
        if (subStyleStr == 'i') {
          fontItalic = true;
        }
      }

      if (subStyleLen == 3) {
        final formatCh = subStyleStr.substring(0,1);
        final formatId = subStyleStr.substring(0,2);
        final colorKey = subStyleStr.substring(2,3);
        final color = colorKeyMap[colorKey];

        if (formatId == 'cc') {
          charColor = color;
        }
        if (formatId == 'bc') {
          backgroundColor = color;
        }
        if (formatId == 'fc') {
          frameColor = color;
        }

        if (formatCh == 'l') {
          linePos = TextDecoration.underline;
          final lineStyleStr = formatId.substring(1,2);
          lineStyle = _lineStyleKeyMap[lineStyleStr] ;
          lineColor  = color;
        }

        if (formatCh == 'd') {
          linePos = TextDecoration.lineThrough;
          final lineStyleStr = formatId.substring(1,2);
          lineStyle = _lineStyleKeyMap[lineStyleStr] ;
          lineColor  = color;
        }
      }
    }

    return StyleInfo(
        fontBold         : fontBold,
        fontItalic       : fontItalic,
        charColor        : charColor,
        backgroundColor  : backgroundColor,
        frameColor       : frameColor,
        linePos          : linePos,
        lineStyle        : lineStyle,
        lineColor        : lineColor,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      StyleInfoField.charColor       : colorNameMap[_colorToColorKey(charColor)],
      StyleInfoField.backgroundColor : colorNameMap[_colorToColorKey(backgroundColor)],
      StyleInfoField.frameColor      : colorNameMap[_colorToColorKey(frameColor)],
      StyleInfoField.fontBold        : fontBold,
      StyleInfoField.fontItalic      : fontItalic,
      StyleInfoField.linePos         : linePos?.toString().split('.').last,
      StyleInfoField.lineStyle       : lineStyle?.name,
      StyleInfoField.lineColor       : colorNameMap[_colorToColorKey(lineColor)],
    };

    return result;
  }

  factory StyleInfo.fromMap(Map<String, dynamic> map) {
    return StyleInfo(
      fontBold         : map[StyleInfoField.fontBold]??false,
      fontItalic       : map[StyleInfoField.fontItalic]??false,
      charColor        : colorNameToColor(map[StyleInfoField.charColor]),
      backgroundColor  : colorNameToColor(map[StyleInfoField.backgroundColor]),
      frameColor       : colorNameToColor(map[StyleInfoField.frameColor]),
      linePos          : linePosNameMap[map[StyleInfoField.linePos]],
      lineStyle        : TextDecorationStyle.values.firstWhereOrNull((lineStyle) => lineStyle.name == map[StyleInfoField.lineStyle]),
      lineColor        : colorNameToColor(map[StyleInfoField.lineColor]),
    );
  }

  static Color colorNameToColor(String? colorName) {
    if (colorName == null) return Colors.transparent;
    final colorKey = colorNameMap.entries.firstWhereOrNull((entry) => entry.value == colorName)?.key;
    if (colorKey == null) return Colors.transparent;
    return colorKeyMap[colorKey]!;
  }

  @override
  String toString() {
    final subStyleList = <String>[];

    if (fontBold) {
      subStyleList.add('b');
    }

    if (fontItalic) {
      subStyleList.add('i');
    }

    if (charColor != null) {
      subStyleList.add('cc${_colorToColorKey(charColor!)}');
    }

    if (backgroundColor != null) {
      subStyleList.add('bc${_colorToColorKey(backgroundColor!)}');
    }

    if (frameColor != null) {
      subStyleList.add('fc${_colorToColorKey(frameColor!)}');
    }

    if (linePos != null) {
      final linePosStr   = _linePosKeyMap.entries.firstWhereOrNull((entry) => entry.value == linePos)?.key;
      final lineStyleStr = _lineStyleKeyMap.entries.firstWhereOrNull((entry) => entry.value == lineStyle)?.key;
      final lineColorStr = _colorToColorKey(lineColor!);
      subStyleList.add('$linePosStr$lineStyleStr$lineColorStr');
    }


    return subStyleList.join(',');
  }

  String? _colorToColorKey(Color? color) {
    if (color == null) return null;
    return colorKeyMap.entries.firstWhereOrNull((entry) => entry.value == color)?.key;
  }
}

typedef RegisterAnswer = void Function(String answerValue, [List<String>? answerList]);
typedef PrepareFilePath = String Function(String fileName);

class TextConstructorWidget extends StatefulWidget {
  final TextConstructorData textConstructor;
  final RegisterAnswer? onRegisterAnswer;
  final PrepareFilePath? onPrepareFileUrl;
  final int? randomPercent;
  final void Function(int pos, String label)? onTapLabel;
  const TextConstructorWidget({required this.textConstructor, this.onRegisterAnswer, this.onPrepareFileUrl, this.randomPercent, this.onTapLabel, Key? key}) : super(key: key);

  @override
  State<TextConstructorWidget> createState() => TextConstructorWidgetState();
}

class _HistData {
  String panelStr;
  String basementStr;
  _HistData(this.panelStr, this.basementStr);
}

class _RandomDelWordResult {
  final String text;
  final String delWords;
  _RandomDelWordResult(this.text, this.delWords);
}

class TextConstructorWidgetState extends State<TextConstructorWidget> {
  late TextConstructorData textConstructorData;
  late WordPanelController panelController;
  late WordGridController  _basementController;

  final Color  _defaultTextColor  = Colors.white;
  late  double _fontSize;
  final Color  _borderColor      = Colors.black;
  final double _borderWidth      = 1.0;
  final Color  _tapInProcessBorderColor  = Colors.green;
  final Color  _focusBorderColor  = Colors.blue;
  final double _focusBorderWidth  = 2.0;
  final Color  _editPosColor      = Colors.blue;
  final Color  _insertPosColor    = Colors.green;
  final Color  _colorWordNormal   = Colors.grey;
  final Color  _colorWordCanDrop  = Colors.amber;
  final Color  _colorWordMove     = Colors.black12;
  final double _editPosWidth      = 10;
  final double _insertPosWidth    = 10;

  final _historyList = <_HistData>[];
  bool _historyRecordOn = true;
  int _historyPos = -1;

  final _toolBarRefresh = SimpleEvent();

  bool   _starting = true;
  double _panelHeight = 0.0;
  double _basementHeight = 0.0;

  final _panelKey = GlobalKey();
  final _basementKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    textConstructorData = widget.textConstructor; //TextConstructorData.fromMap(jsonDecode(textConstructorJson));
    _fontSize = textConstructorData.fontSize;

    var panelText = textConstructorData.text;
    var basementText = widget.textConstructor.basement;

    if (widget.randomPercent != null) {
      if (textConstructorData.randomMixWord) {
        panelText = _randomMixWord(panelText, widget.randomPercent!);
      }
      if (textConstructorData.randomDelWord) {
        final delResult = _randomDelWord(panelText, widget.randomPercent!);
        panelText = delResult.text;
        basementText = '$basementText ${delResult.delWords}';
      }
    }

    panelController = WordPanelController(
      text          : panelText,
      onChange      : _onChange,
      canMoveWord   : textConstructorData.canMoveWord,
      noCursor      : textConstructorData.noCursor,
      focusAsCursor : textConstructorData.focusAsCursor,
    );

    _basementController = WordGridController(basementText);
  }

  String _randomMixWord(String text, int percent) {
    final wordList = WordPanelController.textToWordList(text);
    final count = ( wordList.length * percent ) ~/ 100;
    final wordListLength = wordList.length;

    final random = Random();

    for ( var i = 0; i < count ; i++) {
      final delPos = random.nextInt(wordListLength);
      final word = wordList[delPos];
      wordList.removeAt(delPos);

      final insPos = random.nextInt(wordListLength);
      wordList.insert(insPos, word);
    }

    final result = WordPanelController.wordListToText(wordList);
    return result;
  }

  _RandomDelWordResult _randomDelWord(String text, int percent) {
    final wordList = WordPanelController.textToWordList(text);
    final count = ( wordList.length * percent ) ~/ 100;
    final wordListLength = wordList.length;
    final delWords = <String>[];

    final random = Random();

    for ( var i = 0; i < count ; i++) {
      final delPos = random.nextInt(wordListLength);
      final word = wordList[delPos];
      wordList.removeAt(delPos);
      delWords.add(word);
    }

    final newText = WordPanelController.wordListToText(wordList);
    final delWordsText = WordPanelController.wordListToText(delWords);

    return _RandomDelWordResult(newText, delWordsText);
  }

  void _onChange() {
    if (_starting) return;
    if (!_historyRecordOn) return;

    if (_historyPos >= 0) {
      _historyList.removeRange(_historyPos + 1, _historyList.length);
      _historyPos = -1;
    }

    final panelStr = panelController.text;
    if (_historyList.isNotEmpty && _historyList.last.panelStr == panelStr) {
      return;
    }

    final basementStr = _basementController.getVisibleWords();

    _historyList.add(_HistData(panelStr, basementStr));
    _toolBarRefresh.send();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        if (_starting) {
          setState(() {
            _starting = false;
            _onChange();
          });
        }
      });

      if (_starting) {
        return Offstage(
          child: _startBody(),
        );
      }

      return _body(viewportConstraints);
    });

  }

  Widget _body(BoxConstraints viewportConstraints) {
    if (_basementHeight == 0.0) {
      return Column(
        children: [

          _toolbar(),

          Container(height: 4),

          SizedBox(
            height: _panelHeight,
            child: _wordPanel()
          ),

          Offstage( child: SizedBox(
            height:  300,
            child: _basement(),
          )),
        ],
      );
    }

    return Column(
      children: [

        _toolbar(),

        Container(height: 4),

        SizedBox(
            height: _panelHeight,
            child: _wordPanel()
        ),

        const Divider(
          color: Colors.black,
        ),

        SizedBox(
          height:  _basementHeight,
          child: _basement(),
        ),

        Container(height: 4),
      ],
    );

  }

  Widget _startBody() {
    return Column(
      children: [

        SizedBox(
          height: 100,
          child: _wordPanel(),
        ),

        SizedBox(
            height: 100,
            child: _basement()
        ),

      ],
    );
  }

  Widget _wordPanel() {
    return WordPanel(
      key                : _panelKey,
      controller         : panelController,
      onDragBoxBuild     : _onDragBoxBuild,
      onDragBoxTap       : _onDragBoxTap,
      onDragBoxLongPress : _onDragBoxLongPress,
      onDoubleTap        : _onDragBoxLongPress,
      onChangeHeight     : (double newHeight) {
        final extHeight = newHeight + panelController.wordBoxHeight;
        if (_panelHeight != extHeight) {
          setState(() {
            _panelHeight = extHeight;
          });
        }
      },
    );
  }

  Widget _basement() {
    return WordGrid(
      key            : _basementKey,
      controller     : _basementController,
      onDragBoxBuild : _onBasementBoxBuild,
      onDragBoxTap   : _onBasementBoxTap,
      onChangeHeight : (double newHeight) {
        final extHeight = newHeight;
        if (_basementHeight != extHeight) {
          setState(() {
            _basementHeight = extHeight;
          });
        }
      },
    );
  }

  Widget _toolbar() {
    return  EventReceiverWidget(
        events: [_toolBarRefresh],
        builder: (BuildContext context) {
          return BottomAppBar(
              color: Colors.blue,
              child: IconTheme(
                data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [

                  if (textConstructorData.btnKeyboard) ...[
                    IconButton(
                      onPressed: () async {
                        final word = await _wordInputDialog(context);
                        if (word.isEmpty) return;

                        final pos = panelController.getCursorPos(lastPostIfNot: true);
                        panelController.saveCursor();
                        panelController.insertWord(pos, word);
                        panelController.refreshPanel();
                      },
                      icon: const Icon(Icons.keyboard_alt_outlined),
                    ),
                  ],

                  if (textConstructorData.btnUndo) ...[
                    IconButton(
                      onPressed: (_historyPos == 0 || _historyList.length == 1) ? null : (){
                        if (_historyPos < 0) {
                          _historyPos = _historyList.length - 2;
                        } else {
                          _historyPos --;
                        }

                        _historyRecordOn = false;
                        final histData = _historyList[_historyPos];
                        panelController.text = histData.panelStr;
                        _basementController.setVisibleWords(histData.basementStr);
                        _historyRecordOn = true;

                        _toolBarRefresh.send();
                      },
                      icon: const Icon(Icons.undo_outlined),
                    ),
                  ],

                  if (textConstructorData.btnRedo) ...[
                    IconButton(
                      onPressed: (_historyPos < 0 || _historyPos == (_historyList.length - 1) ) ? null : (){
                        _historyPos ++;
                        _historyRecordOn = false;
                        final histData = _historyList[_historyPos];
                        panelController.text = histData.panelStr;
                        _basementController.setVisibleWords(histData.basementStr);
                        _historyRecordOn = true;

                        _toolBarRefresh.send();
                      },
                      icon: const Icon(Icons.redo_outlined),
                    ),
                  ],

                  if (textConstructorData.btnBackspace) ...[
                    IconButton(
                      onPressed: ()=> _deleteWord(-1),
                      icon: const Icon(Icons.backspace_outlined),
                    ),
                  ],

                  if (textConstructorData.btnDelete) ...[
                    IconButton(
                      onPressed: ()=> _deleteWord(),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],

                  if (textConstructorData.btnClear) ...[
                    IconButton(
                      onPressed: (){
                        panelController.text = '';
                      },
                      icon: const Icon(Icons.clear_outlined),
                    ),
                  ],

                  if (widget.onRegisterAnswer != null) ...[
                    IconButton(
                      onPressed: (){
                        widget.onRegisterAnswer!.call(panelController.text, textConstructorData.answerList);
                      },
                      icon: const Icon(Icons.check, color: Colors.lightGreenAccent),
                    ),
                  ],

                ]),
              )
          );
        }
    );
  }

  void _deleteWord([int posAdd = 0]){
    var pos = panelController.getCursorPos(onlyCursor: true);

    bool cursor = false;
    if (pos < 0) {
      pos = panelController.getFocusPos();
      if (pos < 0) return;
    } else {
      cursor = true;
    }

    pos += posAdd;

    if (pos < 0) return;

    if (cursor) {
      if (pos == 0) {
        panelController.saveCursor(pos + 1);
      } else {
        panelController.saveCursor(pos);
      }
    }

    var word = panelController.getWord(pos);

    final wordInfo = LabelInfo(word);

    if (wordInfo.isObject) {
      final wordObject = getWordObject(wordInfo.objectName);
      if (wordObject.nonRemovable) return;
    }

    _basementController.addWord(wordInfo.word);

    panelController.deleteWord(pos);
    panelController.refreshPanel();
  }

  Future<String?> _onDragBoxTap(String label, Widget child, int pos, Offset position, Offset globalPosition) async {
    if (label.isEmpty) return label;

    widget.onTapLabel?.call(pos, label);

    if (label == JrfSpecText.wordKeyboard) {
      final inputValue = await _wordInputDialog(context);
      if (inputValue.isEmpty) return null;
      return inputValue;
    }

    final boxWidget = child as _BoxWidget;
    final fileName = textConstructorData.audioMap[boxWidget.outStr];
    if (fileName != null) {
      final filePath = widget.onPrepareFileUrl!(fileName);
      await playAudio(filePath);
    }

    if (textConstructorData.markStyle >= 0) {
      if (label.startsWith(LabelInfo.selectPrefix)) {
        label = label.substring(1);
      } else {
        label = '${LabelInfo.selectPrefix}$label';
      }
    }

    return label;
  }

  Future<String?> _onDragBoxLongPress(String label, Widget child, int pos, Offset position, Offset globalPosition) async {
    return _showPopupMenu(label, globalPosition);
  }

  Widget _editPosWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        color: _editPosColor,
      ),
      width: _editPosWidth,
      height: panelController.wordBoxHeight,
    );
  }

  Widget _insertPosWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        color: _insertPosColor,
      ),
      width: _insertPosWidth,
      height: panelController.wordBoxHeight,
    );
  }

  Widget _onDragBoxBuild(BuildContext context, PanelBoxExt ext){ //String label, DragBoxSpec spec) {
    if (ext.spec == DragBoxSpec.editPos){
      return _editPosWidget();
    }

    if (ext.spec == DragBoxSpec.insertPos){
      return _insertPosWidget();
    }

    return labelWidget(context, ext.label, ext.spec);
  }

  Widget _basementGroupHead(BuildContext context, String label) {
    return Text(label);
  }

  Widget _onBasementBoxBuild(BuildContext context, GridBoxExt ext) {
    if (ext.isGroup) {
      return _basementGroupHead(context, ext.label);
    }

    return labelWidget(context, ext.label, DragBoxSpec.none);
  }

  double _internalBoxHeight() {
    if (textConstructorData.boxHeight > 0) {
      return textConstructorData.boxHeight - 2;
    }

    if (panelController.wordBoxHeight == 0.0) return 20.0;
    return panelController.wordBoxHeight - 2;
  }

  WordObject getWordObject(String objectName) {
    final wordObject = textConstructorData.objects.firstWhereOrNull((wordObject) => wordObject.name == objectName)!;
    return wordObject;
  }

  Widget labelWidget(BuildContext context, String label, DragBoxSpec spec) {
    if (label.isEmpty) return Container();

    int? styleIndex;

    final labelInfo = LabelInfo(label);

    if (labelInfo.isSelected && textConstructorData.markStyle >= 0) {
      styleIndex = textConstructorData.markStyle;
    }

    if (labelInfo.isObject) {

      final wordObject = textConstructorData.objects.firstWhereOrNull((wordObject) => wordObject.name == labelInfo.objectName)!;

      final viewStr = wordObject.views[labelInfo.viewIndex??wordObject.viewIndex];

      return getObjectViewWidget(context, objectName: labelInfo.objectName, viewStr: viewStr, styleIndex: styleIndex, spec: spec );
    }

    return getObjectViewWidget(context, label: label, styleIndex: styleIndex, spec : spec );
  }

  Widget getObjectViewWidget(BuildContext context, {
    String      label      = '',
    String      objectName = '',
    String      viewStr    = '',
    int?        styleIndex ,
    DragBoxSpec spec       = DragBoxSpec.none,
    bool        forPopup   = false
  }) {
    var textStyleBold   = false;
    var textStyleItalic = false;

    var textColor       = _defaultTextColor;
    var backgroundColor = _colorWordNormal;

    var lineColor = Colors.black;
    var linePos   = TextDecoration.none;
    var lineStyle = TextDecorationStyle.solid;

    var borderColor = _borderColor;
    var borderWidth = _borderWidth;

    var menuText = '';

    var outStr = '';

    var localStyleIndex = -1;

    if (viewStr.isNotEmpty) {
      final viewInfo = ViewInfo(viewStr);

      outStr = viewInfo.text;

      localStyleIndex = viewInfo.styleIndex;
    }

    if (objectName.isNotEmpty) {
      if (outStr.isEmpty) {
        outStr = objectName;
      }
    }

    if (styleIndex != null) {
      localStyleIndex = styleIndex;
    }

    if (localStyleIndex >= 0) {
      final styleStr = textConstructorData.styles[localStyleIndex];
      final styleInfo = StyleInfo.fromStyleStr(styleStr);

      textStyleBold = styleInfo.fontBold;
      textStyleItalic = styleInfo.fontItalic;

      if (styleInfo.charColor != null) {
        textColor = styleInfo.charColor!;
      }
      if (styleInfo.backgroundColor != null) {
        backgroundColor = styleInfo.backgroundColor!;
      }
      if (styleInfo.frameColor != null) {
        borderColor = styleInfo.frameColor!;
      }

      if (styleInfo.linePos != null) {
        linePos   = styleInfo.linePos!;
        lineStyle = styleInfo.lineStyle!;
        lineColor = styleInfo.lineColor!;
      }
    }

    if (label.isNotEmpty) {
      outStr = label;
    }

    if (forPopup && menuText.isNotEmpty) {
      outStr = menuText;
    }

    if (spec == DragBoxSpec.move) {
      backgroundColor = _colorWordMove;
    }
    if (spec == DragBoxSpec.canDrop) {
      backgroundColor = _colorWordCanDrop;
    }
    if (spec == DragBoxSpec.tapInProcess) {
      borderColor = _tapInProcessBorderColor;
      borderWidth = _focusBorderWidth;
    }
    if (spec == DragBoxSpec.focus) {
      borderColor = _focusBorderColor;
      borderWidth = _focusBorderWidth;
    }

    Widget? retWidget;

    retWidget = _extWidget(context, outStr, spec, textColor, backgroundColor);
    if (retWidget != null) {
      retWidget = SizedBox(
          height : _internalBoxHeight(),
          child  : retWidget
      );
    }

    retWidget ??= Container(
        color: backgroundColor,
        child: Text(
          outStr,
          style: TextStyle(
            color: textColor,

            decoration     : linePos,
            decorationColor: lineColor,
            decorationStyle: lineStyle,

            fontSize: _fontSize,
            fontWeight: textStyleBold? FontWeight.bold : null,
            fontStyle: textStyleItalic? FontStyle.italic : null,
          ),
        ),
    );

    if (forPopup) {
      return _BoxWidget(
        outStr: outStr,
        menuText: menuText,
        child: _makeDecoration(
          child           : retWidget,
          borderColor     : _borderColor,
          borderWidth     : _borderWidth,
          backgroundColor : backgroundColor,
        ),
      );
    }

    return _BoxWidget(
      outStr: outStr,
      menuText: menuText,
      child: _makeDecoration(
        child           : retWidget,
        borderColor     : borderColor,
        borderWidth     : borderWidth,
        backgroundColor : backgroundColor,
      ),
    );
  }

  Widget? _extWidget(BuildContext context, String outStr, DragBoxSpec spec, Color textColor, Color backgroundColor) {
    if (outStr.indexOf(JrfSpecText.imagePrefix) == 0) {
      final imagePath = outStr.substring(JrfSpecText.imagePrefix.length);

      final fileUrl = widget.onPrepareFileUrl!.call(imagePath);
      return imageFromUrl(fileUrl);
    }

    if (outStr.indexOf(JrfSpecText.audioPrefix) == 0) {
      final audioPath = outStr.substring(JrfSpecText.audioPrefix.length);
      final fileUrl = widget.onPrepareFileUrl!.call(audioPath);

      return audioButtonFromUrl(fileUrl, textColor);
    }

    if (outStr == JrfSpecText.wordKeyboard) {
      return Icon(Icons.keyboard_alt_outlined, color: textColor);
    }

    return null;
  }

  Widget _makeDecoration({
    required Widget child,
    required Color  borderColor,
    required double borderWidth,
    required Color  backgroundColor,
  }){
    return  Container(
      height:  textConstructorData.boxHeight > 0 ? textConstructorData.boxHeight : null,
      padding: const EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: backgroundColor,
      ),
      child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: child
      ),
    );
  }

  Future<String?> _showPopupMenu(String label, Offset position) async {
    if (label.isEmpty) return null;
    final labelInfo = LabelInfo(label);

    if (!labelInfo.isObject) return null;

    final wordObject = textConstructorData.objects.firstWhereOrNull((wordObject) => wordObject.name == labelInfo.objectName)!;

    final popupItems = <PopupMenuEntry<String>>[];

    for ( var i = 0; i < wordObject.views.length; i++ ) {
      final viewStr = wordObject.views[i];
      final popupItemWidget = getObjectViewWidget(context, objectName: labelInfo.objectName, viewStr: viewStr, forPopup: true) as _BoxWidget;
      if (popupItemWidget.menuText == JrfSpecText.hideMenuItem) continue;

      popupItems.add( PopupMenuItem(
          value: '#$i|${labelInfo.objectName}',
          padding: EdgeInsets.zero,
          child: Center(child: popupItemWidget)
      ));
    }

    final value = await showMenu<String>(
      context  : context,
      position : RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items    : popupItems,
      shape: const RoundedRectangleBorder( borderRadius: BorderRadius.all(Radius.circular(5)) ),
    );

    return value;
  }

  void _onBasementBoxTap(DragBoxInfo<GridBoxExt> boxInfo, Offset position) {
    if (!textConstructorData.notDelFromBasement){
      boxInfo.setState(visible: false);
      _basementController.refresh();
    }

    final curPos = panelController.getCursorPos(lastPostIfNot: true);
    panelController.saveCursor();
    panelController.insertWord(curPos, boxInfo.data.ext.label);
    panelController.refreshPanel();
  }

  Future<String> _wordInputDialog(BuildContext context) async {
    final textController = TextEditingController();
    String  word = '';

    final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(TextConst.txtDialogInputText),
            content: TextField(
              onChanged: (value) {
                word = value;
              },
              controller: textController,
            ),
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
                word = '';
                Navigator.pop(context, false);
              }),

              IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: () {
                Navigator.pop(context, true);
              }),

            ],
          );
        });

    //textController.dispose();

    if (result != null && result) return word;

    return '';
  }
}

class _BoxWidget extends StatelessWidget {
  final Widget child;
  final String outStr;
  final String menuText;

  const _BoxWidget({required this.child, required this.outStr, required this.menuText, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

