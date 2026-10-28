import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/models/project_models.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/screens/active_board_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Active Board Employee Project Assignment & Task Removal Tests', () {
    testWidgets('Active Board displays admin-assigned project and removes old dummy tasks for employee', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        // Set user as EMPLOYEE (Daniel Paul)
        state.userProfile = UserProfile(
          id: 'USR-1001',
          employeeId: 'IN-1001',
          name: 'Daniel Paul',
          email: 'danielpaul@enterprise-crm.com',
          role: 'EMPLOYEE',
          department: 'Mobile Application Development',
          designation: 'Mobile Engineer',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ActiveBoardScreen(state: state),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify old dummy tasks are REMOVED
        expect(find.text('Responsive Layout Redesign'), findsNothing);
        expect(find.text('Biometric Auth Integration'), findsNothing);
        expect(find.text('Timesheet Auto-clocking Fix'), findsNothing);
        expect(find.text('Ticket Escalation Workflow'), findsNothing);
        expect(find.text('Salary Slip PDF Generator'), findsNothing);
        expect(find.text('Leave Balance Credit Sync'), findsNothing);
        expect(find.text('TSK-101'), findsNothing);
        expect(find.text('TSK-102'), findsNothing);

        // 2. Verify project assigned by admin to employee IS SHOWN
        expect(find.text('Enterprise Mobile CRM App'), findsWidgets);
        expect(find.text('PRJ-101'), findsWidgets);
        expect(find.text('Medium Priority'), findsWidgets);
        expect(find.text('Client Project'), findsWidgets);

        // 3. Verify Kanban Board columns
        expect(find.text('TO DO'), findsOneWidget);
        expect(find.text('IN PROGRESS'), findsOneWidget);
        expect(find.text('IN REVIEW'), findsOneWidget);
        expect(find.text('DONE'), findsOneWidget);

        // 4. Verify the project is shown under IN PROGRESS with stage advancement action
        expect(find.text('Stage: In Progress'), findsOneWidget);
        expect(find.text('Advance Stage'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });

    testWidgets('Active Board displays admin-assigned project and removes dummy tasks for intern', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        // Set user as INTERN
        state.userProfile = UserProfile(
          id: 'USR-2002',
          employeeId: 'IN-2002',
          name: 'Anto A',
          email: 'antorajan501@gmail.com',
          role: 'INTERN',
          department: 'Mobile Application Development',
          designation: 'Intern Developer',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ActiveBoardScreen(state: state),
          ),
        );
        await tester.pumpAndSettle();

        // Verify old tasks are NOT present
        expect(find.text('Responsive Layout Redesign'), findsNothing);
        expect(find.text('TSK-101'), findsNothing);

        // Verify admin-assigned project is displayed
        expect(find.text('Enterprise Mobile CRM App'), findsWidgets);
        expect(find.text('PRJ-101'), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });

    testWidgets('Active Board reflects admin stage rejection and employee redo flow', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        state.userProfile = UserProfile(
          id: 'USR-1001',
          employeeId: 'IN-1001',
          name: 'Daniel Paul',
          email: 'danielpaul@enterprise-crm.com',
          role: 'EMPLOYEE',
          department: 'Mobile Application Development',
          designation: 'Mobile Engineer',
        );

        // Admin rejects current stage
        await state.advanceProjectStage(projectId: 'PRJ-1001', userEmail: 'danielpaul@enterprise-crm.com');
        await state.rejectProjectStage(
          projectId: 'PRJ-1001',
          rejectedBy: 'System Admin',
          rejectionReason: 'Code coverage is below 80%. Please write additional unit tests.',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ActiveBoardScreen(state: state),
          ),
        );
        await tester.pumpAndSettle();

        // Verify rejection alert callout and redo button appear on active board
        expect(find.textContaining('Stage Rejected by Admin — Redo Required'), findsOneWidget);
        expect(find.textContaining('Code coverage is below 80%'), findsOneWidget);
        expect(find.text('Redo & Resubmit to Admin'), findsOneWidget);

        // Tap Redo & Resubmit
        await tester.tap(find.text('Redo & Resubmit to Admin'));
        await tester.pumpAndSettle();

        // Should now be under admin review
        expect(state.projects.first.isAwaitingApproval, isTrue);
        expect(find.textContaining('Under Admin Review'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });

    testWidgets('Active Board displays empty state when employee has no assigned projects', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        // User with no assigned projects
        state.userProfile = UserProfile(
          id: 'USR-9999',
          employeeId: 'IN-9999',
          name: 'Unassigned Person',
          email: 'unassigned@nowhere.com',
          role: 'EMPLOYEE',
          department: 'Unrelated Operations',
          designation: 'Staff',
        );

        // Remove all projects
        for (final p in state.projects.toList()) {
          await state.deleteEnterpriseProject(p.id);
        }

        await tester.pumpWidget(
          MaterialApp(
            home: ActiveBoardScreen(state: state),
          ),
        );
        await tester.pumpAndSettle();

        // Verify empty state is displayed with no dummy tasks
        expect(find.text('No Projects Assigned'), findsWidgets);
        expect(find.textContaining('There are no active projects assigned to you by the Admin yet'), findsOneWidget);
        expect(find.text('Responsive Layout Redesign'), findsNothing);
        expect(find.text('TSK-101'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });
  });
}
