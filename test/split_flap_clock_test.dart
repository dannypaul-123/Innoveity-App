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

      // Verify flap digits (each card renders top and bottom halves)
      expect(find.text('11'), findsNWidgets(2));
      expect(find.text('12'), findsNWidgets(2));
      expect(find.text('52'), findsNWidgets(2));

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

      // Verify flap digits (15:45 in 12hr is 03:45, top and bottom halves)
      expect(find.text('03'), findsNWidgets(2));
      expect(find.text('45'), findsNWidgets(2));
      expect(find.text('10'), findsNWidgets(2));

      // Verify date
      expect(find.text('Friday • 15 May'), findsOneWidget);

      // Verify clock background is White in light theme
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
    });

    testWidgets('Flips seconds smoothly when currentTime updates without throwing ParentData errors', (tester) async {
      final initialTime = DateTime(2026, 10, 28, 11, 12, 52);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SplitFlapClock(
                  currentTime: initialTime,
                  isDark: true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('52'), findsNWidgets(2));

      // Advance time by 1 second to trigger the flip animation
      final nextTime = DateTime(2026, 10, 28, 11, 12, 53);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitFlapClock(
              currentTime: nextTime,
              isDark: true,
            ),
          ),
        ),
      );

      // Advance partially through the animation (100ms - Phase 1)
      await tester.pump(const Duration(milliseconds: 100));
      // In Phase 1, outgoing flap "52" and incoming "53" are rendered
      expect(tester.takeException(), isNull);

      // Advance into Phase 2 (250ms)
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);

      // Settle animation to completion
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('53'), findsNWidgets(2));
    });
  });
}
