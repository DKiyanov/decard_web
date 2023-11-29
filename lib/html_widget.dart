import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HtmlViewWidget extends StatefulWidget {
  final String html;
  final String filesDir;
  const HtmlViewWidget({required this.html, required this.filesDir, Key? key}) : super(key: key);

  @override
  State<HtmlViewWidget> createState() => _HtmlViewWidgetState();
}

class _HtmlViewWidgetState extends State<HtmlViewWidget> {
  double htmlWidgetHeight = 1;

  @override
  Widget build(BuildContext context) {
    //return Container(); // TODO нужно подобрать другой виджет для web версии

    // for correct operation, the html must contain the line:
    // <meta name="viewport" content="width=device-width, initial-scale=1.0">

    const imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Female_Irish_mountain_hare.jpg/800px-Female_Irish_mountain_hare.jpg';
    //const imageUrl = 'http://192.168.0.202:1337/parse/files/dk_parental_control/Female_Irish_mountain_hare.jpg';
    const htmlStr ='''
<!DOCTYPE html>
<html>
<head>
	<title>MyTitle</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
	<div>
		<p>html Hello World! ImHere</p>
		<img src="$imageUrl" alt="corn" width="100%">
		<p>end of html</p>
	</div>
</body>
</html>    
    ''';

    return SizedBox(
      height: htmlWidgetHeight,

      child: InAppWebView(
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            disableHorizontalScroll: true,
            disableVerticalScroll: true,
            // allowFileAccessFromFileURLs: true,
            // allowUniversalAccessFromFileURLs: true,
          ),
          // android: AndroidInAppWebViewOptions(
          //   domStorageEnabled: true,
          //   loadsImagesAutomatically: true,
          //   mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          // )
        ),

        onLoadStop: (InAppWebViewController controller, Uri? url) async {
          final contentHeight = await controller.getContentHeight();
          if (contentHeight == null) return;
          htmlWidgetHeight = contentHeight.toDouble();
          setState(() {});
        },

        initialData: InAppWebViewInitialData(
          data: htmlStr, // widget.html,
          baseUrl: Uri.parse("http://192.168.0.202:1337/parse/files/dk_parental_control/"), // Uri(scheme: 'file', path: widget.filesDir)
        ),
      ),
    );
  }
}
