import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/simple_dialog.dart';
import 'package:decard_web/simple_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:routemaster/routemaster.dart';
import 'common.dart';
import 'pack_upload_file.dart';
import 'decardj.dart';

class OwnPackList extends StatefulWidget {
  final List<Widget>? actions;
  final WebPackListManager packInfoManager;
  final ParseUser user;
  const OwnPackList({required this.packInfoManager, required this.user, this.actions, Key? key}) : super(key: key);

  @override
  State<OwnPackList> createState() => _OwnPackListState();
}

class _OwnPackListState extends State<OwnPackList> {
  bool _isStarting = true;

  bool _uploadPanelVisible = false;

  final _webPackList = <WebPackInfo>[];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await widget.packInfoManager.init();
    await _refresh();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refresh() async {
    _webPackList.clear();
    _webPackList.addAll(await widget.packInfoManager.getUserPackList(widget.user.objectId!));
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
        title: Text(TextConst.txtOwnPackList),
        leading: popupMenu(icon: const Icon(Icons.menu), menuItemList: [
          SimpleMenuItem(
              child: const Text('Создать новый пакет'),
              onPress: _createNewPackage,
          ),

          if (kIsWeb) ...[
            SimpleMenuItem(
                child: const Text('Загрузить пакет'),
                onPress: () {
                  setState(() {
                    _uploadPanelVisible = true;
                  });
                }
            ),
          ],
        ]),
        actions: widget.actions
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(children: [
      Expanded(child: _mainPanel()),

      if (_uploadPanelVisible) ...[
        Expanded(child: _uploadPanel()),
      ],
    ]);
  }

  Widget _mainPanel() {
    return ListView(
      children: _webPackList.map((packInfo) {
        return Slidable(
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                flex: 2,
                onPressed: (context) {
                  _copyPackage(packInfo.packId, newVersion : true);
                },
                foregroundColor: Colors.blue,
                icon: Icons.copy,
                label: 'Создать новую версию',
              ),
            ],
          ),

          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                flex: 2,
                onPressed: (context) {
                  _deletePackage(packInfo.packId);
                },
                foregroundColor: Colors.red,
                icon: Icons.delete,
                label: 'Удалит пакет',
              ),
            ],
          ),

          child: ListTile(
            title: Text(packInfo.title),
            subtitle: _getSubtitle(packInfo),
            trailing: packInfo.published? null : InkWell(
                child: const Icon(Icons.edit),
                onTap: (){
                  Routemaster.of(context).push('/pack_editor/${packInfo.packId}');
                }
            ),
            onTap: (){
              Routemaster.of(context).push('/pack/${packInfo.packId}');
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _uploadPanel() {
    return PackUploadFile(
      onFileUpload: (filePath, url) {
        // TODO add uploaded files to own file list above
      },

      onClearFileUploadList: () {
        _uploadPanelVisible = false;
        setState(() {});
      },

    );
  }

  Widget _getSubtitle(WebPackInfo packInfo) {
    final subtitle = 'возраст: ${packInfo.targetAgeLow}-${packInfo.targetAgeHigh}; теги: ${packInfo.tags}';
    return Text(subtitle);
  }

  Future<void> _createNewPackage() async {
    final parameters = await _createNewPackageDialog();
    if (parameters == null) return;

    final createPackFunction = ParseCloudFunction('createNewPackage');
    final response = await createPackFunction.execute(parameters: parameters);

    final packId = response.result?[WebPackFields.packId];

    if (!response.success || packId == null) {
      return;
    }

    if (!mounted) return;

    Routemaster.of(context).push('/pack_editor/$packId').result.then((value) async {
      await _refresh();
      setState(() {});
    });
  }

  Future<Map<String, dynamic>?> _createNewPackageDialog() async {
    void Function(void Function())? dialogState;

    final titleController = TextEditingController();
    String titleError = '';

    final ageFromController = TextEditingController();
    String ageFromError = '';
    int? ageFrom;

    final ageToController = TextEditingController();
    String ageToError = '';
    int? ageTo;

    final result = await simpleDialog(
      context: context,
      title: const Text('Создать новый пакет'),
      content: StatefulBuilder(builder: (context, setState) {
        dialogState = setState;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(children: [
              const Expanded(
                child: Text('Наименование')
              ),
              Expanded(
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    errorText: titleError
                  ),
                )
              )
            ]),

            Row(children: [
              const Expanded(
                  child: Text('Целевой возраст')
              ),
              Expanded(
                  child: Row(
                    children: [
                      const Text(' c '),

                      Expanded(
                        child: TextField(
                          controller: ageFromController,
                          keyboardType : TextInputType.number,
                          inputFormatters : [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            errorText: ageFromError,
                          ),

                        ),
                      ),

                      const Text(' по '),

                      Expanded(
                        child: TextField(
                          controller: ageToController,
                          keyboardType : TextInputType.number,
                          inputFormatters : [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                              errorText: ageToError
                          ),
                        ),
                      ),
                    ],
                  )
              )
            ]),

          ]
        );
      }),
      onPressOk: () {
        titleError = '';
        ageFromError = '';
        ageToError = '';
        bool err = false;

        if (titleController.text.isEmpty) {
          titleError = 'заполните поле';
          err = true;
        }
        if (ageFromController.text.isEmpty) {
          ageFromError = 'заполните поле';
          err = true;
        }
        if (ageToController.text.isEmpty) {
          ageToError = 'заполните поле';
          err = true;
        }

        if (titleController.text.length < 15) {
          titleError = 'Слишком короткое название';
          err = true;
        }

        if (_webPackList.any((packInfo) => packInfo.title == titleController.text)) {
          titleError = 'есть пакет с таким же наименованием';
          err = true;
        }

        ageFrom = int.tryParse(ageFromController.text);
        if (ageFrom == null) {
          ageFromError = 'не корректное значение';
          err = true;
        }

        ageTo = int.tryParse(ageToController.text);
        if (ageTo == null) {
          ageToError = 'не корректное значение';
          err = true;
        }

        if (ageFrom != null && ageTo != null && ageFrom! > ageTo!) {
          ageFromError = '> $ageTo';
          ageToError = '< $ageFrom';
          err = true;
        }

        if (err) {
          dialogState?.call((){});
          return false;
        }

        return true;
      }
    );

    if (result == null || !result) return null;

    return {
      DjfFile.title         : titleController.text,
      DjfFile.targetAgeLow  : ageFrom!,
      DjfFile.targetAgeHigh : ageTo!,
    };
  }

  Future<void> _deletePackage(int packId) async {
    final result = await simpleDialog(
      context: context,
      title: const Text('Удалить пакет?')
    );

    if (result == null || !result) return;

    final deletePackFunction = ParseCloudFunction('deletePackage');
    final response = await deletePackFunction.execute(parameters: {WebPackFields.packId : packId});

    if (!response.success) {

      return;
    }

    await _refresh();
    setState(() {});
  }

  Future<void> _copyPackage(int packId, {required bool newVersion}) async {
    final result = await simpleDialog(
        context: context,
        title: const Text('Создать новую версию пакета')
    );

    if (result == null || !result) return;

    final copyPackFunction = ParseCloudFunction('copyPackage');
    final response = await copyPackFunction.execute(parameters: {WebPackFields.packId : packId, 'newVersion' : newVersion});

    final newPackId = response.result?[WebPackFields.packId];

    if (!response.success || newPackId == null) {
      return;
    }

    if (!mounted) return;

    Routemaster.of(context).push('/pack_editor/$newPackId').result.then((value) async {
      await _refresh();
      setState(() {});
    });
  }
}
