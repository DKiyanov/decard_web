import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
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
  final DateTime? publicationMoment;
  final int    starsCount    ;
  final String userID        ;

  final tagList = <String>[];

  bool get published => publicationMoment != null;

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
    required this.publicationMoment ,
    required this.starsCount   ,
    required this.userID,
  }) {
    final prevTagList = tags.split(',');

    for (var tag in prevTagList) {
      tagList.add(tag.trim().toLowerCase());
    }
  }

  factory WebPackInfo.fromParse(ParseObject parseObject) {
    return WebPackInfo(
      packId        : parseObject.get<int>(WebPackFields.packId  )!,
      title         : parseObject.get<String>(DjfFile.title      )!,
      guid          : parseObject.get<String>(DjfFile.guid       )!,
      version       : parseObject.get<int>(DjfFile.version       )!,
      author        : parseObject.get<String>(DjfFile.author     )!.toLowerCase(),
      site          : parseObject.get<String>(DjfFile.site       )!,
      email         : parseObject.get<String>(DjfFile.email      )!,
      tags          : parseObject.get<String>(DjfFile.tags       )??'',
      license       : parseObject.get<String>(DjfFile.license    )??'',
      targetAgeLow  : parseObject.get<int>(DjfFile.targetAgeLow  )??0,
      targetAgeHigh : parseObject.get<int>(DjfFile.targetAgeHigh )??100,
      publicationMoment: parseObject.get<DateTime>(WebPackFields.publicationMoment),
      starsCount    : parseObject.get<int>(WebPackFields.starsCount)??0,
      userID        : parseObject.get<String>(WebPackFields.userID)!,
    );
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

class WebPackUploadFileFields {
  static const String className = 'UploadWebFile';
  static const String userID    = 'UserID';
  static const String fileName  = 'FileName';
  static const String size      = 'Size';
  static const String content   = 'Content';
}

class WebPackFields {
  static const String className    = 'DecardFileHead';
  static const String packId       = 'packID';
  static const String content      = 'Content';
  static const String fileName     = 'FileName';
  static const String createdAt    = 'createdAt';
  static const String publicationMoment = 'PublicationMoment';
  static const String starsCount   = 'StarsCount';
  static const String userID       = 'UserID';
}

class WebPackSubFileFields {
  static const String className    = 'DecardFileSub';
  static const String packId       = 'packID';
  static const String file         = 'file';
  static const String path         = 'path';
}

class WebPackUserFilesFields {
  static const String className    = 'DecardUserFiles';
  static const String userID       = 'UserID';
  static const String packId       = 'packID';
}

class WebPackListManager {
  final _webPackInfoList = <WebPackInfo>[];
  bool _initialized = false;

  WebPackListManager();

  Future<void> init() async {
    if (_initialized) return;

    final query = QueryBuilder<ParseObject>(ParseObject(WebPackFields.className));
    query.whereGreaterThan(WebPackFields.publicationMoment, DateTime(2000));
    final parsePackList = await query.find();

    for (var parsePack in parsePackList) {
      _webPackInfoList.add(WebPackInfo.fromParse(parsePack));
    }

    _initialized = true;
  }

  Future<List<WebPackInfo>> getUserPackList(String userID) async {
    final result = <WebPackInfo>[];

    // other people's used packages
    {
      final query = QueryBuilder<ParseObject>(ParseObject(WebPackUserFilesFields.className));
      query.whereEqualTo(WebPackFields.userID, userID);
      final userPackList = await query.find();

      for (var userPack in userPackList) {
        final packId = userPack.get<int>(WebPackFields.packId)!;
        final webPackInfo = _webPackInfoList.firstWhereOrNull((webPackInfo) => webPackInfo.packId == packId);
        if (webPackInfo == null) continue;

        result.add(webPackInfo);
      }
    }

    // own user packages
    final query = QueryBuilder<ParseObject>(ParseObject(WebPackFields.className));
    query.whereEqualTo(WebPackFields.userID, userID);
    final parsePackList = await query.find();

    for (var parsePack in parsePackList) {
      final packId = parsePack.get<int>(WebPackFields.packId)!;
      final webPackInfo = _webPackInfoList.firstWhereOrNull((webPackInfo) => webPackInfo.packId == packId);
      if (webPackInfo != null) {
        result.add(webPackInfo);
        continue;
      }

      result.add(WebPackInfo.fromParse(parsePack));
    }

    return result;
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
  
  Future<void> createNewPackage(String userID, String fileName, Map<String, dynamic> newJsonMap) async {
    final query = QueryBuilder<ParseObject>(ParseObject(WebPackUploadFileFields.className));
    query.whereEqualTo(WebPackUploadFileFields.fileName, 'CreateNewPackageTemplate.decardj');
    query.keysToReturn([WebPackUploadFileFields.content]);
    final row = await query.first();
    if (row == null) return;

    final url = row.get<ParseWebFile>(WebPackUploadFileFields.content)!.url!;
    final jsonStr = await getTextFromUrl(url);
    if (jsonStr == null) return;

    final jsonMap = jsonDecode(jsonStr);

    jsonMap.addEntries(newJsonMap.entries);

    final newJsonStr = jsonEncode(jsonMap);

    final fileContent  = Uint8List.fromList(newJsonStr.codeUnits);
    final fileSize     = newJsonStr.length;
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

typedef LoadPackAddInfoCallback = Function(String jsonStr, String jsonUrl, String rootPath, Map<String, String> fileUrlMap);

Future<int?> loadPack(DbSource dbSource, int packId, {LoadPackAddInfoCallback? addInfoCallback}) async {
  Map<String, String>? fileUrlMap;

  if (kIsWeb) {
    fileUrlMap = await _getPackSourceWeb(dbSource, packId);
  } else {
    fileUrlMap = await _getPackSourceApp(dbSource, packId);
  }

  if (fileUrlMap == null) return null;

  String? jsonUrl;
  late String jsonPath;

  for (var fileUrlMapEntry in fileUrlMap.entries) {
    if (fileUrlMapEntry.key.toLowerCase().endsWith(DjfFileExtension.json)) {
      jsonPath = fileUrlMapEntry.key;
      jsonUrl  = fileUrlMapEntry.value;
      break;
    }
  }

  if (jsonUrl == null) return null;

  fileUrlMap.remove(jsonPath);
  final rootPath = path_util.dirname(jsonPath);

  final fileUrlMapOk = <String, String>{};

  for (var fileUrlMapEntry in fileUrlMap.entries) {
    final newPath = path_util.relative(fileUrlMapEntry.key, from: rootPath);
    fileUrlMapOk[newPath] = fileUrlMapEntry.value;
  }

  final jsonStr = await getTextFromUrl(jsonUrl);

  if (jsonStr == null) return null;

  final jsonMap = jsonDecode(jsonStr);

  final jsonFileID = await dbSource.loadJson(sourceFileID: '$packId', rootPath: rootPath, jsonMap: jsonMap, fileUrlMap: fileUrlMapOk);

  if (jsonFileID == null) return null;

  if (addInfoCallback != null) {
    addInfoCallback.call(jsonStr, jsonUrl, rootPath, fileUrlMapOk);
  }

  return jsonFileID;
}

Future<Map<String, String>?> _getPackSourceWeb(DbSource dbSource, int packId) async {
  final query = QueryBuilder<ParseObject>(ParseObject(WebPackSubFileFields.className));
  query.whereEqualTo(WebPackFields.packId, packId);
  final sourceList = await query.find();

  final Map<String, String> fileUrlMap = {};

  for (var source in sourceList) {
    final path = source.get<String>(WebPackSubFileFields.path)!;
    final url  = source.get<ParseWebFile>(WebPackSubFileFields.file)!.url!;
    fileUrlMap[path] = url;
  }

  return fileUrlMap;
}

Future<String> getPackAppBasePath(int packId) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  final path = path_util.join(appDocDir.path, 'pack_$packId' );
  return path;
}

Future<Map<String, String>?> _getPackSourceApp(DbSource dbSource, int packId) async {
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

  final packPath = await getPackAppBasePath(packId);
  final dir = Directory(packPath);
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

  for (var object in fileList) {
    if (object is File){
      final File file = object;

      final relPath = path_util.relative(file.path, from: packPath);
      fileUrlMap[relPath] = file.path;
    }
  }

  return fileUrlMap;
}

Future<String> addFileToPack(int packId, String filePath, Uint8List fileContent) async {
  final query = QueryBuilder<ParseObject>(ParseObject(WebPackSubFileFields.className));
  query.whereEqualTo(WebPackFields.packId, packId);
  query.whereEqualTo(WebPackSubFileFields.path, filePath);

  {
    final serverFile = await query.first();
    if (serverFile != null) {
      await serverFile.delete();
    }
  }

  final techFileName = '${DateTime.now().millisecondsSinceEpoch}.data';

  final serverFileContent = ParseWebFile(fileContent, name : techFileName);
  await serverFileContent.save();

  final serverFile = ParseObject(WebPackSubFileFields.className);
  serverFile.set<ParseWebFile>(WebPackSubFileFields.file, serverFileContent);
  serverFile.set<String>(WebPackSubFileFields.path, filePath);
  serverFile.set<int>(WebPackSubFileFields.packId, packId);
  await serverFile.save();

  if (!kIsWeb) {
    final url = await _addFileToAppPack(packId, filePath, fileContent);
    return url;
  }

  return serverFileContent.url!;
}

Future<String> _addFileToAppPack(int packId, String filePath, Uint8List fileContent) async {
  final packPath = await getPackAppBasePath(packId);
  final path = path_util.join(packPath, filePath);

  final dirPath = path_util.dirname(path);
  final dir = Directory(dirPath);
  if (! await dir.exists()) {
    await dir.create(recursive: true);
  }

  final file = File(path);
  file.writeAsBytes(fileContent);
  return path;
}

Future<void> deleteFileFromPack(int packId, String filePath) async {
  final query = QueryBuilder<ParseObject>(ParseObject(WebPackSubFileFields.className));
  query.whereEqualTo(WebPackFields.packId, packId);
  query.whereEqualTo(WebPackSubFileFields.path, filePath);

  final serverFile = await query.first();
  if (serverFile != null) {
    await serverFile.delete();
  }

  if (!kIsWeb) {
    await _deleteFileFromAppPack(packId, filePath);
  }
}

Future<void> _deleteFileFromAppPack(int packId, String filePath) async {
  final packPath = await getPackAppBasePath(packId);
  final path = path_util.join(packPath, filePath);
  final file = File(path);
  await file.delete();

  final dirPath = path_util.dirname(path);
  final dir = Directory(dirPath);

  final dirList = dir.listSync(recursive: true);

  for (var fileSystemObject in dirList) {
    if (fileSystemObject is File) {
      return;
    }
  }

  dir.delete(recursive: true);
}

Future<String?> moveFileInsidePack(int packId, String oldFilePath, String newFilePath, String oldUrl) async {
  final query = QueryBuilder<ParseObject>(ParseObject(WebPackSubFileFields.className));
  query.whereEqualTo(WebPackFields.packId, packId);
  query.whereEqualTo(WebPackSubFileFields.path, oldFilePath);

  final serverFile = await query.first();
  if (serverFile == null) return null;

  serverFile.set<String>(WebPackSubFileFields.path, newFilePath);
  await serverFile.save();

  if (!kIsWeb) {
    final packPath = await getPackAppBasePath(packId);
    final newUrl = path_util.join(packPath, newFilePath);
    final file = File(oldUrl);
    if (!file.existsSync()) return null;

    final newDirPath = path_util.dirname(newUrl);
    final newDir = Directory(newDirPath);
    if (!newDir.existsSync()) {
      await newDir.create(recursive: true);
    }

    await file.rename(newUrl);

    final oldDirPath = path_util.dirname(oldUrl);
    final oldDir = Directory(oldDirPath);

    final oldDirList = oldDir.listSync(recursive: true);

    bool fileExists = false;
    for (var fileSystemObject in oldDirList) {
      if (fileSystemObject is File) {
        fileExists = true;
        break;
      }
    }

    if (!fileExists) {
      oldDir.delete(recursive: true);
    }

    return newUrl;
  }

  return oldUrl;
}