import 'package:decard_web/app_state.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

import 'invite_key_present.dart';
import 'login_invite.dart';

class MenuPage extends StatefulWidget {
  final List<Widget>? actions;
  const MenuPage({required this.actions, Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Меню'),
        actions: widget.actions,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 50, right: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            button(
              title: 'Пригласить другого родителя',
              onPressed: () {
                Invite.navigatorPush(context, appState.serverConnect.user!.objectId!, LoginMode.slaveParent, const Duration(minutes: 30));
              }
            ),

            button(
              title: 'Пригласить ребёнка',
              onPressed: () {
                Invite.navigatorPush(context, appState.serverConnect.user!.objectId!, LoginMode.child, const Duration(minutes: 30));
              }
            ),

            button(
              title: 'Выйти',
              onPressed: () async {
                await appState.serverConnect.logout();
                if (!mounted) return;
                Routemaster.of(context).push('/');
              }
            ),

          ]
        ),
      ),
    );
  }

  Widget button({required String title, required VoidCallback onPressed}) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
              onPressed: onPressed,
              child: Text(title)
          ),
        ),
      ],
    );
  }
}
