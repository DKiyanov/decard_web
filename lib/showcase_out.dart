import 'package:decard_web/app_state.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'common.dart';
import 'pack_list.dart';

class ShowcaseOut extends StatelessWidget {
  const ShowcaseOut({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WebPackList(packInfoManager: appState.packInfoManager, actions: [
      ElevatedButton(
          onPressed: () {
            Routemaster.of(context).push('/login', queryParameters: {'redirectTo': '/'});
          },
          child: Text(TextConst.txtEntry)
      ),
    ]);
  }
}
