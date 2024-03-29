import 'package:decard_web/app_state.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

import 'child_list.dart';
import 'menu_page.dart';
import 'own_pack_list.dart';
import 'pack_list.dart';

class HomePage extends StatefulWidget {
  static const String tabShowcase    = 'showcase';
  static const String tabChildren    = 'children';
  static const String tabPossessions = 'possessions';
  static const String tabMenu        = 'menu';

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget? tabBar;

  @override
  Widget build(BuildContext context) {
    final tabState = TabPage.of(context);

    tabBar = SizedBox(
      width: 200,
      child: TabBar(
        indicatorWeight: 6,
        controller: tabState.controller,
        tabs: const [
          Tab(icon: Icon(Icons.shower)),
          Tab(icon: Icon(Icons.child_care)),
          Tab(icon: Icon(Icons.folder_special_outlined)),
          Tab(icon: Icon(Icons.menu)),
        ],
      ),
    );

    return TabBarView(
      controller: tabState.controller,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        PageStackNavigator(stack: tabState.stacks[0]),
        PageStackNavigator(stack: tabState.stacks[1]),
        PageStackNavigator(stack: tabState.stacks[2]),
        PageStackNavigator(stack: tabState.stacks[3]),
      ],
    );
  }
}

class HomePageTabView extends StatelessWidget {
  final String tabKey;

  const HomePageTabView({
    Key? key,
    required this.tabKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homePageState = context.findAncestorStateOfType<_HomePageState>();
    if (homePageState?.tabBar == null) return Container();

    if (tabKey == HomePage.tabShowcase) {
      return WebPackList(actions: [homePageState!.tabBar!], packInfoManager: appState.packInfoManager);
    }
    if (tabKey == HomePage.tabChildren) {
      return ChildList(childManager: appState.childManager!, actions: [homePageState!.tabBar!]);
    }
    if (tabKey == HomePage.tabPossessions) {
      return OwnPackList(packInfoManager: appState.packInfoManager, childManager: appState.childManager!, user: appState.serverConnect.user!, actions: [homePageState!.tabBar!]);
    }
    if (tabKey == HomePage.tabMenu) {
      return MenuPage(actions: [homePageState!.tabBar!]);
    }

    return Container();
  }
}
