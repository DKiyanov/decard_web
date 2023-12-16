import 'package:flutter/material.dart';

class PackHeadUI extends StatefulWidget {
  const PackHeadUI({Key? key}) : super(key: key);

  @override
  State<PackHeadUI> createState() => _PackHeadUIState();
}

class _PackHeadUIState extends State<PackHeadUI> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Заголовок'));
  }
}
