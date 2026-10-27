import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> saveAndDownloadFile(List<int> bytes, String fileName) async {
  try {
    Directory? targetDir;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloads = Directory('$userProfile\\Downloads');
        if (downloads.existsSync()) {
          targetDir = downloads;
        }
      }
    } else if (Platform.isAndroid) {
      // Check standard public Android Download folder first
      final androidDownloads = Directory('/storage/emulated/0/Download');
      if (androidDownloads.existsSync()) {
        targetDir = androidDownloads;
      } else {
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) targetDir = extDir;
        } catch (_) {}
      }
    } else if (Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final downloads = Directory('$home/Downloads');
        if (downloads.existsSync()) {
          targetDir = downloads;
        }
      }
    }

    if (targetDir == null) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        targetDir = docDir;
      } catch (_) {
        targetDir = Directory.current;
      }
    }

    final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (e) {
    try {
      final file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
