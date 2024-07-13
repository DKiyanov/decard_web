import 'web_spec_web.dart' if (dart.library.io) 'web_spec_io.dart' as web;

void webDownloadFile(String url, String filename) {
  web.webDownloadFile(url, filename);
}

void webOpenNewTab(String path,) {
  web.webOpenNewTab(path);
}