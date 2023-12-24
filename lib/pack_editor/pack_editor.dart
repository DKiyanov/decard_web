import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:collection/collection.dart';

import '../card_controller.dart';
import '../card_navigator.dart';
import '../card_widget.dart';
import '../common.dart';
import '../db_mem.dart';
import '../parse_pack_info.dart';
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

class _PackEditorState extends State<PackEditor> with SingleTickerProviderStateMixin {
  bool _isStarting = true;

  late DbSourceMem  _dbSource;
  late CardController _cardController;
  late int? _jsonFileID;

  late CardNavigatorData _cardNavigatorData;

  late String _packJsonUrl;
  late Map<String, dynamic> _packJson;
  late Map<String, FieldDesc> _descMap;

  late TabController _editorTabController;

  final pagePadding = const EdgeInsets.only(left: 10, right: 20);

  @override
  void initState() {
    super.initState();

    _editorTabController = TabController(
      initialIndex: 0,
      length: 3,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    _dbSource = DbSourceMem.create();
    _cardController = CardController(dbSource: _dbSource);
    _jsonFileID = await loadPack(_dbSource, widget.packId, addInfoCallback: (jsonStr, jsonUrl){
      _packJsonUrl = jsonUrl;
      _packJson    = jsonDecode(jsonStr);
    });

    if (_jsonFileID == null) {
      // TODO нужно вывести соощение что пакет не удалось загрузить
      return;
    }

    _descMap = loadDescFromMap(jsonDecode(descJsonStr));

    _cardNavigatorData = CardNavigatorData(_dbSource);
    await _cardNavigatorData.init();

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
    _editorTabController.dispose();
    super.dispose();
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
        centerTitle: true,
        title: const Text('Editor'),
      ),
      body:  _body(),
    );
  }

  Widget _body() {
    return Row(children: [
      Expanded(child: _editor()),
      Expanded(child: _packView()),
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

  Widget _head() {
    return Padding(
      padding: pagePadding,
      child: ListView(
        children: [
          PackHeadWidget(json: _packJson, fieldDesc: _descMap["head"]!),
          _qualityLevels(),
        ],
      ),
    );
  }

  Widget _styles() {
    return Padding(
      padding: pagePadding,
      child: SingleChildScrollView(
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
      padding: pagePadding,
      child: SingleChildScrollView(
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
      selItemTextColor: Colors.yellowAccent,
      bodyButtonColor: Colors.orangeAccent,
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
}
