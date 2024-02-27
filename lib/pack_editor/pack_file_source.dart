import 'package:decard_web/db.dart';
import 'package:decard_web/dk_expansion_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../card_model.dart';
import '../parse_pack_info.dart';
import '../simple_dialog.dart';
import '../simple_menu.dart';
import 'pack_editor.dart';
import 'pack_file_source_preview.dart';
import 'pack_file_source_upload.dart';

import 'package:simple_events/simple_events.dart' as event;
import 'package:path/path.dart' as path_util;

import 'pack_widgets.dart';

class PackFileSource extends StatefulWidget {
  final PackEditorState editor;
  final int packId;
  final int jsonFileID;
  final String rootPath;
  final DbSource dbSource;
  final Map<String, String> fileUrlMap;

  const PackFileSource({
    required this.editor,
    required this.packId,
    required this.jsonFileID,
    required this.rootPath,
    required this.dbSource,
    required this.fileUrlMap,

    Key? key
  }) : super(key: key);

  @override
  State<PackFileSource> createState() => PackFileSourceState();
}

enum _PackFileSourceMode{
  none,
  upload,
  preview
}

class PackFileSourceState extends State<PackFileSource> with AutomaticKeepAliveClientMixin<PackFileSource> {
  static const Map<String, String> _createFileMap = {
    FileExt.contentTextConstructor : 'Создать файл конструктор текстов',
    FileExt.contentTxt             : 'Создать простой текстовый файл',
  };

  final _scrollbarController = ScrollController();

  var _mode = _PackFileSourceMode.none;

  late PackFileSourceController _selectController;

  bool _moveButtonVisible = false;

  @override
  bool get wantKeepAlive => true;

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

    _selectController = PackFileSourceController(fileList);
  }

  @override
  void dispose() {
    _scrollbarController.dispose();
    super.dispose();
  }

  void setSelectedFileSource(String filePath) {
    _selectController.setSelection(filePath, true);

    Future.delayed(const Duration(milliseconds: 500), (){
      if (_selectController.selectedWidgetContext != null) {
        Scrollable.ensureVisible(_selectController.selectedWidgetContext!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide( color: Colors.grey.shade300))
          ),

          child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              event.EventReceiverWidget(
                builder: (context){
                  if (widget.editor.needFileSourceController == null) return Container();

                  bool retPossible = false;
                  if (_selectController.isFile) {
                    if (widget.editor.needFileExtList.isEmpty) {
                      retPossible = true;
                    } else {
                      final fileExt = FileExt.getFileExt(_selectController.selectedPath);
                      retPossible = widget.editor.needFileExtList.contains(fileExt);
                    }
                  }

                  return Tooltip(
                    message: 'Вставить файл',
                    child: IconButton(
                        onPressed: !retPossible ? null : (){
                          widget.editor.needFileSourceController!.text = _selectController.selectedPath;
                        },
                        icon: Icon(Icons.arrow_back_sharp, color: retPossible? Colors.blue : Colors.grey)
                    ),
                  );
                },
                events: [
                  _selectController.onChange,
                  widget.editor.onNeedFileSourceControllerChanged,
                ],
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

              event.EventReceiverWidget(
                builder: (context) {
                  final editPossible = _selectController.checkboxPaths.isEmpty
                    && _selectController.isFile
                    && _createFileMap.keys.contains(FileExt.getFileExt(_selectController.selectedPath));

                  return Tooltip(
                    message: 'Редактировать файл',
                    child: IconButton(
                      onPressed: !editPossible? null : (){
                        final url = widget.fileUrlMap[_selectController.selectedPath]!;
                        widget.editor.editSourceFile(_selectController.selectedPath, url);
                      },
                      icon: const Icon(Icons.edit),
                    ),
                  );
                },
                events: [_selectController.onChange],
              ),

              popupMenu(
                icon: const Icon(Icons.menu),
                menuItemList: _createFileMap.entries.map((entry) {
                  return  SimpleMenuItem(
                      child: Text(entry.value),
                      onPress: () {
                        final filename = path_util.join(_selectController.selectedDir, 'new.${entry.key}');
                        widget.editor.editSourceFile(filename, '');
                      },
                    );
                }).toList(),
              ),

              event.EventReceiverWidget(
                builder: (context){
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
                },
                events: [
                  _selectController.onChange,
                  _selectController.onCheckboxChanged,
                ],
                onEventCallback: (listener, object){
                  final newMoveButtonVisible = _selectController.checkboxPaths.isNotEmpty && _selectController.selectedPath.isNotEmpty;
                  if (_moveButtonVisible != newMoveButtonVisible) {
                    _moveButtonVisible = newMoveButtonVisible;
                    return true;
                  }
                  return false;
                },
              ),

          ]),
        ),

        Expanded(
          child: Container(
            color: Colors.grey,
            child: _panelsCombinations(),
          ),
        ),

      ],
    );
  }

  Widget _panelsCombinations() {
    if (_mode == _PackFileSourceMode.none) {
      return _filePanel();
    }

    if (_mode == _PackFileSourceMode.preview) {
      return MultiSplitView(
        key: const ValueKey(_PackFileSourceMode.preview),
        axis: Axis.vertical,
        initialAreas: [
          Area(weight: 0.3)
        ],
        children: [
          _previewPanel(),
          _filePanel(),
        ]
      );
    }

    if (_mode == _PackFileSourceMode.upload) {
      return MultiSplitView(
        key: const ValueKey(_PackFileSourceMode.upload),
        axis: Axis.vertical,
        initialAreas: [
          Area(),
          Area(size: 150),
        ],
        children: [
          _filePanel(),
          _uploadPanel(),
        ]
      );
    }

    return Container();
  }

  Widget _filePanel() {
    return Container(
      color: Colors.white,
      child: Scrollbar(
        controller: _scrollbarController,
        child: SingleChildScrollView(
          controller: _scrollbarController,
          child: _Folder(
            controller: _selectController,
            path: '.',
          ),
        ),
      ),
    );
  }

  Widget _uploadPanel() {
    return Container(
      color: Colors.white,
      child: PackFileSourceUpload(
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
          addNewFile(filePath, url);
        },
        onClearFileUploadList: (){
          _selectController.multiSelPaths.clear();
          _selectController.onChange.send();

          _mode = _PackFileSourceMode.none;
          setState(() {});
        },
      ),
    );
  }

  void addNewFile(String filePath, String url) {
    _selectController.multiSelPaths.remove(filePath);
    if (!_selectController.fileList.contains(filePath)) {
      _selectController.fileList.add(filePath);
    }
    widget.fileUrlMap[filePath] = url;
    widget.dbSource.tabFileUrlMap.insertRow(jsonFileID: widget.jsonFileID, fileName: filePath, url: url);
    //_folderController.onChangeSelection.send();
    JsonWidgetChangeListener.of(context)?.setChanged();

    setState(() {});
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
    return Container(
      color: Colors.white,

      child: event.EventReceiverWidget(
        builder: (context){
          if (!_selectController.isFile) return Container();
          final url = widget.fileUrlMap[_selectController.selectedPath]!;

          return PackFileSourcePreview(
            fileName : _selectController.selectedPath,
            url      : url,
            onPrepareFileUrl: (fileName) {
              return widget.fileUrlMap[fileName];
            },
          );
        },
        events: [_selectController.onChange],
      ),
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
    )??false;

    if (!result || folderName.isEmpty) return;

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

  PackFileSourceController(this.fileList);

  String _selectedPath = "";
  String get selectedPath => _selectedPath;

  String _selectedDir = "";
  String get selectedDir => _selectedDir;

  bool _isFile = false;
  bool get isFile => _isFile  && _selectedPath.isNotEmpty;
  bool get isDir  => !_isFile && _selectedPath.isNotEmpty;

  BuildContext? selectedWidgetContext;

  final multiSelPaths = <String>[];

  final checkboxPaths = <String>[];

  final onChange = event.SimpleEvent();
  final onCheckboxChanged = event.SimpleEvent();

  void setSelection(String path, bool isFile) {
    _selectedPath = path;
    _isFile = isFile;
    selectedWidgetContext = null;

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

    onCheckboxChanged.send();
  }
}

class _Folder extends StatefulWidget {
  final PackFileSourceController controller;
  final String path;
  const _Folder({required this.controller, required this.path, Key? key}) : super(key: key);

  @override
  State<_Folder> createState() => _FolderState();
}

class _FolderState extends State<_Folder> {
  late event.Listener _selectControllerListener;
  final _expansionController =  DkExpansionTileController();

  @override
  void initState() {
    super.initState();

    _selectControllerListener = widget.controller.onChange.subscribe((listener, data) {
      if (path_util.isWithin(widget.path, widget.controller.selectedPath)) {
        if (_expansionController.isAssigned) {
          _expansionController.expand();
        }
      }
    });
  }

  @override
  void dispose() {
    _selectControllerListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final subFolders = <String>[];

    for (var filePath in widget.controller.fileList) {
      final fileDirPath = path_util.dirname(filePath);
      if (fileDirPath == widget.path) {

        final fileName = path_util.basename(filePath);

        if (fileName != '.') {
          children.add(
            _PathWidget(
              path: filePath,
              isFile: true,

              selectController: widget.controller,
              builder: (context, selColor, selBackgroundColor, setCheckbox) {
                Widget? leading;

                if (setCheckbox != null) {
                  leading = Checkbox(
                    value: widget.controller.checkboxPaths.contains(filePath),
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
                    widget.controller.setSelection(filePath, true);
                  },
                  onLongPress: (){
                    widget.controller.setCheckbox(filePath, true);
                  },
                );
              }
            )
          );
        }
      }

      if (fileDirPath != '.') {
        final prevPath = path_util.dirname(fileDirPath);
        if (prevPath == widget.path && !subFolders.contains(fileDirPath)) {
          subFolders.add(fileDirPath);
        }
      }
    }

    for (var subFolder in subFolders) {
      children.add(
        _Folder(
          controller : widget.controller,
          path       : subFolder,
        )
      );
    }

    if (widget.path != '.') {
      return Padding(
        padding: const EdgeInsets.only(left: 20),
        child: DkExpansionTile(
          controller: _expansionController,
          title: _PathWidget(
            path: widget.path,
            isFile: false,
            selectController: widget.controller, builder: (context, selColor, selBackgroundColor, showCheckBox) {
              return Container(
                color: selBackgroundColor,
                child: Text(widget.path, style: TextStyle(color: selColor??Colors.black))
              );
            },
          ),

          onTap: () {
            widget.controller.setSelection(widget.path, false);
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
    if (widget.isFile && widget.selectController.selectedPath == widget.path) {
      widget.selectController.selectedWidgetContext = context;
    }

    return widget.builder.call(context, color, backgroundColor, !showCheckbox ? null : _setCheckbox);
  }

  void _setCheckbox(bool checked) {
    widget.selectController.setCheckbox(widget.path, checked);
    setState(() {});
  }
}

