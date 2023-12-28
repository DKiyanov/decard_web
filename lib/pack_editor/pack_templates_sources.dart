import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'package:fluttertoast/fluttertoast.dart';

import '../decardj.dart';
import '../simple_dialog.dart';
import 'pack_widgets.dart';

class TemplatesSources extends StatefulWidget {
  final Map<String, dynamic> json;

  const TemplatesSources({required this.json, Key? key}) : super(key: key);

  @override
  State<TemplatesSources> createState() => _TemplatesSourcesState();
}

class _TemplatesSourcesState extends State<TemplatesSources> {
  final _templatesMap = <String, List<String>>{};
  String _selTemplate = "";
  int _selIndex = 0;

  GlobalKey? _paramTabKey;

  @override
  void initState() {
    super.initState();
    _getTemplatesInfo();

    if (_templatesMap.isNotEmpty) {
      _selectTemplate(_selIndex);
    }
  }

  void _selectTemplate(int index) {
    final newTemplate  = _templatesMap.entries.elementAt(index).key;
    if (_selTemplate == newTemplate) return;

    _selIndex    = index;
    _selTemplate = newTemplate;
    _paramTabKey = GlobalKey();

    if (mounted) {
      setState(() {});
    }
  }

  void _getTemplatesInfo() {
    final templateList = (widget.json[DjfFile.templateList]??[]) as List;

    for (var template in templateList) {
      final templateMap = template as Map<String, dynamic>;
      final templateName = templateMap[DjfCardTemplate.templateName] as String;
      final params = _getParameters(templateMap[DjfCardTemplate.cardTemplateList]);
      if (params.isEmpty) continue;

      _templatesMap[templateName] = params;
    }
  }

  List<String> _getParameters(Object? json) {
    final jsonStr = jsonEncode(json);

    final resultParamList = getParamList(jsonStr);

    resultParamList.sort((a, b) => a.compareTo(b));

    return resultParamList;
  }

  @override
  Widget build(BuildContext context) {
    if (_templatesMap.isEmpty) {
      return const Center(child: Text('Нет блоков с параметрами'));
    }

    return Column(children: [
      // top panel, select template for display

      if (_templatesMap.length == 1) ...[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_selTemplate),
        ),
      ] else ...[
        Row(children: [
          ElevatedButton(
            onPressed: _selIndex == 0? null : (){
              setState(() {
                _selIndex --;
                _selectTemplate(_selIndex);
              });
            },
            child: const Icon( Icons.arrow_left),
          ),

          Container(width: 4),

          Expanded(child: DropdownButton<String>(
            value: _selTemplate,
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            onChanged: (value) {
              if (value == null) return;
              _selIndex = _templatesMap.keys.toList().indexOf(value);
              _selectTemplate(_selIndex);
            },

            items: _templatesMap.entries.map<DropdownMenuItem<String>>((template) {
              return DropdownMenuItem<String>(
                value: template.key,
                child: Text(template.key, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
          ) ),

          Container(width: 4),

          ElevatedButton(
            onPressed: _selIndex >= _templatesMap.length ? null : (){
              _selIndex ++;
              _selectTemplate(_selIndex);
            },
            child: const Icon( Icons.arrow_right),
          ),
        ]),
      ],

      Expanded(
        child: TemplateParamTab(
          key          : _paramTabKey,
          json         : widget.json,
          fieldName    : DjfFile.templatesSources,
          templateName : _selTemplate,
          params       : _templatesMap[_selTemplate]!,
        ),
      ),

    ]);
  }
}

class TemplateParamTab extends StatefulWidget {
  final Map<String, dynamic> json;
  final String fieldName;
  final String templateName;
  final List<String> params;

  const TemplateParamTab({
    required this.json,
    required this.fieldName,
    required this.templateName,
    required this.params,

    Key? key
  }) : super(key: key);

  @override
  State<TemplateParamTab> createState() => _TemplateParamTabState();
}

class _TemplateParamTabState extends State<TemplateParamTab> {
  final _columns = <PlutoColumn>[];
  final _rows = <PlutoRow>[];
  final _rowDataMap = <PlutoRow, Map<String, dynamic>>{};

  late PlutoGridStateManager _stateManager;

  late List<dynamic> _sourceList;

  @override
  void initState() {
    super.initState();

    for (var param in widget.params) {
      _columns.add(PlutoColumn(
        title: param,
        field: param,
        type : PlutoColumnType.text()
      ));
    }

    _sourceList = widget.json[widget.fieldName]??[];

    for (var sourceRow in _sourceList) {
      final sourceMap = sourceRow as Map<String, dynamic>;
      final templateName = sourceMap[DjfTemplateSource.templateName]??"";
      if (templateName != widget.templateName) continue;

      final cells = <String, PlutoCell>{};

      for (var param in widget.params) {
        final value = sourceMap[param];
        cells[param] = PlutoCell(value: value);
      }

      final row  = PlutoRow(cells: cells);
      _rowDataMap[row] = sourceMap;
      _rows.add(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          Tooltip(
            message: 'Добавить запись',
            child: IconButton(
                onPressed: (){
                  _insertNewRow(_stateManager.refRows.length);
                  _stateManager.moveScrollByRow(PlutoMoveDirection.down, _stateManager.refRows.length);
                },
                icon: const Icon(Icons.add)
            ),
          ),

          Tooltip(
            message: 'Вставить запись',
            child: IconButton(
                onPressed: (){
                  if (_stateManager.currentRowIdx == null) return;
                  _insertNewRow(_stateManager.currentRowIdx!);
                },
                icon: const Icon(Icons.add_box_outlined)
            ),
          ),

          Tooltip(
            message: 'Дублировать запись',
            child: IconButton(
                onPressed: (){
                  if (_stateManager.currentRowIdx == null) return;
                  _doubleRow(_stateManager.currentRowIdx!);
                },
                icon: const Icon(Icons.copy_all)
            ),
          ),

          Tooltip(
            message: 'Удалить запись',
            child: IconButton(
                onPressed: (){
                  _deleteCurrentRow();
                },
                icon: const Icon(Icons.remove)
            ),
          ),

          Tooltip(
            message: 'Отчистить таблицу',
            child: IconButton(
                onPressed: (){
                  _clearTable();
                },
                icon: const Icon(Icons.clear)
            ),
          ),

          Tooltip(
            message: 'Скопировать таблицу в буффер обмена',
            child: IconButton(
                onPressed: (){
                  _copyToClipboard();
                },
                icon: const Icon(Icons.copy)
            ),
          ),

          Tooltip(
            message: 'Вставить из буффера обмена в конец таблицы',
            child: IconButton(
                onPressed: (){
                  _pasteFromClipboard();
                },
                icon: const Icon(Icons.paste)
            ),
          ),

        ]),

        Expanded(
          child: PlutoGrid(
            columns: _columns,
            rows   : _rows,
            configuration: const PlutoGridConfiguration(
              columnSize: PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.scale,
                resizeMode: PlutoResizeMode.normal,

              )
            ),
            onLoaded: (event) {
              _stateManager = event.stateManager;
            },
            onChanged: (event) {
              final sourceMap = _rowDataMap[event.row]!;
              sourceMap[event.column.field] = event.value;
              _setChanged();
            },
          ),
        ),
      ],
    );
  }

  void _setChanged() {
    JsonWidgetChangeListener.of(context)?.setChanged();
  }

  void _insertNewRow(int rowIndex) {
    final sourceMap = {DjfTemplateSource.templateName : widget.templateName};
    _sourceList.insert(rowIndex, sourceMap);

    final newRows = _stateManager.getNewRows();
    _rowDataMap[newRows.first] = sourceMap;

    _stateManager.insertRows(rowIndex, newRows);
    _setChanged();
  }

  void _doubleRow(int rowIndex) {
    final fromMap = _sourceList[rowIndex];

    final sourceMap = {DjfTemplateSource.templateName : widget.templateName};
    _sourceList.insert(rowIndex, sourceMap);

    final cells = <String, PlutoCell>{};

    for (var param in widget.params) {
      final value = fromMap[param];
      sourceMap[param] = value;
      cells[param] = PlutoCell(value: value);
    }

    final row  = PlutoRow(cells: cells);

    _rowDataMap[row] = sourceMap;

    _stateManager.insertRows(rowIndex, [row]);
    _setChanged();
  }

  _deleteCurrentRow() async {
    if (_stateManager.currentRowIdx == null) return;

    if (! await warningDialog(context, 'Удалить строку?')) return;

    final row = _stateManager.refRows[_stateManager.currentRowIdx!];
    _rowDataMap.remove(row);

    _sourceList.removeAt(_stateManager.currentRowIdx!);
    _stateManager.removeCurrentRow();

    _setChanged();
  }

  _clearTable() async {
    if (! await warningDialog(context, 'Отчистить таблицу?')) return;

    _sourceList.clear();
    _stateManager.removeAllRows();
    _rowDataMap.clear();
    _setChanged();
  }

  Future<void> _copyToClipboard() async {
    String content = "";

    for (var param in widget.params) {
      if (content.isEmpty) {
        content = param;
        continue;
      }

      content = '$content\t$param';
    }

    for (var sourceRow in _sourceList) {
      final sourceMap = sourceRow as Map<String, dynamic>;

      String row = "";

      for (var param in widget.params) {
        final value = sourceMap[param];

        if (row.isEmpty) {
          row = value;
          continue;
        }

        row = '$row\t$value';
      }

      content = '$content\n$row';
    }

    await Clipboard.setData(ClipboardData(text: content));

    Fluttertoast.showToast(msg: 'Таблица скопирована в буффер обмена');
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    final text = clipboardData?.text;
    if (text == null) return;

    final rowList = text.split('\n');

    final rows = <PlutoRow>[];

    for (var stringRow in rowList) {
      final values = stringRow.split('\t');

      final Map<String, dynamic> sourceMap = {DjfTemplateSource.templateName : widget.templateName};
      _sourceList.add(sourceMap);

      final cells = <String, PlutoCell>{};

      for(var col = 0; col <  widget.params.length; col++) {
        String? value;
        if (col < values.length) {
          value = values[col];
        }

        final param = widget.params[col];

        sourceMap[param] = value;
        cells[param] = PlutoCell(value: value);
      }

      final row  = PlutoRow(cells: cells);

      _rowDataMap[row] = sourceMap;
      rows.add(row);
    }

    _stateManager.appendRows(rows);

    _setChanged();
  }

}