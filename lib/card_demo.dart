import 'package:flutter/material.dart';
import 'package:simple_events/simple_events.dart';

import 'card_controller.dart';
import 'card_navigator.dart';
import 'card_widget.dart';
import 'common.dart';
import 'pack_info_widget.dart';

class DeCardDemo extends StatefulWidget {
  final CardController cardController;
  final String fileGuid;
  final bool onlyThatFile;

  const DeCardDemo({
    required this.cardController,
    this.fileGuid = '',
    this.onlyThatFile = false,
    Key? key
  }) : super(key: key);

  @override
  State<DeCardDemo> createState() => _DeCardDemoState();
}

class _DeCardDemoState extends State<DeCardDemo> {
  @override
  Widget build(BuildContext context) {

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
      CardNavigator(cardController: widget.cardController),
      Expanded(child: _cardWidget()),
    ]);
  }

  Widget _cardWidget() {
    return EventReceiverWidget(
      builder: (_) {
        if (widget.cardController.card == null) return Container();

        return CardWidget(
          card     : widget.cardController.card!,
        );
      },
      events: [widget.cardController.onChange],
    );
  }
}
