import 'card_sub_widgets.dart';

import 'package:flutter/material.dart';

import 'card_model.dart';
import 'common.dart';

class CardWidget extends StatefulWidget {
  final CardData card;

  const CardWidget({required this.card, Key? key}) : super(key: key);

  @override
  State<CardWidget> createState() => CardWidgetState();
}

class CardWidgetState extends State<CardWidget> {

  @override
  Widget build(BuildContext context) {
    final widgetList = <Widget>[];

    widgetList.add(
      CardQuestion(card: widget.card)
    );

    widgetList.add(
      AnswerInput(card: widget.card, onAnswerResult: (bool result) {  })
    );

    widgetList.add(
      Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            color: Colors.lightGreenAccent
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: _answerLine(TextConst.txtAnswerIs),
          )
      )
    );

    return Column(children: [
      Expanded( child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child:  Stack(
          children: [
            ListView(
              children: widgetList,
            )
          ],
        )
      )),

    ]);
  }

  Widget _answerLine(String label){
    final answerList = <Widget>[];
    answerList.add(Text('$label '));

    for (int i = 0; i < widget.card.body.answerList.length; i++){
      final answerValue = widget.card.body.answerList[i];
      answerList.add(ValueWidget(widget.card, answerValue));

      if ((widget.card.body.answerList.length > 1) && ((i + 1) < widget.card.body.answerList.length)){
        answerList.add(const Text("; "));
      }
    }

    return Row(children: answerList);
  }

}




