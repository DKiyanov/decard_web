import 'package:decard_web/parse_connect.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'common.dart';

Future<String> loginWithGoogle(ParseConnect connect) async {
  final googleSignIn = GoogleSignIn( scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'] );

  final account = await googleSignIn.signIn();
  if (account == null) {
    return TextConst.errFailedLogin;
  }

  final authentication = await account.authentication;
  if (authentication.accessToken == null || googleSignIn.currentUser == null || authentication.idToken == null) {
    return TextConst.errFailedLogin;
  }

  final authData = google(authentication.accessToken!, googleSignIn.currentUser!.id, authentication.idToken!);

  return await connect.loginWith('google', authData);
}