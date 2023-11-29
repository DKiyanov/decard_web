import 'package:decard_web/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'page_scaffold.dart';
import 'package:path/path.dart' as path_util;

class UploadFile extends StatefulWidget {
  const UploadFile({Key? key}) : super(key: key);

  @override
  State<UploadFile> createState() => _UploadFileState();
}

class FileInfo {
  final dynamic file;
  final String filename;
  final int fileSize;
  bool uploaded = false;

  FileInfo(this.file, this.filename, this.fileSize);
}

class _UploadFileState extends State<UploadFile> {
  static const String _clsFile     = 'UploadWebFile';
  static const String _fldUserID   = 'UserID';
  static const String _fldFileName = 'FileName';
  static const String _fldSize     = 'Size';
  static const String _fldContent  = 'Content';

  late DropzoneViewController _dzController;

  bool _dzHover = false;

  final _fileList = <FileInfo>[];

  void _addFiles(List<dynamic> fileList) async {
    for (var file in fileList) {
      final filename = await _dzController.getFilename(file);
      final fileExt = path_util.extension(filename).toLowerCase();

      if (fileExt == '.decardj' || fileExt == '.decardz') {
        _fileList.add(
            FileInfo(
                file,
                filename,
                await _dzController.getFileSize(file)
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!appState.serverConnect.isLoggedIn) {
      return const PageScaffold(
        title: 'UploadFile',
        body: Center(child: Text('Для загрузки файлов сначало нужной войти')),
      );
    }

    return PageScaffold(
      title: 'UploadFile',
      body: Column(children: [
        Container(
          color: _dzHover ? Colors.red : Colors.green,
          height: 200,
          child: Stack(
            children: [
              DropzoneView(
                operation: DragOperation.copy,
                cursor: CursorType.grab,

                onCreated: (ctrl) => _dzController = ctrl,

                onLoaded: () => print('Zone 1 loaded'),

                onError: (ev) => print('Zone 1 error: $ev'),

                onHover: () {
                  setState(() => _dzHover = true);
                  //print('Zone 1 hovered');
                },
                onLeave: () {
                  setState(() => _dzHover = false);
                  print('Zone 1 left');
                },

                // onDrop: (ev) async {
                //   print('Zone 1 drop: ${ev}');
                //   setState(() {
                //     _dzHover = false;
                //   });
                //   final bytes = await _dzController.getFileData(ev);
                //   print(bytes.sublist(0, 20));
                // },

                onDropInvalid: (ev) => print('Zone 1 invalid MIME: $ev'),

                onDropMultiple: (fileList) async {
                  if (fileList == null) return;
                  _addFiles(fileList);
                  setState(() {});
                },
              ),

              Center(
                child: ElevatedButton(
                  onPressed: () async{
                    final fileList = await _dzController.pickFiles();
                    _addFiles(fileList);
                    setState(() {});
                  },
                  child: const Text('Select file'),
                ),
              )

            ],
          ),
        ),

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

          Expanded(
            child: ListView(
              children: _fileList.map((fileInfo) => ListTile(
                tileColor: fileInfo.uploaded? Colors.green : null,
                title: Text(fileInfo.filename),
              )).toList(),
            ),
          ),
        ],
      ])
    );
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

    final query =  QueryBuilder<ParseObject>(ParseObject(_clsFile));
    query.whereEqualTo(_fldUserID, userID);
    query.whereEqualTo(_fldFileName, fileName);

    {
      final serverFile = await query.first();
      if (serverFile != null) {
        print('delete file');
        await serverFile.delete();
      }
    }

    final fileContent  = await _dzController.getFileData(htmlFile);
    final fileSize     = await _dzController.getFileSize(htmlFile);
    final techFileName = '${DateTime.now().millisecondsSinceEpoch}.data';

    final serverFileContent = ParseWebFile(fileContent, name : techFileName);
    print('before save file');
    await serverFileContent.save();
    print('after save file');

    final serverFile = ParseObject(_clsFile);
    serverFile.set<String>(_fldUserID  , userID);
    serverFile.set<String>(_fldFileName, fileName);
    serverFile.set<int>(_fldSize, fileSize);
    serverFile.set<ParseWebFile>(_fldContent, serverFileContent);
    await serverFile.save();
  }
}