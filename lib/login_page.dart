import 'app_state.dart';
import 'page_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

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
    return PageScaffold(
      title: 'Log in',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: (){
                    Routemaster.of(context).push('login_email');
                  },
                  child: Text('Email + пароль')
              ),
              ElevatedButton(
                  onPressed: (){
                    appState.serverConnect.loginWithGoogle();
                  },
                  child: Text('Google')
              ),
              ElevatedButton(
                  onPressed: (){
                    Routemaster.of(context).push('login_invite');
                  },
                  child: Text('По приглашению')
              ),
            ],
          ),
        ),
      ),
    );
  }
}
