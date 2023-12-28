import 'package:decard_web/db.dart';
import 'package:decard_web/dk_expansion_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../card_model.dart';
import '../parse_pack_info.dart';
import '../simple_dialog.dart';
import 'pack_file_source_preview.dart';
import 'pack_file_source_upload.dart';

import 'package:simple_events/simple_events.dart' as event;
import 'package:path/path.dart' as path_util;

import 'pack_widgets.dart';

class PackFileSource extends StatefulWidget {
  final int packId;
  final int jsonFileID;
  final String rootPath;
  final DbSource dbSource;
  final Map<String, String> fileUrlMap;

  const PackFileSource({
    required this.packId,
    required this.jsonFileID,
    required this.rootPath,
    required this.dbSource,
    required this.fileUrlMap,

    Key? key
  }) : super(key: key);

  @override
  State<PackFileSource> createState() => _PackFileSourceState();
}

enum _PackFileSourceMode{
  none,
  upload,
  preview
}

class _PackFileSourceState extends State<PackFileSource> {
  final _scrollbarController = ScrollController();

  var _mode = _PackFileSourceMode.none;

  final _previewPanelKey = GlobalKey();

  late PackFileSourceController _selectController;
  late event.Listener _selectControllerListener;

  bool _moveButtonVisible = false;
  final _moveButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    final fileList = <String>[];

    for (var file in widget.fileUrlMap.keys) {
      final fileExt = path_util.extension(file).substring(1).toLowerCase();

      if (FileExt.sourceExtList.contains(fileExt)) {
        fileList.add(file);
      }
    }

    _selectController = PackFileSourceController(fileList, (){
      _calcMoveButtonVisible();
    });

    _selectControllerListener = _selectController.onChange.subscribe((listener, data) {
      _previewPanelKey.currentState?.setState(() {});
      _calcMoveButtonVisible();
    });
  }

  void _calcMoveButtonVisible() {
    final newMoveButtonVisible = _selectController.checkboxPaths.isNotEmpty && _selectController.selectedPath.isNotEmpty;
    if (_moveButtonVisible != newMoveButtonVisible) {
      _moveButtonVisible = newMoveButtonVisible;
      _moveButtonKey.currentState?.setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollbarController.dispose();
    _selectControllerListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Tooltip(
              message: 'Вставить в тело карточки',
              child: IconButton(
                  onPressed: (){

                  },
                  icon: const Icon(Icons.arrow_back_sharp)
              ),
            ),

            Tooltip(
              message: 'Удалить',
              child: IconButton(
                  onPressed: (){
                    if (_selectController.checkboxPaths.isNotEmpty) {
                      _deleteSelectedFilesFromPack();
                      return;
                    }

                    if (_selectController.isDir) {
                      _deleteFolder(_selectController.selectedDir);
                      return;
                    }

                    _deleteFileFromPack();
                  },
                  icon: const Icon(Icons.delete_outline),
              ),
            ),

            Tooltip(
              message: 'Загрузить',
              child: IconButton(
                  onPressed: (){
                    if (_mode == _PackFileSourceMode.upload) {
                      _mode = _PackFileSourceMode.none;
                    } else {
                      _mode = _PackFileSourceMode.upload;
                    }

                    setState(() {});
                  },
                  icon: Icon(kIsWeb? Icons.upload_outlined : Icons.folder_special_outlined, color: _mode == _PackFileSourceMode.upload ? Colors.green : null )
              ),
            ),

            Tooltip(
              message: 'Предварительный просмотр',
              child: IconButton(
                  onPressed: (){
                    if (_mode == _PackFileSourceMode.preview) {
                      _mode = _PackFileSourceMode.none;
                    } else {
                      _mode = _PackFileSourceMode.preview;
                    }

                    setState(() {});
                  },
                  icon: Icon(Icons.image_outlined, color: _mode == _PackFileSourceMode.preview ? Colors.green : null)
              ),
            ),

            Tooltip(
              message: 'Создать каталог',
              child: IconButton(
                onPressed: (){
                  _createFolder();
                },
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
            ),

            StatefulBuilder(
              key: _moveButtonKey,
              builder: (context, setState) {
                if (!_moveButtonVisible) {
                  return Container();
                }

                return Tooltip(
                  message: 'Переместить выбранные файлы в выбранный каталог',
                  child: IconButton(
                    onPressed: (){
                      _moveFilesToFolder();
                    },
                    icon: const Icon(Icons.move_down),
                  ),
                );
              }
            ),
        ]),

        if (_mode == _PackFileSourceMode.preview) ...[
          Expanded(child: _previewPanel()),
        ],

        Expanded(child: _filePanel() ),

        if (_mode == _PackFileSourceMode.upload) ...[
          Expanded(child: _uploadPanel()),
        ]
      ],
    );
  }

  Widget _filePanel() {
    return Scrollbar(
      controller: _scrollbarController,
      child: SingleChildScrollView(
        controller: _scrollbarController,
        child: _Folder(
          controller: _selectController,
          path: '.',
        ),
      ),
    );
  }

  Widget _uploadPanel() {
    return PackFileSourceUpload(
      packId: widget.packId,
      rootPath: widget.rootPath,
      selectController: _selectController,
      onCheckFileExists: (filePath){
        final result = widget.fileUrlMap[filePath] != null;
        if (result) {
          _selectController.multiSelPaths.add(filePath);
          _selectController.onChange.send();
        }
        return result;
      },
      onFileUpload: (filePath, url){
        _selectController.multiSelPaths.remove(filePath);
        if (!_selectController.fileList.contains(filePath)) {
          _selectController.fileList.add(filePath);
        }
        widget.fileUrlMap[filePath] = url;
        widget.dbSource.tabFileUrlMap.insertRow(jsonFileID: widget.jsonFileID, fileName: filePath, url: url);
        //_folderController.onChangeSelection.send();
        JsonWidgetChangeListener.of(context)?.setChanged();

        setState(() {});
      },
      onClearFileUploadList: (){
        _selectController.multiSelPaths.clear();
        _selectController.onChange.send();

        _mode = _PackFileSourceMode.none;
        setState(() {});
      },
    );
  }

  Future<void> _deleteFileFromPack() async {
    if (!_selectController.isFile) return;

    if (! await warningDialog(context, 'Удалить файл "${_selectController.selectedPath}" ?')) return;

    _deleteFileFromPackEx(_selectController.selectedPath);

    JsonWidgetChangeListener.of(context)?.setChanged();

    _selectController.setSelection("", true);

    setState(() {});
  }

  Future<void> _deleteFileFromPackEx(String filePath) async {
    _selectController.fileList.remove(filePath);
    _selectController.setCheckbox(filePath, false);

    final path = path_util.join(widget.rootPath, filePath);
    deleteFileFromPack(widget.packId, path);

    widget.dbSource.tabFileUrlMap.deleteRow(jsonFileID: widget.jsonFileID, fileName: filePath) ;
    widget.fileUrlMap.remove(filePath);
  }

  Future<void> _deleteSelectedFilesFromPack() async {
    if (_selectController.checkboxPaths.isEmpty) return;
    if (! await warningDialog(context, 'Удалить выбранные файл ?')) return;

    final delFileList = <String>[];
    delFileList.addAll(_selectController.checkboxPaths);

    for (var filePath in delFileList) {
      await _deleteFileFromPackEx(filePath);
    }

    if (!mounted) return;

    JsonWidgetChangeListener.of(context)?.setChanged();

    _selectController.setSelection("", true);

    setState(() {});
  }

  Widget _previewPanel() {
    return StatefulBuilder(
      key: _previewPanelKey,
      builder: (context, setState) {
        if (!_selectController.isFile) return Container();
        final url = widget.fileUrlMap[_selectController.selectedPath]!;

        return Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: PackFileSourcePreview(
            fileName : _selectController.selectedPath,
            url      : url,
          ),
        );
      },
    );
  }

  Future<void> _createFolder() async {
    String folderName = '';

    final result = await simpleDialog(
      context: context,
      title: const Text('Создание каталога'),
      content: StatefulBuilder(builder: (context, setState) {
        return TextField(
          onChanged: (value){
            folderName = value;
          },
        );
      })
    );

    if (result == null || !result || folderName.isEmpty) return;

    final path = path_util.join(_selectController.selectedDir, folderName, '.');
    _selectController.fileList.add(path);

    setState(() {});
  }

  Future<void> _deleteFolder(String folderPath) async {
    final delFileList = <String>[];

    for (var filePath in _selectController.fileList) {
      if (!path_util.isWithin(folderPath, filePath)) continue;
      delFileList.add(filePath);
    }

    if (delFileList.isNotEmpty) {
      if (! await warningDialog(context, 'Каталог "$folderPath" не пустой, хотите удалить каталог вместе с содержимым?')) return;
    } else {
      if (! await warningDialog(context, 'Удалить каталог "$folderPath" ?')) return;
    }

    if (delFileList.isNotEmpty) {
      for (var filePath in delFileList) {
        await _deleteFileFromPackEx(filePath);
      }
    }

    final specPath = path_util.join(folderPath, '.');
    _selectController.fileList.remove(specPath);

    if (!mounted) return;

    JsonWidgetChangeListener.of(context)?.setChanged();

    _selectController.setSelection("", false);

    setState(() {});
  }

  Future<void> _moveFilesToFolder() async {
    if (! await warningDialog(context, 'Переместить выбранные файлы в "${_selectController.selectedDir.isEmpty? 'Корневой каталог' : _selectController.selectedDir}" ?')) return;

    final moveFileList = <String>[];
    moveFileList.addAll(_selectController.checkboxPaths);

    for (var filePath in moveFileList) {
      await _moveFileToFolder(filePath, _selectController.selectedDir);
    }

    if (!mounted) return;

    JsonWidgetChangeListener.of(context)?.setChanged();

    _selectController.setSelection("", false);

    setState(() {});
  }

  Future<void> _moveFileToFolder(String filePath, String folderPath) async {
    final fileName = path_util.basename(filePath);
    final newFilePath = path_util.join(folderPath, fileName);

    if (filePath == newFilePath) return;
    if (_selectController.fileList.contains(newFilePath)) return;

    final url = widget.fileUrlMap[filePath]!;

    final oldFilePathOk = path_util.join(widget.rootPath, filePath);
    final newFilePathOk = path_util.join(widget.rootPath, newFilePath);

    final newUrl = await moveFileInsidePack(widget.packId, oldFilePathOk, newFilePathOk, url);

    if (newUrl == null) return;

    _selectController.multiSelPaths.remove(filePath);

    _selectController.fileList.remove(filePath);
    _selectController.fileList.add(newFilePath);

    if (_selectController.checkboxPaths.remove(filePath)) {
      _selectController.checkboxPaths.add(newFilePath);
    }

    widget.fileUrlMap.remove(filePath);
    widget.dbSource.tabFileUrlMap.deleteRow(jsonFileID: widget.jsonFileID, fileName: filePath);

    widget.fileUrlMap[newFilePath] = newUrl;
    widget.dbSource.tabFileUrlMap.insertRow(jsonFileID: widget.jsonFileID, fileName: newFilePath, url: newUrl);
  }
}

class PackFileSourceController {
  final List<String> fileList;
  final VoidCallback onCheckboxChanged;

  PackFileSourceController(this.fileList, this.onCheckboxChanged);

  String _selectedPath = "";
  String get selectedPath => _selectedPath;

  String _selectedDir = "";
  String get selectedDir => _selectedDir;

  bool _isFile = false;
  bool get isFile => _isFile  && _selectedPath.isNotEmpty;
  bool get isDir  => !_isFile && _selectedPath.isNotEmpty;

  final multiSelPaths = <String>[];

  final checkboxPaths = <String>[];

  final onChange = event.SimpleEvent();

  void setSelection(String path, bool isFile) {
    _selectedPath = path;
    _isFile = isFile;

    if (isFile) {
      _selectedDir = path_util.dirname(path);
    } else {
      _selectedDir = path;
    }
    if (_selectedDir == '.') {
      _selectedDir = '';
    }

    onChange.send();
  }

  void setCheckbox(String path, bool checked){
    final nowCheckboxShow = checkboxPaths.isNotEmpty;

    if (checked && !checkboxPaths.contains(path)) {
      checkboxPaths.add(path);
    }
    if (!checked) {
      checkboxPaths.remove(path);
    }

    final newCheckboxShow = checkboxPaths.isNotEmpty;

    if (nowCheckboxShow != newCheckboxShow) {
      onChange.send();
    }

    onCheckboxChanged.call();
  }
}

class _Folder extends StatelessWidget {
  final PackFileSourceController controller;
  final String path;
  const _Folder({required this.controller, required this.path, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lowPath = path.toLowerCase();

    final children = <Widget>[];
    final subFolders = <String>[];

    for (var filePath in controller.fileList) {
      final lowFilePath = path_util.dirname(filePath).toLowerCase();
      if (lowFilePath == lowPath) {

        final fileName = path_util.basename(filePath);

        if (fileName != '.') {
          children.add(
            _PathWidget(
              path: filePath,
              isFile: true,

              selectController: controller,
              builder: (context, selColor, selBackgroundColor, setCheckbox) {
                Widget? leading;

                if (setCheckbox != null) {
                  leading = Checkbox(
                    value: controller.checkboxPaths.contains(filePath),
                    onChanged: (value) {
                      if (value == null) return;
                      setCheckbox.call(value);
                    }
                  );
                }

                return ListTile(
                  leading: leading,
                  title: Text(path_util.basename(filePath), style: TextStyle(color: selColor)),
                  tileColor: selBackgroundColor,
                  onTap: (){
                    controller.setSelection(filePath, true);
                  },
                  onLongPress: (){
                    controller.setCheckbox(filePath, true);
                  },
                );
              }
            )
          );
        }
      }

      if (lowFilePath != '.') {
        final prevPath = path_util.dirname(lowFilePath);
        if (prevPath == lowPath && !subFolders.contains(lowFilePath)) {
          subFolders.add(lowFilePath);
        }
      }
    }

    for (var subFolder in subFolders) {
      children.add(
        _Folder(
          controller : controller,
          path       : subFolder,
        )
      );
    }

    if (lowPath != '.') {
      return Padding(
        padding: const EdgeInsets.only(left: 20),
        child: DkExpansionTile(
          title: _PathWidget(
            path: lowPath,
            isFile: false,
            selectController: controller, builder: (context, selColor, selBackgroundColor, showCheckBox) {
              return Container(
                color: selBackgroundColor,
                child: Text(lowPath, style: TextStyle(color: selColor??Colors.black))
              );
            },
          ),

          onTap: () {
            controller.setSelection(lowPath, false);
          },
          children: children,
        ),
      );
    }

    return Column(
      children: children,
    );

  }
}

typedef _SetCheckbox = void Function(bool checked);
typedef _SelectBuilder = Widget Function(BuildContext context, Color? selColor, Color? selBackgroudColor, _SetCheckbox? setCheckbox);

class _PathWidget extends StatefulWidget {
  final String path;
  final bool isFile;
  final PackFileSourceController selectController;
  final _SelectBuilder builder;
  const _PathWidget({required this.path, required this.isFile, required this.selectController, required this.builder, Key? key}) : super(key: key);

  @override
  State<_PathWidget> createState() => _PathWidgetState();
}

class _PathWidgetState extends State<_PathWidget> {
  late event.Listener _selectControllerListener;

  Color? color;
  Color? backgroundColor;
  bool showCheckbox = false;

  @override
  void initState() {
    super.initState();

    _selectControllerListener = widget.selectController.onChange.subscribe((listener, data) {
      onChangeSelection();
    });

    onChangeSelection();
  }

  @override
  void dispose() {
    _selectControllerListener.dispose();
    super.dispose();
  }

  void onChangeSelection() {
    Color? newColor;
    Color? newBackgroundColor;
    bool newShowCheckbox = false;

    if (widget.selectController.selectedPath == widget.path) {
      newColor = Colors.blue;
    }

    if (widget.selectController.multiSelPaths.contains(widget.path) ) {
      newBackgroundColor = Colors.deepOrangeAccent;
    }

    newShowCheckbox = widget.isFile && widget.selectController.checkboxPaths.isNotEmpty;

    if (color != newColor || backgroundColor != newBackgroundColor || showCheckbox != newShowCheckbox) {
      color = newColor;
      backgroundColor = newBackgroundColor;
      showCheckbox = newShowCheckbox;

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder.call(context, color, backgroundColor, !showCheckbox ? null : _setCheckbox);
  }

  void _setCheckbox(bool checked) {
    widget.selectController.setCheckbox(widget.path, checked);
    setState(() {});
  }
}

