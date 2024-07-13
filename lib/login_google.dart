import 'package:decard_web/parse_connect.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'common.dart';

Future<String> loginWithGoogle(ParseConnect connect) async {
  final googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  final account = await googleSignIn.signIn();
  if (account == null) {
    return TextConst.errFailedLogin;
  }

  final authentication = await account.authentication;
  if ((authentication.accessToken == null && authentication.idToken == null) || googleSignIn.currentUser == null ) {
    return TextConst.errFailedLogin;
  }

  final authData = _googleAuthData(authentication.accessToken, googleSignIn.currentUser!.id, authentication.idToken);

  return await connect.loginWith('google', authData, account.email);
}

Map<String, dynamic> _googleAuthData(String? token, String id, String? idToken) {
  return <String, dynamic>{
    if (token != null ) 'access_token': token,
    'id': id,
    if (idToken != null ) 'id_token': idToken,
  };
}
