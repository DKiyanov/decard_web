import 'dart:convert';

import 'package:flutter/material.dart';
import 'audio_widget.dart';
import 'dart:io';

enum UrlType {
  httpUrl,
  localPath
}

UrlType getUrlType(String url) {
  final prefix = url.split('://').first.toLowerCase();
  if (["http", "https"].contains(prefix)) return UrlType.httpUrl;
  return UrlType.localPath;
}

Widget audioPanelFromUrl(String fileUrl, key){
  final urlType = getUrlType(fileUrl);

  if ( urlType == UrlType.httpUrl ) {
    return AudioPanelWidget(
      key     : ValueKey(key),
      httpUrl : fileUrl
    );
  }

  if ( urlType == UrlType.localPath ) {
    final audioFile = File(fileUrl);
    if (audioFile.existsSync()) {
      return AudioPanelWidget(
        key:  ValueKey(key),
        localFilePath : fileUrl
      );
    }
  }

  return Container();
}

Widget imageFromUrl(String fileUrl){
  final urlType = getUrlType(fileUrl);

  if ( urlType == UrlType.httpUrl ) {
    return Image.network(fileUrl);
  }

  if ( urlType == UrlType.localPath ) {
    final imgFile = File(fileUrl);
    if (imgFile.existsSync()) {
      return Image.file(imgFile);
    }
  }

  return Container();
}

Future<String?> getTextFromUrl(String fileUrl) async {
  final urlType = getUrlType(fileUrl);

  if ( urlType == UrlType.httpUrl ) {
    var client = HttpClient();
    try {
      final request  = await client.getUrl(Uri.parse(fileUrl));
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  if ( urlType == UrlType.localPath ) {
    final textFile = File(fileUrl);
    if (textFile.existsSync()) {
      return await textFile.readAsString();
    }
  }

  return null;
}

