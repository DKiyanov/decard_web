import 'package:decard_web/db.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:routemaster/routemaster.dart';

import '../card_controller.dart';
import '../card_navigator.dart';
import '../card_widget.dart';
import '../common.dart';
import '../db_mem.dart';
import '../decardj.dart';
import '../loader.dart';
import '../parse_class_info.dart';
import '../parse_pack_info.dart';
import 'pack_file_source_list.dart';
import 'pack_file_source_editor.dart';
import 'pack_head_widget.dart';
import 'pack_quality_level_widget.dart';
import 'pack_style_widget.dart';
import 'pack_template_widget.dart';
import 'desc_json.dart';
import 'pack_templates_sources.dart';
import 'pack_widgets.dart';
import '../simple_events.dart' as event;

class PackEditor extends StatefulWidget {
  final int packId;
  const PackEditor({required this.packId, Key? key}) : super(key: key);

  @override
  State<PackEditor> createState() => PackEditorState();

  static PackEditorState? of(BuildContext context){
    return context.findAncestorStateOfType<PackEditorState>();
  }
}

class PackEditorState extends State<PackEditor> with TickerProviderStateMixin {
  bool _isStarting = true;

  late DbSourceMem  _dbSource;
  late CardController _cardController;
  int? _jsonFileID;

  late DbValidator _dbValidator;

  late CardNavigatorData _cardNavigatorData;

  late String packRootPath;
  late Map<String, dynamic> _packJson;
  late Map<String, String> _fileUrlMap;

  late WebPackTextFile _jsonFile;
  late ParseObject _packHead;

  late Map<String, FieldDesc> _descMap;

  late TabController _editorTabController;
  late TabController _rightTabController;

  final _headScrollController   = ScrollController();

  final _pagePadding = const EdgeInsets.only(left: 10, right: 20);

  bool _dataChanged = false;
  bool _dataChangeSaveInProcess = false;
  bool _dataChangeSaved = true;
  final _dataChangedButtonKey = GlobalKey();

  final _packTitleKey = GlobalKey();
  String _packTitle = '';

  final _fileSourceKey = GlobalKey<PackFileSourceListState>();

  final String _rootPath = '';

  final _jsonOwnerKey = GlobalKey<JsonOwnerState>();
  event.Listener? _selectPathListener;

  final _headTabIndex  = 0;
  final _styleTabIndex = 1;
  final _cardsTabIndex = 2;

  //final _fileSourceTabIndex = 0;
  final _paramsTabIndex     = 1;
  //final _packPreview        = 3;

  final _packErrorList = <DbValidatorResult>[];
  final _validatePackResultPanelKey = GlobalKey();
  DbValidatorResult? _selectedPackError;

  String _editableSourceFile = '';
  String _editableSourceUrl  = '';

  bool _viewOnly = false;

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
//    _descMap = loadDescFromMap(jsonDecode(descJsonStr));
    _descMap = loadDescFromMap(descJson);

    _dbSource = DbSourceMem.create();
    _cardController = CardController(dbSource: _dbSource);
    _dbValidator = DbValidator(_dbSource);

    String? packJsonPath;

    _jsonFileID = await loadWebPack(_dbSource, widget.packId, addInfoCallback: (jsonStr, jsonPath, rootPath, fileUrlMap) {
      packJsonPath = jsonPath;
      packRootPath = rootPath;
      _packJson    = jsonDecode(jsonStr);
      _fileUrlMap  = fileUrlMap;
    });

    if (_jsonFileID == null) {
      Fluttertoast.showToast(msg: 'Не удалось загрузить пакет');
      if (!mounted) return;
      Routemaster.of(context).pop();
      return;
    }

    _jsonFile = WebPackTextFile(packId: widget.packId, path: packJsonPath!);

    final packHeadQuery = QueryBuilder<ParseObject>(ParseObject(ParseWebPackHead.className));
    packHeadQuery.whereEqualTo(ParseWebPackHead.packId, widget.packId);
    _packHead = (await packHeadQuery.first())!;

    _viewOnly = _packHead.get(ParseWebPackHead.publicationMoment) != null;

    _setEditorTitle();

    _cardNavigatorData = CardNavigatorData(_dbSource);
    await _cardNavigatorData.setData();

    final card = _cardNavigatorData.cardList.firstWhereOrNull((card) => card.jsonFileID == _jsonFileID);

    if (card != null) {
      _cardController.setCard(_jsonFileID!, card.cardID, bodyNum: 0);
    }

    _validatePack(refreshView: false);

    setState(() {
      _isStarting = false;
    });
  }

  @override
  void dispose() {
    _saveJson();

    _selectPathListener?.dispose();
    _headScrollController.dispose();
    _editorTabController.dispose();

    super.dispose();
  }

  void _refresh() async {
    final cardKey = _cardController.card?.head.cardKey;

    _dbSource.db.clearDb();
   _jsonFileID = await _dbSource.loadJson(sourceFileID: '${widget.packId}', rootPath: packRootPath, jsonMap: _packJson, fileUrlMap: _fileUrlMap);

   _validatePack();

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

    return WillPopScope(
      onWillPop: () async {
        if (!_dataChangeSaved && _viewOnly) {
          Fluttertoast.showToast(msg: 'Изменения НЕ сохранены');
        }

        await _saveJson();
        return true;
      },

      child: Scaffold(
        appBar: AppBar(

          title: StatefulBuilder(
            key: _packTitleKey,
            builder: (context, setState) {
              return Text('Редактирование пакета: $_packTitle ${_viewOnly ? '(просмотр)' : ''}');
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
        body:  Container(
          color: Colors.grey,
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2, left: 4, right: 4),
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_packErrorList.isEmpty) return _bodyMain();

    return MultiSplitView(
      axis: Axis.vertical,
      initialAreas: [
        Area(),
        Area(weight: 0.2),
      ],
      children: [
        Container(child: _bodyMain()), // Container needed for hide key _jsonOwnerKey from MultiSplitView - it`s crash him
        _validatePackResultPanel(),
      ],
    );
  }

  Widget _bodyMain() {
    return JsonOwner(
      key: _jsonOwnerKey,
      json: _packJson,
      onDataChanged: () {
        _setDataChanged(true);
        _setEditorTitle();
        _dataChangeSaved = false;
        Future.delayed(const Duration(seconds: 20), (){
          _saveJson();
        });
      },

      child: Container(
        color: Colors.grey,
        child: MultiSplitView(children: [
          if (_editableSourceFile.isEmpty) ...[
            _editor(),
          ],
          if (_editableSourceFile.isNotEmpty) ...[
            _sourceFileEditorPanel(),
          ],
          _rightPanel(),
        ]),
      ),
    );
  }

  Decoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(
        color: Colors.white,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(5))
    );
  }

  void editSourceFile(String filename, String url) {
    setState(() {
      _editableSourceFile = filename;
      _editableSourceUrl  = url;
    });
  }

  Widget _sourceFileEditorPanel() {
    return Container(
      decoration: _panelDecoration(),

      child: Column(children: [
        Expanded(
          child: SourceFileEditor(
            packId: widget.packId,
            rootPath: packRootPath,
            filename: _editableSourceFile,
            url: _editableSourceUrl,
            onAddNewFile: (filePath, url) {
              _fileSourceKey.currentState?.addNewFile(filePath, url);
            },
            tryExitCallback: (){
              setState((){
                _editableSourceFile = '';
              });
            },
            onPrepareFileUrl: (String fileName) {
              return _fileUrlMap[fileName];
            },
          ),
        )
      ]),
    );
  }

  Widget _editor() {
    return Container(
      decoration: _panelDecoration(),

      child: Column(children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide( color: Colors.grey.shade300))
          ),

          child: TabBar(
            controller: _editorTabController,
            isScrollable: false,
            labelColor: Colors.black,
            tabs: const [
              Tab(icon: Icon(Icons.child_care ), text: 'Заголовок'),
              Tab(icon: Icon(Icons.style      ), text: 'Стили'),
              Tab(icon: Icon(Icons.credit_card), text: 'Карточки'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _editorTabController,
            children: [
              _head(),
              _styles(),
              _cards()
            ],
          ),
        )

      ]),
    );
  }

  Widget _rightPanel() {
    return Container(
      decoration: _panelDecoration(),

      child: Column(children: [
        Container(
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide( color: Colors.grey.shade300))
          ),

          child: TabBar(
            controller: _rightTabController,
            isScrollable: false,
            labelColor: Colors.black,
            tabs: const [
              Tab(icon: Icon(Icons.source ), text: 'Ресурсы'),
              Tab(icon: Icon(Icons.table_chart_outlined      ), text: 'Значения параметров'),
              Tab(icon: Icon(Icons.streetview_outlined), text: 'Пакет'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _rightTabController,
            children: [
              _fileSources(),
              _templatesSources(),
              _packView()
            ],
          ),
        )

      ]),
    );
  }

  Widget _head() {
    return Padding(
      padding: _pagePadding,
      child: ListView(
        controller: _headScrollController,
        children: [
          PackHeadWidget(json: _packJson, path: _rootPath, fieldDesc: _descMap["head"]!),
          _qualityLevels(),
        ],
      ),
    );
  }

  Widget _styles() {
    return Padding(
      padding: _pagePadding,
      child: _PackEditorJsonTab(
        json: _packJson,
        path: _rootPath,
        fieldName: DjfFile.cardStyleList,
        fieldDesc: _descMap[DjfFile.cardStyleList]!,
        objectWidgetCreator: _getStyleWidget,
      ),
    );
  }

  Widget _cards() {
    return Padding(
      padding: _pagePadding,
      child: _PackEditorJsonTab(
        json: _packJson,
        path: _rootPath,
        fieldName: DjfFile.templateList,
        fieldDesc: _descMap[DjfFile.templateList]!,
        objectWidgetCreator: _getTemplateWidget,
      ),
    );
  }

  Widget _qualityLevels() {
    return JsonObjectArray(
      json: _packJson,
      path: _rootPath,
      fieldName: DjfFile.qualityLevelList,
      fieldDesc: _descMap[DjfFile.qualityLevelList]!,
      objectWidgetCreator: _getQualityLevelWidget,
    );
  }

  Widget _getQualityLevelWidget(
      Map<String, dynamic> json,
      path,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return PackQualityLevelWidget(json: json, path: path, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Widget _getStyleWidget(
      Map<String, dynamic> json,
      String path,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return PackStyleWidget(json: json, path: path, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Widget _getTemplateWidget(
      Map<String, dynamic> json,
      String path,
      FieldDesc fieldDesc,
      OwnerDelegate? ownerDelegate,
      ){
    return PackTemplateWidget(json: json, path: path, fieldDesc: fieldDesc, ownerDelegate: ownerDelegate);
  }

  Widget _packView() {
    if (_cardNavigatorData.cardList.isEmpty) {
      return Center(
        child: Text('Пакет на данный момент не содержит карточек${ _packErrorList.isNotEmpty ? '\nв пакете присутствуют ошибки': ''}',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      color: Colors.grey,
      child: MultiSplitView(
        children: [
          _tree(),
          _card(),
        ]
      ),
    );
  }

  Widget _tree() {
    return Container(
      color: Colors.white,

      child: CardNavigatorTree(
        cardController: _cardController,
        cardNavigatorData: _cardNavigatorData,
        itemTextColor: Colors.black,
        selItemTextColor: Colors.blue,
        bodyButtonColor: Colors.orangeAccent,
        mode: NavigatorMode.noPackHead,
      ),
    );
  }

  Widget _card () {
    return Container(
      color: Colors.white,

      child: Column(children: [
        _cardNavigator(),
        Expanded(child: _cardWidget()),
      ]),
    );
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
    return PackFileSourceList(
      key        : _fileSourceKey,
      editor     : this,
      packId     : widget.packId,
      jsonFileID : _jsonFileID!,
      rootPath   : packRootPath,
      dbSource   : _dbSource,
      fileUrlMap : _fileUrlMap
    );
  }

  Widget _templatesSources() {
    return TemplatesSources(
      json   : _packJson,
      editor : this,
    );
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

  final onNeedFileSourceControllerChanged = event.SimpleEvent<TextEditingController>();
  TextEditingController? needFileSourceController;
  final needFileExtList = <String>[];

  void setNeedFileSourceController(TextEditingController controller, bool hasFocus, List<String> fileExtList ) {
    if (needFileSourceController == controller && !hasFocus) {
      needFileSourceController = null;
      needFileExtList.clear();
      onNeedFileSourceControllerChanged.send();
      return;
    }

    if (needFileSourceController != controller && hasFocus) {
      needFileSourceController = controller;
      needFileExtList.clear();
      needFileExtList.addAll(fileExtList);
      onNeedFileSourceControllerChanged.send(needFileSourceController);
      return;
    }
  }

  void setSelectedFileSource(String value) {
    _fileSourceKey.currentState?.setSelectedFileSource(value);
  }



  Future<List<String>> getQualityNameList() async { // Uplink multi
    return _dbSource.tabQualityLevel.getLevelNameList(jsonFileID: _jsonFileID!);
  }

  Future<List<String>> getStyleIdList() async { // Card.Body multi
    return _dbSource.tabCardStyle.getStyleKeyList(jsonFileID: _jsonFileID!);
  }

  Future<List<String>> getTagList() async { // UpLink multi
    return _dbSource.tabCardTag.getFileTagList(jsonFileID: _jsonFileID!);
  }

  Future<List<String>> getCardIdList() async { // UpLink multi
    return _dbSource.tabCardHead.getFileCardKeyList(jsonFileID: _jsonFileID!);
  }

  Future<List<String>> getCardGroupList() async { // UpLink multi
    return _dbSource.tabCardHead.getFileGroupList(jsonFileID: _jsonFileID!);
  }

  Future<List<String>?> getStyleAnswerVariantList(String cardStyleKey) async { // for Card.Body multi
    final style = await _dbSource.tabCardStyle.getRow(jsonFileID: _jsonFileID!, cardStyleKey: cardStyleKey);
    if (style == null) return null;

    final answerVariantList = style[DjfCardStyle.answerVariantList];
    if (answerVariantList == null) return null;

    return (answerVariantList as List).map((value) => value as String).toList();
  }

  Future<List<String>> getNearGroupList(String cardID) async { // Card single
    final rows = await _dbSource.tabCardHead.getFileRows(jsonFileID: _jsonFileID!);
    final index = rows.indexWhere((row) => row[TabCardHead.kCardID] == cardID);

    final result = <String>[];

    if (index < 0) return result;

    if (index > 0) {
      final group = (rows[index - 1][TabCardHead.kGroup]??'') as String;
      if (group.isNotEmpty) {
        result.add(group);
      }
    }

    if (index + 1 < rows.length) {
      final group = (rows[index + 1][TabCardHead.kGroup]??'') as String;
      if (group.isNotEmpty && !result.contains(group)) {
        result.add(group);
      }
    }

    return result;
  }

  Future<void> _saveJson() async {
    if (_viewOnly) return;
    if (_dataChangeSaveInProcess) return;
    if (_dataChangeSaved) return;
    _dataChangeSaved = true;
    _dataChangeSaveInProcess = true;

    try {
      final jsonStr = jsonEncode(_packJson);
      await _jsonFile.setText(jsonStr);

      _packHead.set<String?>(DjfFile.title, _packJson[DjfFile.title]);
      _packHead.set<String?>(DjfFile.site, _packJson[DjfFile.site ]);
      _packHead.set<String?>(DjfFile.email, _packJson[DjfFile.email ]);
      _packHead.set<String?>(DjfFile.tags, _packJson[DjfFile.tags ]);
      _packHead.set<String?>(DjfFile.license, _packJson[DjfFile.license]);
      _packHead.set<int?>(
          DjfFile.targetAgeLow, _packJson[DjfFile.targetAgeLow ]);
      _packHead.set<int?>(
          DjfFile.targetAgeHigh, _packJson[DjfFile.targetAgeHigh]);
      await _packHead.save();
    } catch (e) {
      _dataChangeSaved = false;
    } finally {
      _dataChangeSaveInProcess = false;
    }
  }

  void _selectPath(String path) {
    if (_jsonOwnerKey.currentState == null) return;
    _selectPathListener ??= _jsonOwnerKey.currentState!.onSelectPath.subscribe((listener, path) => _onSelectPath(path??''));
    _jsonOwnerKey.currentState!.selectPath(path);
  }

  void _onSelectPath(String path) {
    final firstObject =  path.split('/').first;
    if (firstObject == DjfFile.cardStyleList) {
      _editorTabController.index = _styleTabIndex;
      return;
    }
    if (firstObject.startsWith(DjfFile.templateList)) {
      _editorTabController.index = _cardsTabIndex;
      return;
    }
    _editorTabController.index = _headTabIndex;
  }

  Future<void> _validatePack({bool refreshView = true}) async {
    final panelWasVisible = _packErrorList.isNotEmpty;

    _packErrorList.clear();
    final checkResultList = await _dbValidator.checkJsonFile(_jsonFileID!);
    _packErrorList.addAll(checkResultList);

    if (!refreshView) return;

    if (panelWasVisible != _packErrorList.isNotEmpty) {
      setState(() {});
    } else if (_packErrorList.isNotEmpty) {
      _validatePackResultPanelKey.currentState?.setState(() {});
    }
  }

  final onSelectSourceIndex = event.SimpleEvent<int>();

  Widget _validatePackResultPanel() {
    return Container(
      decoration: _panelDecoration(),

      child: StatefulBuilder(
        key: _validatePackResultPanelKey,
        builder: (context, setState) {
          return ListView(
            shrinkWrap: true,
            children: _packErrorList.map((errData) => ListTile(
              title: Text(errData.message),
              subtitle: Text(errData.path),
              selected: errData == _selectedPackError,
              selectedTileColor: Colors.yellow,
              onTap: (){
                _selectedPackError = errData;
                _selectPath(errData.path);

                if (errData.sourceIndex != null) {
                  _rightTabController.index = _paramsTabIndex;
                  onSelectSourceIndex.send(errData.sourceIndex);
                }

                setState((){});
              },
            )).toList(),
          );
        }
      ),
    );
  }
}

class _PackEditorJsonTab extends StatefulWidget {
  final Map<String, dynamic> json;
  final String path;
  final String fieldName;
  final FieldDesc fieldDesc;
  final JsonObjectBuild objectWidgetCreator;

  const _PackEditorJsonTab({
    required this.json,
    required this.path,
    required this.fieldName,
    required this.fieldDesc,
    required this.objectWidgetCreator,

    Key? key
  }) : super(key: key);

  @override
  State<_PackEditorJsonTab> createState() => _PackEditorJsonTabState();
}

class _PackEditorJsonTabState extends State<_PackEditorJsonTab> with AutomaticKeepAliveClientMixin<_PackEditorJsonTab> {
  final _cardsScrollController  = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _cardsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      controller: _cardsScrollController,
      child: JsonObjectArray(
        json: widget.json,
        path: widget.path,
        fieldName: widget.fieldName,
        fieldDesc: widget.fieldDesc,
        objectWidgetCreator: widget.objectWidgetCreator,
      ),
    );
  }
}
