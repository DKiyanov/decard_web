import 'package:collection/collection.dart';
import 'package:decard_web/app_state.dart';
import 'package:decard_web/card_sub_widgets.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/view_source.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:routemaster/routemaster.dart';

import 'card_model.dart';
import 'card_navigator.dart';
import 'card_widget.dart';
import 'common.dart';
import 'common_func.dart';
import 'pack_info_widget.dart';
import 'simple_events.dart' as event;

class PackView extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, int packId, {bool onlyThatFile = true, String? cardKey} ) async {
    return Navigator.push(context, MaterialPageRoute( builder: (_) => PackView(packId: packId, onlyThatFile: onlyThatFile, cardKey: cardKey)));
  }

  final int packId;
  final bool onlyThatFile;
  final String? cardKey;
  const PackView({required this.packId, this.onlyThatFile = true, this.cardKey, Key? key}) : super(key: key);

  @override
  State<PackView> createState() => _PackViewState();
}

class _PackViewState extends State<PackView> {
  bool _isStarting = true;

  late int? _jsonFileID;

  late CardNavigatorData _cardNavigatorData;

  event.Listener? onAddEarnListener;

  double _earned = 0;

  static const Color _drawerPanelColor = Colors.lightBlueAccent;

  final GlobalKey<ScaffoldState> _keyScaffoldState = GlobalKey();

  late NavigatorMode _navigatorMode;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    _navigatorMode = widget.onlyThatFile? NavigatorMode.singlePack : NavigatorMode.multiPack;

    _jsonFileID = await loadWebPackEx(dbSource: appState.dbSource, packId: widget.packId);

    _cardNavigatorData = CardNavigatorData(appState.dbSource);
    await _cardNavigatorData.setData();

    CardHead? card;

    if (widget.cardKey != null) {
      card = _cardNavigatorData.cardList.firstWhereOrNull((card) => card.jsonFileID == _jsonFileID && card.cardKey == widget.cardKey);
    } else {
      card = _cardNavigatorData.cardList.firstWhereOrNull((card) => card.jsonFileID == _jsonFileID);
    }

    if (card != null) {
      appState.cardController.setCard(_jsonFileID!, card.cardID, bodyNum: 0);
    }

    setState(() {
      _isStarting = false;
    });
  }

  @override
  void dispose() {
    onAddEarnListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtLoading),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      var drawerPanelWidth = constraints.maxWidth / 4;
      if (drawerPanelWidth > 500) {
        drawerPanelWidth = 500;
      }

      Drawer? drawer;

      if (isMobile) {
        drawer = Drawer(
          child: Container(
            child: _tree(),
          ),
        );
      }

      return Scaffold(
          key: _keyScaffoldState,
          drawer: drawer,
          appBar: AppBar(
              leading: isMobile? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      //Navigator.pop(context);
                      Routemaster.of(context).pop();
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.account_tree_outlined),
                    onPressed: () => _keyScaffoldState.currentState!.openDrawer(),
                  ),
                ],
              ) : null,
              leadingWidth: 96,
              title: title(),
              actions: [
                appState.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
                  if (card.body.clue == null) return Container();

                  return HelpButton(
                    key           : ValueKey(card),
                    delayDuration : 10,
                    icon          : Icons.live_help,
                    color         : Colors.lime,
                    onTap         : () {
                      ViewContent.navigatorPush(
                          context, card, card.body.clue!, TextConst.txtClue
                      );
                    },
                  );
                }),

                appState.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
                  if (card.head.help == null) return Container();

                  return HelpButton(
                    key           : ValueKey(card),
                    delayDuration : 10,
                    icon          : Icons.help,
                    color         : Colors.white,
                    onTap         : () {
                      ViewContent.navigatorPush(
                          context, card, card.head.help!, TextConst.txtHelp
                      );
                    },
                  );
                }),

                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                      onTap: (){
                        final card = appState.cardController.card;
                        if (card == null) return;
                        packInfoDisplay(context, card.pacInfo);
                      },
                      child: const Icon(Icons.info_outline)
                  ),
                ),
              ]
          ),
          body: _body(isMobile, drawerPanelWidth)
      );
    });

  }

  Widget _body(bool isMobile, double? treeWidth) {
    if (isMobile) {
      return _main();
    }

    return Container(
      color: Colors.grey,

      child: MultiSplitView(
        axis: Axis.horizontal,
        initialAreas: [
          Area(weight: 0.25)
        ],
        children: [
          _tree(treeWidth),
          _main()
        ]
      ),
    );
  }

  Widget _tree([double? width]) {
    return Container(
      width: width,
      color: _drawerPanelColor,
      child: CardNavigatorTree(
        cardController: appState.cardController,
        cardNavigatorData: _cardNavigatorData,
        itemTextColor: Colors.black,
        selItemTextColor: Colors.yellowAccent,
        bodyButtonColor: Colors.orangeAccent,
        mode: _navigatorMode,
      ),
    );
  }

  Widget _main() {
    return Container(
      color: Colors.white,

      child: Column(children: [
        CardNavigator(
          key: ValueKey(widget.packId),
          cardController: appState.cardController,
          cardNavigatorData: _cardNavigatorData,
          mode: _navigatorMode,
        ),

        Expanded(
          child: _cardWidget()
        ),
      ]),
    );
  }

  Widget _cardWidget() {
    return appState.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
      return CardWidget(
        key        : ValueKey(card),
        card       : card,
        cardParam  : cardParam,
        controller : cardViewController,
        whenResultChild: Row(
          children: [
            Expanded(child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: ()=> appState.cardController.setNextCard(),
                  child: Text(TextConst.txtSetNextCard)
              ),
            )),
          ],
        ),
      );
    });
  }

  Widget title() {
    return event.EventReceiverWidget(
      builder: (_) {
        String earnedStr = '';
        if (_earned != 0) {
          earnedStr = 'заработано: ${getEarnedText(_earned)}';
        }
        return Text('${TextConst.txtAppTitle} $earnedStr');
      },

      events: [appState.cardController.onAddEarn],

      onEventCallback: (listener, value) {
        final addEarned = value as double;
        _earned += addEarned;
        return true;
      },
    );
  }
}
