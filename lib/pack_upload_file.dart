import 'package:decard_web/app_state.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path/path.dart' as path_util;

import 'decardj.dart';

class _FileInfo {
  final dynamic file;
  final String filename;
  final int fileSize;
  bool uploaded = false;

  _FileInfo(this.file, this.filename, this.fileSize);
}

typedef OnFileUpload = Function(String filePath, String url);

class PackUploadFile extends StatefulWidget {
  final OnFileUpload? onFileUpload;
  final VoidCallback? onClearFileUploadList;

  const PackUploadFile({required this.onFileUpload, required this.onClearFileUploadList, Key? key}) : super(key: key);

  @override
  State<PackUploadFile> createState() => _PackUploadFileState();
}

class _PackUploadFileState extends State<PackUploadFile> {
  late DropzoneViewController _dzController;

  bool _dzHover = false;

  final _fileList = <_FileInfo>[];

  @override
  Widget build(BuildContext context) {
    final children = _fileList.map((fileInfo) => ListTile(
      tileColor: fileInfo.uploaded? Colors.green : null,
      title: Text(fileInfo.filename),
    )).toList();

    return Column(children: [
      if (_fileList.isNotEmpty) ...[
        Row(children: [
          Expanded(
            child: ElevatedButton(
                onPressed: _fileList.any((fileInfo) => !fileInfo.uploaded)? () {
                  _sendAllFiles();
                } : null,
                child: const Text('Загрузить файлы')
            ),
          ),

          Container(width: 4),

          ElevatedButton(
            onPressed: (){
              _fileList.clear();
              setState(() {});
            },
            child: const Icon(Icons.clear, color: Colors.red,),
          )
        ]),

        LimitedBox(
          maxHeight: 150,
          child: ListView(
            shrinkWrap: true,
            children: children,
          ),
        ),
      ],

      Expanded( child: _dropZoneWidget() ),
    ]);
  }

  Widget _dropZoneWidget() {
    return Container(
      color: _dzHover ? Colors.red : Colors.green,

      child: Stack(
        children: [
          DropzoneView(
            operation: DragOperation.copy,
            cursor: CursorType.grab,

            onCreated: (ctrl) {
              _dzController = ctrl;
            },

            onHover: () {
              _dzHover = true;
              setState((){});
            },
            onLeave: () {
              _dzHover = false;
              setState((){});
            },

            onDropMultiple: (fileList) async {
              if (fileList == null) return;
              await _dropZoneAddFiles(fileList);
              _dzHover = false;
              setState(() {});
            },
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
      ),
    );
  }

  Future<void> _dropZoneAddFiles(List<dynamic> fileList) async {
    for (var file in fileList) {
      final filename = await _dzController.getFilename(file);
      final fileExt = path_util.extension(filename).toLowerCase();

      if (DjfFileExtension.values.contains(fileExt)) {
        _fileList.add(
            _FileInfo(
                file,
                filename,
                await _dzController.getFileSize(file)
            )
        );
      }
    }
  }

  Future<void> _sendAllFiles() async {
    for (var fileInfo in _fileList) {
      if (!fileInfo.uploaded) {
        await _putFileToServer(fileInfo.file);
        fileInfo.uploaded = true;
        setState(() {});
      }
    }
  }

  /// sends file to the server
  Future<void> _putFileToServer(dynamic htmlFile) async {
    final userID = appState.serverConnect.user!.objectId!;
    final fileName = await _dzController.getFilename(htmlFile);

    final query =  QueryBuilder<ParseObject>(ParseObject(WebPackUploadFileFields.className));
    query.whereEqualTo(WebPackUploadFileFields.userID, userID);
    query.whereEqualTo(WebPackUploadFileFields.fileName, fileName);

    {
      final serverFile = await query.first();
      if (serverFile != null) {
        await serverFile.delete();
      }
    }

    final fileContent  = await _dzController.getFileData(htmlFile);
    final fileSize     = await _dzController.getFileSize(htmlFile);
    final techFileName = '${DateTime.now().millisecondsSinceEpoch}.data';

    final serverFileContent = ParseWebFile(fileContent, name : techFileName);
    await serverFileContent.save();

    final serverFile = ParseObject(WebPackUploadFileFields.className);
    serverFile.set<String>(WebPackUploadFileFields.userID  , userID);
    serverFile.set<String>(WebPackUploadFileFields.fileName, fileName);
    serverFile.set<int>(WebPackUploadFileFields.size, fileSize);
    serverFile.set<ParseWebFile>(WebPackUploadFileFields.content, serverFileContent);
    await serverFile.save();
  }
}