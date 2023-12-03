import 'package:decard_web/app_state.dart';
import 'package:decard_web/card_sub_widgets.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/view_source.dart';
import 'package:flutter/material.dart';

import 'card_controller.dart';
import 'card_navigator.dart';
import 'card_widget.dart';
import 'common.dart';
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

  event.Listener? onAddEarnListener;

  double _earned = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    _jsonFileID = await loadPack(appState.dbSource, widget.packId);

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

    return Scaffold(
        appBar: AppBar(
            title: title(),
            actions: [
              widget.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
                if (card.body.clue.isEmpty) return Container();

                return HelpButton(
                  key           : ValueKey(card),
                  delayDuration : 10,
                  icon          : Icons.live_help,
                  color         : Colors.lime,
                  onTap         : () {
                    ViewContent.navigatorPush(
                      context, card, card.body.clue, TextConst.txtClue
                    );
                  },
                );
              }),

              widget.cardController.cardListenWidgetBuilder((card, cardParam, cardViewController) {
                if (card.head.help.isEmpty) return Container();

                return HelpButton(
                  key           : ValueKey(card),
                  delayDuration : 10,
                  icon          : Icons.help,
                  color         : Colors.white,
                  onTap         : () {
                    ViewContent.navigatorPush(
                      context, card, card.head.help, TextConst.txtHelp
                    );
                  },
                );
              }),

              InkWell(
                  onTap: (){
                    final card = widget.cardController.card;
                    if (card == null) return;
                    packInfoDisplay(context, card.pacInfo);
                  },
                  child: const Icon(Icons.info_outline)
              ),
            ]
        ),
        body: _body()
    );
  }

  Widget _body() {
    return Column(children: [
      CardNavigator(
        key: ValueKey(widget.packId),
        cardController: widget.cardController,
        jsonFileID: _jsonFileID,
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
        cardParam   : cardParam,
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
