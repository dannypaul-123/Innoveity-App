import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'export_permission_service.dart';
import 'push_notification_service.dart';

Future<String?> saveAndDownloadFile(
  List<int> bytes,
  String fileName, {
  BuildContext? context,
  bool skipPermissionCheck = false,
}) async {
  // 1. Ask necessary permission to user if not already granted
  if (!skipPermissionCheck) {
    final hasPermission = await ExportPermissionService.ensurePermission(
      context: context,
      fileName: fileName,
    );
    if (!hasPermission) {
      debugPrint('[FileSaver] Export cancelled: user denied storage permission.');
      return null;
    }
  }

  final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  final pushService = PushNotificationService();

  // 2. Display start progress notification in notification bar
  await pushService.showDownloadProgress(
    id: notificationId,
    fileName: fileName,
    progress: 20,
    statusMessage: 'Preparing $fileName (20%)...',
  );

  try {
    Directory? targetDir;

    if (Platform.isAndroid) {
      // Show progress update: 50%
      await pushService.showDownloadProgress(
        id: notificationId,
        fileName: fileName,
        progress: 50,
        statusMessage: 'Locating Android Downloads folder (50%)...',
      );

      // Standard public Android Download folder paths
      final candidatePaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/self/primary/Download',
        '/sdcard/Download',
      ];

      for (final p in candidatePaths) {
        try {
          final dir = Directory(p);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          if (dir.existsSync()) {
            targetDir = dir;
            break;
          }
        } catch (_) {}
      }

      // Fallback to path_provider external storage downloads directory
      if (targetDir == null) {
        try {
          final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (extDirs != null && extDirs.isNotEmpty) {
            targetDir = extDirs.first;
          }
        } catch (_) {}
      }

      // General external storage directory fallback
      if (targetDir == null) {
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) targetDir = extDir;
        } catch (_) {}
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloads = Directory('$userProfile\\Downloads');
        if (downloads.existsSync()) {
          targetDir = downloads;
        }
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

    // 3. Show progress update: 80% (Writing file)
    await pushService.showDownloadProgress(
      id: notificationId,
      fileName: fileName,
      progress: 80,
      statusMessage: 'Saving to Downloads folder (80%)...',
    );

    final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);

    // 4. Complete notification: 100% Download Complete
    await pushService.showDownloadComplete(
      id: notificationId,
      fileName: fileName,
      filePath: file.path,
    );

    return file.path;
  } catch (e) {
    debugPrint('[FileSaver] Error writing file to Downloads folder: $e');
    try {
      final file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);

      await pushService.showDownloadComplete(
        id: notificationId,
        fileName: fileName,
        filePath: file.path,
      );

      return file.path;
    } catch (fallbackError) {
      await pushService.showDownloadFailed(
        id: notificationId,
        fileName: fileName,
        error: fallbackError.toString(),
      );
      return null;
    }
  }
}
