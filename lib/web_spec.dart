import 'dart:html' as html;

void webDownloadFile(String url, String filename) {
  final anchorElement = html.AnchorElement(href: url);
  anchorElement.download = filename;
  anchorElement.click();
}

webOpenNewTab(String path,) {
  html.window.open('${Uri.base.origin}$path', '');
}