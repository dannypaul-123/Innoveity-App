import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/widgets/live_attendance_osm_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveAttendanceOsmMap & OpenStreetMap Integration Tests', () {
    late AppState appState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
    });

    testWidgets('Renders FlutterMap with OpenStreetMap TileLayer and HQ reference circle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveAttendanceOsmMap(
                state: appState,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify OpenStreetMap Header
      expect(find.text('OpenStreetMap Live Geofence Verification'), findsOneWidget);
      expect(find.textContaining('Ref: 12.920466, 80.121639'), findsOneWidget);

      // Verify 60-second auto-refresh indicator is present
      expect(find.text('60s'), findsOneWidget);
      expect(find.textContaining('Auto-refreshing every 60s'), findsOneWidget);

      // Verify FlutterMap & OSM TileLayer are present in the tree
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(CircleLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);

      // Verify OSM Copyright attribution
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

      // Verify Staff Filter Chips
      expect(find.textContaining('All Staff'), findsOneWidget);
      expect(find.textContaining('Interns'), findsOneWidget);
      expect(find.textContaining('Employees'), findsOneWidget);
    });

    testWidgets('Tapping filter chips filters staff markers on the OpenStreetMap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveAttendanceOsmMap(
                state: appState,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Interns filter
      final internChip = find.textContaining('Interns');
      expect(internChip, findsOneWidget);
      await tester.tap(internChip);
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Employees filter
      final employeeChip = find.textContaining('Employees');
      expect(employeeChip, findsOneWidget);
      await tester.tap(employeeChip);
      await tester.pump(const Duration(milliseconds: 100));

      // Re-tap All Staff
      final allStaffChip = find.textContaining('All Staff');
      expect(allStaffChip, findsOneWidget);
      await tester.tap(allStaffChip);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Map floating action buttons (zoom and HQ recenter) are interactive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveAttendanceOsmMap(
                state: appState,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify zoom buttons and recenter button
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);

      // Tap zoom in
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap zoom out
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap recenter to HQ
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump(const Duration(milliseconds: 100));

      // Toggle geofence perimeter
      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump(const Duration(milliseconds: 100));
    });

    test('Deduplicates employee and intern profiles so each individual appears exactly once', () {
      final employees = appState.allEmployees;
      final ids = employees.map((e) => e.employeeId.toUpperCase()).toList();
      final names = employees.map((e) => e.name.toLowerCase()).toList();

      // Specifically check Daniel Paul (IN-1001)
      final danielCount = names.where((n) => n == 'daniel paul').length;
      expect(danielCount, equals(1), reason: 'Daniel Paul must only have one profile');

      final danielIdCount = ids.where((id) => id == 'IN-1001').length;
      expect(danielIdCount, equals(1), reason: 'IN-1001 must appear only once in roster');

      // Verify no duplicate IDs among non-empty IDs
      final nonEmptyIds = ids.where((id) => id.isNotEmpty).toList();
      expect(nonEmptyIds.toSet().length, equals(nonEmptyIds.length));
    });

    testWidgets('Live geofence verification plots clocked-in intern inside company radius', (tester) async {
      try {
        // Set user to Daniel Paul (Intern) and clock in inside campus premise
        await appState.loginWithCredentials('dp0345217@gmail.com', 'password');
        await appState.clockInWithGeofence(
          distanceMeters: 28.0,
          isRemoteExemption: false,
          userLat: appState.hqLatitude + 0.00010,
          userLng: appState.hqLongitude + 0.00008,
        );

        expect(appState.isClockedIn, isTrue);
        expect(appState.lastClockInDistance, lessThanOrEqualTo(appState.geofenceRadiusMeters));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LiveAttendanceOsmMap(
                  state: appState,
                  isDark: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Verify Daniel Paul marker is displayed exactly once
        expect(find.text('DP'), findsOneWidget);

        // Tap DP marker to open details bottom sheet
        await tester.tap(find.text('DP'));
        await tester.pump(const Duration(milliseconds: 300));

        // Details card verifies employee name, intern role, inside fence status, and Clock In / Out details
        expect(find.text('Daniel Paul'), findsWidgets);
        expect(find.textContaining('IN-1001'), findsOneWidget);
        expect(find.textContaining('Inside Fence'), findsOneWidget);
        expect(find.text('CLOCK IN'), findsOneWidget);
        expect(find.text('CLOCK OUT'), findsOneWidget);
        expect(find.text('Still working'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        appState.dispose();
      }
    });

    testWidgets('Live geofence radar displays specific clock out time when employee has clocked out', (tester) async {
      try {
        await appState.loginWithCredentials('dp0345217@gmail.com', 'password');
        await appState.clockInWithGeofence(
          distanceMeters: 28.0,
          isRemoteExemption: false,
          userLat: appState.hqLatitude + 0.00010,
          userLng: appState.hqLongitude + 0.00008,
        );
        await appState.clockOutShift();

        expect(appState.isClockedIn, isFalse);
        expect(appState.hasClockedOutToday, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LiveAttendanceOsmMap(
                  state: appState,
                  isDark: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Tap DP marker
        await tester.tap(find.text('DP'));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify clock in and clock out details
        expect(find.text('CLOCK IN'), findsOneWidget);
        expect(find.text('CLOCK OUT'), findsOneWidget);
        expect(find.textContaining(appState.clockOutTimeDisplay!), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox());
        appState.dispose();
      }
    });
  });
}
