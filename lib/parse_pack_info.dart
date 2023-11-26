import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path/path.dart' as path_util;

import 'decardj.dart';

class PackInfo extends ParseObject implements ParseCloneable {
  static const String keyClassName  = 'DecardFileHead';
  static const String keyPackId     = 'packID';

  PackInfo() : super(keyClassName);
  PackInfo.clone() : this();

  @override
  PackSource clone(Map<String, dynamic> map) => PackSource.clone()..fromJson(map);

  int    get packId        => get<int>(keyPackId)!;
  String get formatVersion => get<String>(DjfFile.formatVersion)!;
  String get title         => get<String>(DjfFile.title        )!;
  String get guid          => get<String>(DjfFile.guid         )!;
  int    get version       => get<int>(DjfFile.version         )!;
  String get author        => get<String>(DjfFile.author       )!;
  String get site          => get<String>(DjfFile.site         )!;
  String get email         => get<String>(DjfFile.email        )!;
  String get tags          => get<String>(DjfFile.tags         )!;
  String get license       => get<String>(DjfFile.license      )!;
  String get targetAgeLow  => get<String>(DjfFile.targetAgeLow )!;
  String get targetAgeHigh => get<String>(DjfFile.targetAgeHigh)!;
}


class PackSource extends ParseObject implements ParseCloneable {
  static const String keyClassName  = 'DecardFileSub';
  static const String keyPackId     = 'packID';
  static const String keyPath       = 'path';
  static const String keyFile       = 'file';

  PackSource() : super(keyClassName);
  PackSource.clone() : this();

  @override
  PackSource clone(Map<String, dynamic> map) => PackSource.clone()..fromJson(map);

  String get path => get<String>(keyPath)!;
  String get url  => get<ParseFile>(keyPath)!.url!;
}

class PackListManager {
  List<PackInfo>? _packInfoList;

  PackListManager();

  Future<void> init() async {
    if (_packInfoList != null) return;

    final query = QueryBuilder<PackInfo>(PackInfo());
    _packInfoList = await query.find();
  }

  Future<List<PackInfo>> getPackList() async {
    return _packInfoList??[];
  }
}



// Обеспечивает загрузку и доступ к ресурсам пакета
class PackSourceManager {
  final int packId;
  final sourceList = <PackSource>[];

  PackSourceManager(this.packId);

  Future<void> getData() async {
    await loadSourceList();

    final jsonSource = sourceList.firstWhere((source) => path_util.extension(source.path).toLowerCase() == '.decardj' );

  }

  Future<void> loadSourceList() async {
    sourceList.clear();
    final query = QueryBuilder<PackSource>(PackSource());
    query.whereEqualTo(PackInfo.keyPackId, packId);
    sourceList.addAll(await query.find());
  }
}