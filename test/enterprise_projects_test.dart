import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innoveity_app/models/project_models.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/screens/enterprise_projects_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Enterprise Projects Models & Logic Tests', () {
    test('ProjectWorkflowStage serialization and state transitions', () {
      const stage = ProjectWorkflowStage(
        id: 'stg-1',
        name: 'In Review',
        order: 3,
        requiresApproval: true,
        status: 'PENDING',
      );

      final json = stage.toJson();
      final fromJson = ProjectWorkflowStage.fromJson(json);

      expect(fromJson.id, 'stg-1');
      expect(fromJson.name, 'In Review');
      expect(fromJson.order, 3);
      expect(fromJson.requiresApproval, isTrue);
      expect(fromJson.status, 'PENDING');

      // Test copyWith
      final updated = stage.copyWith(
        status: 'REJECTED_REDO',
        rejectionReason: 'Code comments and test coverage missing',
        rejectedBy: 'System Admin',
      );
      expect(updated.status, 'REJECTED_REDO');
      expect(updated.rejectionReason, 'Code comments and test coverage missing');
      expect(updated.rejectedBy, 'System Admin');
    });

    test('EnterpriseProject progress and stage helpers', () {
      final stages = [
        const ProjectWorkflowStage(id: 's1', name: 'To Do', order: 1, status: 'APPROVED'),
        const ProjectWorkflowStage(id: 's2', name: 'In Progress', order: 2, status: 'ACTIVE'),
        const ProjectWorkflowStage(id: 's3', name: 'In Review', order: 3, requiresApproval: true),
        const ProjectWorkflowStage(id: 's4', name: 'Done', order: 4, isFinalCompletedStage: true),
      ];

      final project = EnterpriseProject(
        id: 'PRJ-101',
        code: 'PRJ-101',
        name: 'Enterprise Mobile App',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        workflowStages: stages,
        currentStageIndex: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(project.currentStage.name, 'In Progress');
      expect(project.isAwaitingApproval, isFalse);
      expect(project.isStageRejected, isFalse);
      expect(project.progressPercent, 25);
    });
  });

  group('Admin Approval & Rejection-Redo Workflow Tests', () {
    test('Stage reaches approval gate, admin rejects with redo requirement, employee redos and resubmits', () async {
      final state = AppState();
      try {
        final stages = [
          const ProjectWorkflowStage(id: 's1', name: 'To Do', order: 1, status: 'APPROVED'),
          const ProjectWorkflowStage(id: 's2', name: 'In Progress', order: 2, status: 'ACTIVE'),
          const ProjectWorkflowStage(id: 's3', name: 'In Review', order: 3, requiresApproval: true),
          const ProjectWorkflowStage(id: 's4', name: 'Done', order: 4, isFinalCompletedStage: true),
        ];

        final project = EnterpriseProject(
          id: 'PRJ-TEST-1',
          code: 'PRJ-999',
          name: 'AI Agent Portal',
          projectType: 'Client Project',
          priority: 'High',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 14)),
          workflowStages: stages,
          currentStageIndex: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await state.addEnterpriseProject(project);
        expect(state.projects.any((p) => p.id == 'PRJ-TEST-1'), isTrue);

        // 1. Advance project from Stage 2 (In Progress) to Stage 3 (In Review, requiresApproval = true)
        await state.advanceProjectStage(projectId: 'PRJ-TEST-1', userEmail: 'intern@company.com');

        var updated = state.projects.firstWhere((p) => p.id == 'PRJ-TEST-1');
        expect(updated.currentStageIndex, 2);
        expect(updated.currentStage.name, 'In Review');
        expect(updated.currentStage.status, 'AWAITING_APPROVAL');
        expect(updated.isAwaitingApproval, isTrue);

        // 2. Admin Rejects the stage deliverables with mandatory redo reason
        await state.rejectProjectStage(
          projectId: 'PRJ-TEST-1',
          rejectedBy: 'System Admin',
          rejectionReason: 'Figma mockups do not match responsive layout guidelines. Please fix padding.',
        );

        updated = state.projects.firstWhere((p) => p.id == 'PRJ-TEST-1');
        expect(updated.currentStage.status, 'REJECTED_REDO');
        expect(updated.isStageRejected, isTrue);
        expect(updated.currentStage.rejectionReason, contains('Figma mockups do not match'));
        expect(updated.currentStage.rejectedBy, 'System Admin');

        // 3. Employee redos and resubmits the stage
        await state.resubmitProjectStage(
          projectId: 'PRJ-TEST-1',
          resubmittedBy: 'intern@company.com',
        );

        updated = state.projects.firstWhere((p) => p.id == 'PRJ-TEST-1');
        expect(updated.currentStage.status, 'AWAITING_APPROVAL');
        expect(updated.isAwaitingApproval, isTrue);
        expect(updated.isStageRejected, isFalse);

        // 4. Admin Approves the stage -> Advances to Done
        await state.approveProjectStage(
          projectId: 'PRJ-TEST-1',
          approvedBy: 'System Admin',
        );

        updated = state.projects.firstWhere((p) => p.id == 'PRJ-TEST-1');
        expect(updated.currentStageIndex, 3);
        expect(updated.currentStage.name, 'Done');
        expect(updated.isCompleted, isTrue);
      } finally {
        state.dispose();
      }
    });
  });

  group('Enterprise Projects UI Screen Tests', () {
    testWidgets('Renders Enterprise Projects screen matching Image 1 with metrics and filters', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnterpriseProjectsView(
                state: state,
                isDark: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify breadcrumbs
        expect(find.text('Portal'), findsOneWidget);
        expect(find.text('Workspaces'), findsOneWidget);
        expect(find.text('Projects'), findsOneWidget);

        // Verify Title & Subtitle
        expect(find.text('Enterprise Projects'), findsOneWidget);
        expect(find.textContaining('Manage project lifecycles'), findsOneWidget);

        // Verify Metric Cards
        expect(find.text('TOTAL PROJECTS'), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('OVERDUE'), findsOneWidget);
        expect(find.text('COMPLETED'), findsOneWidget);
        expect(find.text('ON HOLD'), findsOneWidget);
        expect(find.text('ARCHIVED'), findsOneWidget);

        // Verify Filter Pills
        expect(find.text('All Projects'), findsOneWidget);
        expect(find.text('Active'), findsWidgets);
        expect(find.text('Overdue'), findsOneWidget);
        expect(find.text('Draft'), findsOneWidget);
        expect(find.text('Scheduled'), findsOneWidget);
        expect(find.text('On Hold'), findsOneWidget);
        expect(find.text('Completed'), findsWidgets);
        expect(find.text('Archived'), findsOneWidget);

        // Verify Create New Project button
        expect(find.text('Create New Project'), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });

    testWidgets('Wizard launches and steps through from Step 1 to Step 5', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnterpriseProjectsView(
                state: state,
                isDark: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Click Create New Project button in top header
        await tester.tap(find.text('Create New Project').first);
        await tester.pumpAndSettle();

        // Step 1: Basic Info
        expect(find.text('Project & Workflow Setup Wizard'), findsOneWidget);
        expect(find.text('Step 1 of 5 — Basic Info'), findsOneWidget);
        expect(find.text('Project Name *'), findsOneWidget);

        // Enter Project Name into the wizard dialog text field
        final projectNameField = find.descendant(
          of: find.byType(ProjectWorkflowSetupWizardDialog),
          matching: find.byType(TextField),
        ).first;
        await tester.enterText(projectNameField, 'Redux Architecture Upgrade');
        await tester.pumpAndSettle();

        // Click Next Step -> Step 2: Team Members
        final nextBtn = find.descendant(
          of: find.byType(ProjectWorkflowSetupWizardDialog),
          matching: find.widgetWithText(ElevatedButton, 'Next Step'),
        );
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
        expect(find.text('Step 2 of 5 — Team Members'), findsOneWidget);

        // Click Next Step -> Step 3: Workflow Stages
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
        expect(find.text('Step 3 of 5 — Workflow Stages'), findsOneWidget);
        expect(find.text('FINAL APPROVAL STAGE — AUTO COMPLETED'), findsOneWidget);

        // Click Next Step -> Step 4: Approval Rules
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
        expect(find.text('Step 4 of 5 — Approval Rules'), findsOneWidget);
        expect(find.text('Mandatory Admin Approval Gate'), findsOneWidget);
        expect(find.text('Strict Redo on Stage Rejection'), findsOneWidget);

        // Click Next Step -> Step 5: Preview & Create
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
        expect(find.text('Step 5 of 5 — Preview & Create'), findsOneWidget);
        expect(find.text('Project Configuration Summary'), findsOneWidget);
        expect(find.text('Redux Architecture Upgrade'), findsOneWidget);
        expect(find.text('Launch Project & Workflow'), findsOneWidget);

        // Tap Launch Project & Workflow
        await tester.tap(find.text('Launch Project & Workflow'));
        await tester.pumpAndSettle();

        // Verify project is launched and appears in list
        expect(state.projects.any((p) => p.name == 'Redux Architecture Upgrade'), isTrue);
        expect(find.text('Redux Architecture Upgrade'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });

    testWidgets('Stage rejection alert and redo button are rendered for rejected stage', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        final stages = [
          const ProjectWorkflowStage(id: 's1', name: 'To Do', order: 1, status: 'APPROVED'),
          const ProjectWorkflowStage(
            id: 's2',
            name: 'In Review',
            order: 2,
            requiresApproval: true,
            status: 'REJECTED_REDO',
            rejectionReason: 'API latency benchmark failed. Please optimize queries.',
            rejectedBy: 'System Admin',
          ),
          const ProjectWorkflowStage(id: 's3', name: 'Done', order: 3, isFinalCompletedStage: true),
        ];

        final project = EnterpriseProject(
          id: 'PRJ-REJECTED-1',
          code: 'PRJ-777',
          name: 'Backend API Microservice',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 10)),
          workflowStages: stages,
          currentStageIndex: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await state.addEnterpriseProject(project);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnterpriseProjectsView(
                state: state,
                isDark: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check for Rejection Redo Callout
        expect(find.textContaining('Stage "In Review" Rejected by Admin — Redo Required'), findsOneWidget);
        expect(find.textContaining('API latency benchmark failed'), findsOneWidget);
        expect(find.textContaining('Employee / Intern must redo this stage'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });

    testWidgets('Renders cleanly on narrow mobile screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnterpriseProjectsView(
                state: state,
                isDark: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify elements render without clipping or exception
        expect(find.text('Enterprise Projects'), findsOneWidget);
        expect(find.text('Create New Project'), findsWidgets);
        expect(find.text('TOTAL PROJECTS'), findsOneWidget);
        expect(find.text('Enterprise Mobile CRM App'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }
    });
  });
}
