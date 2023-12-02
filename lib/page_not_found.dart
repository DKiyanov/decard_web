import 'package:flutter/material.dart';

import 'common.dart';

class PageNotFound extends StatelessWidget {
  const PageNotFound({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtPageNotFound),
      ),
      body: Center(child: Text(TextConst.txtPageNotFound)),
    );
  }
}
