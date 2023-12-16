import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class PackEditor extends StatelessWidget {
  static const String tabHead    = 'head';
  static const String tabStyles  = 'styles';
  static const String tabCards   = 'cards';
  static const String tabSources = 'sources';

  const PackEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tabState = TabPage.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Редактор пакета'),
      ),

      body: Column(
        children: [
          Container(
            color: const Color(0xff202f3f),
            height: 70,
            child: TabBar(
              indicatorWeight: 6,
              controller: tabState.controller,
              tabs: const [
                Tab(icon: Icon(Icons.child_care ), text: 'Заголовок'),
                Tab(icon: Icon(Icons.style      ), text: 'Стили'),
                Tab(icon: Icon(Icons.credit_card), text: 'Карточки'),
                Tab(icon: Icon(Icons.source     ), text: 'Ресурсы'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabState.controller,
              children: <Widget>[
                PageStackNavigator(stack: tabState.stacks[0]),
                PageStackNavigator(stack: tabState.stacks[1]),
                PageStackNavigator(stack: tabState.stacks[2]),
                PageStackNavigator(stack: tabState.stacks[3]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PackEditorTabView extends StatelessWidget {
  final String tabKey;

  const PackEditorTabView({
    Key? key,
    required this.tabKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tabKey == PackEditor.tabHead) {
      return Container(); //WebPackList();
    }
    if (tabKey == PackEditor.tabStyles) {
      return Container(); //const ChildList();
    }
    if (tabKey == PackEditor.tabCards) {
      return Container(); //const OwnPackList();
    }
    if (tabKey == PackEditor.tabSources) {
      return Container(); //const OwnPackList();
    }

    return Container();
  }
}
