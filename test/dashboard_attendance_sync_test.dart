import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/screens/attendance_portal_screen.dart';
import 'package:innoveity_app/screens/dashboard_screen.dart';
import 'package:innoveity_app/screens/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dashboard and Attendance Portal Clock Sync Unit & State Tests', () {
    test('Clock-in state and elapsed time are unified in AppState', () async {
      final appState = AppState();
      try {
        await appState.loginWithCredentials('dp0345217@gmail.com', '123456');

        expect(appState.isClockedIn, false);
        expect(appState.clockedSeconds, 0);

        // Perform geofenced clock in
        await appState.clockInWithGeofence(
          distanceMeters: 42.0,
          isRemoteExemption: false,
          userLat: 12.920466,
          userLng: 80.121639,
        );

        expect(appState.isClockedIn, true);
        expect(appState.lastClockInDistance, 42.0);
        expect(appState.lastWorkLocation, 'Office');
        expect(appState.clockInTimeDisplay, isNotEmpty);
        expect(appState.clockInTimeDisplay, isNot('Not Clocked In'));

        // Both Dashboard and Attendance tabs read from the exact same getters:
        final dashboardClockIn = appState.clockInTimeDisplay;
        final dashboardFormattedTime = appState.formattedClockTime;
        final dashboardShiftPercent = appState.shiftCompletionPercent;
        final dashboardTargetHours = appState.shiftTargetHours;

        expect(dashboardClockIn, isNotEmpty);
        expect(dashboardFormattedTime, '00:00:00');
        expect(dashboardShiftPercent, 0);
        expect(dashboardTargetHours, 7.0); // Daniel Paul is an INTERN

        // Perform clock out
        final outResult = await appState.clockOutShift();
        expect(outResult['success'], true);
        expect(appState.isClockedIn, false);
        expect(appState.hasClockedOutToday, true);
        expect(appState.clockOutTimeDisplay, isNotNull);
      } finally {
        appState.dispose();
      }
    });

    test('Shift target hours and cutoff hour dynamically adapt by role', () async {
      final internState = AppState();
      final staffState = AppState();
      try {
        await internState.loginWithCredentials('dp0345217@gmail.com', '123456'); // INTERN

        expect(internState.shiftTargetHours, 7.0);
        expect(internState.autoClockOutCutoffHour, 17);
        expect(internState.autoClockOutCutoffLabel, contains('5:00 PM'));

        await staffState.loginWithCredentials('antorajan501@gmail.com', '123456'); // EMPLOYEE

        expect(staffState.shiftTargetHours, 8.0);
        expect(staffState.autoClockOutCutoffHour, 18);
        expect(staffState.autoClockOutCutoffLabel, contains('6:00 PM'));
      } finally {
        internState.dispose();
        staffState.dispose();
      }
    });
  });

  group('Dashboard and Attendance Portal UI Synchronization Widget Tests', () {
    testWidgets('Dashboard and Attendance tab render synchronized clock states when offline',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
      try {
        await appState.loginWithCredentials('dp0345217@gmail.com', '123456');

        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationScreen(state: appState),
          ),
        );
        await tester.pump();

        // 1. Dashboard Tab (Tab 0) is visible initially
        expect(find.byType(DashboardScreen), findsOneWidget);
        // Dashboard action button says 'Clock In'
        expect(find.widgetWithText(ElevatedButton, 'Clock In'), findsOneWidget);

        // 2. Switch to Attendance Tab (Tab 2)
        appState.setTab(2);
        await tester.pump();

        expect(find.byType(AttendancePortalScreen), findsOneWidget);
        // Attendance Tab status pill indicates offline
        expect(find.text('OFFLINE • NOT CLOCKED IN'), findsOneWidget);
        // Attendance Tab button says 'Clock In'
        expect(find.widgetWithText(ElevatedButton, 'Clock In'), findsOneWidget);
        // Target hours reflects Intern 7.0h target
        expect(find.textContaining('7.0h Target'), findsOneWidget);
        // Scheduled hours ends at 17:00
        expect(find.textContaining('17:00'), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox());
        appState.dispose();
      }
    });

    testWidgets('Clock-in via Dashboard immediately updates Attendance tab UI',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
      try {
        await appState.loginWithCredentials('dp0345217@gmail.com', '123456');

        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationScreen(state: appState),
          ),
        );
        await tester.pump();

        // Perform geofenced clock in on appState
        await appState.clockInWithGeofence(
          distanceMeters: 28.0,
          isRemoteExemption: false,
          userLat: 12.920466,
          userLng: 80.121639,
        );
        await tester.pump();

        // Dashboard now displays 'Clock Out'
        expect(find.widgetWithText(ElevatedButton, 'Clock Out'), findsOneWidget);
        expect(find.text('HQ Geofence Verified'), findsOneWidget);

        // Navigate to Attendance Tab
        appState.setTab(2);
        await tester.pump();

        // Attendance Tab immediately reflects active shift
        expect(find.text('ON SHIFT • CLOCKED IN (PRESENT)'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Clock Out'), findsOneWidget);
        expect(find.textContaining(appState.clockInTimeDisplay), findsWidgets);
        expect(find.text('28m from HQ (Verified)'), findsOneWidget);
        expect(find.text('Location Verified (On-Site)'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        appState.dispose();
      }
    });

    testWidgets('Clocking out from Attendance tab updates Dashboard UI immediately',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
      try {
        await appState.loginWithCredentials('dp0345217@gmail.com', '123456');

        // Start in clocked-in state
        await appState.clockInWithGeofence(
          distanceMeters: 35.0,
          isRemoteExemption: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationScreen(state: appState),
          ),
        );
        await tester.pump();

        // Switch to Attendance tab
        appState.setTab(2);
        await tester.pump();

        expect(find.text('ON SHIFT • CLOCKED IN (PRESENT)'), findsOneWidget);

        // Clock out
        await appState.clockOutShift();
        await tester.pump();

        // Attendance tab shows offline and button reverts to Clock In
        expect(find.text('OFFLINE • NOT CLOCKED IN'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Clock In'), findsOneWidget);

        // Switch back to Dashboard
        appState.setTab(0);
        await tester.pump();

        // Dashboard button reverts to Clock In
        expect(find.widgetWithText(ElevatedButton, 'Clock In'), findsOneWidget);
        expect(find.text('Shift Completed'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        appState.dispose();
      }
    });

    testWidgets('Employee role displays 8.0h Target and 18:00 cutoff on both tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
      try {
        await appState.loginWithCredentials('antorajan501@gmail.com', '123456'); // Employee

        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationScreen(state: appState),
          ),
        );
        await tester.pump();

        // Dashboard shows 8.0 Hours Working Hour Target
        expect(find.text('8.0 Hours'), findsOneWidget);
        expect(find.text('Staff Daily Target'), findsOneWidget);

        // Switch to Attendance tab
        appState.setTab(2);
        await tester.pump();

        expect(find.textContaining('8.0h Target'), findsOneWidget);
        expect(find.textContaining('18:00'), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox());
        appState.dispose();
      }
    });
  });
}
