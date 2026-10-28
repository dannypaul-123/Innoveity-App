import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/screens/dashboard_screen.dart';
import 'package:innoveity_app/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Original Dashboard Clock & Clean Profile Tests', () {
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

    testWidgets('Profile screen does not have CLOCK TIME & DATE card', (tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileScreen(
              userProfile: testUser,
              onLogout: () {},
              onToggleTheme: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Switch to 'My Profile Details' tab
      await tester.tap(find.text('My Profile Details'));
      await tester.pumpAndSettle();

      // Verify Clock Settings Card and edit clock button are NOT present
      expect(find.text('CLOCK TIME & DATE'), findsNothing);
      expect(find.text('Edit Clock Time & Date'), findsNothing);
      expect(find.text('LIVE SYSTEM TIME'), findsNothing);
      expect(find.text('CUSTOM CLOCK'), findsNothing);
    });
  });
}
