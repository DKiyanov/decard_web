import 'app_state.dart';
import 'common.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

import 'login_email.dart';
import 'login_google.dart';
import 'login_invite.dart';

class LoginPage extends StatefulWidget {
  final String? redirectTo;

  const LoginPage({
    Key? key,
    this.redirectTo = '/',
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtEntry),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: (){
                    LoginEmail.navigate(
                      context: context,
                      connect: appState.serverConnect,
                      onLoginOk: (context) {
                        _loginOkRedirect();
                      }
                    );
                    //Routemaster.of(context).push('login_email');
                  },
                  child: const Text('Email + пароль')
              ),
              ElevatedButton(
                  onPressed: (){
                    loginWithGoogle(appState.serverConnect);
                  },
                  child: const Text('Google')
              ),
              ElevatedButton(
                  onPressed: () {
                    // LoginInvite.navigate(
                    //   context: context,
                    //   connect: appState.serverConnect,
                    //   loginMode: LoginMode.slaveParent,
                    //   getDeviceID: getDeviceID,
                    //   title: 'Другой родитель по приглашению',
                    //   onLoginOk: () {
                    //     _loginOkRedirect();
                    //   }
                    // );
                  },
                  child: const Text('По приглашению')
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loginOkRedirect() {
    Routemaster.of(context).push(widget.redirectTo!);
  }
}
