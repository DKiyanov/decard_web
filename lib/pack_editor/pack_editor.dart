import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:collection/collection.dart';

import '../card_controller.dart';
import '../card_navigator.dart';
import '../card_widget.dart';
import '../common.dart';
import '../db_mem.dart';
import '../decardj.dart';
import '../parse_pack_info.dart';
import 'pack_file_source.dart';
import 'pack_head_widget.dart';
import 'pack_quality_level_widget.dart';
import 'pack_style_widget.dart';
import 'pack_template_widget.dart';
import 'desc_json.dart';
import 'pack_widgets.dart';

class PackEditor extends StatefulWidget {
  final int packId;
  const PackEditor({required this.packId, Key? key}) : super(key: key);

  @override
  State<PackEditor> createState() => _PackEditorState();
}

class _PackEditorState extends State<PackEditor> with TickerProviderStateMixin {
  bool _isStarting = true;

  late DbSourceMem  _dbSource;
  late CardController _cardController;
  int? _jsonFileID;

  late CardNavigatorData _cardNavigatorData;

  late String packJsonUrl;
  late Map<String, dynamic> _packJson;
  late Map<String, String> _fileUrlMap;

  late Map<String, FieldDesc> _descMap;

  late TabController _editorTabController;
  late TabController _rightTabController;

  final _headScrollController   = ScrollController();
  final _stylesScrollController = ScrollController();
  final _cardsScrollController  = ScrollController();

  final _pagePadding = const EdgeInsets.only(left: 10, right: 20);

  bool _dataChanged = false;
  final _dataChangedButtonKey = GlobalKey();

  final _packTitleKey = GlobalKey();
  String _packTitle = '';

  @override
  void initState() {
    super.initState();

    _editorTabController = TabController(
      initialIndex: 0,
      length: 3,
      vsync: this,
    );

    _rightTabController = TabController(
      initialIndex: 0,
      length: 3,
      vsync: this,
    );


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    _descMap = loadDescFromMap(jsonDecode(descJsonStr));

    _dbSource = DbSourceMem.create();
    _cardController = CardController(dbSource: _dbSource);
    _jsonFileID = await loadPack(_dbSource, widget.packId, addInfoCallback: (jsonStr, jsonUrl, fileUrlMap){
      packJsonUrl = jsonUrl;
      _packJson    = jsonDecode(jsonStr);
      _fileUrlMap  = fileUrlMap;
    });

    if (_jsonFileID == null) {
      // TODO нужно вывести соощение что пакет не удалось загрузить
      return;
    }

    _setEditorTitle();

    _cardNavigatorData = CardNavigatorData(_dbSource);
    await _cardNavigatorData.setData();

    final card = _cardNavigatorData.cardList.firstWhereOrNull((card) => card.jsonFileID == _jsonFileID);

    if (card != null) {
      _cardController.setCard(_jsonFileID!, card.cardID, bodyNum: 0);
    }

    setState(() {
      _isStarting = false;
    });
  }

  @override
  void dispose() {
    _headScrollController.dispose();

    _stylesScrollController.dispose();
    _cardsScrollController.dispose();
    _editorTabController.dispose();

    super.dispose();
  }

  void _refresh() async {
    final cardKey = _cardController.card?.head.cardKey;

    _dbSource.db.clearDb();
   _jsonFileID = await _dbSource.loadJson(sourceFileID: '${widget.packId}', jsonMap: _packJson, fileUrlMap: _fileUrlMap);

    await _cardNavigatorData.setData();

    await _setCard(cardKey);

    Future.delayed(const Duration(milliseconds: 100), (){
      _cardController.onChange.send();
    });

    _setDataChanged(false);
  }

  Future<void> _setCard(String? cardKey) async {
    if (cardKey != null) {
      final cardHead = _cardNavigatorData.cardList.firstWhereOrNull((cardHead) => cardHead.cardKey == cardKey);
      if (cardHead != null) {
        await _cardController.setCard(_jsonFileID!, cardHead.cardID);
        return;
      }
    }

    if (_cardNavigatorData.cardList.isNotEmpty) {
      final cardHead = _cardNavigatorData.cardList.first;
      await _cardController.setCard(_jsonFileID!, cardHead.cardID);
      return;
    }

    _cardController.setNoCard();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtLoading),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(

        title: StatefulBuilder(
          key: _packTitleKey,
          builder: (context, setState) {
            return Text('Редактирование пакета: $_packTitle');
          }
        ),

        actions: [
          StatefulBuilder(
            key: _dataChangedButtonKey,
            builder: (context, setState) {
              return IconButton(
                onPressed: !_dataChanged? null : (){
                  _refresh();
                },
                icon: Icon(Icons.refresh, color: _dataChanged? Colors.red : Colors.grey),
              );
            }
          ),
        ],
      ),
      body:  _body(),
    );
  }

  Widget _body() {
    return Row(children: [
      Expanded(child: _editor()),
      Expanded(child: _rightPanel()),
    ]);
  }

  Widget _editor() {
    return Column(children: [
      TabBar(
        controller: _editorTabController,
        isScrollable: false,
        labelColor: Colors.black,
        tabs: const [
          Tab(icon: Icon(Icons.child_care ), text: 'Заголовок'),
          Tab(icon: Icon(Icons.style      ), text: 'Стили'),
          Tab(icon: Icon(Icons.credit_card), text: 'Карточки'),
        ],
      ),

      Expanded(
        child: JsonOwner(
          json: _packJson,
          dbSource: _dbSource,
          onDataChanged: () {
            _setDataChanged(true);
            _setEditorTitle();
          },
          child: TabBarView(
            controller: _editorTabController,
            children: [
              _head(),
              _styles(),
              _cards()
            ],
          ),
        ),
      )

    ]);
  }

  Widget _rightPanel() {
    return Column(children: [
      TabBar(
        controller: _rightTabController,
        isScrollable: false,
        labelColor: Colors.black,
        tabs: const [
          Tab(icon: Icon(Icons.source ), text: 'Ресурсы'),
          Tab(icon: Icon(Icons.table_chart_outlined      ), text: 'Значения параметров'),
          Tab(icon: Icon(Icons.streetview_outlined), text: 'Пакет'),
        ],
      ),

      Expanded(
        child: TabBarView(
          controller: _rightTabController,
          children: [
            _fileSources(),
            _templatesSources(),
            _packView()
          ],
        ),
      )

    ]);
  }

  Widget _head() {
    return Padding(
      padding: _pagePadding,
      child: ListView(
        controller: _headScrollController,
        children: [
          PackHeadWidget(json: _packJson, fieldDesc: _descMap["head"]!),
          _qualityLevels(),
        ],
      ),
    );
  }

  Widget _styles() {
    return Padding(
      padding: _pagePadding,
      child: SingleChildScrollView(
        controller: _stylesScrollController,
        child: JsonObjectArray(
          json: _packJson,
          fieldName: "cardStyleList",
          fieldDesc: _descMap["cardStyleList"]!,
          objectWidgetCreator: _getStyleWidget,
        ),
      ),
    );
  }

  Widget _cards() {
    return Padding(
      padding: _pagePadding,
      child: SingleChildScrollView(
        controller: _cardsScrollController,
        child: JsonObjectArray(
          json: _packJson,
          fieldName: "templateList",
          fieldDesc: _descMap["templateList"]!,
          objectWidgetCreator: _getTemplateWidget,
        ),
      ),
    );
  }

  Widget _qualityLevels() {
    return JsonObjectArray(
      json: _packJson,
      fieldName: "qualityLevelList",
      fieldDesc: _descMap["qualityLevelList"]!,
      objectWidgetCreator: _getQualityLevelWidget,
    );
  }

  Widget _getQualityLevelWidget(
      Map<String, dynamic> json,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return PackQualityLevelWidget(json: json, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Widget _getStyleWidget(
      Map<String, dynamic> json,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return PackStyleWidget(json: json, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Widget _getTemplateWidget(
      Map<String, dynamic> json,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return PackTemplateWidget(json: json, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Widget _packView() {
    return Row(children: [
      Expanded(child: _tree()),
      Expanded(child: _card()),
    ]);
  }

  Widget _tree() {
    return CardNavigatorTree(
      cardController: _cardController,
      cardNavigatorData: _cardNavigatorData,
      itemTextColor: Colors.black,
      selItemTextColor: Colors.blue,
      bodyButtonColor: Colors.orangeAccent,
      mode: NavigatorMode.noPackHead,
    );
  }

  Widget _card () {
    return Column(children: [
      _cardNavigator(),
      Expanded(child: _cardWidget()),
    ]);
  }

  Widget _cardNavigator() {
    return CardNavigator(
      key: ValueKey(widget.packId),
      cardController: _cardController,
      cardNavigatorData: _cardNavigatorData,
      mode: NavigatorMode.noPackHead,
    );
  }

  Widget _cardWidget() {
    return _cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
      return CardWidget(
        key        : ValueKey(card),
        card       : card,
        cardParam  : cardParam,
        controller : cardViewController,
      );
    });
  }

  Widget _fileSources(){
    return PackFileSource(fileUrlMap: _fileUrlMap);
  }

  Widget _templatesSources() {
    return const Center(child: Text('Значения параметров'));
  }

  void _setDataChanged(bool dataChanged){
    _dataChanged = dataChanged;
    _dataChangedButtonKey.currentState?.setState(() {});
  }

  void _setEditorTitle(){
    final newTitle = _packJson[DjfFile.title]??"";
    if (_packTitle != newTitle) {
      _packTitle = newTitle;
      _packTitleKey.currentState?.setState(() {});
    }
  }
}