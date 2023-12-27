import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:path/path.dart' as path_util;

import '../card_model.dart';

class _FileInfo {
  final dynamic file;
  final String filename;
  final int fileSize;
  bool uploaded = false;

  _FileInfo(this.file, this.filename, this.fileSize);
}

class PackFileSourceUpload extends StatefulWidget {
  const PackFileSourceUpload({Key? key}) : super(key: key);

  @override
  State<PackFileSourceUpload> createState() => _PackFileSourceUploadState();
}

class _PackFileSourceUploadState extends State<PackFileSourceUpload> {
  late DropzoneViewController _dzController;

  bool _dzHover = false;

  final _fileList = <_FileInfo>[];

  void _addFiles(List<dynamic> fileList) async {
    for (var file in fileList) {
      final filename = await _dzController.getFilename(file);
      final fileExt = path_util.extension(filename).toLowerCase().substring(1);

      if (FileExt.textExtList.contains(fileExt) ||
          FileExt.imageExtList.contains(fileExt) ||
          FileExt.audioExtList.contains(fileExt)) {
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

  @override
  Widget build(BuildContext context) {
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
            children: _fileList.map((fileInfo) => ListTile(
              tileColor: fileInfo.uploaded? Colors.green : null,
              title: Text(fileInfo.filename),
            )).toList(),
          ),
        ),
      ],

      Expanded(
        child: Container(
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
                  _addFiles(fileList);
                  _dzHover = false;
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
      ),

    ]);
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

  }
}