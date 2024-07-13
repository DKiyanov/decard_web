import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path_util;

import '../card_model.dart';
import '../decardj.dart';
import '../parse_pack_info.dart';
import 'pack_file_source_list.dart';
import '../simple_events.dart' as event;

class _FileInfo {
  final dynamic file;
  final String filename;
  final int fileSize;
  final String path;
  final bool isNew;
  bool uploaded = false;
  String? url;

  _FileInfo({
    required this.file,
    required this.filename,
    required this.fileSize,
    required this.path,
    required this.isNew
  });
}

typedef OnCheckFileExists = bool Function(String filePath);
typedef OnFileUpload = Function(String filePath, String url);

class PackFileSourceUpload extends StatefulWidget {
  final int packId;
  final String rootPath;
  final PackFileSourceController selectController;
  final OnCheckFileExists? onCheckFileExists;
  final OnFileUpload? onFileUpload;
  final VoidCallback? onClearFileUploadList;

  const PackFileSourceUpload({
    required this.packId,
    required this.rootPath,
    required this.selectController,
    this.onCheckFileExists,
    this.onFileUpload,
    this.onClearFileUploadList,

    Key? key
  }) : super(key: key);

  @override
  State<PackFileSourceUpload> createState() => _PackFileSourceUploadState();
}

class _PackFileSourceUploadState extends State<PackFileSourceUpload> {
  late DropzoneViewController _dzController;

  bool _dzHover = false;
  final _dropzoneBackgroundKey = GlobalKey();

  final _fileList = <_FileInfo>[];

  late event.Listener _selectControllerListener;

  final _titleKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _selectControllerListener = widget.selectController.onChange.subscribe((listener, data) {
      _titleKey.currentState?.setState(() {});
    });

    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _pickFiles();
      });
    }
  }

  @override
  void dispose() {
    _selectControllerListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = _fileList.map((fileInfo) => ListTile(
      tileColor: fileInfo.uploaded? Colors.green : !fileInfo.isNew? Colors.deepOrangeAccent : null,
      title: Text(fileInfo.filename),
    )).toList();

    return Column(children: [
      if (_fileList.isNotEmpty || !kIsWeb) ...[
        Row(children: [
          if (!kIsWeb) ...[
            ElevatedButton(
              onPressed: () {
                _pickFiles();
              },
              child: const Icon(Icons.folder_special_sharp),
            ),

            Container(width: 4),
          ],

          Expanded(
            child: ElevatedButton(
                onPressed: _fileList.any((fileInfo) => !fileInfo.uploaded)? () {
                  _sendAllFiles();
                } : null,
                child: Text('Загрузить файлы в\n${widget.selectController.selectedDir.isEmpty ? 'Корневой каталог' : widget.selectController.selectedDir}',
                  key: _titleKey,
                  textAlign: TextAlign.center,
                )
            ),
          ),

          Container(width: 4),

          ElevatedButton(
            onPressed: (){
              _fileList.clear();
              widget.onClearFileUploadList?.call();
              setState(() {});
            },
            child: const Icon(Icons.clear, color: Colors.red,),
          )
        ]),
      ],

      if (kIsWeb) ...[
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide( color: Colors.grey.shade300))
          ),
          child: LimitedBox(
            maxHeight: 150,
            child: ListView(
              shrinkWrap: true,
              children: children,
            ),
          ),
        ),

        Expanded( child: _dropZoneWidget() ),
      ],

      if (!kIsWeb) ...[
        Container(
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide( color: Colors.grey.shade300))
          ),
          child: Expanded(
            child: ListView(
              children: children,
            ),
          ),
        ),
      ],

    ]);
  }

  Widget _dropZoneWidget() {
    return Stack(
      children: [

        DropzoneView(
          operation: DragOperation.copy,
          cursor: CursorType.grab,

          onCreated: (ctrl) {
            _dzController = ctrl;
          },

          onHover: () {
            if (_dzHover) return;
            _dzHover = true;
            _dropzoneBackgroundKey.currentState?.setState((){});
          },

          onLeave: () {
            if (!_dzHover) return;
            _dzHover = false;
            _dropzoneBackgroundKey.currentState?.setState((){});
          },

          onDropMultiple: (fileList) async {
            if (fileList == null) return;
            await _dropZoneAddFiles(fileList);
            _dzHover = false;
            _dropzoneBackgroundKey.currentState?.setState((){});
          },
        ),

        StatefulBuilder(
            key: _dropzoneBackgroundKey,
            builder: (context, setState) {
              return Container(
                color: _dzHover ? Colors.grey.shade300 : null,
              );
            }
        ),

        Center(
          child: ElevatedButton(
            onPressed: () async {
              final fileList = await _dzController.pickFiles();
              await _dropZoneAddFiles(fileList);
              setState(() {});
            },
            child: const Text('Выбирите файлы'),
          ),
        )

      ],
    );
  }

  Future<void> _dropZoneAddFiles(List<dynamic> fileList) async {
    int skipCount = 0;
    int addCount = 0;

    for (var file in fileList) {
      final fileName = await _dzController.getFilename(file);
      final fileExt = FileExt.getFileExt(fileName);

      if (FileExt.sourceExtList.contains(fileExt)) {
        final path = path_util.join(widget.selectController.selectedDir, fileName);
        _fileList.add(
            _FileInfo(
              file     : file,
              filename : fileName,
              fileSize : await _dzController.getFileSize(file),
              path     : path,
              isNew    : _checkIsNew(path),
            )
        );
        addCount ++;
      } else {
        skipCount ++;
      }
    }

    String msg = '';
    if (addCount == 0 && skipCount > 0) {
      msg = 'Для загрузки возможны файлы с расширениями: ${DjfFileExtension.values.join(', ')}';
    } else if (addCount > 0 && skipCount > 0) {
      msg = 'Файлы с не подходящим расширением были пропущены';
    }
    if (msg.isNotEmpty) {
      Fluttertoast.showToast(msg: msg);
    }

    setState(() {});
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: FileExt.sourceExtList,
    );

    if (result == null) return;

    for (var selFilePath in result.paths) {
      final fileName = path_util.basename(selFilePath!);
      final path = path_util.join(widget.selectController.selectedDir, fileName);
      final file = File(selFilePath);

      _fileList.add(
          _FileInfo(
            file     : file,
            filename : fileName,
            fileSize : file.lengthSync(),
            path     : path,
            isNew    : _checkIsNew(path),
          )
      );
    }

    setState(() {});
  }

  bool _checkIsNew(String filePath) {
    return !(widget.onCheckFileExists?.call(filePath)??false);
  }

  Future<Uint8List> _getFileContent(_FileInfo fileInfo) async {
    if (kIsWeb) {
      return await _dzController.getFileData(fileInfo.file);
    }

    final File file = fileInfo.file as File;
    return await file.readAsBytes();
  }

  Future<void> _sendAllFiles() async {
    for (var fileInfo in _fileList) {
      if (!fileInfo.uploaded) {
        await _putFileToServer(fileInfo);
        widget.onFileUpload?.call(fileInfo.path, fileInfo.url!);

        setState(() {});
      }
    }
  }

  /// sends file to the server
  Future<void> _putFileToServer(_FileInfo fileInfo) async {
    final path = path_util.join(widget.rootPath, widget.selectController.selectedDir, fileInfo.filename);
    final fileContent  = await _getFileContent(fileInfo);

    fileInfo.url = await addFileToPack(widget.packId, path, fileContent);
    fileInfo.uploaded = true;
  }
}