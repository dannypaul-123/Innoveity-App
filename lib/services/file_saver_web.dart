// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/widgets.dart';

Future<String?> saveAndDownloadFile(
  List<int> bytes,
  String fileName, {
  BuildContext? context,
  bool skipPermissionCheck = false,
}) async {
  final blob = html.Blob(
    [bytes],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return 'Browser Downloads ($fileName)';
}
