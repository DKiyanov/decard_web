import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/simple_dialog.dart';
import 'package:decard_web/simple_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:routemaster/routemaster.dart';
import 'common.dart';
import 'pack_upload_file.dart';
import 'decardj.dart';

class OwnPackList extends StatefulWidget {
  final List<Widget>? actions;
  final WebPackListManager packInfoManager;
  final String userID;
  const OwnPackList({required this.packInfoManager, required this.userID, this.actions, Key? key}) : super(key: key);

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
    _webPackList.addAll(await widget.packInfoManager.getUserPackList(widget.userID));
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
              onPress: _startCreateNewPackage,
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
        return ListTile(
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

  Future<void> _startCreateNewPackage() async {
    void Function(void Function())? dialogState;

    final titleController = TextEditingController();
    String titleError = '';

    final ageFromController = TextEditingController();
    String ageFromError = '';

    final ageToController = TextEditingController();
    String ageToError = '';

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

        final ageFrom = int.tryParse(ageFromController.text);
        if (ageFrom == null) {
          ageFromError = 'не корректное значение';
          err = true;
        }

        final ageTo = int.tryParse(ageToController.text);
        if (ageTo == null) {
          ageToError = 'не корректное значение';
          err = true;
        }

        if (ageFrom != null && ageTo != null && ageFrom > ageTo) {
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

    if (result == null || !result) return;
    if (!mounted) return;

    await _createNewPackage({
      DjfFile.title         : titleController.text,
      DjfFile.targetAgeLow  : ageFromController.text,
      DjfFile.targetAgeHigh : ageToController.text,
    });

    //Routemaster.of(context).push('/pack_editor');
  }

  Future<void> _createNewPackage(Map<String, dynamic> json) async {

  }
}
