import 'package:simple_events/simple_events.dart';
import 'db.dart';
import 'card_model.dart';

class CardController {
  final DbSource dbSource;

  CardController({
    required this.dbSource,
  });

  CardData? _card;
  CardData? get card => _card;

  final onChange = SimpleEvent();

  /// Sets the current card data
  Future<void> setCard(int jsonFileID, int cardID, {int? bodyNum, CardSetBody setBody = CardSetBody.random, int startTime = 0, bool forView = false}) async {
    _card = await CardData.create(dbSource, jsonFileID, cardID, bodyNum: bodyNum, setBody: setBody);
    onChange.send();
  }
}