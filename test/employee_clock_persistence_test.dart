import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmployeeAttendanceRecord Model Tests', () {
    test('Serializes and deserializes correctly to/from JSON', () {
      final record = EmployeeAttendanceRecord(
        email: 'dp0345217@gmail.com',
        employeeId: 'EMP-001',
        employeeName: 'Daniel Paul',
        isClockedIn: true,
        date: '2026-10-27',
        clockInIso: '2026-10-27T09:30:00.000',
        clockInDisplay: '09:30 AM',
        clockOutIso: null,
        clockOutDisplay: null,
        clockedSeconds: 1800,
        distanceMeters: 42.0,
        userLat: 12.920466,
        userLng: 80.121639,
        statusText: 'Present (HQ Verified 42m)',
        workLocation: 'Office',
      );

      final json = record.toJson();
      final restored = EmployeeAttendanceRecord.fromJson(json);

      expect(restored.email, 'dp0345217@gmail.com');
      expect(restored.employeeId, 'EMP-001');
      expect(restored.employeeName, 'Daniel Paul');
      expect(restored.isClockedIn, isTrue);
      expect(restored.date, '2026-10-27');
      expect(restored.clockInDisplay, '09:30 AM');
      expect(restored.distanceMeters, 42.0);
      expect(restored.workLocation, 'Office');
    });

    test('Calculates currentElapsedSeconds from clockInIso dynamically', () {
      final now = DateTime.now();
      final fortyMinsAgo = now.subtract(const Duration(minutes: 40));

      final record = EmployeeAttendanceRecord(
        email: 'dp0345217@gmail.com',
        employeeId: 'EMP-001',
        employeeName: 'Daniel Paul',
        isClockedIn: true,
        date: AppState.todayDateStr(),
        clockInIso: fortyMinsAgo.toIso8601String(),
        clockInDisplay: '09:20 AM',
        clockedSeconds: 0,
      );

      final elapsed = record.currentElapsedSeconds;
      expect(elapsed, greaterThanOrEqualTo(2390));
      expect(record.formattedCurrentTimer.startsWith('00:4'), isTrue);
    });
  });

  group('Employee Clock In & Clock Out Persistence Across Logout Tests', () {
    late AppState appState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
    });

    test('Remembers employee clock in after logging out and logging back in', () async {
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.isClockedIn, isFalse);

      await appState.clockInWithGeofence(
        distanceMeters: 36.0,
        isRemoteExemption: false,
        userLat: 12.920466,
        userLng: 80.121639,
      );
      expect(appState.isClockedIn, isTrue);
      final originalClockInTime = appState.clockInTimeDisplay;
      expect(originalClockInTime.isNotEmpty, isTrue);

      appState.logout();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.isClockedIn, isFalse);

      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      expect(appState.isLoggedIn, isTrue);

      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, originalClockInTime);
      expect(appState.attendanceLogs.first.checkOut, 'Active Shift');
    });

    test('Remembers employee clock out after logging out and logging back in', () async {
      await appState.loginWithCredentials('antorajan501@gmail.com', '123456');
      expect(appState.isLoggedIn, isTrue);

      await appState.clockInWithGeofence(
        distanceMeters: 55.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isTrue);
      final recordedClockIn = appState.clockInTimeDisplay;

      final outResult = await appState.clockOutShift();
      expect(outResult['success'], isTrue);
      expect(appState.isClockedIn, isFalse);
      expect(appState.hasClockedOutToday, isTrue);
      final recordedClockOut = appState.clockOutTimeDisplay;
      expect(recordedClockOut, isNotNull);

      appState.logout();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.isClockedIn, isFalse);

      await appState.loginWithCredentials('antorajan501@gmail.com', '123456');
      expect(appState.isLoggedIn, isTrue);

      expect(appState.isClockedIn, isFalse);
      expect(appState.clockInTimeDisplay, recordedClockIn);
      expect(appState.clockOutTimeDisplay, recordedClockOut);
      expect(appState.hasClockedOutToday, isTrue);
      expect(appState.attendanceLogs.first.checkOut, recordedClockOut);
    });

    test('Maintains isolated independent attendance state for each employee across logouts', () async {
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      await appState.clockInWithGeofence(distanceMeters: 25.0, isRemoteExemption: false);
      expect(appState.isClockedIn, isTrue);
      final danielClockIn = appState.clockInTimeDisplay;
      appState.logout();

      await appState.loginWithCredentials('admin@enterprise-crm.com', 'Admin123!');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.isClockedIn, isFalse);

      final danielRecord = appState.getEmployeeAttendanceRecord('dp0345217@gmail.com');
      expect(danielRecord, isNotNull);
      expect(danielRecord!.isClockedIn, isTrue);
      expect(danielRecord.clockInDisplay, danielClockIn);

      appState.logout();
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, danielClockIn);
    });

    test('Loads persisted employee attendance across app restarts (cold boot)', () async {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final savedRecord = EmployeeAttendanceRecord(
        email: 'dp0345217@gmail.com',
        employeeId: 'EMP-001',
        employeeName: 'Daniel Paul',
        isClockedIn: true,
        date: AppState.todayDateStr(),
        clockInIso: oneHourAgo.toIso8601String(),
        clockInDisplay: '08:45 AM',
        clockedSeconds: 3600,
        distanceMeters: 38.0,
      );

      SharedPreferences.setMockInitialValues({
        'emp_attendance_dp0345217@gmail.com': jsonEncode(savedRecord.toJson()),
        'all_employees_attendance_registry_v1': jsonEncode({
          'dp0345217@gmail.com': savedRecord.toJson(),
        }),
      });

      final freshAppState = AppState();
      await freshAppState.loginWithCredentials('dp0345217@gmail.com', '123456');

      expect(freshAppState.isClockedIn, isTrue);
      expect(freshAppState.clockInTimeDisplay, '08:45 AM');
      expect(freshAppState.clockedSeconds, greaterThanOrEqualTo(3590));
    });

    test('Remembers clock in when logging out and logging in via employee ID (IN-1001)', () async {
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      expect(appState.isLoggedIn, isTrue);

      await appState.clockInWithGeofence(
        distanceMeters: 30.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isTrue);
      final clockTime = appState.clockInTimeDisplay;

      appState.logout();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.isClockedIn, isFalse);

      // Log in using Employee ID instead of email
      await appState.loginWithCredentials('IN-1001', '123456');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, clockTime);
      expect(appState.attendanceLogs.first.checkOut, 'Active Shift');
    });

    test('Remembers clock in across email aliases (dp0345217@gmail.com -> logout -> danielpaul@enterprise-crm.com)', () async {
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      await appState.clockInWithGeofence(distanceMeters: 45.0, isRemoteExemption: false);
      expect(appState.isClockedIn, isTrue);
      final originalClockIn = appState.clockInTimeDisplay;

      appState.logout();

      // Log in with work email alias
      await appState.loginWithCredentials('danielpaul@enterprise-crm.com', '123456');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, originalClockIn);
      expect(appState.attendanceLogs.first.checkOut, 'Active Shift');
    });

    test('Multiple successive logout and login cycles keep employee clock-in intact', () async {
      await appState.loginWithCredentials('antorajan501@gmail.com', '123456');
      await appState.clockInWithGeofence(distanceMeters: 28.0, isRemoteExemption: false);
      expect(appState.isClockedIn, isTrue);
      final recordedTime = appState.clockInTimeDisplay;

      // Cycle 1
      appState.logout();
      expect(appState.isClockedIn, isFalse);
      await appState.loginWithCredentials('antorajan501@gmail.com', '123456');
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, recordedTime);

      // Cycle 2
      appState.logout();
      expect(appState.isClockedIn, isFalse);
      await appState.loginWithCredentials('IN-9002', '123456');
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, recordedTime);

      // Cycle 3
      appState.logout();
      expect(appState.isClockedIn, isFalse);
      await appState.loginWithCredentials('antorajan501@gmail.com', '123456');
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, recordedTime);
      expect(appState.attendanceLogs.first.checkOut, 'Active Shift');
    });

    test('Preserves active local shift and logs during refreshApiData()', () async {
      await appState.loginWithCredentials('antorajan501@gmail.com', '123456');
      await appState.clockInWithGeofence(distanceMeters: 20.0, isRemoteExemption: false);
      expect(appState.isClockedIn, isTrue);
      final checkInTime = appState.clockInTimeDisplay;

      // Run refreshApiData
      await appState.refreshApiData();
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, checkInTime);
      expect(appState.attendanceLogs.first.checkOut, 'Active Shift');

      // Logout and log back in
      appState.logout();
      expect(appState.isClockedIn, isFalse);

      await appState.loginWithCredentials('antorajan501@gmail.com', '123456');
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, checkInTime);
      expect(appState.attendanceLogs.first.checkOut, 'Active Shift');
    });
  });
}
