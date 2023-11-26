import 'db.dart';

class MemDbRow{
  final int jsonFileID;
  final String tabName;
  final dynamic key;
  final Map<String, dynamic> row;

  MemDbRow(this.jsonFileID, this.tabName, this.key, this.row);
}

class MemDB{
  final rowList = <MemDbRow>[];

  insertRow(int jsonFileID, String tabName, dynamic key, Map<String, dynamic> row) {
    rowList.add(MemDbRow(jsonFileID, tabName, key, row));
  }

  List<Map<String, dynamic>> getTabRows(String tabName, {dynamic key, Map<String, dynamic>? filter}) {
    final result = <Map<String, dynamic>>[];

    for (var dbRow in rowList) {
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

    for (var dbRow in rowList) {
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
    for (var dbRow in rowList) {
      if (dbRow.jsonFileID == jsonFileID && dbRow.tabName == tabName && dbRow.key == key) {
        return dbRow.row;
      }
    }

    return null;
  }

  void deleteRows(int jsonFileID, String tabName){
    rowList.removeWhere((dbRow) => dbRow.jsonFileID == jsonFileID && dbRow.tabName == tabName);
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
    return db.getRow(jsonFileID, TabJsonFile.tabName, '');
  }

  @override
  Future<List<Map<String, Object?>>> getRowByGuid(String guid, int version) async {
    return db.getTabRows(TabJsonFile.tabName);
  }

  @override
  Future<Map<String, dynamic>?> getRowBySourceID({required String sourceFileID}) async {
    final rows = db.getTabRows(TabJsonFile.tabName);
    if (rows.isEmpty) return null;
    return rows[0];
  }

  @override
  Future<int> insertRow(String sourceFileID, Map jsonMap) async {
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
    };

    db.insertRow(jsonFileID, TabCardStyle.tabName, jsonFileID, row);

    return jsonFileID;
  }
}

class TabCardStyleMem extends TabCardStyle {
  final MemDB db;
  TabCardStyleMem(this.db);

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardStyle.tabName);
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required String cardStyleKey}) async {
    return db.getRow(jsonFileID, TabCardStyle.tabName, cardStyleKey);
  }

  @override
  Future<void> insertRow({required int jsonFileID, required String cardStyleKey, required String jsonStr}) async {
    final Map<String, Object?> row = {
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

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabQualityLevel.tabName);
  }

  @override
  Future<void> insertRow({required int jsonFileID, required String qualityName, required int minQuality, required int avgQuality}) async {
    final Map<String, Object?> row = {
      TabQualityLevel.kJsonFileID   : jsonFileID,
      TabQualityLevel.kQualityName  : qualityName,
      TabQualityLevel.kMinQuality   : minQuality,
      TabQualityLevel.kAvgQuality   : avgQuality,
    };

    db.insertRow(jsonFileID, TabCardTag.tabName, qualityName, row);
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
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required int cardID}) async {
    return db.getRow(jsonFileID, TabCardHead.tabName, cardID);
  }

  @override
  Future<int> insertRow({
    required int jsonFileID,
    required String cardKey,
    required String title,
    required String help,
    required int difficulty,
    required String cardGroupKey,
    required int bodyCount
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
    };

    db.insertRow(jsonFileID, TabCardHead.tabName, cardID, row);

    return cardID;
  }

}

class TabCardTagMem extends TabCardTag {
  final MemDB db;
  TabCardTagMem(this.db);

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
  Future<void> insertRow({required int jsonFileID, required int cardID, required String tag}) async {
    final Map<String, Object?> row = {
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

class TabCardLinkTagMem extends TabCardLinkTag {
  final MemDB db;
  TabCardLinkTagMem(this.db);

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardLinkTag.tabName);
  }

  @override
  Future<void> insertRow({required int jsonFileID, required int linkId, required String tag}) async {
    final Map<String, Object?> row = {
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

  @override
  Future<void> deleteJsonFile(int jsonFileID) async {
    db.deleteRows(jsonFileID, TabCardBody.tabName);
  }

  @override
  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required int cardID, required int bodyNum}) async {
    return db.getRow(jsonFileID, TabCardBody.tabName, '$cardID/$bodyNum');
  }

  @override
  Future<void> insertRow({required int jsonFileID, required int cardID, required int bodyNum, required String json}) async {
    final Map<String, Object?> row = {
      TabCardBody.kJsonFileID : jsonFileID,
      TabCardBody.kCardID     : cardID,
      TabCardBody.kBodyNum    : bodyNum,
      TabCardBody.kJson       : json
    };

    db.insertRow(jsonFileID, TabCardBody.tabName, '$cardID/$bodyNum', row);
  }
}

class DbSourceMem extends DbSource{
  final MemDB db;
  DbSourceMem(this.db);

  static DbSourceMem create() {
    final db = MemDB();

    final dbSource = DbSourceMem(db);

    dbSource.tabCardBody = TabCardBodyMem(db);

    return dbSource;
  }
}