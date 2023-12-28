import 'dart:math';
import 'dart:ui';
import 'package:decard_web/regulator.dart';
import 'package:path/path.dart' as path_util;

import 'db.dart';
import 'decardj.dart';
import 'media_widgets.dart';

class CardParam {
  late int cost;
  late int penalty;
  late int tryCount;
  late int duration;
  late int lowCost;

  CardParam(RegDifficulty difficulty, int quality) {
    cost     = _getValueForQuality(difficulty.maxCost,     difficulty.minCost,     quality);
    penalty  = _getValueForQuality(difficulty.minPenalty,  difficulty.maxPenalty,  quality); // penalty moves in the opposite direction to all others
    tryCount = _getValueForQuality(difficulty.maxTryCount, difficulty.minTryCount, quality);
    duration = _getValueForQuality(difficulty.maxDuration, difficulty.minDuration, quality);

    lowCost = (cost * _getValueForQuality(difficulty.maxDurationLowCostPercent, difficulty.minDurationLowCostPercent, quality) / 100).round();
  }

  int _getValueForQuality(int maxValue, int minValue, int quality){
    final int result = (maxValue - (( (maxValue - minValue) * quality ) / 100 ) ).round();
    return result;
  }
}


class TagPrefix {
  static String cardKey    = 'id@';
  static String group      = 'grp@';
  static String difficulty = 'dfy@';
}

class FileExt {
  static const String textFile = "text:";
  static const txtExtList   = <String>['txt', 'md', 'html'];
  static const textExtList  = <String>['txt', 'md', 'html', 'json', DjfFileExtension.json];
  static const imageExtList = <String>['apng', 'avif', 'gif', 'jpg', 'jpeg', 'jfif', 'pjpeg', 'pjp', 'png', 'svg', 'webp', 'bmp', 'tif', 'tiff'];
  static const audioExtList = <String>['m4a', 'flac', 'mp3', 'mp4', 'wav', 'wma', 'aac'];
  static const sourceExtList = <String>[...txtExtList, ...imageExtList, ...audioExtList];

  static const contentHtml     = 'html';
  static const contentMarkdown = 'md';
  static const contentJson     = 'json';
  static const contentText     = 'txt';

  static String getFileExt(String fileName) {
    final fileExt = path_util.extension(fileName);
    if (fileExt.isEmpty) return '';
    if (fileExt.length > 6) return '';

    final extension = fileExt.toLowerCase().substring(1);

    if (!textExtList.contains(extension) && !imageExtList.contains(extension) && !audioExtList.contains(extension)) {
      return '';
    }

    return extension;
  }

  static String getContentExt(String content) {
    String subStr = '';
    if (content.length > 10) {
      subStr = content.substring(0, 10);
    } else {
      subStr = content;
    }

    if (subStr.contains(':')){
      return subStr.split(':').first.toLowerCase();
    }

    return '';
  }

  static String prepareMarkdown(CardData card, String markdown) {
    final regexp = RegExp(r'!\[.*\]\((.*?)\s*(".*")?\s*\)', caseSensitive: false, multiLine: true);

    final newMarkdown = markdown.replaceAllMapped(regexp, (match) {
      final matchStr = match[0]!;
      final fileName = match[1];
      if (fileName == null) return matchStr;

      final fileUrl = getFileUrl(card, fileName);
      final str = matchStr.replaceFirst(']($fileName', ']($fileUrl');
      return str;
    });

    return newMarkdown;
  }

  static String prepareHtml(CardData card, String html) {
    final regexp = RegExp(r'<img[^>]*src="([^"]+)"[^>]*>', caseSensitive: false, multiLine: true);

    final newHtml = html.replaceAllMapped(regexp, (match) {
      final matchStr = match[0]!;
      final fileName = match[1];
      if (fileName == null) return matchStr;

      final fileUrl = getFileUrl(card, fileName);
      final str = matchStr.replaceFirst('src="$fileName', 'src="$fileUrl');
      return str;
    });

    return newHtml;
  }

  static Future<String?> getTextFileContent(DbSource dbSource, int jsonFileID, String? source, {required bool setSourceType, Map<String, dynamic>? convertMap}) async {
    if (source == null || source.isEmpty) return source;

    final fileExt = FileExt.getFileExt(source);
    if (FileExt.textExtList.contains(fileExt)) {
      final fileName = source;

      final fileUrl = dbSource.getFileUrl(jsonFileID, fileName);
      var fileContent = await getTextFromUrl(fileUrl);
      if (fileContent == null) return null;

      if (convertMap != null) {
        convertMap.forEach((key, value) {
          fileContent =  fileContent!.replaceAll('${DjfTemplateSource.paramBegin}$key${DjfTemplateSource.paramEnd}', value);
        });
      }

      if (setSourceType) {
        return '$fileExt:$fileContent';
      }

      return fileContent;
    }

    return source;
  }

  static String getFileUrl(CardData card, String fileName) {
    return card.dbSource.getFileUrl(card.pacInfo.jsonFileID, fileName);
  }
}

class CardData {
  final DbSource  dbSource;

  final PacInfo   pacInfo;
  final CardHead  head;
  final CardBody  body;
  final CardStyle style;

  List<String>? _tagList;
  List<String> get tagList => _tagList??[];
  
  CardData({
    required this.dbSource,
    required this.head,
    required this.style,
    required this.body,
    required this.pacInfo,
  });

  static Future<CardData> create(
    DbSource dbSource,
    int jsonFileID,
    int cardID,
    {
      int? bodyNum,
      CardSetBody setBody = CardSetBody.random,
    }
  ) async {

    final card = await _CardGenerator.createCard(dbSource, jsonFileID, cardID, bodyNum: bodyNum, setBody: setBody);
    return card;
  }

  Future<void> fillTags() async {
    if (_tagList != null) return;

    _tagList = await dbSource.tabCardTag.getCardTags(jsonFileID: head.jsonFileID, cardID: head.cardID);
    _tagList!.add('${TagPrefix.cardKey}${head.cardKey}');
    if (head.group.isNotEmpty){
      _tagList!.add('${TagPrefix.group}${head.group}');
    }
    _tagList!.add('${TagPrefix.difficulty}${head.difficulty}');
  }
}

enum CardSetBody {
  none,
  first,
  last,
  random,
}

class _CardGenerator {
  static DbSource?     _dbSource;

  static PacInfo?   _pacInfo;
  static CardHead?  _cardHead;
  static CardBody?  _cardBody;
  static CardStyle? _cardStyle;

  static Map<String, dynamic>? _convertMap;

  static final _random = Random();

  static Future<CardData> createCard(
      DbSource dbSource,
      int jsonFileID,
      int cardID,
      {
        int? bodyNum,
        CardSetBody setBody = CardSetBody.random,
      }) async {

    _dbSource   = dbSource;
    _pacInfo    = null;
    _cardHead   = null;
    _cardBody   = null;
    _cardStyle  = null;
    _convertMap = null;

    final pacData = await dbSource.tabJsonFile.getRow(jsonFileID: jsonFileID);
    _pacInfo = PacInfo.fromMap(pacData!);

    final headData = (await dbSource.tabCardHead.getRow(jsonFileID: jsonFileID, cardID : cardID))!;


    final templateSourceRowId = headData[TabCardHead.kSourceRowId];
    if (templateSourceRowId != null) {
      _convertMap = await dbSource.tabTemplateSource.getRow(jsonFileID: jsonFileID, sourceId: templateSourceRowId);
    }

    await CardHead.prepareMap(dbSource, _pacInfo!.jsonFileID, headData, _convertMap);
    _cardHead = CardHead.fromMap(headData);
    
    if (bodyNum != null) {
      await _setBodyNum(bodyNum);
    } else {
      switch(setBody){
        case  CardSetBody.first:
          await _setBodyNum(0);
          break;
        case CardSetBody.last:
          await _setBodyNum(_cardHead!.bodyCount - 1);
          break;
        case CardSetBody.random:
          await _setRandomBodyNum();
          break;
        case CardSetBody.none:
          break;
      }
    }
    
    final card = CardData(
        dbSource   : dbSource,
        head       : _cardHead!,
        body       : _cardBody!,
        style      : _cardStyle!,
        pacInfo    : _pacInfo!,
    );

    return card;
  }

  static Future<void> _setBodyNum(int bodyNum) async {
    final bodyData = (await _dbSource!.tabCardBody.getRow(jsonFileID: _cardHead!.jsonFileID, cardID: _cardHead!.cardID, bodyNum: bodyNum))!;
    await CardBody.prepareMap(_dbSource!, _pacInfo!.jsonFileID, bodyData, _convertMap);
    _cardBody = CardBody.fromMap(bodyData);

    final Map<String, dynamic> styleMap = {};
    for (var styleKey in _cardBody!.styleKeyList) {
      final styleData = await _dbSource!.tabCardStyle.getRow(jsonFileID: _cardHead!.jsonFileID, cardStyleKey: styleKey );
      styleMap.addEntries(styleData!.entries.where((element) => element.value != null));
    }

    styleMap.addEntries(_cardBody!.styleMap.entries.where((element) => element.value != null));

    _cardStyle = CardStyle.fromMap(styleMap);
  }

  static Future<void> _setRandomBodyNum() async {
    int bodyNum = 0;
    if (_cardHead!.bodyCount > 1) bodyNum = _random.nextInt(_cardHead!.bodyCount);

    await _setBodyNum(bodyNum);
  }
}

class CardPointer {
  final int jsonFileID;  // integer, identifier of the file in the database
  final int cardID;      // integer card identifier in the database

  CardPointer(this.jsonFileID, this.cardID);
}

enum AnswerInputMode {
  none,           // Input method not defined
  ddList,         // Drop-down list
  vList,          // vertical list
  hList,          // Horizontal list
  input,          // Arbitrary input field
  inputDigit,     // Field for arbitrary numeric input
  widgetKeyboard, // virtual keyboard: list of buttons on the keyboard, buttons can contain several characters, button separator symbol "\t" string translation "\n"
}

class CardStyle {
  final int id;                          // integer, style identifier in the database
  final int jsonFileID;                  // integer, identifier of the file in the database
  final String cardStyleKey;             // string, style identifier
  final bool dontShowAnswer;             // boolean, default false, will NOT show if the answer is wrong
  final bool dontShowAnswerOnDemo;       // boolean, default false, do NOT show in demo mode
  final List<String> answerVariantList;  // list of answer choices
  final int answerVariantCount;          // the number of displayed answer variants
  final TextAlign answerVariantAlign;    // the text alignment when displaying the answer choices
  final bool answerVariantListRandomize; // boolean, default false, output the list in random order
  final bool answerVariantMultiSel;      // boolean, default false, multiple selection from a set of values
  final AnswerInputMode answerInputMode; // string, fixed value set
  final bool answerCaseSensitive;        // boolean, answer is case sensitive
  final String? widgetKeyboard;          // virtual keyboard: list of buttons on the keyboard, buttons can contain several characters, button separator symbol "\t" string translation "\n"
  final int imageMaxHeight;              // maximum image height as a percentage of the screen height
  final int buttonImageWidth;            // Maximum button image width  as a percentage of the screen width
  final int buttonImageHeight;           // Maximum button image height as a percentage of the screen height

  const CardStyle({
    required this.id,
    required this.jsonFileID,
    required this.cardStyleKey,
    this.dontShowAnswer = false,
    this.dontShowAnswerOnDemo = false,
    required this.answerVariantList,
    this.answerVariantCount = -1,
    this.answerVariantAlign = TextAlign.center,
    this.answerVariantListRandomize = false,
    this.answerVariantMultiSel = false,
    this.answerInputMode = AnswerInputMode.vList,
    this.answerCaseSensitive = false,
    this.widgetKeyboard,
    this.imageMaxHeight = 50,
    this.buttonImageWidth = 0,
    this.buttonImageHeight = 0,
  });

  factory CardStyle.fromMap(Map<String, dynamic> json){
    final String answerInputModeStr = json[DjfCardStyle.answerInputMode];
    final String textAlignStr       = json[DjfCardStyle.answerVariantAlign]??TextAlign.center.name;

    return CardStyle(
      id                         : json[TabCardStyle.kID],
      jsonFileID                 : json[TabCardStyle.kJsonFileID],
      cardStyleKey               : json[TabCardStyle.kCardStyleKey],
      dontShowAnswer             : json[DjfCardStyle.dontShowAnswer]??false,
      dontShowAnswerOnDemo       : json[DjfCardStyle.dontShowAnswerOnDemo]??false,
      answerVariantList          : json[DjfCardStyle.answerVariantList] != null ? List<String>.from(json[DjfCardStyle.answerVariantList].map((x) => x)) : [],
      answerVariantCount         : json[DjfCardStyle.answerVariantCount]??-1,
      answerVariantAlign         : TextAlign.values.firstWhere((x) => x.name == textAlignStr),
      answerVariantListRandomize : json[DjfCardStyle.answerVariantListRandomize]??false,
      answerVariantMultiSel      : json[DjfCardStyle.answerVariantMultiSel]??false,
      answerInputMode            : AnswerInputMode.values.firstWhere((x) => x.name == answerInputModeStr),
      answerCaseSensitive        : json[DjfCardStyle.answerCaseSensitive]??false,
      widgetKeyboard             : json[DjfCardStyle.widgetKeyboard],
      imageMaxHeight             : json[DjfCardStyle.imageMaxHeight]??50,
      buttonImageWidth           : json[DjfCardStyle.buttonImageWidth]??0,
      buttonImageHeight          : json[DjfCardStyle.buttonImageHeight]??0,
    );
  }
}

class CardHead {
  final int    cardID;      // integer, the card identifier in the database
  final int    jsonFileID;  // integer, identifier of the file in the database
  final String cardKey;     // string, identifier of the card in the file
  final String group;
  final String title;
  final String help;
  final int    difficulty;
  final int    bodyCount;

  final int?    regulatorSetIndex;

  const CardHead({
    required this.cardID,
    required this.jsonFileID,
    required this.cardKey,
    required this.group,
    required this.title,
    required this.help,
    required this.difficulty,
    required this.bodyCount,
    required this.regulatorSetIndex
  });

  static Future<void> prepareMap(DbSource dbSource, int jsonFileID, Map<String, dynamic> map, Map<String, dynamic>? convertMap) async {
    map[DjfCard.help] = await FileExt.getTextFileContent(dbSource, jsonFileID, map[DjfCard.help], setSourceType: true, convertMap: convertMap);
  }

  factory CardHead.fromMap(Map<String, dynamic> json) {
    return CardHead(
      cardID     : json[TabCardHead.kCardID],
      jsonFileID : json[TabCardHead.kJsonFileID],
      cardKey    : json[TabCardHead.kCardKey],
      group      : json[TabCardHead.kGroup],
      title      : json[TabCardHead.kTitle],
      help       : json[TabCardHead.kHelp]??'',
      difficulty : json[TabCardHead.kDifficulty]??0,
      bodyCount  : json[TabCardHead.kBodyCount],
      regulatorSetIndex : json[TabCardHead.kRegulatorSetIndex],
    );
  }
}

class QuestionData {
  QuestionData({
    this.text,
    this.html,
    this.markdown,
    this.textConstructor,
    this.audio,
    this.video,
    this.image,
  });

  final String? text;     // String question text
  final String? html;     // html source
  final String? markdown; // markdown source
  final String? textConstructor; // textConstructor source
  final String? audio;    // link to audio source
  final String? video;    // link to video source
  final String? image;    // link to image source

  static Future<void> prepareMap(DbSource dbSource, int jsonFileID, Map<String, dynamic> map, Map<String, dynamic>? convertMap) async {
    map[DjfQuestionData.html]            = await FileExt.getTextFileContent(dbSource, jsonFileID, map[DjfQuestionData.html], setSourceType: false, convertMap: convertMap);
    map[DjfQuestionData.markdown]        = await FileExt.getTextFileContent(dbSource, jsonFileID, map[DjfQuestionData.markdown], setSourceType: false, convertMap: convertMap);
    map[DjfQuestionData.textConstructor] = await FileExt.getTextFileContent(dbSource, jsonFileID, map[DjfQuestionData.textConstructor], setSourceType: false, convertMap: convertMap);
  }

  factory QuestionData.fromMap(Map<String, dynamic> json) => QuestionData(
    text     : json[DjfQuestionData.text],
    html     : json[DjfQuestionData.html],
    markdown : json[DjfQuestionData.markdown],
    textConstructor : json[DjfQuestionData.textConstructor],
    audio    : json[DjfQuestionData.audio],
    video    : json[DjfQuestionData.video],
    image    : json[DjfQuestionData.image],
  );
}

class CardBody {
  final int    id;                // integer, body identifier in the database
  final int    jsonFileID;        // integer, file identifier in the database
  final int    cardID;            // integer, card identifier in the database
  final int    bodyNum;           // integer, body number
  final QuestionData questionData;
  final List<String> styleKeyList; // List of global styles
  final Map<String, dynamic> styleMap; // Own body style
  final List<String> answerList;
  final String clue;

  const CardBody({
    required this.id,
    required this.jsonFileID,
    required this.cardID,
    required this.bodyNum,
    required this.questionData,
    required this.styleKeyList,
    required this.styleMap,
    required this.answerList,
    required this.clue
  });

  static Future<void> prepareMap(DbSource dbSource, int jsonFileID, Map<String, dynamic> map, Map<String, dynamic>? convertMap) async {
    map[DjfCardBody.clue] = await FileExt.getTextFileContent(dbSource, jsonFileID, map[DjfCardBody.clue], setSourceType: true, convertMap: convertMap);

    final Map<String, dynamic> questionMap = map[ DjfCardBody.questionData];
    await QuestionData.prepareMap(dbSource, jsonFileID, questionMap, convertMap);
  }

  factory CardBody.fromMap(Map<String, dynamic> json) {
    return CardBody(
      id                : json[TabCardBody.kID],
      jsonFileID        : json[TabCardBody.kJsonFileID],
      cardID            : json[TabCardBody.kCardID],
      bodyNum           : json[TabCardBody.kBodyNum],
      questionData      : QuestionData.fromMap(json[ DjfCardBody.questionData]),
      styleKeyList      : json[DjfCardBody.styleIdList] != null ? List<String>.from(json[ DjfCardBody.styleIdList].map((x) => x)) : [],
      styleMap          : json[DjfCardBody.style]??{},
      answerList        : json[DjfCardBody.answerList] != null ? List<String>.from(json[ DjfCardBody.answerList].map((x) => x)) : [],
      clue              : json[DjfCardBody.clue]??'',
    );
  }
}

class PacInfo {
  final int    jsonFileID;
  final String sourceFileID;
  final String title;
  final String guid;
  final int    version;
  final String author;
  final String site;
  final String email;
  final String license;
  final String? sourceDir;

  PacInfo({
    required this.jsonFileID,
    required this.sourceFileID,
    required this.title,
    required this.guid,
    required this.version,
    required this.author,
    required this.site,
    required this.email,
    required this.license,
    this.sourceDir,
  });

  factory PacInfo.fromMap(Map<String, dynamic> json){
    return PacInfo(
      jsonFileID   : json[TabJsonFile.kJsonFileID],
      sourceFileID : json[TabJsonFile.kSourceFileID],
      title        : json[TabJsonFile.kTitle],
      guid         : json[TabJsonFile.kGuid],
      version      : json[TabJsonFile.kVersion],
      author       : json[TabJsonFile.kAuthor],
      site         : json[TabJsonFile.kSite],
      email        : json[TabJsonFile.kEmail],
      license      : json[TabJsonFile.kLicense],
      sourceDir    : json[TabJsonFile.kRootPath],
    );
  }
}