import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innoveity_app/services/export_permission_service.dart';
import 'package:innoveity_app/services/push_notification_service.dart';
import 'package:innoveity_app/services/file_saver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await ExportPermissionService.resetPermission();
  });

  group('ExportPermissionService Unit Tests', () {
    test('Initial permission state is false', () async {
      final granted = await ExportPermissionService.hasGrantedPermission();
      expect(granted, isFalse);
    });

    test('setPermission sets and persists permission state', () async {
      await ExportPermissionService.setPermission(true);
      expect(await ExportPermissionService.hasGrantedPermission(), isTrue);

      await ExportPermissionService.setPermission(false);
      expect(await ExportPermissionService.hasGrantedPermission(), isFalse);
    });

    test('resetPermission clears permission from SharedPreferences', () async {
      await ExportPermissionService.setPermission(true);
      expect(await ExportPermissionService.hasGrantedPermission(), isTrue);

      await ExportPermissionService.resetPermission();
      expect(await ExportPermissionService.hasGrantedPermission(), isFalse);
    });

    test('ensurePermission returns true immediately if already granted', () async {
      await ExportPermissionService.setPermission(true);
      final allowed = await ExportPermissionService.ensurePermission(
        fileName: 'test_report.csv',
      );
      expect(allowed, isTrue);
    });
  });

  group('Export Permission Dialog Widget Tests', () {
    testWidgets('Displays permission dialog with Downloads folder and Notification details', (tester) async {
      bool? permissionResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    permissionResult = await ExportPermissionService.ensurePermission(
                      context: context,
                      fileName: 'employee_attendance.xlsx',
                      fileType: 'Excel',
                    );
                  },
                  child: const Text('Export'),
                );
              },
            ),
          ),
        ),
      );

      // Tap Export button to trigger permission dialog
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Verify Dialog Title and content
      expect(find.text('Allow Storage & Download?'), findsOneWidget);
      expect(find.textContaining('employee_attendance.xlsx'), findsOneWidget);
      expect(find.text('Android Downloads Folder'), findsOneWidget);
      expect(find.textContaining('/storage/emulated/0/Download'), findsOneWidget);
      expect(find.text('Notification Bar Progress'), findsOneWidget);
      expect(find.textContaining('notification bar'), findsOneWidget);
      expect(find.text('Always allow exports to Downloads folder'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);
      expect(find.text('Allow & Download'), findsOneWidget);

      // Tap Allow & Download
      await tester.tap(find.text('Allow & Download'));
      await tester.pumpAndSettle();

      // Dialog closed and permission granted
      expect(permissionResult, isTrue);
      expect(await ExportPermissionService.hasGrantedPermission(), isTrue);
    });

    testWidgets('Tapping Deny cancels export without persisting permission', (tester) async {
      bool? permissionResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    permissionResult = await ExportPermissionService.ensurePermission(
                      context: context,
                      fileName: 'leaves.csv',
                      fileType: 'CSV',
                    );
                  },
                  child: const Text('Export'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Tap Deny
      await tester.tap(find.text('Deny'));
      await tester.pumpAndSettle();

      expect(permissionResult, isFalse);
      expect(await ExportPermissionService.hasGrantedPermission(), isFalse);
    });
  });

  group('PushNotificationService Download Progress Notifications', () {
    test('showDownloadProgress runs safely without uncaught exceptions', () async {
      final pushService = PushNotificationService();
      await pushService.showDownloadProgress(
        id: 101,
        fileName: 'attendance_report.xlsx',
        progress: 45,
        statusMessage: 'Saving to Downloads folder... (45%)',
      );
    });

    test('showDownloadComplete runs safely without uncaught exceptions', () async {
      final pushService = PushNotificationService();
      await pushService.showDownloadComplete(
        id: 101,
        fileName: 'attendance_report.xlsx',
        filePath: '/storage/emulated/0/Download/attendance_report.xlsx',
      );
    });

    test('showDownloadFailed runs safely without uncaught exceptions', () async {
      final pushService = PushNotificationService();
      await pushService.showDownloadFailed(
        id: 101,
        fileName: 'attendance_report.xlsx',
        error: 'Permission denied',
      );
    });
  });

  group('saveAndDownloadFile File Operations', () {
    test('Saves file with valid bytes and returns valid path', () async {
      await ExportPermissionService.setPermission(true);

      const csvContent = 'ID,Name,Status\n1,Daniel Paul,Present\n2,Abishek,Present\n';
      final bytes = csvContent.codeUnits;
      final fileName = 'test_attendance_${DateTime.now().millisecondsSinceEpoch}.csv';

      final savedPath = await saveAndDownloadFile(bytes, fileName);
      expect(savedPath, isNotNull);

      final file = File(savedPath!);
      expect(file.existsSync(), isTrue);

      final readContent = await file.readAsString();
      expect(readContent, equals(csvContent));

      // Clean up test artifact
      try {
        await file.delete();
      } catch (_) {}
    });

    test('Aborts saving and returns null if permission is denied', () async {
      await ExportPermissionService.setPermission(false);

      const csvContent = 'ID,Name,Status\n1,Daniel Paul,Present\n';
      final bytes = csvContent.codeUnits;
      final fileName = 'unauthorized_export.csv';

      // No context provided and permission explicitly false
      final savedPath = await saveAndDownloadFile(bytes, fileName);
      expect(savedPath, isNull);
    });
  });
}
