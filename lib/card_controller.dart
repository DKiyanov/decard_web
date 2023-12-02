import 'package:decard_web/regulator.dart';
import 'package:simple_events/simple_events.dart';
import 'card_sub_widgets.dart';
import 'db.dart';
import 'card_model.dart';
import 'package:flutter/material.dart';

typedef CardWidgetBuilder = Widget Function(CardData card, CardCost cardCost, CardViewController cardViewController);

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

  CardCost? _cardCost;
  CardCost? get carCost => _cardCost;

  final onChange = SimpleEvent();

  /// Sets the current card data
  Future<void> setCard(int jsonFileID, int cardID, {int? bodyNum, CardSetBody setBody = CardSetBody.random, int startTime = 0, bool forView = false}) async {
    _card = await CardData.create(dbSource, jsonFileID, cardID, bodyNum: bodyNum, setBody: setBody);

    _cardViewController = CardViewController();
    _cardCost   = CardCost(regulator.difficultyList[0], 0);

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
    return EventReceiverWidget(
      builder: (_) {
        if (_card == null) return Container();
        return builder.call(_card!, _cardCost!, _cardViewController!);
      },

      events: [onChange],
    );
  }
}