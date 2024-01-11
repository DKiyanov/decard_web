import 'regulator.dart';
import 'db.dart';

final dbAddInitialized = _init();

bool _init() {
  Regulator.applySetItemToDB = applySetItemToDB;
  return true;
}

Future<void> applySetItemToDB(DbSource dbSource, RegCardSet set, int setIndex) async {

}