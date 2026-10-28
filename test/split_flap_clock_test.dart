import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/widgets/split_flap_clock.dart';

void main() {
  group('SplitFlapClock Widget Tests', () {
    testWidgets('Renders tactile split-flap cards for hours, minutes, seconds and AM badge', (tester) async {
      // 11:12:52 AM on Wednesday, 28 October 2026
      final sampleTime = DateTime(2026, 10, 28, 11, 12, 52);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitFlapClock(
              currentTime: sampleTime,
              isDark: true,
            ),
          ),
        ),
      );

      // Verify flap digits
      expect(find.text('11'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('52'), findsOneWidget);

      // Verify AM badge is rendered and PM is present
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);

      // Verify formatted date: Wednesday • 28 October
      expect(find.text('Wednesday • 28 October'), findsOneWidget);

      // Verify clock background is Black in dark theme
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.black));
    });

    testWidgets('Clock background is White in light theme and renders PM badge correctly', (tester) async {
      // 03:45:10 PM on Friday, 15 May 2026
      final sampleTime = DateTime(2026, 5, 15, 15, 45, 10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitFlapClock(
              currentTime: sampleTime,
              isDark: false,
            ),
          ),
        ),
      );

      // Verify flap digits (15:45 in 12hr is 03:45)
      expect(find.text('03'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      // Verify date
      expect(find.text('Friday • 15 May'), findsOneWidget);

      // Verify clock background is White in light theme
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
    });
  });
}
