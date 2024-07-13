// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages

import 'dart:html' as html;

import 'package:flutter/foundation.dart';

void webDownloadFile(String url, String filename) {
  if (!kIsWeb) return;
  final anchorElement = html.AnchorElement(href: url);
  anchorElement.download = filename;
  anchorElement.click();
}

void webOpenNewTab(String path,) {
  if (!kIsWeb) return;
  html.window.open('${Uri.base.origin}$path', '');
}