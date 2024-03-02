import 'package:decard_web/parse_class_info.dart';
import 'package:flutter/material.dart';
import 'package:decard_web/web_child.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'common_func.dart';
import 'db.dart';

class ChildTestResults {
  static const int _statDayCount = 10;

  final WebChild child;

  late DateTime firstDate;
  late DateTime lastDate;

  late int _firstTime;
  late int _lastTime;

  int _fromDate = 0;
  int _toDate = 0;

  DateTime get fromDate => intDateTimeToDateTime(_fromDate);
  DateTime get toDate   => intDateTimeToDateTime(_toDate);

  final resultList = <TestResult>[];

  ChildTestResults(this.child);

  Future<void> init() async {
    await updateBdFromServer();

    final now = DateTime.now();

    _firstTime = await child.statDB.tabTestResult.getFirstTime();
    if (_firstTime > 0) {
      firstDate = intDateTimeToDateTime(_firstTime);
    } else {
      firstDate = now;
    }

    _lastTime = await child.statDB.tabTestResult.getLastTime();
    if (_lastTime > 0) {
      lastDate = intDateTimeToDateTime(_lastTime);
    } else {
      lastDate = now;
    }

    final prev = now.add(const Duration(days: - _statDayCount));

    int fromDate = 0;
    int toDate = 0;

    fromDate = dateTimeToInt(DateTime(prev.year, prev.month, prev.day));
    toDate   = dateTimeToInt(now); // for end of current day

    await getData(fromDate, toDate);
  }

  Future<void> updateBdFromServer() async {
    final from = await child.statDB.tabTestResult.getLastTime();
    final to   = dateTimeToInt(DateTime.now());

    final testResultList = await _getTestsResultsFromServer(from, to);

    for (var testResult in testResultList) {
      child.statDB.tabTestResult.insertRow(testResult);
    }
  }

  Future<List<TestResult>> _getTestsResultsFromServer(int from, int to) async {
    final result = <TestResult>[];

    final query =  QueryBuilder<ParseObject>(ParseObject(ParseTestResult.className));
    query.whereEqualTo(ParseTestResult.userID                 , child.userID);
    query.whereEqualTo(ParseTestResult.childID                , child.childID);
    query.whereGreaterThanOrEqualsTo(ParseTestResult.dateTime , from);
    query.whereLessThanOrEqualTo(ParseTestResult.dateTime     , to);

    final resultList = await query.find();

    for (var row in resultList) {
      final json = row.toJson();
      final testResult = TestResult.fromMap(json);
      result.add(testResult);
    }

    return result;
  }

  Future<void> getData(int fromDate, int toDate) async {
    final time = toDate % 1000000;
    toDate = toDate - time;
    toDate += 240000;

    if (fromDate < _firstTime) fromDate = _firstTime;
    if (toDate   > _lastTime ) toDate   = _lastTime;

    if (_fromDate == fromDate && _toDate == toDate) return;

    _fromDate = fromDate;
    _toDate = toDate;

    resultList.clear();
    resultList.addAll( await child.statDB.tabTestResult.getForPeriod(_fromDate, _toDate) );
  }

  Future<bool> pickedFromDate (BuildContext context) async {
    final pickedDate = await showDatePicker(
      context     : context,
      initialDate : intDateTimeToDateTime(_fromDate),
      firstDate   : firstDate,
      lastDate    : lastDate,
    );

    if (pickedDate == null) return false;

    final fromDate = dateTimeToInt(pickedDate);
    await getData(fromDate, _toDate);
    return true;
  }

  Future<bool> pickedToDate (BuildContext context) async {
    final pickedDate = await showDatePicker(
      context     : context,
      initialDate : intDateTimeToDateTime(_toDate),
      firstDate   : firstDate,
      lastDate    : lastDate,
    );

    if (pickedDate == null) return false;

    final toDate = dateTimeToInt(pickedDate);
    await getData(_fromDate, toDate);
    return true;
  }
}