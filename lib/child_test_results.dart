import 'package:flutter/material.dart';
import 'package:decard_web/web_child.dart';

import 'common.dart';
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
    final now = DateTime.now();

    //TODO remake it
    // _firstTime = await child.dbSource.tabTestResult.getFirstTime();
    // if (_firstTime > 0) {
    //   firstDate = intDateTimeToDateTime(_firstTime);
    // } else {
    //   firstDate = now;
    // }
    //
    // _lastTime = await child.dbSource.tabTestResult.getLastTime();
    // if (_lastTime > 0) {
    //   lastDate = intDateTimeToDateTime(_lastTime);
    // } else {
    //   lastDate = now;
    // }

    final prev = now.add(const Duration(days: - _statDayCount));

    int fromDate = 0;
    int toDate = 0;

    fromDate = dateTimeToInt(DateTime(prev.year, prev.month, prev.day));
    toDate   = dateTimeToInt(now); // for end of current day

    await getData(fromDate, toDate);
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
    //TODO remake it
    //resultList.addAll( await child.dbSource.tabTestResult.getForPeriod(_fromDate, _toDate) );
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