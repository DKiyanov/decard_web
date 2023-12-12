import 'dart:io';

import 'package:decard_web/db.dart';
import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_util;
import 'package:flutter_archive/flutter_archive.dart';

import 'decardj.dart';
import 'media_widgets.dart';

class WebPackInfo {
  final int    packId        ;
  final String title         ;
  final String guid          ;
  final int    version       ;
  final String author        ;
  final String site          ;
  final String email         ;
  final String tags          ;
  final String license       ;
  final int    targetAgeLow  ;
  final int    targetAgeHigh ;

  final tagList = <String>[];

  WebPackInfo({
    required this.packId       ,
    required this.title        ,
    required this.guid         ,
    required this.version      ,
    required this.author       ,
    required this.site         ,
    required this.email        ,
    required this.tags         ,
    required this.license      ,
    required this.targetAgeLow ,
    required this.targetAgeHigh,
  }) {
    final prevTagList = tags.split(',');

    for (var tag in prevTagList) {
      tagList.add(tag.trim().toLowerCase());
    }
  }
}

class WebPackListResult{
  List<WebPackInfo> packInfoList;
  List<MapEntry<String, int>> tagList;
  List<MapEntry<String, int>> authorList;
  int targetAgeLow;
  int targetAgeHigh;

  WebPackListResult({
    required this.packInfoList,
    required this.authorList,
    required this.tagList,
    required this.targetAgeLow,
    required this.targetAgeHigh,
  });
}

class WebPackFields {
  static const String className  = 'DecardFileHead';
  static const String packId     = 'packID';
  static const String content    = 'Content';
  static const String fileName   = 'FileName';
}

class WebPackListManager {
  final _webPackInfoList = <WebPackInfo>[];

  WebPackListManager();

  Future<void> init() async {
    final query = QueryBuilder<ParseObject>(ParseObject(WebPackFields.className));
    final parsePackList = await query.find();

    for (var parsePack in parsePackList) {
      _webPackInfoList.add(WebPackInfo(
        packId        : parsePack.get<int>(WebPackFields.packId  )!,
        title         : parsePack.get<String>(DjfFile.title      )!,
        guid          : parsePack.get<String>(DjfFile.guid       )!,
        version       : parsePack.get<int>(DjfFile.version       )!,
        author        : parsePack.get<String>(DjfFile.author     )!.toLowerCase(),
        site          : parsePack.get<String>(DjfFile.site       )!,
        email         : parsePack.get<String>(DjfFile.email      )!,
        tags          : parsePack.get<String>(DjfFile.tags       )??'',
        license       : parsePack.get<String>(DjfFile.license    )??'',
        targetAgeLow  : parsePack.get<int>(DjfFile.targetAgeLow  )??0,
        targetAgeHigh : parsePack.get<int>(DjfFile.targetAgeHigh )??100,
      ));
    }
  }

  Future<WebPackListResult> getPackList({String? title, List<String>? authorList, List<String>? tagList, int? targetAge}) async {
    final packInfoList = <WebPackInfo>[];
    final tagMap       = <String, int>{};
    final authorMap    = <String, int>{};
    int targetAgeLow   = 0;
    int targetAgeHigh  = 0;

    RegExp? titleRegexp;

    if (title != null && title.isNotEmpty) {
      final titleMask = '.*${title.replaceAll(r"/\s\s+/g", ' ').trim().replaceAll(' ', '.*')}.*';
      titleRegexp = RegExp(titleMask, caseSensitive: false);
    }

    for (var packInfo in _webPackInfoList) {
      if (titleRegexp != null) {
        if (!titleRegexp.hasMatch(packInfo.title)) continue;
      }

      if (authorList != null && authorList.isNotEmpty) {
        if (!authorList.contains(packInfo.author)) continue;
      }

      if (tagList != null && tagList.isNotEmpty) {
        bool skip = false;
        for (var tag in tagList) {
          if (!packInfo.tagList.contains(tag)) {
            skip = true;
            break;
          }
        }
        if (skip) continue;
      }

      if (targetAgeLow > packInfo.targetAgeLow) {
        targetAgeLow = packInfo.targetAgeLow;
      }
      if (targetAgeHigh < packInfo.targetAgeHigh) {
        targetAgeHigh = packInfo.targetAgeHigh;
      }

      if (targetAge != null && targetAge >= 0) {
        if (packInfo.targetAgeLow > targetAge || packInfo.targetAgeHigh < targetAge) {
          continue;
        }
      }

      packInfoList.add(packInfo);

      final count = authorMap[packInfo.author]??0;
      authorMap[packInfo.author] = count  + 1;

      for (var tag in packInfo.tagList) {
        final count = tagMap[tag]??0;
        tagMap[tag] = count + 1;
      }

    }

    final authorCountList = authorMap.entries.toList()..sort((e2, e1) => e1.value.compareTo(e2.value));
    final tagCountList    = tagMap.entries.toList()..sort((e2, e1) => e1.value.compareTo(e2.value));

    return WebPackListResult(
        packInfoList  : packInfoList,
        authorList    : authorCountList,
        tagList       : tagCountList,
        targetAgeLow  : targetAgeLow,
        targetAgeHigh : targetAgeHigh
    );
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
  final query = QueryBuilder<ParseObject>(ParseObject('DecardFileSub'));
  query.whereEqualTo(WebPackFields.packId, packId);
  final sourceList = await query.find();

  final Map<String, String> fileUrlMap = {};

  for (var source in sourceList) {
    final path = source.get<String>('path')!;
    final url  = source.get<ParseWebFile>('file')!.url!;
    fileUrlMap[path] = url;
  }

  return fileUrlMap;
}

Future<Map<String, String>?> getPackSourceApp(DbSource dbSource, int packId) async {
  final query = QueryBuilder<ParseObject>(ParseObject(WebPackFields.className));
  query.whereEqualTo(WebPackFields.packId, packId);
  query.keysToReturn([WebPackFields.fileName, WebPackFields.content]);
  final packInfo = await query.first();

  if (packInfo == null) return null;

  final packFileName = packInfo.get<String>(WebPackFields.fileName)!;
  final fileExt = path_util.extension(packFileName).toLowerCase();
  if (fileExt != DjfFileExtension.zip && fileExt != DjfFileExtension.json) {
    return null;
  }

  Directory appDocDir = await getApplicationDocumentsDirectory();
  final dir = Directory(path_util.join(appDocDir.path, 'pack_$packId' ));
  if (!dir.existsSync()) {
    final content = packInfo.get<ParseFile>(WebPackFields.content)!;
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