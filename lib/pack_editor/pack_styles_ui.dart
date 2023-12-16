import 'package:flutter/material.dart';

class PackStylesUI extends StatefulWidget {
  const PackStylesUI({Key? key}) : super(key: key);

  @override
  State<PackStylesUI> createState() => _PackStylesUIState();
}

class _PackStylesUIState extends State<PackStylesUI> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Стили'));
  }
}
