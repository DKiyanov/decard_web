import 'package:decard_web/card_cost_panel.dart';

import 'card_sub_widgets.dart';

import 'package:flutter/material.dart';

import 'card_model.dart';
import 'common.dart';

class CardWidget extends StatefulWidget {
  final CardData card;
  final CardCost cardCost;
  final CardProcessController controller;
  final Widget? whenResultChild;

  const CardWidget({required this.card, required this.cardCost, required this.controller, this.whenResultChild, Key? key}) : super(key: key);

  @override
  State<CardWidget> createState() => CardWidgetState();
}

class CardWidgetState extends State<CardWidget> {
  late List<String> _resultValues;
  final _answerVariantList = [];

  @override
  Widget build(BuildContext context) {
    final widgetList = <Widget>[];

    widgetList.add(
      CardQuestion(card: widget.card)
    );

    if (widget.controller.result == null) {
      widgetList.add(
        AnswerInput(card: widget.card, controller: widget.controller, onAnswerResult: (bool result, List<String> values, List<String> answerVariantList) {
          setState(() {
            widget.controller.result = result;
            _resultValues = values;
            _answerVariantList.addAll(answerVariantList) ;
          });
        })
      );
    }

    if (widget.controller.result != null) {
      // ответ введён - показываем введённый/выбранный ответ
      if (_answerVariantList.isEmpty) {
        _answerVariantList.addAll(_resultValues);
      }

      for (var value in _answerVariantList) {
        if (_resultValues.contains(value)){
          widgetList.add(
              ElevatedButton(
                style: ElevatedButton.styleFrom(alignment: AnswerInput.getAnswerAlignment(widget.card)),
                child: ValueWidget(widget.card, value),
                onPressed: (){},
              )
          );
        }
      }
    }

    if (widget.controller.result != null && widget.controller.result!) {
      // введён правильный ответ
      widgetList.add(
          Container(
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  color: Colors.lightGreenAccent
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                    TextConst.txtRightAnswer,
                    textAlign: widget.card.style.answerVariantAlign
                ),
              )
          )
      );
    }

    if (widget.controller.result != null && !widget.controller.result!) {
      // введён НЕ правильный ответ
      widgetList.add(
          Container(
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  color: Colors.deepOrange
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                    TextConst.txtWrongAnswer,
                    textAlign: widget.card.style.answerVariantAlign
                ),
              )
          )
      );

      if (!widget.card.style.dontShowAnswer) {
        widgetList.add(
          RightAnswerLine(card: widget.card, label: TextConst.txtRightAnswerIs)
        );
      }
    }

    return Column(children: [
      CostPanel(cardCost: widget.cardCost, controller: widget.controller),

      Expanded( child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Stack(
          children: [
            ListView(
              children: widgetList,
            ),

            if (widget.card.style.answerVariantMultiSel && widget.controller.result == null) ...[
              Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: widget.controller.onMultiSelectAnswerOk,
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(17),
                        backgroundColor: Colors.green
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  )
              )
            ]


          ],
        )
      )),

      if (widget.controller.result != null && widget.whenResultChild != null) ...[
        widget.whenResultChild!
      ]
    ]);
  }

}




