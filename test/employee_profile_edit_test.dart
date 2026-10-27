import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/screens/admin_portal_screen.dart';

void main() {
  group('Employee Profile & Registration Details Model Tests', () {
    test('UserProfile holds and round-trips all employee and intern registration details', () {
      final profile = UserProfile(
        id: 'USR-2001',
        employeeId: 'IN-9002',
        name: 'Anto A',
        email: 'antorajan501@gmail.com',
        role: 'EMPLOYEE',
        department: 'Mobile Engineering',
        designation: 'Mobile App Developer',
        phone: '+91 98401 23456',
        joiningDate: '15-09-2026',
        status: 'ACTIVE',
        netSalary: 25000.0,
        candidateType: 'Professional',
        dob: '15-06-2002',
        gender: 'Male',
        college: 'Anna University',
        degree: 'B.Tech IT',
        gradYear: '2024',
        currentSem: 'Completed',
        cgpa: '8.8',
        prevCompany: 'Cognizant',
        experience: '2 Years',
        skills: 'Flutter, Dart, Firebase',
        reportingManager: 'System Admin',
        workMode: 'In-Office',
        resumeFileName: 'anto_resume.pdf',
      );

      final json = profile.toJson();
      final fromJsonProfile = UserProfile.fromJson(json);

      expect(fromJsonProfile.id, 'USR-2001');
      expect(fromJsonProfile.employeeId, 'IN-9002');
      expect(fromJsonProfile.name, 'Anto A');
      expect(fromJsonProfile.email, 'antorajan501@gmail.com');
      expect(fromJsonProfile.role, 'EMPLOYEE');
      expect(fromJsonProfile.department, 'Mobile Engineering');
      expect(fromJsonProfile.designation, 'Mobile App Developer');
      expect(fromJsonProfile.phone, '+91 98401 23456');
      expect(fromJsonProfile.joiningDate, '15-09-2026');
      expect(fromJsonProfile.netSalary, 25000.0);
      expect(fromJsonProfile.candidateType, 'Professional');
      expect(fromJsonProfile.dob, '15-06-2002');
      expect(fromJsonProfile.gender, 'Male');
      expect(fromJsonProfile.college, 'Anna University');
      expect(fromJsonProfile.degree, 'B.Tech IT');
      expect(fromJsonProfile.gradYear, '2024');
      expect(fromJsonProfile.currentSem, 'Completed');
      expect(fromJsonProfile.cgpa, '8.8');
      expect(fromJsonProfile.prevCompany, 'Cognizant');
      expect(fromJsonProfile.experience, '2 Years');
      expect(fromJsonProfile.skills, 'Flutter, Dart, Firebase');
      expect(fromJsonProfile.reportingManager, 'System Admin');
      expect(fromJsonProfile.workMode, 'In-Office');
      expect(fromJsonProfile.resumeFileName, 'anto_resume.pdf');
    });

    test('UserProfile copyWith updates details accurately', () {
      final initial = UserProfile(
        id: 'USR-3001',
        employeeId: 'IN-3001',
        name: 'Jane Doe',
        email: 'jane@innoveity.com',
        role: 'INTERN',
        netSalary: 12000.0,
      );

      final updated = initial.copyWith(
        name: 'Jane Smith',
        role: 'EMPLOYEE',
        netSalary: 30000.0,
        department: 'Backend Engineering',
        designation: 'Junior Developer',
        college: 'IIT Madras',
        skills: 'Go, Docker, PostgreSQL',
      );

      expect(updated.name, 'Jane Smith');
      expect(updated.role, 'EMPLOYEE');
      expect(updated.netSalary, 30000.0);
      expect(updated.department, 'Backend Engineering');
      expect(updated.designation, 'Junior Developer');
      expect(updated.college, 'IIT Madras');
      expect(updated.skills, 'Go, Docker, PostgreSQL');
      expect(updated.employeeId, 'IN-3001'); // Unchanged
    });
  });

  group('AppState Employee Update & Sync Tests', () {
    test('AppState.updateEmployee synchronizes across userDirectory and active profile', () async {
      final appState = AppState();
      final initialEmp = UserProfile(
        id: 'USR-TEST-1',
        employeeId: 'EM-9999',
        name: 'Initial Employee',
        email: 'testemp@innoveity.com',
        role: 'INTERN',
        netSalary: 15000.0,
      );

      AppState.userDirectory[initialEmp.email] = initialEmp;

      final updatedEmp = initialEmp.copyWith(
        name: 'Updated Employee',
        role: 'EMPLOYEE',
        netSalary: 40000.0,
        department: 'Platform Team',
      );

      await appState.updateEmployee(updatedEmp);

      final inDirectory = AppState.userDirectory['testemp@innoveity.com'];
      expect(inDirectory, isNotNull);
      expect(inDirectory!.name, 'Updated Employee');
      expect(inDirectory.role, 'EMPLOYEE');
      expect(inDirectory.netSalary, 40000.0);
      expect(inDirectory.department, 'Platform Team');
    });
  });

  group('Admin Portal Staff Directory Edit Button UI Tests', () {
    testWidgets('Employee profile card replaces profile icon with Edit button', (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPortalScreen(state: appState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Staff Directories tab (tabIndex 7, 'Staff' in quick access bar)
      final staffTab = find.text('Staff');
      expect(staffTab, findsOneWidget);
      await tester.tap(staffTab);
      await tester.pumpAndSettle();

      // Verify profile icon Icons.contact_page_outlined is NOT present
      expect(find.byIcon(Icons.contact_page_outlined), findsNothing);

      // Verify Edit buttons are present for employee records
      expect(find.text('Edit'), findsWidgets);

      // Tap on the first Edit button to open the editor modal
      final firstEditBtn = find.text('Edit').first;
      await tester.tap(firstEditBtn);
      await tester.pumpAndSettle();

      // Verify the comprehensive editor modal opened with all tabs and Save & Sync button
      expect(find.text('Personal & Role'), findsOneWidget);
      expect(find.text('Job & Pay'), findsOneWidget);
      expect(find.text('Academic & Skills'), findsOneWidget);
      expect(find.text('Save & Sync'), findsOneWidget);

      // Dismiss modal and dispose state timer
      Navigator.of(tester.element(find.text('Save & Sync'))).pop();
      await tester.pumpAndSettle();
      appState.dispose();
    });
  });
}
