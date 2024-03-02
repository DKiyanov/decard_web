import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:decard_web/app_state.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'child_test_results.dart';
import 'db_mem.dart';
import 'regulator.dart';
import 'card_controller.dart';
import 'db.dart';
import 'parse_class_info.dart';
import 'package:simple_events/simple_events.dart' as event;

class WebChild{
  final String userID;
  final String childID;
  final String childName; 

  Regulator? _regulator;
  Regulator get regulator => _regulator!;
  ParseObject? regulatorParseObject;

  final statDB = DbSourceMem.create();

  // Future<int?> loadPack({int? packId, String? fileGuid, int? fileVersion }) async {
  //   final jsonFileID = await loadWebPackEx(dbSource: appState.dbSource,  packId: packId, fileGuid: fileGuid, fileVersion: fileVersion, expiredDuration: const Duration(minutes: 20));
  //   return jsonFileID!;
  // }

  ChildTestResults? _testResults;
  Future<ChildTestResults> get testResults async {
    if (_testResults != null) return _testResults!;
    _testResults = ChildTestResults(this);
    await _testResults!.init();
    return _testResults!;
  }

  WebChild(this.userID, this.childID, this.childName, String? regulatorJson, this.regulatorParseObject) {
    if (regulatorJson != null) {
      _regulator = Regulator.fromMap(jsonDecode(regulatorJson));
    } else {
      _regulator = Regulator.newEmpty();
    }
    _regulator!.fillDifficultyLevels();
  }
  
  Future<void> regulatorChange(Map<String, dynamic> json) async {
    _regulator = Regulator.fromMap(json);

    final jsonStr = jsonEncode(json);

    if (regulatorParseObject == null) {
      regulatorParseObject = ParseObject(ParseWebChildSource.className);
      regulatorParseObject!.set(ParseWebChildSource.userID     , userID);
      regulatorParseObject!.set(ParseWebChildSource.path       , childName);
      regulatorParseObject!.set(ParseWebChildSource.sourceType , ParseWebChildSource.sourceTypeRegulator);
      regulatorParseObject!.set(ParseWebChildSource.fileName   , ParseWebChildSource.sourceTypeRegulator);
    }

    regulatorParseObject!.set(ParseWebChildSource.textContent, jsonStr);
    regulatorParseObject!.set(ParseWebChildSource.size       , jsonStr.length);
    await regulatorParseObject!.save();
  }
}

class WebChildDevice {
  final String childID;
  final String name;
  final String deviceName;

  final String sourcePath;

  late DbSource dbSource;
  late CardController cardController;


  final packInfoList = <WebPackInfo>[];

  WebChildDevice(this.childID, this.name, this.deviceName, this.sourcePath) {
    dbSource       = DbSourceMem.create();
    cardController = CardController(dbSource: dbSource);
  }
}

class WebChildListManager {
  final String userID;

  WebChildListManager(this.userID);

  final childList     = <WebChild>[];
  final deviceList    = <WebChildDevice>[];
  final _packInfoList = <WebPackInfo>[];

  final onChange = event.SimpleEvent();
  bool _changed = false;

  Future<WebChild?> getChild(String childID) async {
    final child = appState.childManager!.childList.firstWhereOrNull((child) => child.childID == childID);
    if (child != null) return child;

    await refreshChildList();
    final child2 = appState.childManager!.childList.firstWhereOrNull((child) => child.childID == childID);
    return child2;
  }

  Future<void> refreshChildList() async {
    final queryChild =  QueryBuilder<ParseObject>(ParseObject(ParseChild.className));
    queryChild.whereEqualTo(ParseChild.userID, userID);
    final parseChildList = await queryChild.find();

    final queryDevice =  QueryBuilder<ParseObject>(ParseObject(ParseDevice.className));
    queryDevice.whereEqualTo(ParseDevice.userID, userID);
    final parseDeviceList = await queryDevice.find();

    final queryRegulator = QueryBuilder<ParseObject>(ParseObject(ParseWebChildSource.className));
    queryRegulator.whereEqualTo(ParseWebChildSource.userID, userID);
    queryRegulator.whereEqualTo(ParseWebChildSource.sourceType, ParseWebChildSource.sourceTypeRegulator);
    queryRegulator.keysToReturn([ParseWebChildSource.path, ParseWebChildSource.textContent]);
    final parseRegulatorList = await queryRegulator.find();

    final localChildList = <WebChild>[];
    localChildList.addAll(childList);

    for (var parseChild in parseChildList) {
      final child = childList.firstWhereOrNull((child) => child.childID == parseChild.objectId);
      if (child == null) {
        final childName = parseChild.get<String>(ParseChild.name)!;

        String? regulatorJson;
        final parseRegulator = parseRegulatorList.firstWhereOrNull((parseRegulator) => parseRegulator.get<String>(ParseWebChildSource.path) == childName);
        if (parseRegulator != null) {
          regulatorJson = parseRegulator.get<String>(ParseWebChildSource.textContent)!;
        }

        final newChild = WebChild(userID, parseChild.objectId!, childName, regulatorJson, parseRegulator);
        childList.add(newChild);
        _changed = true;
      } else {
        localChildList.remove(child);
      }
    }

    for (var child in localChildList) {
      childList.remove(child);
      _changed = true;
    }

    final localDeviceList = <WebChildDevice>[];
    localDeviceList.addAll(deviceList);

    for (var parseDevice in parseDeviceList) {
      final deviceName    = parseDevice.get<String>(ParseDevice.name)!;
      final deviceChildID = parseDevice.get<String>(ParseDevice.childID)!;
      final child         = childList.firstWhere((child) => child.childID == deviceChildID);

      final sourcePath = '${child.childName}/$deviceName';

      final device = deviceList.firstWhereOrNull((device) => device.sourcePath == sourcePath);
      if (device == null) {
        final newDevice = WebChildDevice(deviceChildID, child.childName, deviceName, sourcePath);
        deviceList.add(newDevice);
        _changed = true;
      } else {
        localDeviceList.remove(device);
      }
    }

    for (var device in localDeviceList) {
      deviceList.remove(device);
      _changed = true;
    }

    await _refreshChildSource();

    if (_changed) {
      onChange.send();
      _changed = false;
    }
  }

  Future<void> _refreshChildSource() async {
    final querySource = QueryBuilder<ParseObject>(ParseObject(ParseWebChildSource.className));
    querySource.whereEqualTo(ParseWebChildSource.userID, userID);
    querySource.whereEqualTo(ParseWebChildSource.sourceType, ParseWebChildSource.sourceTypePack);
    querySource.keysToReturn([ParseWebChildSource.path, ParseWebChildSource.addInfo]);
    final sourceList = await querySource.find();

    final packList = <int>[];

    for (var source in sourceList) {
      final packId = int.parse(source.get<String>(ParseWebChildSource.addInfo)!);
      if (_packInfoList.any((packInfo) => packInfo.packId == packId)) continue;
      packList.add(packId);
    }

    if (packList.isNotEmpty) {
      final queryPack = QueryBuilder<ParseObject>(ParseObject(ParseWebPackHead.className));
      queryPack.whereContainedIn(ParseWebPackHead.packId, packList);
      final packHeadList = await queryPack.find();

      for (var packHead in packHeadList) {
        _packInfoList.add(WebPackInfo.fromParse(packHead));
      }
    }

    for (var device in deviceList) {
      final localPackInfoList = <WebPackInfo>[];
      localPackInfoList.addAll(device.packInfoList);

      for (var source in sourceList) {
        final sourcePath = source.get<String>(ParseWebChildSource.path)!;
        if (sourcePath != device.sourcePath) continue;

        final packId = int.parse(source.get<String>(ParseWebChildSource.addInfo)!);
        final packInfo = _packInfoList.firstWhere((packInfo) => packInfo.packId == packId);

        if (device.packInfoList.contains(packInfo)) {
          localPackInfoList.remove(packInfo);
        } else {
          device.packInfoList.add(packInfo);
          _changed = true;
        }
      }

      for (var packInfo in localPackInfoList) {
        device.packInfoList.remove(packInfo);
        _changed = true;
      }
    }

  }

  Future<bool> addPack(WebPackInfo packInfo, WebChildDevice device) async {
    final result = await addPackForChild(packInfo.packId, userID, device.sourcePath);

    if (result) {
      if (!_packInfoList.any((testPackInfo) => testPackInfo.packId == packInfo.packId)) {
        _packInfoList.add(packInfo);
      }
      _refreshChildSource();
      onChange.send();
    }

    return result;
  }
}