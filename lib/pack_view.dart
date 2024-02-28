import 'package:collection/collection.dart';
import 'package:decard_web/app_state.dart';
import 'package:decard_web/card_sub_widgets.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/view_source.dart';
import 'package:flutter/material.dart';

import 'card_controller.dart';
import 'card_navigator.dart';
import 'card_widget.dart';
import 'common.dart';
import 'common_func.dart';
import 'pack_info_widget.dart';
import 'package:simple_events/simple_events.dart' as event;

class PackView extends StatefulWidget {
  final CardController cardController;
  final int packId;
  final bool onlyThatFile;
  const PackView({required this.cardController, required this.packId, this.onlyThatFile = false, Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    _jsonFileID = await loadWebPack(appState.dbSource, widget.packId);

    _cardNavigatorData = CardNavigatorData(appState.dbSource);
    await _cardNavigatorData.setData();

    final card = _cardNavigatorData.cardList.firstWhereOrNull((card) => card.jsonFileID == _jsonFileID);

    if (card != null) {
      widget.cardController.setCard(_jsonFileID!, card.cardID, bodyNum: 0);
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
                    onPressed: () => Navigator.pop(context),
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
                widget.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
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

                widget.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
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
                        final card = widget.cardController.card;
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

    return Row(
      children: [
        _tree(treeWidth),
        Expanded(child: _main())
      ]
    );
  }

  Widget _tree([double? width]) {
    return Container(
      width: width,
      color: _drawerPanelColor,
      child: CardNavigatorTree(
        cardController: widget.cardController,
        cardNavigatorData: _cardNavigatorData,
        itemTextColor: Colors.black,
        selItemTextColor: Colors.yellowAccent,
        bodyButtonColor: Colors.orangeAccent,
      ),
    );
  }

  Widget _main() {
    return Column(children: [
      CardNavigator(
        key: ValueKey(widget.packId),
        cardController: widget.cardController,
        cardNavigatorData: _cardNavigatorData,
      ),

      Expanded(
        child: _cardWidget()
      ),
    ]);
  }

  Widget _cardWidget() {
    return widget.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
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
                  onPressed: ()=> widget.cardController.setNextCard(),
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

      events: [widget.cardController.onAddEarn],

      onEventCallback: (listener, value) {
        final addEarned = value as double;
        _earned += addEarned;
        return true;
      },
    );
  }
}
