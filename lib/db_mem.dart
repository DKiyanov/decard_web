import 'db.dart';

class MemDbRow{
  final int jsonFileID;
  final String tabName;
  final dynamic key;
  final Map<String, dynamic> row;

  MemDbRow(this.jsonFileID, this.tabName, this.key, this.row);
}

class MemDB{
  final _rowList = <MemDbRow>[];

  insertRow(int jsonFileID, String tabName, dynamic key, Map<String, dynamic> row) {
    _rowList.add(MemDbRow(jsonFileID, tabName, key, row));
  }

  List<Map<String, dynamic>> getTabRows(String tabName, {dynamic key, Map<String, dynamic>? filter}) {
    final result = <Map<String, dynamic>>[];

    for (var dbRow in _rowList) {
      if (dbRow.tabName == tabName) {
        if (key != null && dbRow.key != key) continue;

        if (filter != null) {
          bool skip = false;
          for (var filterElement in filter.entries) {
            final value = dbRow.row[filterElement.key];
            if (value != filterElement.value) {
              skip = true;
              break;
            }
          }
          if (skip) continue;
        }

        result.add(dbRow.row);
      }
    }

    return result;
  }

  List<Map<String, dynamic>> getRows(int jsonFileID, String tabName, {dynamic key, Map<String, dynamic>? filter}) {
    final result = <Map<String, dynamic>>[];

    for (var dbRow in _rowList) {
      if (dbRow.jsonFileID == jsonFileID && dbRow.tabName == tabName) {
        if (key != null && dbRow.key != key) continue;

        if (filter != null) {
          bool skip = false;
          for (var filterElement in filter.entries) {
            final value = dbRow.row[filterElement.key];
            if (value != filterElement.value) {
              skip = true;
              break;
            }
          }
          if (skip) continue;
        }

        result.add(dbRow.row);
      }
    }

    return result;
  }

  Map<String, dynamic>? getRow(int jsonFileID, String tabName, dynamic key) {
    for (var dbRow in _rowList) {
      if (dbRow.jsonFileID == jsonFileID && dbRow.tabName == tabName && dbRow.key == key) {
        return dbRow.row;
      }
    }

    return null;
  }

  void deleteRows(int jsonFileID, String tabName, {dynamic key, Map<String, dynamic>? filter}){
    final toDelRowList = <MemDbRow>[];

    for (var dbRow in _rowList) {
      if (dbRow.jsonFileID == jsonFileID && dbRow.tabName == tabName) {
        if (key != null && dbRow.key != key) continue;

        if (filter != null) {
          bool skip = false;
          for (var filterElement in filter.entries) {
            final value = dbRow.row[filterElement.key];
            if (value != filterElement.value) {
              skip = true;
              break;
            }
          }
          if (skip) continue;
        }

        toDelRowList.add(dbRow);
      }
    }

    for (var row in toDelRowList) {
      _rowList.remove(row);
    }
  }

  void clearDb() {
    _rowList.clear();
  }
}

class TabSourceFileMem extends TabSourceFile {
  final MemDB db;
  TabSourceFileMem(this.db);

  int _lastSourceFileID = 0;

  @override
  Future<bool> checkFileRegistered(String path, DateTime changeDateTime, int size) async {
    final row = db.getRow(0, TabSourceFile.tabName, '$path|${changeDateTime.millisecondsSinceEpoch}|$size');
    return row != null;
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int sourceFileID}) async {
    final rows = db.getRows(0, TabSourceFile.tabName, filter: {TabSourceFile.kSourceFileID : _lastSourceFileID});
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  Future<int> registerFile(String path, DateTime changeDateTime, int size) async {
    _lastSourceFileID ++;

    db.insertRow(0, TabSourceFile.tabName, '$path|${changeDateTime.millisecondsSinceEpoch}|$size', {
      TabSourceFile.kSourceFileID : _lastSourceFileID,
      TabSourceFile.kFilePath : path,
      TabSourceFile.kChangeDateTime : changeDateTime.millisecondsSinceEpoch,
      TabSourceFile.kSize : size,
    });

    return _lastSourceFileID;
  }

}

class TabJsonFileMem extends TabJsonFile {
  final MemDB db;
  TabJsonFileMem(this.db);

  int _lastJsonFileID = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabJsonFile.tabName);
  }

  @override
  Future<List<Map<String, Object?>>> getAllRows() async {
    return db.getTabRows(TabJsonFile.tabName);
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID}) async {
    return db.getRow(jsonFileID, TabJsonFile.tabName, jsonFileID);
  }

  @override
  Future<List<Map<String, Object?>>> getRowByGuid(String guid, {int? version}) async {
    Map<String, dynamic> filter = {
      TabJsonFile.kGuid : guid
    };

    if (version != null) {
      filter[TabJsonFile.kVersion] = version;
    }

    return db.getTabRows(TabJsonFile.tabName, filter: filter);
  }

  @override
  Future<Map<String, dynamic>?> getRowBySourceID({required String sourceFileID}) async {
    final rows = db.getTabRows(TabJsonFile.tabName, filter: { TabJsonFile.kSourceFileID : sourceFileID });
    if (rows.isEmpty) return null;
    return rows[0];
  }

  @override
  Future<int> insertRow(String sourceFileID, String rootPath, Map jsonMap) async {
    _lastJsonFileID++;
    final jsonFileID = _lastJsonFileID;

    final Map<String, Object?> row = {
      TabJsonFile.kJsonFileID   : jsonFileID,
      TabJsonFile.kSourceFileID : sourceFileID,
      TabJsonFile.kTitle        : jsonMap[TabJsonFile.kTitle   ],
      TabJsonFile.kGuid         : jsonMap[TabJsonFile.kGuid    ],
      TabJsonFile.kVersion      : jsonMap[TabJsonFile.kVersion ],
      TabJsonFile.kAuthor       : jsonMap[TabJsonFile.kAuthor  ],
      TabJsonFile.kSite         : jsonMap[TabJsonFile.kSite    ],
      TabJsonFile.kEmail        : jsonMap[TabJsonFile.kEmail   ],
      TabJsonFile.kLicense      : jsonMap[TabJsonFile.kLicense ],
      TabJsonFile.kRootPath     : rootPath,
    };

    db.insertRow(jsonFileID, TabJsonFile.tabName, jsonFileID, row);

    return jsonFileID;
  }

  @override
  int? fileGuidToJsonFileId(String guid) {
    final rows = db.getTabRows(TabJsonFile.tabName, filter: {TabJsonFile.kGuid : guid});
    if (rows.isEmpty) return null;

    final jsonFileID = rows.first[TabJsonFile.kJsonFileID];
    return jsonFileID;
  }

  @override
  FileKey jsonFileIdToFileKey(int jsonFileId) {
    final row = db.getRow(jsonFileId, TabJsonFile.tabName, jsonFileId)!;
    final guid = row[TabJsonFile.kGuid];
    final version = row[TabJsonFile.kVersion];
    return FileKey(guid, version, jsonFileId);
  }
}

class TabCardStyleMem extends TabCardStyle {
  final MemDB db;
  TabCardStyleMem(this.db);

  int _lastId = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardStyle.tabName);
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required String cardStyleKey}) async {
    final row = db.getRow(jsonFileID, TabCardStyle.tabName, cardStyleKey);
    return getRowPrepare(row);
  }

  @override
  Future<List<String>> getStyleKeyList({ required int jsonFileID}) async {
    final rows = db.getRows(jsonFileID, TabCardStyle.tabName);
    final result = <String>[];

    for (var row in rows) {
      final styleKey = row[TabCardStyle.kCardStyleKey];
      if (styleKey == null) continue;
      result.add(styleKey);
    }

    return result;
  }

  @override
  Future<void> insertRow({required int jsonFileID, required String cardStyleKey, required String jsonStr}) async {
    _lastId++;
    final id = _lastId;

    final Map<String, Object?> row = {
      TabCardStyle.kID           : id,
      TabCardStyle.kJsonFileID   : jsonFileID,
      TabCardStyle.kCardStyleKey : cardStyleKey,
      TabCardStyle.kJson         : jsonStr
    };

    db.insertRow(jsonFileID, TabCardStyle.tabName, cardStyleKey, row);
  }
}

class TabQualityLevelMem extends TabQualityLevel {
  final MemDB db;
  TabQualityLevelMem(this.db);

  int _lastId = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabQualityLevel.tabName);
  }

  @override
  Future<void> insertRow({required int jsonFileID, required String qualityName, required int minQuality, required int avgQuality}) async {
    _lastId++;
    final id = _lastId;

    final Map<String, Object?> row = {
      TabQualityLevel.kID           : id,
      TabQualityLevel.kJsonFileID   : jsonFileID,
      TabQualityLevel.kQualityName  : qualityName,
      TabQualityLevel.kMinQuality   : minQuality,
      TabQualityLevel.kAvgQuality   : avgQuality,
    };

    db.insertRow(jsonFileID, TabQualityLevel.tabName, qualityName, row);
  }

  @override
  Future<List<String>> getLevelNameList({required int jsonFileID}) async {
    final rows = db.getRows(jsonFileID, TabQualityLevel.tabName);
    final result = <String>[];

    for (var row in rows) {
      final levelName = row[TabQualityLevel.kQualityName];
      if (levelName == null) continue;
      result.add(levelName);
    }

    return result;
  }
}

class TabCardHeadMem extends TabCardHead{
  final MemDB db;
  TabCardHeadMem(this.db);

  int _lastCardID = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardHead.tabName);
  }

  @override
  Future<List<Map<String, Object?>>> getAllRows() async {
    return db.getTabRows(TabCardHead.tabName);
  }

  @override
  Future<List<Map<String, Object?>>> getFileRows({ required int jsonFileID}) async {
    return db.getRows(jsonFileID, TabCardHead.tabName);
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required int cardID}) async {
    return db.getRow(jsonFileID, TabCardHead.tabName, cardID);
  }

  @override
  Future<List<String>> getFileCardKeyList({ required int jsonFileID}) async {
    final rows = db.getRows(jsonFileID, TabCardHead.tabName);
    final result = <String>[];

    for (var row in rows) {
      final cardKey = row[TabCardHead.kCardKey];
      if (cardKey == null) continue;
      result.add(cardKey);
    }

    return result;
  }

  @override
  Future<List<String>> getFileGroupList({ required int jsonFileID}) async {
    final rows = db.getRows(jsonFileID, TabCardHead.tabName);
    final result = <String>[];

    for (var row in rows) {
      final group = row[TabCardHead.kGroup];
      if (group == null) continue;
      if (result.contains(group)) continue;
      result.add(group);
    }

    return result;
  }

  @override
  Future<int?> getCardIdFromKey({ required int jsonFileID, required String cardKey}) async {
    final rows = db.getRows(jsonFileID, TabCardHead.tabName, filter: {TabCardHead.kCardKey : cardKey});
    if (rows.length != 1) return null;
    return rows[0][TabCardHead.kCardID] as int;
  }

  @override
  Future<int> insertRow({
    required int jsonFileID,
    required String cardKey,
    required String title,
    required String help,
    required int difficulty,
    required String cardGroupKey,
    required int bodyCount,
    int? sourceRowId,
  }) async {

    _lastCardID++;
    final cardID = _lastCardID;

    final Map<String, Object?> row = {
      TabCardHead.kJsonFileID : jsonFileID,
      TabCardHead.kCardID     : cardID,
      TabCardHead.kCardKey    : cardKey,
      TabCardHead.kTitle      : title,
      TabCardHead.kHelp       : help,
      TabCardHead.kDifficulty : difficulty,
      TabCardHead.kGroup      : cardGroupKey,
      TabCardHead.kBodyCount  : bodyCount,
      TabCardHead.kSourceRowId: sourceRowId,
    };

    db.insertRow(jsonFileID, TabCardHead.tabName, cardID, row);

    return cardID;
  }

  @override
  Future<void> clearRegulatorPatchOnAllRow() async {
    final rows = db.getTabRows(TabCardHead.tabName);
    for (var row in rows) {
      row[TabCardHead.kExclude] = false;
    }
  }

  @override
  Future<int> getGroupCardCount({required int jsonFileID, required cardGroupKey}) async {
     final rows = db.getRows(jsonFileID, TabCardHead.tabName, filter: { TabCardHead.kGroup : cardGroupKey });
     return rows.length;
  }

  @override
  Future<void> setRegulatorPatchOnCard({required int jsonFileID, required int cardID, required int regulatorSetIndex, required bool exclude}) async {
    final row = db.getRow(jsonFileID, TabCardHead.tabName, cardID)!;
    row[TabCardHead.kExclude] = exclude;
  }

}

class TabCardTagMem extends TabCardTag {
  final MemDB db;
  TabCardTagMem(this.db);

  int _lastId = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardTag.tabName);
  }

  @override
  Future<List<String>> getCardTags({required int jsonFileID, required int cardID}) async {
    final rows = db.getRows(jsonFileID, TabCardTag.tabName, key: cardID);
    return rows.map((row) => row[TabCardTag.kTag] as String).toList();
  }

  @override
  Future<List<String>> getFileTagList({ required int jsonFileID}) async {
    final rows = db.getRows(jsonFileID, TabCardTag.tabName);

    final result = <String>[];

    for (var row in rows) {
      final tag = row[TabCardTag.kTag];
      if (tag == null) continue;
      if (result.contains(tag)) continue;
      result.add(tag);
    }

    return result;
  }

  @override
  Future<void> insertRow({required int jsonFileID, required int cardID, required String tag}) async {
    _lastId++;
    final id = _lastId;

    final Map<String, Object?> row = {
      TabCardTag.kID             : id,
      TabCardTag.kTag            : tag
    };

    db.insertRow(jsonFileID, TabCardTag.tabName, cardID, row);
  }
}

class TabCardLinkMem extends TabCardLink {
  final MemDB db;
  TabCardLinkMem(this.db);

  int _lastLinkId = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardLink.tabName);
  }

  @override
  Future<int> insertRow({required int jsonFileID, required int cardID, required String qualityName}) async {
    _lastLinkId++;
    final linkId = _lastLinkId;

    final Map<String, Object?> row = {
      TabCardLink.kJsonFileID     : jsonFileID,
      TabCardLink.kLinkID         : linkId,
      TabCardLink.kCardID         : cardID,
      TabCardLink.kQualityName    : qualityName,
    };

    db.insertRow(jsonFileID, TabCardLink.tabName, linkId, row);

    return linkId;
  }

}

class TabTemplateSourceMem extends TabTemplateSource {
  final MemDB db;
  TabTemplateSourceMem(this.db);

  int _lastSourceId = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabTemplateSource.tabName);
  }

  @override
  Future<int> insertRow({required int jsonFileID, required Map<String, dynamic> source}) async {
    _lastSourceId++;
    final sourceId = _lastSourceId;

    db.insertRow(jsonFileID, TabTemplateSource.tabName, sourceId, source);

    return sourceId;
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required int sourceId}) async {
    return db.getRow(jsonFileID, TabTemplateSource.tabName, sourceId);
  }
}

class TabCardLinkTagMem extends TabCardLinkTag {
  final MemDB db;
  TabCardLinkTagMem(this.db);

  int _lastId = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardLinkTag.tabName);
  }

  @override
  Future<void> insertRow({required int jsonFileID, required int linkId, required String tag}) async {
    _lastId++;
    final id = _lastId;

    final Map<String, Object?> row = {
      TabCardLinkTag.kID         : id,
      TabCardLinkTag.kJsonFileID : jsonFileID,
      TabCardLinkTag.kLinkID     : linkId,
      TabCardLinkTag.kTag        : tag
    };

    db.insertRow(jsonFileID, TabCardLinkTag.tabName, linkId, row);
  }
}

class TabCardBodyMem extends TabCardBody {
  final MemDB db;
  TabCardBodyMem(this.db);

  int _lastId = 0;

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardBody.tabName);
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required int cardID, required int bodyNum}) async {
    final row = db.getRow(jsonFileID, TabCardBody.tabName, '$cardID/$bodyNum');
    return getRowPrepare(row);
  }

  @override
  Future<void> insertRow({required int jsonFileID, required int cardID, required int bodyNum, required String json}) async {
    _lastId++;
    final id = _lastId;

    final Map<String, Object?> row = {
      TabCardBody.kID         : id,
      TabCardBody.kJsonFileID : jsonFileID,
      TabCardBody.kCardID     : cardID,
      TabCardBody.kBodyNum    : bodyNum,
      TabCardBody.kJson       : json
    };

    db.insertRow(jsonFileID, TabCardBody.tabName, '$cardID/$bodyNum', row);
  }
}

class TabFileUrlMapMem extends TabFileUrlMap {
  final MemDB db;
  TabFileUrlMapMem(this.db);

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabFileUrlMap.tabName);
  }

  @override
  String? getFileUrl({required int jsonFileID, required String fileName}) {
    final fileUrlMap = db.getRow(jsonFileID, TabFileUrlMap.tabName, jsonFileID);
    if (fileUrlMap == null) return null;
    return fileUrlMap[fileName];
  }

  @override
  Future<void> insertRows({required int jsonFileID, required Map<String, String> fileUrlMap}) async {
    db.insertRow(jsonFileID, TabFileUrlMap.tabName, jsonFileID, fileUrlMap);
  }

  @override
  Future<void> deleteRow({required int jsonFileID, required String fileName}) async {
    final fileUrlMap = db.getRow(jsonFileID, TabFileUrlMap.tabName, jsonFileID);
    if (fileUrlMap == null) return;
    fileUrlMap.remove(fileName);
  }

  @override
  Future<void> insertRow({required int jsonFileID, required String fileName, required String url}) async {
    final fileUrlMap = db.getRow(jsonFileID, TabFileUrlMap.tabName, jsonFileID);
    if (fileUrlMap == null) return;
    fileUrlMap[fileName] = url;
  }
}

class TabCardStatMem extends TabCardStat {
  final MemDB db;
  TabCardStatMem(this.db);

  int _lastId = 0;

  @override
  Future<void> clear() async {
    db.deleteRows(0, TabCardStat.tabName);
  }

  @override
  Future<List<Map<String, Object?>>> getAllRows() async {
    final rows = db.getTabRows(TabCardStat.tabName);
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required int cardID}) async {
    final row = db.getRow(jsonFileID, TabCardStat.tabName, cardID);
    return row;
  }

  @override
  Future<int> insertRow({
    required int    jsonFileID,
    required int    cardID,
    required String cardKey,
    required String cardGroupKey
  }) async {
    _lastId ++;

    Map<String, Object> row = {
      TabCardStat.kID              : _lastId,
      TabCardStat.kJsonFileID      : jsonFileID,
      TabCardStat.kCardID          : cardID,
      TabCardStat.kCardKey         : cardKey,
      TabCardStat.kCardGroupKey    : cardGroupKey,
      TabCardStat.kQuality         : 0,
      TabCardStat.kLastResult      : false,
      TabCardStat.kQualityFromDate : 0,
      TabCardStat.kStartDate       : 0,
      TabCardStat.kTestsCount      : 0,
      TabCardStat.kJson            : '',
    };

    db.insertRow(jsonFileID, TabCardStat.tabName, cardID, row);

    return _lastId;
  }

  @override
  Future<int> insertRowFromMap(Map<String, dynamic> rowMap) async {
    final jsonFileID = rowMap[TabCardStat.kJsonFileID] as int;
    final cardID     = rowMap[TabCardStat.kCardID    ] as int;

    _lastId ++;

    final cloneMap = {
      TabCardStat.kID : _lastId,
      ...rowMap
    };

    db.insertRow(jsonFileID, TabCardStat.tabName, cardID, cloneMap);

    return _lastId;
  }

  @override
  Future<void> removeOldCard(int jsonFileID, List<String> cardKeyList) async {
    final rows = db.getRows(jsonFileID, TabCardStat.tabName);

    for (var row in rows) {
      final cardKey = row[TabCardStat.kCardKey];
      if (cardKeyList.contains(cardKey)) continue;
      final cardID = row[TabCardStat.kCardID];
      db.deleteRows(jsonFileID, TabCardStat.tabName, filter: {TabCardStat.kCardID: cardID});
    }

  }

  @override
  Future<bool> updateRow(int jsonFileID, int cardID, Map<String, Object?> map) async {
    final row = db.getRow(jsonFileID, TabCardStat.tabName, cardID);
    if (row == null) return false;

    for (var mapEntry in map.entries) {
      row[mapEntry.key] = mapEntry.value;
    }

    return true;
  }
  
}

class TabTestResultMem extends TabTestResult  {
  final MemDB db;
  TabTestResultMem(this.db);

  int _lastId = 0;

  @override
  Future<int> getFirstTime() async {
    final rows = db.getTabRows(TabTestResult.tabName);

    int result = 0;

    for (var row in rows) {
      final dateTime = row[TabTestResult.kDateTime] as int;
      if (result == 0) {
        result = dateTime;
        continue;
      }

      if (result > dateTime) {
        result = dateTime;
      }
    }

    return result;
  }

  @override
  Future<int> getLastTime() async {
    final rows = db.getTabRows(TabTestResult.tabName);

    int result = 0;

    for (var row in rows) {
      final dateTime = row[TabTestResult.kDateTime] as int;

      if (result < dateTime) {
        result = dateTime;
      }
    }

    return result;
  }

  @override
  Future<List<TestResult>> getForPeriod(int fromDate, int toDate) async {
    final rows = db.getTabRows(TabTestResult.tabName);

    final result = <TestResult>[];

    for (var row in rows) {
      final dateTime = row[TabTestResult.kDateTime] as int;

      if (dateTime < fromDate || dateTime > toDate) continue;

      result.add(TestResult.fromMap(row));
    }
    
    return result;
  }

  @override
  Future<int> insertRow(TestResult testResult) async {
    _lastId ++;

    Map<String, Object> row = {
      TabTestResult.kFileGuid      : testResult.fileGuid,
      TabTestResult.kFileVersion   : testResult.fileVersion,
      TabTestResult.kCardID        : testResult.cardID,
      TabTestResult.kBodyNum       : testResult.bodyNum,
      TabTestResult.kResult        : testResult.result,
      TabTestResult.kEarned        : testResult.earned,
      TabTestResult.kTryCount      : testResult.tryCount,
      TabTestResult.kSolveTime     : testResult.solveTime,
      TabTestResult.kDateTime      : testResult.dateTime,
      TabTestResult.kQualityBefore : testResult.qualityBefore,
      TabTestResult.kQualityAfter  : testResult.qualityAfter,
      TabTestResult.kDifficulty    : testResult.difficulty,
    };

    db.insertRow(0, TabTestResult.tabName, _lastId, row);

    return _lastId;
  }

}

class DbSourceMem extends DbSource{
  final MemDB db;
  DbSourceMem(this.db);

  static DbSourceMem create() {
    final db         = MemDB();

    final dbSource = DbSourceMem(db);

    dbSource.tabSourceFile     = TabSourceFileMem(db);
    dbSource.tabJsonFile       = TabJsonFileMem(db);
    dbSource.tabCardHead       = TabCardHeadMem(db);
    dbSource.tabCardTag        = TabCardTagMem(db);
    dbSource.tabCardLink       = TabCardLinkMem(db);
    dbSource.tabCardLinkTag    = TabCardLinkTagMem(db);
    dbSource.tabCardBody       = TabCardBodyMem(db);
    dbSource.tabCardStyle      = TabCardStyleMem(db);
    dbSource.tabQualityLevel   = TabQualityLevelMem(db);
    dbSource.tabTemplateSource = TabTemplateSourceMem(db);
    dbSource.tabFileUrlMap     = TabFileUrlMapMem(db);
    dbSource.tabCardStat       = TabCardStatMem(db);
    dbSource.tabTestResult     = TabTestResultMem(db);

    return dbSource;
  }

  @override
  Future<void> init() async {}
}