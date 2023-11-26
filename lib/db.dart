import 'dart:core';
import 'decardj.dart';

class FileKey {
  final String guid;
  final int version;
  final int jsonFileID;
  FileKey(this.guid, this.version, this.jsonFileID);
}

/// Loaded json files
abstract class TabJsonFile {
  static const String tabName       = 'JsonFile';

  static const String kJsonFileID   = 'jsonFileID';
  static const String kSourceFileID = 'sourceFileID';
  static const String kTitle        = DjfFile.title;
  static const String kGuid         = DjfFile.guid;
  static const String kVersion      = DjfFile.version;
  static const String kAuthor       = DjfFile.author;
  static const String kSite         = DjfFile.site;
  static const String kEmail        = DjfFile.email;
  static const String kLicense      = DjfFile.license;

  TabJsonFile();

  Future<List<Map<String, Object?>>> getRowByGuid(String guid, int version);

  Future<Map<String, dynamic>?> getRowBySourceID({required String sourceFileID});

  // return jsonFileID
  Future<int> insertRow(String sourceFileID, Map jsonMap);

  Future<Map<String, dynamic>?> getRow({required int jsonFileID});

  Future<List<Map<String, Object?>>> getAllRows();

  Future<void> deleteJsonFile(int jsonFileID);
}

abstract class TabCardStyle {
  static const String tabName        = 'CardStyle';

  static const String kID            = 'id';
  static const String kJsonFileID    = TabJsonFile.kJsonFileID;
  static const String kCardStyleKey  = 'cardStyleKey';  // map from DjfCardStyle.id
  static const String kJson          = 'json';          // style data are stored as json, when needed they are unpacked

  TabCardStyle();

  Future<void> deleteJsonFile(int jsonFileID);

  Future<void> insertRow({ required int jsonFileID, required String cardStyleKey, required String jsonStr });

  Future<Map<String, dynamic>?> getRow({ required int jsonFileID, required String cardStyleKey });
}

abstract class TabQualityLevel {
  static const String tabName        = 'QualityLevel';

  static const String kID            = 'id';
  static const String kJsonFileID    = TabJsonFile.kJsonFileID;
  static const String kQualityName   = 'qualityName'; // map from DjfQualityLevel.qualityName
  static const String kMinQuality    = DjfQualityLevel.minQuality;
  static const String kAvgQuality    = DjfQualityLevel.avgQuality;

  TabQualityLevel();

  Future<void> insertRow({ required int jsonFileID, required String qualityName, required int minQuality, required int avgQuality });

  Future<void> deleteJsonFile(int jsonFileID);
}

abstract class TabCardHead {
  static const String tabName        = 'CardHead';

  static const String kCardID        = 'cardID';
  static const String kJsonFileID    = TabJsonFile.kJsonFileID;
  static const String kCardKey       = 'cardKey'; // map from DjfCard.id
  static const String kTitle         = DjfCard.title;
  static const String kHelp          = DjfCard.help;
  static const String kDifficulty    = DjfCard.difficulty;
  static const String kGroup         = 'groupKey'; // map from DjfCard.group;
  static const String kBodyCount     = 'bodyCount'; // number of records in the DjfCard.bodyList

  static const String kRegulatorSetIndex   = 'regulatorSetIndex'; // index of set in Regulator.setList

  TabCardHead();

  Future<void> deleteJsonFile(int jsonFileID);

  Future<int> insertRow({
    required int    jsonFileID,
    required String cardKey,
    required String title,
    required String help,
    required int    difficulty,
    required String cardGroupKey,
    required int    bodyCount,
  });

  Future<Map<String, dynamic>?> getRow({required int jsonFileID, required int cardID});

  Future<List<Map<String, Object?>>> getAllRows();
}

abstract class TabCardTag {
  static const String tabName         = 'CardTag';

  static const String kID             = 'id';
  static const String kJsonFileID     = TabJsonFile.kJsonFileID;
  static const String kCardID         = TabCardHead.kCardID;
  static const String kTag            = 'tag';

  TabCardTag();

  Future<void> deleteJsonFile(int jsonFileID);

  Future<void> insertRow({ required int jsonFileID, required int cardID, required String tag});

  Future<List<String>> getCardTags({required int jsonFileID, required int cardID});
}

abstract class TabCardLink {
  static const String tabName         = 'CardLink';

  static const String kLinkID         = 'linkID';
  static const String kJsonFileID     = TabJsonFile.kJsonFileID;
  static const String kCardID         = TabCardHead.kCardID;
  static const String kQualityName    = 'qualityName';

  TabCardLink();

  Future<void> deleteJsonFile(int jsonFileID);

  Future<int> insertRow({ required int jsonFileID, required int cardID, required String qualityName});
}

abstract class TabCardLinkTag {
  static const String tabName  = 'CardLinkTag';

  static const String kID         = 'id';
  static const String kJsonFileID = TabJsonFile.kJsonFileID;
  static const String kLinkID     = TabCardLink.kLinkID;
  static const String kTag        = 'tag';

  TabCardLinkTag();

  Future<void> deleteJsonFile(int jsonFileID);

  Future<void> insertRow({ required int jsonFileID, required int linkId, required String tag});
}

abstract class TabCardBody {
  static const String tabName     = 'CardBody';

  static const String kID         = 'id';
  static const String kJsonFileID = TabJsonFile.kJsonFileID;
  static const String kCardID     = TabCardHead.kCardID;
  static const String kBodyNum    = 'bodyNum'; // the card can have many bodies, the body number is stored here
  static const String kJson       = 'json';    // card body data are stored as json, when needed they are unpacked

  Future<void> deleteJsonFile(int jsonFileID);

  Future<void> insertRow({ required int jsonFileID, required int cardID, required int bodyNum, required String json });

  Future<Map<String, dynamic>?> getRow({ required int jsonFileID, required int cardID, required int bodyNum });
}

abstract class DbSource {
  late TabJsonFile     tabJsonFile;
  late TabCardHead     tabCardHead;
  late TabCardTag      tabCardTag;
  late TabCardLink     tabCardLink;
  late TabCardLinkTag  tabCardLinkTag;
  late TabCardBody     tabCardBody;
  late TabCardStyle    tabCardStyle;
  late TabQualityLevel tabQualityLevel;

  Future<void> deleteJsonFile(int jsonFileID) async {
    await tabJsonFile.deleteJsonFile(jsonFileID);
    await tabCardHead.deleteJsonFile(jsonFileID);
    await tabCardTag.deleteJsonFile(jsonFileID);
    await tabCardLink.deleteJsonFile(jsonFileID);
    await tabCardLinkTag.deleteJsonFile(jsonFileID);
    await tabCardBody.deleteJsonFile(jsonFileID);
    await tabCardStyle.deleteJsonFile(jsonFileID);
    await tabQualityLevel.deleteJsonFile(jsonFileID);
  }
}