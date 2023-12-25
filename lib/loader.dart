import 'dart:convert';
import 'package:path/path.dart' as path_util;

import 'db.dart';
import 'decardj.dart';

enum DecardFileType {
  json,
  zip,
  notDecardFile
}

DecardFileType getDecardFileType(String fileName){
  final fileExt = path_util.extension(fileName).toLowerCase();
  if (fileExt == DjfFileExtension.json) return DecardFileType.json;
  if (fileExt == DjfFileExtension.zip) return DecardFileType.zip;
  return DecardFileType.notDecardFile;
}

typedef CheckCanLoadFile = Future<bool> Function(String guid, int version);

class DataLoader {
  final errorList = <String>[];

  final DbSource dbSource;

  DataLoader(this.dbSource);

  Future<int?> loadJson(String sourceFileID, Map<String, dynamic> jsonMap, CheckCanLoadFile? checkCanLoadFile) async {
    final jsonFileRow = await dbSource.tabJsonFile.getRowBySourceID(sourceFileID: sourceFileID);
    if (jsonFileRow != null) {
      return jsonFileRow[TabJsonFile.kJsonFileID];
    }

//    final jsonMap = jsonDecode(jsonStr);

    final String guid = jsonMap[TabJsonFile.kGuid]??'';
    if (guid.isEmpty) {
      errorList.add('filed ${TabJsonFile.kGuid} not found');
      return null;
    }

    final int fileVersion = jsonMap[TabJsonFile.kVersion]??0;

    if (checkCanLoadFile != null) {
      if (! await checkCanLoadFile.call(guid, fileVersion)) {
        return null;
      }
    }

    final jsonFileID = await dbSource.tabJsonFile.insertRow(sourceFileID, jsonMap);

    final styleList = (jsonMap[DjfFile.cardStyleList]) as List;
    for (Map<String, dynamic> cardStyle in styleList) {
      await dbSource.tabCardStyle.insertRow(
        jsonFileID   : jsonFileID,
        cardStyleKey : cardStyle[DjfCardStyle.id],
        jsonStr      : jsonEncode(cardStyle)
      );
    }

    final qualityLevelList = (jsonMap[DjfFile.qualityLevelList]) as List;
    for (Map<String, dynamic> qualityLevel in qualityLevelList) {
      await dbSource.tabQualityLevel.insertRow(
          jsonFileID   : jsonFileID,
          qualityName  : qualityLevel[DjfQualityLevel.qualityName],
          minQuality   : qualityLevel[DjfQualityLevel.minQuality],
          avgQuality   : qualityLevel[DjfQualityLevel.avgQuality],
      );
    }

    final cardKeyList = <String>[];

    final templateList = (jsonMap[DjfFile.templateList]) as List?;
    final templatesSources = (jsonMap[DjfFile.templatesSources]) as List?;
    if (templateList != null && templatesSources != null) {
      await _processTemplateList(jsonFileID: jsonFileID, templateList : templateList, sourceList: templatesSources, cardKeyList : cardKeyList);
    }

    final cardList = (jsonMap[DjfFile.cardList]) as List?;
    if (cardList != null) {
      await _processCardList(jsonFileID: jsonFileID, cardList : cardList, cardKeyList : cardKeyList);
    }

    return jsonFileID;
  }

  Future<void> _processTemplateList({required int jsonFileID, required List templateList, required List sourceList, required List<String> cardKeyList}) async {
    for (var template in templateList) {
      final templateName          = template[DjfCardTemplate.templateName] as String;
      final cardTemplateList      = template[DjfCardTemplate.cardTemplateList];
      final cardsTemplatesJsonStr = jsonEncode(cardTemplateList);

      for (Map<String, dynamic> sourceRow in sourceList) {
        if (sourceRow[DjfTemplateSource.templateName] == templateName) {

          final sourceRowId = await dbSource.tabTemplateSource.insertRow(jsonFileID: jsonFileID, source: sourceRow);

          String curTemplate = cardsTemplatesJsonStr;

          sourceRow.forEach((key, value) {
            curTemplate =  curTemplate.replaceAll('${DjfTemplateSource.paramBegin}$key${DjfTemplateSource.paramEnd}', value);
          });

          final cardList = jsonDecode(curTemplate) as List;
          await _processCardList(jsonFileID: jsonFileID, cardList : cardList, cardKeyList : cardKeyList, sourceRowId: sourceRowId);
        }
      }
    }
  }

  Future<void> _processCardList({required int jsonFileID, required List cardList, required List<String> cardKeyList, int? sourceRowId}) async {
    for (Map<String, dynamic> card in cardList) {
      final String cardKey = card[DjfCard.id];

      if (cardKey.isEmpty) continue; // the card must have a unique identifier within the file
      if (cardKeyList.contains(cardKey)) continue; // card identifiers must be unique

      cardKeyList.add(cardKey);

      final groupKey = card[DjfCard.group]??cardKey;

      final bodyList = (card[DjfCard.bodyList]) as List;

      final cardID = await dbSource.tabCardHead.insertRow(
        jsonFileID   : jsonFileID,
        cardKey      : cardKey,
        title        : card[DjfCard.title],
        help         : card[DjfCard.help]??'',
        difficulty   : card[DjfCard.difficulty]??0,
        cardGroupKey : groupKey,
        bodyCount    : bodyList.length,
        sourceRowId  : sourceRowId,
      );

      await _processCardBodyList(
        jsonFileID : jsonFileID,
        cardID     : cardID,
        bodyList   : bodyList,
      );

      await _processCardTagList(
        jsonFileID : jsonFileID,
        cardID     : cardID,
        cardKey    : cardKey,
        groupKey   : groupKey,
        tagList    : card[DjfCard.tags] as List?,
      );

      await _processCardLinkList(
        jsonFileID : jsonFileID,
        cardID     : cardID,
        linkList   : card[DjfCard.upLinks] as List?,
      );
    }
  }

  Future<void> _processCardLinkList({ required int jsonFileID, required int cardID, required List? linkList }) async {
    if (linkList == null) return;

    for (var link in linkList) {
      final linkID = await dbSource.tabCardLink.insertRow(
          jsonFileID  : jsonFileID,
          cardID      : cardID,
          qualityName : link[DjfUpLink.qualityName],
      );

      await _processCardLinkTagList( jsonFileID: jsonFileID, linkID: linkID, tagList: link[DjfUpLink.tags  ] as List?);
      await _processCardLinkTagList( jsonFileID: jsonFileID, linkID: linkID, tagList: link[DjfUpLink.cards ] as List?, prefix: DjfUpLink.cardTagPrefix);
      await _processCardLinkTagList( jsonFileID: jsonFileID, linkID: linkID, tagList: link[DjfUpLink.groups] as List?, prefix: DjfUpLink.groupTagPrefix);
    }
  }

  Future<void> _processCardLinkTagList({ required int jsonFileID, required int linkID, String prefix = '', required List? tagList }) async {
    if (tagList == null) return;

    for (String tag in tagList) {
      dbSource.tabCardLinkTag.insertRow(jsonFileID: jsonFileID, linkId: linkID, tag: prefix + tag);
    }
  }

  Future<void> _processCardBodyList({ required int jsonFileID, required int cardID, required List bodyList }) async {
    int bodyNum = 0;
    for (var body in bodyList) {
      dbSource.tabCardBody.insertRow(
        jsonFileID : jsonFileID,
        cardID     : cardID,
        bodyNum    : bodyNum,
        json       : jsonEncode(body)
      );
      bodyNum++;
    }
  }

  Future<void> _processCardTagList({ required int jsonFileID, required int cardID, required String cardKey, required String groupKey, required List? tagList }) async {
    if (tagList == null) return;

    dbSource.tabCardTag.insertRow(
      jsonFileID     : jsonFileID,
      cardID         : cardID,
      tag            : DjfUpLink.cardTagPrefix + cardKey,
    );

    if (groupKey.isNotEmpty) {
      dbSource.tabCardTag.insertRow(
        jsonFileID     : jsonFileID,
        cardID         : cardID,
        tag            : DjfUpLink.groupTagPrefix + groupKey,
      );
    }

    for (var tag in tagList) {
      dbSource.tabCardTag.insertRow(
        jsonFileID     : jsonFileID,
        cardID         : cardID,
        tag            : tag,
      );
    }
  }

  Future<void> clearJsonFileID(int jsonFileID) async {
    await dbSource.tabCardStyle.deleteJsonFile(jsonFileID);
    await dbSource.tabCardHead.deleteJsonFile(jsonFileID);
    await dbSource.tabCardBody.deleteJsonFile(jsonFileID);
    await dbSource.tabCardTag.deleteJsonFile(jsonFileID);
    await dbSource.tabCardLink.deleteJsonFile(jsonFileID);
    await dbSource.tabCardLinkTag.deleteJsonFile(jsonFileID);
    await dbSource.tabQualityLevel.deleteJsonFile(jsonFileID);
  }
}
