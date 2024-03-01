import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/simple_dialog.dart';
import 'package:decard_web/simple_menu.dart';
import 'package:decard_web/web_child.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:routemaster/routemaster.dart';
import 'common.dart';
import 'pack_upload_file.dart';
import 'decardj.dart';
import 'parse_class_info.dart';

class OwnPackList extends StatefulWidget {
  final List<Widget>? actions;
  final WebPackListManager packInfoManager;
  final WebChildListManager childManager;
  final ParseUser user;
  const OwnPackList({required this.packInfoManager, required this.childManager,  required this.user, this.actions, Key? key}) : super(key: key);

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
        final childrenStr = getPackChildList(packInfo).join(', ');
        return packInfo.getListTile(context,
          trailing: _packActionMenu(packInfo),
          addSubTitle: childrenStr.isEmpty ? null : 'назначено: $childrenStr',
        );
      }).toList(),
    );
  }

  List<String> getPackChildList(WebPackInfo packInfo) {
    final result = <String>[];

    for (var device in widget.childManager.deviceList) {
      final added = device.packInfoList.any((testPackInfo) => testPackInfo.packId == packInfo.packId);
      if (!added) continue;
      result.add(device.name);
    }

    return result;
  }

  Widget _packActionMenu(WebPackInfo packInfo) {
    return popupMenu(
        icon: const Icon(Icons.menu),
        menuItemList: [
          if (packInfo.published) ...[
            SimpleMenuItem(
                child: const Text('Просмотреть'),
                onPress: () {
                  Routemaster.of(context).push('/pack_editor/${packInfo.packId}');
                }
            )
          ],

          if (!packInfo.published) ...[
            SimpleMenuItem(
                child: const Text('Изменить'),
                onPress: () {
                  Routemaster.of(context).push('/pack_editor/${packInfo.packId}').result.then((value) async {
                    if (!mounted) return;
                    await _refresh();
                    setState(() {});
                  });

                }
            )
          ],

          if (packInfo.userID == widget.user.objectId) ...[
            SimpleMenuItem(
                child: const Text('Создать новую версию'),
                onPress: () {
                  _copyPackage(packInfo.packId, newVersion : true);
                }
            ),
          ],

          SimpleMenuItem(
              child: const Text('Создать копию'),
              onPress: () {
                _copyPackage(packInfo.packId, newVersion : false);
              }
          ),

          if (packInfo.published) ...[
            SimpleMenuItem(
                child: const Text('Назначит пакет детям'),
                onPress: () {
                  _addPackForChildDialog(packInfo);
                }
            ),
          ],

          SimpleMenuItem(
              child: const Text('Удалить пакет'),
              onPress: () {
                _deletePackage(packInfo.packId);
              }
          ),

          if (!packInfo.published) ...[
            SimpleMenuItem(
                child: const Text('Опубликовать пакет'),
                onPress: () {
                  _publishPackage(packInfo.packId);
                }
            ),
          ],

        ]
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

  Future<void> _createNewPackage() async {
    final parameters = await _createNewPackageDialog();
    if (parameters == null) return;

    final createPackFunction = ParseCloudFunction('createNewPackage');
    final response = await createPackFunction.execute(parameters: parameters);

    final packId = response.result?[ParseWebPackHead.packId];

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
    )??false;

    if (!result) return;

    final deletePackFunction = ParseCloudFunction('deletePackage');
    final response = await deletePackFunction.execute(parameters: {ParseWebPackHead.packId : packId});

    if (!response.success) {

      return;
    }

    await _refresh();
    setState(() {});
  }

  Future<void> _publishPackage(int packId) async {
    final result = await simpleDialog(
        context: context,
        title: const Text('Опубликовать пакет?')
    )??false;

    if (!result) return;

    final publishPackFunction = ParseCloudFunction('publishPackage');
    final response = await publishPackFunction.execute(parameters: {ParseWebPackHead.packId : packId});

    if (!response.success) {
      final errCode = response.result?["errCode"];
      Fluttertoast.showToast(msg: errCode);
      return;
    }

    await _refresh();
    setState(() {});
  }

  Future<void> _copyPackage(int packId, {required bool newVersion}) async {
    final result = await simpleDialog(
        context: context,
        title: Text(newVersion ? 'Создать новую версию пакета' : 'Создать копию пакет')
    )??false;

    if (!result) return;

    final copyPackFunction = ParseCloudFunction('copyPackage');
    final response = await copyPackFunction.execute(parameters: {ParseWebPackHead.packId : packId, 'newVersion' : newVersion});

    final newPackId = response.result?[ParseWebPackHead.packId];

    if (!response.success || newPackId == null) {
      final errCode = response.result?["errCode"];
      Fluttertoast.showToast(msg: errCode);
      return;
    }

    if (!mounted) return;

    Routemaster.of(context).push('/pack_editor/$newPackId').result.then((value) async {
      await _refresh();
      setState(() {});
    });
  }

  Future<void> _addPackForChildDialog(WebPackInfo packInfo) async {
    if (widget.childManager.childList.isEmpty) {
      await widget.childManager.refreshChildList();
    }
    if (widget.childManager.childList.isEmpty) {
      Fluttertoast.showToast(msg: 'Ещё нет ни одного ребёнка');
      return;
    }

    final selectedDevice = <WebChildDevice>[];

    final result = await simpleDialog(
      context: context,
      title: Text('Назначить пакет детям\n${packInfo.title}'),
      barrierDismissible: true,
      content: StatefulBuilder(builder: (context, setState) {
        return SingleChildScrollView(
          child: ListBody(
            children: widget.childManager.deviceList.map((device) {
              final added = device.packInfoList.any((testPackInfo) => testPackInfo.packId == packInfo.packId);

              return ListTile(
                leading: Checkbox(
                  value: added || selectedDevice.contains(device),
                  onChanged: added? null : (bool? value) {
                    if (value == null) return;
                    if (value) {
                      selectedDevice.add(device);
                    } else {
                      selectedDevice.remove(device);
                    }
                    setState((){});
                  },
                ),
                title: Text('${device.name} ${device.deviceName}'),
              );
            }).toList(),
          ),
        );
      })
    )?? false;

    if (!result) return;

    for (var device in selectedDevice) {
      await _addPackForChild(packInfo, device);
    }
  }

  Future<void> _addPackForChild(WebPackInfo packInfo, WebChildDevice device) async {
    await widget.childManager.addPack(packInfo, device);
  }
}
