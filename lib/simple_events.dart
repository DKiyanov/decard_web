library simple_events;

import 'package:flutter/material.dart';

typedef EventCallback<T> = void Function(Listener<T> listener, T? data);

class Listener<T> {
  final EventBase event;
  final EventCallback<T> callback;
  final Object? id;

  Listener(this.event, this.callback, [this.id]);

  void dispose(){
    event._removeListener(this);
  }
}

class EventBase<T> {
  final _listenerList = <Listener<T>>[];

  Listener<T> subscribe(EventCallback<T> callback, [Object? id]){
    final listener = Listener<T>(this, callback, id);
//    print('add ${listener.id}');
    _listenerList.add(listener);
    return listener;
  }

  void _removeListener(Listener listener) {
//    print('del ${listener.id}');
    _listenerList.remove(listener);
  }

  void _send([T? data]){
    for (var listener in _listenerList) {
      listener.callback(listener, data);
    }
  }

  void _sendFor(List<Object> ids, [T? data]){
    for (var listener in _listenerList) {
      if (ids.contains(listener.id)) {
        listener.callback(listener, data);
      }
    }
  }
}

typedef OnEventCallback = bool Function(Listener listener, Object? data);

class EventReceiverWidget<T> extends StatefulWidget {
  final WidgetBuilder builder;
  final List<EventBase<T>> events;
  final OnEventCallback? onEventCallback;
  final Object? id;

  const EventReceiverWidget({required this.builder, required this.events, this.id, this.onEventCallback, Key? key}) : super(key: key);

  @override
  State<EventReceiverWidget> createState() => _EventReceiverWidgetState();
}

class _EventReceiverWidgetState<T> extends State<EventReceiverWidget<T>> {
  final listenerList = <Listener>[];

  @override
  void initState() {
    super.initState();

    for (var event in widget.events) {
      listenerList.add( event.subscribe(onListen, widget.id) );
    }
  }

  @override
  void dispose() {
    for (var listener in listenerList) {
      listener.dispose();
    }

    super.dispose();
  }

  void onListen(Listener listener, T? data) {
    if (widget.onEventCallback != null) {
      if (!widget.onEventCallback!(listener, data)) return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

class SimpleEvent<T> extends EventBase<T> {
  void send([T? data]){
    _send(data);
  }

  void sendFor(List<Object> ids, [T? data]){
    _sendFor(ids, data);
  }
}

/// Is for posting an Event without access to send and sendFor
/// final _foo = PrivateEvent()
/// EventBase get fooEvent => _foo.event;
class PrivateEvent<T> {
  final event = EventBase<T>();

  void send([T? data]){
    event._send(data);
  }

  void sendFor(List<Object> ids, [T? data]){
    event._sendFor(ids, data);
  }

  void clear(){
    event._listenerList.clear();
  }
}