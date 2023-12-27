import 'package:decard_web/dk_expansion_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pack_file_source_preview.dart';
import 'pack_file_source_upload.dart';

import 'package:simple_events/simple_events.dart' as event;
import 'package:path/path.dart' as path_util;

class PackFileSource extends StatefulWidget {
  final Map<String, String> fileUrlMap;

  const PackFileSource({required this.fileUrlMap, Key? key}) : super(key: key);

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

  late _FolderController _folderController;
  late event.Listener folderControllerOnChangeSelectionListener;

  @override
  void initState() {
    super.initState();

    _folderController = _FolderController(
      widget.fileUrlMap.keys.toList()
    );

    folderControllerOnChangeSelectionListener = _folderController.onChangeSelection.subscribe((listener, data) {
      _previewPanelKey.currentState?.setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollbarController.dispose();
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

                  },
                  icon: const Icon(Icons.delete_outline),
              ),
            ),

            if (kIsWeb) ...[
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
                    icon: Icon(Icons.upload_outlined, color: _mode == _PackFileSourceMode.upload ? Colors.green : null )
                ),
              ),
            ],

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
          controller: _folderController,
          path: '.',
        ),
      ),
    );
  }

  Widget _uploadPanel() {
    return const PackFileSourceUpload();
  }

  Widget _previewPanel() {
    return StatefulBuilder(
      key: _previewPanelKey,
      builder: (context, setState) {
        if (_folderController.selectedPath.isEmpty) return Container();
        final url = widget.fileUrlMap[_folderController.selectedPath];
        if (url == null) return Container();

        return Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: PackFileSourcePreview(
            fileName : _folderController.selectedPath,
            url      : url,
          ),
        );
      },
    );
  }
}

class _FolderController {
  final List<String> fileList;

  _FolderController(this.fileList);

  String _selectedPath = "";
  String get selectedPath => _selectedPath;

  final onChangeSelection = event.SimpleEvent();

  void setSelection(String path) {
    _selectedPath = path;
    onChangeSelection.send();
  }
}

class _Folder extends StatelessWidget {
  final _FolderController controller;
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

        children.add(
          ListTile(
            title: _PathWidget(
              path: filePath,
              controller: controller, builder: (context, isSelected) {
                return Text(path_util.basename(filePath), style: TextStyle(color: isSelected? Colors.blue : null));
              },
            ),

            onTap: (){
              controller.setSelection(filePath);
            },
          )
        );
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
      return DkExpansionTile(
        title: _PathWidget(
          path: lowPath,
          controller: controller, builder: (context, isSelected) {
            return Text(lowPath, style: TextStyle(color: isSelected? Colors.blue : Colors.black));
          },
        ),

        onTap: () {
          controller.setSelection(lowPath);
        },
        children: children,
      );
    }

    return Column(
      children: children,
    );

  }
}

typedef _SelectBuilder = Widget Function(BuildContext context, bool isSelected);

class _PathWidget extends StatefulWidget {
  final String path;
  final _FolderController controller;
  final _SelectBuilder builder;
  const _PathWidget({required this.path, required this.controller, required this.builder, Key? key}) : super(key: key);

  @override
  State<_PathWidget> createState() => _PathWidgetState();
}

class _PathWidgetState extends State<_PathWidget> {
  late event.Listener folderControllerOnChangeSelectionListener;

  bool _isSelected = false;

  @override
  void initState() {
    super.initState();

    folderControllerOnChangeSelectionListener = widget.controller.onChangeSelection.subscribe((listener, data) {
      onChangeSelection();
    });

    onChangeSelection();
  }

  @override
  void dispose() {
    folderControllerOnChangeSelectionListener.dispose();
    super.dispose();
  }

  void onChangeSelection() {
    final isSelected = widget.controller.selectedPath == widget.path;
    if (_isSelected != isSelected) {
      _isSelected = isSelected;

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder.call(context, _isSelected);
  }
}

