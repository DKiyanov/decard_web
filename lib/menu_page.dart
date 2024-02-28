import 'package:decard_web/app_state.dart';
import 'package:flutter/material.dart';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Invite.navigatorPush(context, appState.serverConnect.user!.objectId!, LoginMode.slaveParent, const Duration(minutes: 30));
            },
            child: const Text('Пригласить другого родителя')
          )
        ]
      ),
    );
  }
}
