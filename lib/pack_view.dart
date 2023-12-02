import 'package:decard_web/app_state.dart';
import 'package:decard_web/card_model.dart';
import 'package:decard_web/parse_pack_info.dart';
import 'package:decard_web/regulator.dart';
import 'package:flutter/material.dart';
import 'package:simple_events/simple_events.dart';

import 'card_controller.dart';
import 'card_navigator.dart';
import 'card_sub_widgets.dart';
import 'card_widget.dart';
import 'common.dart';
import 'pack_info_widget.dart';

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
  late Regulator _regulator;
  late int? _jsonFileID;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    _jsonFileID = await loadPack(appState.dbSource, widget.packId);

    _regulator = Regulator(options: RegOptions(), cardSetList: [], difficultyList: []);
    _regulator.fillDifficultyLevels();

    setState(() {
      _isStarting = false;
    });
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
            title: Text(TextConst.txtAppTitle),
            actions: [
              IconButton(
                  onPressed: (){
                    final card = widget.cardController.card;
                    if (card == null) return;
                    packInfoDisplay(context, card.pacInfo);
                  },
                  icon: const Icon(Icons.info_outline)
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
    return EventReceiverWidget(
      builder: (_) {
        if (widget.cardController.card == null) return Container();

        final controller = CardProcessController();
        final cardCost   = CardCost(_regulator.difficultyList[0], 0);

        return CardWidget(
          key        : ValueKey(widget.cardController.card),
          card       : widget.cardController.card!,
          cardCost   : cardCost,
          controller : controller,
        );
      },
      events: [widget.cardController.onChange],
    );
  }
}
