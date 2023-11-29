import 'package:flutter/material.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
//import 'package:webview_flutter_web/webview_flutter_web.dart';

class HtmlViewWidgetWeb extends StatefulWidget {
  String html;
  HtmlViewWidgetWeb({required this.html, super.key});

  @override
  State<HtmlViewWidgetWeb> createState() => _HtmlViewWidgetWebState();
}

class _HtmlViewWidgetWebState extends State<HtmlViewWidgetWeb> {
  final PlatformWebViewController _controller = PlatformWebViewController(
    const PlatformWebViewControllerCreationParams(),
  )..loadRequest(
    LoadRequestParams(
      uri: Uri.parse('https://flutter.dev'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PlatformWebViewWidget(
      PlatformWebViewWidgetCreationParams(controller: _controller),
    ).build(context);
  }
}