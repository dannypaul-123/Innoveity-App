import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/widgets/geofence_verification_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestModal({
    required String userRole,
    required DateTime currentTime,
    bool? isAdmin,
    String? userName,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: GeofenceVerificationModal(
            userRole: userRole,
            userName: userName ?? 'Test User',
            isAdmin: isAdmin,
            currentTime: currentTime,
            onConfirmClockIn: (result, isRemote) {},
          ),
        ),
      ),
    );
  }

  group('GeofenceVerificationModal Late Clock-In Notice Tests', () {
    testWidgets('Shows late arrival notice for employee clocking in at 10:25 AM (25 mins late)', (tester) async {
      final lateTime = DateTime(2026, 10, 27, 10, 25);
      await tester.pumpWidget(
        buildTestModal(
          userRole: 'EMPLOYEE',
          currentTime: lateTime,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Check that the late notice card is displayed
      expect(find.byKey(const ValueKey('late_clock_in_notice_card')), findsOneWidget);
      expect(find.text('Late Clock-In Notice'), findsOneWidget);
      expect(find.text('25 mins Late'), findsOneWidget);
      expect(
        find.textContaining('Shift cutoff was 10:00 AM. You are logging in 25 mins late at 10:25 AM.'),
        findsOneWidget,
      );

      // Verify that verification and geofence details remain intact
      expect(find.text('Geofence Location Verification'), findsOneWidget);
      expect(find.text('Radius: 200m'), findsOneWidget);
    });

    testWidgets('Shows intern late arrival notice for intern clocking in at 11:15 AM (1 hr 15 mins late)', (tester) async {
      final lateTime = DateTime(2026, 10, 27, 11, 15);
      await tester.pumpWidget(
        buildTestModal(
          userRole: 'INTERN',
          currentTime: lateTime,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('late_clock_in_notice_card')), findsOneWidget);
      expect(find.text('Intern Late Arrival'), findsOneWidget);
      expect(find.text('1 hr 15 mins Late'), findsOneWidget);
      expect(
        find.textContaining('Shift cutoff was 10:00 AM. You are logging in 1 hr 15 mins late at 11:15 AM.'),
        findsOneWidget,
      );
    });

    testWidgets('Shows exact late notice for employee clocking in in the afternoon (3 hrs 40 mins late)', (tester) async {
      final lateTime = DateTime(2026, 10, 27, 13, 40); // 1:40 PM
      await tester.pumpWidget(
        buildTestModal(
          userRole: 'EMPLOYEE',
          currentTime: lateTime,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('late_clock_in_notice_card')), findsOneWidget);
      expect(find.text('3 hrs 40 mins Late'), findsOneWidget);
      expect(
        find.textContaining('Shift cutoff was 10:00 AM. You are logging in 3 hrs 40 mins late at 1:40 PM.'),
        findsOneWidget,
      );
    });

    testWidgets('Does NOT show late notice when employee clocks in on-time before 10:00 AM (09:45 AM)', (tester) async {
      final onTime = DateTime(2026, 10, 27, 9, 45);
      await tester.pumpWidget(
        buildTestModal(
          userRole: 'EMPLOYEE',
          currentTime: onTime,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('late_clock_in_notice_card')), findsNothing);
      expect(find.text('Late Clock-In Notice'), findsNothing);
      expect(find.text('Geofence Location Verification'), findsOneWidget);
    });

    testWidgets('Does NOT show late notice when intern clocks in at exactly 10:00 AM', (tester) async {
      final exactTen = DateTime(2026, 10, 27, 10, 0);
      await tester.pumpWidget(
        buildTestModal(
          userRole: 'INTERN',
          currentTime: exactTen,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('late_clock_in_notice_card')), findsNothing);
      expect(find.text('Intern Late Arrival'), findsNothing);
    });

    testWidgets('Does NOT show late notice for Admin even when clocking in after 10:00 AM', (tester) async {
      final lateTime = DateTime(2026, 10, 27, 11, 30);
      await tester.pumpWidget(
        buildTestModal(
          userRole: 'ADMIN',
          isAdmin: true,
          currentTime: lateTime,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Admins should not see employee late notice
      expect(find.byKey(const ValueKey('late_clock_in_notice_card')), findsNothing);
      expect(find.text('Late Clock-In Notice'), findsNothing);
      expect(find.text('Geofence Location Verification'), findsOneWidget);
    });
  });
}
