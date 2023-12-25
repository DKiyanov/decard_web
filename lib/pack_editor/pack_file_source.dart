import 'package:flutter/material.dart';

class PackFileSource extends StatefulWidget {
  final Map<String, String> fileUrlMap;

  const PackFileSource({required this.fileUrlMap, Key? key}) : super(key: key);

  @override
  State<PackFileSource> createState() => _PackFileSourceState();
}

class _PackFileSourceState extends State<PackFileSource> {
  final scrollbarController = ScrollController();

  @override
  void dispose() {
    scrollbarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollbarController,
      child: ListView(
        controller: scrollbarController,
        children: widget.fileUrlMap.entries.map((file) {
          return ListTile( title:  Text(file.key));
        }).toList(),
      ),
    );
  }
}
