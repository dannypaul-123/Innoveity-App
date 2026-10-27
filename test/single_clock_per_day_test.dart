import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/screens/attendance_portal_screen.dart';
import 'package:innoveity_app/screens/main_navigation_screen.dart';
import 'package:innoveity_app/widgets/geofence_verification_modal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Single Clock-in and Clock-out Per Day Rules', () {
    late AppState appState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
    });

    test('Employee can clock in and clock out once, then cannot clock in again', () async {
      await appState.loginWithCredentials('harish@enterprise-crm.com', '123456');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.userProfile.role.toUpperCase(), 'EMPLOYEE');
      expect(appState.isAdmin, isFalse);
      expect(appState.hasCompletedShiftToday, isFalse);
      expect(appState.isClockedIn, isFalse);

      // First clock-in: succeeds
      await appState.clockInWithGeofence(
        distanceMeters: 30.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isTrue);
      expect(appState.hasCompletedShiftToday, isFalse);
      final firstClockIn = appState.clockInTimeDisplay;

      // Duplicate clock-in while active: blocked
      await appState.clockInWithGeofence(
        distanceMeters: 20.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isTrue);
      expect(appState.clockInTimeDisplay, firstClockIn);

      // First clock-out: succeeds
      final clockOutRes = await appState.clockOutShift();
      expect(clockOutRes['success'], isTrue);
      expect(appState.isClockedIn, isFalse);
      expect(appState.hasCompletedShiftToday, isTrue);

      // Duplicate clock-out: blocked
      final dupClockOut = await appState.clockOutShift();
      expect(dupClockOut['success'], isFalse);

      // Attempt second clock-in after clocking out: MUST BE BLOCKED
      await appState.clockInWithGeofence(
        distanceMeters: 25.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isFalse, reason: 'Employee should not be able to clock in again once clocked out');
      expect(appState.hasCompletedShiftToday, isTrue);

      // toggleClockState also respects completed shift
      await appState.toggleClockState();
      expect(appState.isClockedIn, isFalse);
    });

    test('Intern can clock in and clock out once, then cannot clock in again', () async {
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.userProfile.role.toUpperCase(), 'INTERN');
      expect(appState.isAdmin, isFalse);
      expect(appState.hasCompletedShiftToday, isFalse);

      // Clock-in
      await appState.clockInWithGeofence(
        distanceMeters: 40.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isTrue);

      // Clock-out
      final outRes = await appState.clockOutShift();
      expect(outRes['success'], isTrue);
      expect(appState.isClockedIn, isFalse);
      expect(appState.hasCompletedShiftToday, isTrue);

      // Attempt to clock-in again: blocked
      await appState.clockInWithGeofence(
        distanceMeters: 25.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isFalse, reason: 'Intern should not be able to clock in again once clocked out');
    });

    test('Clock-out status persists across logout and prevents clocking in again', () async {
      await appState.loginWithCredentials('harish@enterprise-crm.com', '123456');
      await appState.clockInWithGeofence(
        distanceMeters: 30.0,
        isRemoteExemption: false,
      );
      await appState.clockOutShift();
      expect(appState.hasCompletedShiftToday, isTrue);

      // Log out
      appState.logout();
      expect(appState.isLoggedIn, isFalse);

      // Log back in
      await appState.loginWithCredentials('harish@enterprise-crm.com', '123456');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.hasCompletedShiftToday, isTrue, reason: 'Completed shift must be remembered after re-login');
      expect(appState.isClockedIn, isFalse);

      // Attempt clock-in after re-login: blocked
      await appState.clockInWithGeofence(
        distanceMeters: 30.0,
        isRemoteExemption: false,
      );
      expect(appState.isClockedIn, isFalse);
    });

    test('Admin is exempt and can clock in and out multiple times for testing', () async {
      await appState.loginWithCredentials('admin@enterprise-crm.com', '123456');
      expect(appState.isAdmin, isTrue);
      expect(appState.hasCompletedShiftToday, isFalse);

      // First shift
      await appState.clockInWithGeofence(distanceMeters: 20.0, isRemoteExemption: false);
      expect(appState.isClockedIn, isTrue);
      await appState.clockOutShift();
      expect(appState.isClockedIn, isFalse);

      // Admin can clock in again
      await appState.clockInWithGeofence(distanceMeters: 20.0, isRemoteExemption: false);
      expect(appState.isClockedIn, isTrue);
    });

    testWidgets('UI blocks clock in dialog and displays warning when shift is completed', (tester) async {
      tester.view.physicalSize = const Size(1024, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await appState.loginWithCredentials('harish@enterprise-crm.com', '123456');
      await appState.clockInWithGeofence(distanceMeters: 30.0, isRemoteExemption: false);
      await appState.clockOutShift();
      expect(appState.hasCompletedShiftToday, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: MainNavigationScreen(state: appState),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap the Clock In button on the main navigation screen
      final clockBtn = find.text('Clock In');
      expect(clockBtn, findsOneWidget);
      await tester.tap(clockBtn);
      await tester.pump();

      // Verify SnackBar warning is displayed
      expect(
        find.text('Shift completed for today. Employees and interns can only clock in and clock out once per day.'),
        findsOneWidget,
      );

      // Verify GeofenceVerificationModal was NOT opened
      expect(find.byType(GeofenceVerificationModal), findsNothing);
      expect(appState.isClockedIn, isFalse);
    });

    testWidgets('Attendance portal UI blocks clock toggle when shift is completed', (tester) async {
      tester.view.physicalSize = const Size(1024, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await appState.loginWithCredentials('harish@enterprise-crm.com', '123456');
      await appState.clockInWithGeofence(distanceMeters: 30.0, isRemoteExemption: false);
      await appState.clockOutShift();
      expect(appState.hasCompletedShiftToday, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: AttendancePortalScreen(state: appState),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the main action button
      final clockBtn = find.widgetWithText(ElevatedButton, 'Clock In');
      expect(clockBtn, findsWidgets);
      await tester.tap(clockBtn.first);
      await tester.pump();

      // Verify SnackBar warning is displayed
      expect(
        find.text('Shift completed for today. Employees and interns can only clock in and clock out once per day.'),
        findsOneWidget,
      );

      // Verify GeofenceVerificationModal was NOT opened
      expect(find.byType(GeofenceVerificationModal), findsNothing);
      expect(appState.isClockedIn, isFalse);
    });
  });
}
