import 'package:flutter/material.dart';

class PackSourcesUI extends StatefulWidget {
  const PackSourcesUI({Key? key}) : super(key: key);

  @override
  State<PackSourcesUI> createState() => _PackSourcesUIState();
}

class _PackSourcesUIState extends State<PackSourcesUI> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Ресурсы'));
  }
}
