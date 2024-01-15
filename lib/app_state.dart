import 'package:decard_web/parse_connect.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/web_child.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_controller.dart';
import 'db.dart';
import 'db_mem.dart';

final appState = AppState();

class AppState {
  static final AppState _instance = AppState._();

  factory AppState() {
    return _instance;
  }

  AppState._();

  late SharedPreferences prefs;
  late ParseConnect serverConnect;
  late WebPackListManager packInfoManager;
  late DbSource dbSource;
  late CardController cardController;
  WebChildListManager? childManager;

  Future<void> initialization() async {
    prefs = await SharedPreferences.getInstance();

    serverConnect = ParseConnect(prefs);
    serverConnect.onLoggedInChange.subscribe((listener, data) {
      if (serverConnect.isLoggedIn) {
        childManager = WebChildListManager(serverConnect.user!.objectId!);
        return;
      }

      childManager = null;
    });
    await serverConnect.init();

    packInfoManager = WebPackListManager();
    dbSource        = DbSourceMem.create();
    cardController  = CardController(dbSource: dbSource);



  }
}