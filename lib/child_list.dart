import 'package:decard_web/dk_expansion_tile.dart';
import 'package:decard_web/web_child.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'common.dart';
import 'package:simple_events/simple_events.dart' as event;

class ChildList extends StatefulWidget {
  final WebChildListManager childManager;
  final List<Widget>? actions;
  const ChildList({required this.childManager, this.actions, Key? key}) : super(key: key);

  @override
  State<ChildList> createState() => _ChildListState();
}

class _ChildListState extends State<ChildList> {
  bool _isStarting = true;
  event.Listener? _childManagerListener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    if (widget.childManager.childList.isEmpty) {
      await widget.childManager.refreshChildList();
    }

    _childManagerListener = widget.childManager.onChange.subscribe((listener, data) {
      setState(() {});
    });

    setState(() {
      _isStarting = false;
    });
  }

  @override
  void dispose() {
    _childManagerListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtLoading),
          actions: widget.actions,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtChildList ),
        actions: widget.actions,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return ListView(
      children: widget.childManager.childList.map((child) {
        return DkExpansionTile(
          title: Row(
            children: [
              Expanded(child: Text('${child.childName} ')),
              InkWell(
                  child: const Icon(Icons.multiline_chart),
                  onTap: () {
                    Routemaster.of(context).push('/child_stat', queryParameters: {'id' : child.childID});
                  }
              ),
              InkWell(
                child: const Icon(Icons.tune),
                onTap: () {
                  Routemaster.of(context).push('/child_tune', queryParameters: {'id' : child.childID});
                }
              ),
            ],
          ),
          children: widget.childManager.deviceList.where((device) => device.childID == child.childID).map((device) => DkExpansionTile(
            title: Text(device.deviceName),
            children: device.packInfoList.map((packInfo) => packInfo.getListTile(context,
                trailing: InkWell(
                  child: const Icon(Icons.tune),
                  onTap: () {
                    Routemaster.of(context).push('/child_pack_tune', queryParameters: {'id' : child.childID, 'packId' : '${packInfo.packId}'});
                  },
                )
            )).toList(),
          )).toList()
        );
      }).toList(),
    );
  }
}
