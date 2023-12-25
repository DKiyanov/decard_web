import 'package:decard_web/regulator.dart';
import 'package:simple_events/simple_events.dart' as event;
import 'card_sub_widgets.dart';
import 'db.dart';
import 'card_model.dart';
import 'package:flutter/material.dart';

typedef CardWidgetBuilder = Widget Function(CardData card, CardParam cardParam, CardViewController cardViewController);
typedef OnCardResult = Function(CardData card, CardParam cardParam, bool result, int tryCount, int solveTime, double earned);

class CardController {
  final DbSource dbSource;
  late Regulator regulator;

  CardController({required this.dbSource}) {
    regulator = Regulator(options: RegOptions(), cardSetList: [], difficultyList: []);
    regulator.fillDifficultyLevels();
  }

  CardData? _card;
  CardData? get card => _card;

  CardViewController? _cardViewController;
  CardViewController? get cardViewController => _cardViewController;

  CardParam? _cardParam;
  CardParam? get carCost => _cardParam;

  final onChange = event.SimpleEvent();
  final onAddEarn = event.SimpleEvent<double>();

  void setNoCard() {
    _card = null;
    _cardParam = null;
    _cardViewController = null;
    onChange.send();
  }

  /// Sets the current card data
  Future<void> setCard(int jsonFileID, int cardID, {int? bodyNum, CardSetBody setBody = CardSetBody.random}) async {
    _card = await CardData.create(dbSource, jsonFileID, cardID, bodyNum: bodyNum, setBody: setBody);

    _cardParam   = CardParam(regulator.difficultyList[0], 0);

    _cardViewController = CardViewController(_card!, _cardParam!, _onCardResult);

    onChange.send();
  }

  Future<void> setNextCard() async {
    Map<String, dynamic> row;

    final rows = await dbSource.tabCardHead.getAllRows();
    if (rows.isEmpty) return;

    if (_card == null) {
      row = rows[0];
    } else {
      final index = rows.indexWhere((cardHead) => cardHead[TabCardHead.kCardID] == _card!.head.cardID) + 1;
      if (index < rows.length) {
        row = rows[index];
      } else {
        row = rows[0];
      }
    }

    final jsonFileID = row[TabCardHead.kJsonFileID] as int;
    final cardID     = row[TabCardHead.kCardID] as int;

    setCard(jsonFileID, cardID);
  }

  Widget cardListenWidgetBuilder(CardWidgetBuilder builder) {
    return event.EventReceiverWidget(
      builder: (_) {
        if (_card == null) return Container();
        return builder.call(_card!, _cardParam!, _cardViewController!);
      },

      events: [onChange],
    );
  }

  Future<void> _onCardResult(CardData card, CardParam cardParam, bool result, int tryCount, int solveTime, double earned) async {
    onAddEarn.send(earned);
  }
}