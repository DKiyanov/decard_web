import 'dart:io';

import 'package:decard_web/db.dart';
import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_util;
import 'package:flutter_archive/flutter_archive.dart';

import 'decardj.dart';
import 'media_widgets.dart';

class PackInfo extends ParseObject implements ParseCloneable {
  static const String keyClassName  = 'DecardFileHead';
  static const String keyPackId     = 'packID';
  static const String keyContent    = 'Content';
  static const String keyFileName   = 'FileName';

  PackInfo() : super(keyClassName);
  PackInfo.clone() : this();

  @override
  PackInfo clone(Map<String, dynamic> map) => PackInfo.clone()..fromJson(map);

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

  String get url {
    if (kIsWeb) {
      return get<ParseWebFile>(keyFile)!.url!;
    }
    return get<ParseFile>(keyFile)!.url!;
  }
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
  Map<String, String>? fileUrlMap;

  if (kIsWeb) {
    fileUrlMap = await getPackSourceWeb(dbSource, packId);
  } else {
    fileUrlMap = await getPackSourceApp(dbSource, packId);
  }

  if (fileUrlMap == null) return null;

  final jsonFileID = await loadPackEx(dbSource, packId, fileUrlMap);
  return jsonFileID;
}

Future<int?> loadPackEx(DbSource dbSource, int packId, Map<String, String> fileUrlMap) async {
  String? jsonUrl;

  for (var fileUrlMapEntry in fileUrlMap.entries) {

    if (fileUrlMapEntry.key.toLowerCase().endsWith(DjfFileExtension.json)) {
      jsonUrl = fileUrlMapEntry.value;
    }
  }

  if (jsonUrl == null) return null;

  final jsonStr = await getTextFromUrl(jsonUrl);

  if (jsonStr == null) return null;

  final jsonFileID = await dbSource.loadJson(sourceFileID: '$packId', jsonStr: jsonStr, fileUrlMap: fileUrlMap);

  return jsonFileID;
}

Future<Map<String, String>?> getPackSourceWeb(DbSource dbSource, int packId) async {
  final query = QueryBuilder<PackSource>(PackSource());
  query.whereEqualTo(PackInfo.keyPackId, packId);
  final sourceList = await query.find();

  final Map<String, String> fileUrlMap = {};

  for (var source in sourceList) {
    fileUrlMap[source.path] = source.url;
  }

  return fileUrlMap;
}

Future<Map<String, String>?> getPackSourceApp(DbSource dbSource, int packId) async {
  final query = QueryBuilder<PackInfo>(PackInfo());
  query.whereEqualTo(PackInfo.keyPackId, packId);
  query.keysToReturn([PackInfo.keyFileName, PackInfo.keyContent]);
  final packInfo = await query.first();

  if (packInfo == null) return null;

  final packFileName = packInfo.get<String>(PackInfo.keyFileName)!;
  final fileExt = path_util.extension(packFileName).toLowerCase();
  if (fileExt != DjfFileExtension.zip && fileExt != DjfFileExtension.json) {
    return null;
  }

  Directory appDocDir = await getApplicationDocumentsDirectory();
  final dir = Directory(path_util.join(appDocDir.path, 'pack_$packId' ));
  if (!dir.existsSync()) {
    final content = packInfo.get<ParseFile>(PackInfo.keyContent)!;
    await content.loadStorage();
    if ( content.file == null){
      await content.download();
    }

    await dir.create();

    if (fileExt == DjfFileExtension.zip) {
      await ZipFile.extractToDirectory(zipFile: content.file!, destinationDir: dir);
    }
    if (fileExt == DjfFileExtension.json) {
      await content.file!.copy(path_util.join(dir.path, packFileName));
    }

    content.file!.delete();
  }

  final Map<String, String> fileUrlMap = {};

  final fileList = dir.listSync( recursive: true);

  final dirPathLen = dir.path.length + packFileName.length + 3;

  for (var object in fileList) {
    if (object is File){
      final File file = object;

      final subFileName = file.path.substring(dirPathLen);
      fileUrlMap[subFileName] = file.path;
    }
  }

  return fileUrlMap;
}