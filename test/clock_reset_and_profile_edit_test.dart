import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/screens/dashboard_screen.dart';
import 'package:innoveity_app/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Clock Reset to Original and Profile Clock Editing Tests', () {
    testWidgets('Dashboard renders original digital clock with monospace orange time and date card', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Target time: 10:30:15 AM on Wednesday, Oct 28, 2026
      final customTime = DateTime(2026, 10, 28, 10, 30, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              tasks: const [],
              onClockToggle: () {},
              isClockedIn: false,
              formattedClockTime: '00:00:00',
              onNavigateTab: (_) {},
              onOpenDesk: () {},
              getCurrentClockTime: () => customTime,
            ),
          ),
        ),
      );

      // Verify original clock formatting: 10:30:15 AM and Wed, Oct 28, 2026
      expect(find.text('10:30:15 AM'), findsOneWidget);
      expect(find.text('Wed, Oct 28, 2026'), findsOneWidget);

      // Verify the orange monospace styling
      final textWidget = tester.widget<Text>(find.text('10:30:15 AM'));
      expect(textWidget.style?.color, equals(const Color(0xFFEA580C)));
      expect(textWidget.style?.fontFamily, equals('monospace'));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w900));
    });

    testWidgets('Profile screen renders CLOCK TIME & DATE card and opens Edit Clock modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testUser = UserProfile(
        id: 'USR-101',
        employeeId: 'IN-1001',
        name: 'Daniel Paul',
        email: 'danielpaul@enterprise-crm.com',
        role: 'EMPLOYEE',
      );

      DateTime? updatedTime;
      bool resetCalled = false;
      final fixedClock = DateTime(2026, 10, 28, 14, 15, 0); // 02:15 PM

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileScreen(
              userProfile: testUser,
              onLogout: () {},
              onToggleTheme: () {},
              isDarkMode: false,
              currentClockTime: fixedClock,
              isCustomClock: false,
              onUpdateClockTime: (dt) => updatedTime = dt,
              onResetClockToLive: () => resetCalled = true,
              getCurrentClockTime: () => fixedClock,
            ),
          ),
        ),
      );

      // Switch to 'My Profile Details' tab
      await tester.tap(find.text('My Profile Details'));
      await tester.pumpAndSettle();

      // Scroll down to the clock card
      await tester.scrollUntilVisible(
        find.text('CLOCK TIME & DATE'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify Clock Settings Card is rendered
      expect(find.text('CLOCK TIME & DATE'), findsOneWidget);
      expect(find.text('LIVE SYSTEM TIME'), findsOneWidget);

      // Scroll to Edit Clock button and tap
      await tester.scrollUntilVisible(
        find.text('Edit Clock Time & Date'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Edit Clock Time & Date'));
      await tester.pumpAndSettle();

      // Verify modal bottom sheet content
      expect(find.text('Selected Clock Target'), findsOneWidget);
      expect(find.text('Change Date'), findsOneWidget);
      expect(find.text('Change Time'), findsOneWidget);
      expect(find.text('QUICK TIME ADJUSTMENTS'), findsOneWidget);
      expect(find.text('+1 Hour'), findsOneWidget);
      expect(find.text('-1 Hour'), findsOneWidget);
      expect(find.text('+1 Day'), findsOneWidget);
      expect(find.text('Apply Custom Clock'), findsOneWidget);

      // Tap '+1 Hour' chip
      await tester.tap(find.text('+1 Hour'));
      await tester.pumpAndSettle();

      // Apply the change
      await tester.tap(find.text('Apply Custom Clock'));
      await tester.pumpAndSettle();

      // Verify callback was triggered with +1 hour (15:15 instead of 14:15)
      expect(updatedTime, isNotNull);
      expect(updatedTime!.hour, equals(15));
      expect(updatedTime!.minute, equals(15));
    });

    testWidgets('Profile screen allows resetting custom clock to live system time', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testUser = UserProfile(
        id: 'USR-101',
        employeeId: 'IN-1001',
        name: 'Daniel Paul',
        email: 'danielpaul@enterprise-crm.com',
        role: 'EMPLOYEE',
      );

      bool resetCalled = false;
      final customClock = DateTime(2026, 11, 1, 9, 0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileScreen(
              userProfile: testUser,
              onLogout: () {},
              onToggleTheme: () {},
              isDarkMode: false,
              currentClockTime: customClock,
              isCustomClock: true,
              onResetClockToLive: () => resetCalled = true,
              getCurrentClockTime: () => customClock,
            ),
          ),
        ),
      );

      // Switch to 'My Profile Details' tab
      await tester.tap(find.text('My Profile Details'));
      await tester.pumpAndSettle();

      // Scroll down to the clock card
      await tester.scrollUntilVisible(
        find.text('CLOCK TIME & DATE'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify 'CUSTOM CLOCK' badge and 'Reset to Live' button are visible
      expect(find.text('CUSTOM CLOCK'), findsOneWidget);
      expect(find.text('Reset to Live'), findsOneWidget);

      // Scroll to Reset to Live button and tap
      await tester.scrollUntilVisible(
        find.text('Reset to Live'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reset to Live'));
      await tester.pumpAndSettle();

      expect(resetCalled, isTrue);
    });

    test('AppState setCustomClockTime and resetClockToLive adjust currentClockTime properly', () async {
      final state = AppState();
      expect(state.isCustomClockActive, isFalse);

      final target = DateTime(2026, 12, 25, 18, 0, 0);
      await state.setCustomClockTime(target);

      expect(state.isCustomClockActive, isTrue);
      expect(state.currentClockTime.year, equals(2026));
      expect(state.currentClockTime.month, equals(12));
      expect(state.currentClockTime.day, equals(25));
      expect(state.currentClockTime.hour, equals(18));

      await state.resetClockToLive();
      expect(state.isCustomClockActive, isFalse);
      expect(state.customClockOffset, equals(Duration.zero));
    });
  });
}
