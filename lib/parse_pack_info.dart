import 'package:decard_web/db.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'decardj.dart';
import 'media_widgets.dart';

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
  String get url  => get<ParseFile>(keyFile)!.url!;
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

Future<int?> loadPack(DbSource dbSource, int packId) async {
  final query = QueryBuilder<PackSource>(PackSource());
  query.whereEqualTo(PackInfo.keyPackId, packId);
  final sourceList = await query.find();

  final Map<String, String> fileUrlMap = {};
  String? jsonUrl;

  for (var source in sourceList) {
    if (source.path.toLowerCase().endsWith(DjfFileExtension.json)) {
      jsonUrl = source.url;
    }
    fileUrlMap[source.path] = source.url;
  }

  if (jsonUrl == null) return null;

  final jsonStr = await getTextFromUrl(jsonUrl);

  if (jsonStr == null) return null;

  final jsonFileID = await dbSource.loadJson(sourceFileID: '$packId', jsonStr: jsonStr, fileUrlMap: fileUrlMap);

  return jsonFileID;
}