import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'db_mem.dart';
import 'regulator.dart';
import 'card_controller.dart';
import 'db.dart';
import 'parse_class_info.dart';
import 'package:simple_events/simple_events.dart' as event;

class WebChild {
  final String childID;
  final String name;
  final String deviceName;

  final String sourcePath;

  late DbSource dbSource;
  late CardController cardController;

  Regulator? _regulator;
  Regulator get regulator => _regulator!;

  final packInfoList = <WebPackInfo>[];

  WebChild(this.childID, this.name, this.deviceName, this.sourcePath, String? regulatorJson) {
    dbSource       = DbSourceMem.create();
    cardController = CardController(dbSource: dbSource);
    if (regulatorJson != null) {
      _regulator = Regulator.fromMap(jsonDecode(regulatorJson));
    }
  }

  Future<void> regulatorChange(Map<String, dynamic> json) async {
    _regulator = Regulator.fromMap(json);
  }
}

class WebChildListManager {
  final String userID;

  WebChildListManager(this.userID);

  final webChildList = <WebChild>[];
  final _packInfoList = <WebPackInfo>[];

  final onChange = event.SimpleEvent();
  bool _changed = false;

  Future<void> refreshChildList() async {
    final queryChild =  QueryBuilder<ParseObject>(ParseObject(ParseChild.className));
    queryChild.whereEqualTo(ParseChild.userID, userID);
    final childList = await queryChild.find();

    final queryDevice =  QueryBuilder<ParseObject>(ParseObject(ParseDevice.className));
    queryDevice.whereEqualTo(ParseDevice.userID, userID);
    final deviceList = await queryDevice.find();

    final queryRegulator = QueryBuilder<ParseObject>(ParseObject(ParseWebChildSource.className));
    queryRegulator.whereEqualTo(ParseWebChildSource.userID, userID);
    queryRegulator.whereEqualTo(ParseWebChildSource.sourceType, ParseWebChildSource.sourceTypeRegulator);
    queryRegulator.keysToReturn([ParseWebChildSource.path, ParseWebChildSource.textContent]);
    final regulatorList = await queryRegulator.find();

    final localWebChildList = <WebChild>[];
    localWebChildList.addAll(webChildList);

    for (var device in deviceList) {
      final deviceName    = device.get<String>(ParseDevice.name)!;
      final deviceChildID = device.get<String>(ParseDevice.childID)!;
      final child         = childList.firstWhere((child) => child.objectId == deviceChildID);
      final childName     = child.get<String>(ParseChild.name)!;

      final sourcePath = '$childName/$deviceName';

      var webChild = webChildList.firstWhereOrNull((webChild) => webChild.sourcePath == sourcePath);
      if (webChild == null) {
        String? regulatorJson;
        final regulator = regulatorList.firstWhereOrNull((regulator) => regulator.get<String>(ParseWebChildSource.path) == sourcePath);
        if (regulator != null) {
          regulatorJson = regulator.get<String>(ParseWebChildSource.textContent)!;
        }

        webChild = WebChild(device.objectId!, childName, deviceName, sourcePath, regulatorJson);
        webChildList.add(webChild);
        _changed = true;
      } else {
        localWebChildList.remove(webChild);
      }
    }

    for (var webChild in localWebChildList) {
      webChildList.remove(webChild);
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

    for (var child in webChildList) {
      final localPackInfoList = <WebPackInfo>[];
      localPackInfoList.addAll(child.packInfoList);

      for (var source in sourceList) {
        final sourcePath = source.get<String>(ParseWebChildSource.path)!;
        if (sourcePath != child.sourcePath) continue;

        final packId = int.parse(source.get<String>(ParseWebChildSource.addInfo)!);
        final packInfo = _packInfoList.firstWhere((packInfo) => packInfo.packId == packId);

        if (child.packInfoList.contains(packInfo)) {
          localPackInfoList.remove(packInfo);
        } else {
          child.packInfoList.add(packInfo);
          _changed = true;
        }
      }

      for (var packInfo in localPackInfoList) {
        child.packInfoList.remove(packInfo);
        _changed = true;
      }
    }

  }

  Future<bool> addPack(WebPackInfo packInfo, WebChild child) async {
    final result = await addPackForChild(packInfo.packId, userID, child.sourcePath);

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