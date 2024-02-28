import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  final List<Widget>? actions;
  const MenuPage({required this.actions, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Меню'),
        actions: actions,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {

            },
            child: const Text('Пригласить другого родителя')
          )
        ]
      ),
    );
  }
}
