import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innoveity_app/core/storage/salary_template_storage.dart';
import 'package:innoveity_app/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SalaryTemplateStorage & Developer-Only Persistence Tests', () {
    test('Initial load provides only the Developer salary structure template', () async {
      const storage = SalaryTemplateStorage();
      final templates = await storage.loadSalaryTemplates();

      expect(templates.length, 1);
      expect(templates.first.name, 'Developer');
      expect(templates.first.id, 'ST-101');
      expect(templates.first.role, 'EMPLOYEE');
      expect(templates.first.basicSalary, 20000.0);
    });

    test('Filters out legacy non-developer seed templates if present in storage', () async {
      // Simulate storage with old templates
      SharedPreferences.setMockInitialValues({
        'saved_salary_structure_templates_v2': '''[
          {"id":"ST-101","name":"Developer","role":"EMPLOYEE","basicSalary":20000.0},
          {"id":"ST-102","name":"Senior Frontend Engineer","role":"EMPLOYEE","basicSalary":25000.0},
          {"id":"ST-103","name":"Lead Systems Architect","role":"TEAM_LEADER","basicSalary":35000.0},
          {"id":"ST-104","name":"Engineering Intern","role":"INTERN","basicSalary":12000.0}
        ]'''
      });

      const storage = SalaryTemplateStorage();
      final templates = await storage.loadSalaryTemplates();

      expect(templates.length, 1);
      expect(templates.first.name, 'Developer');
      expect(templates.any((t) => t.name.contains('Senior Frontend Engineer')), isFalse);
      expect(templates.any((t) => t.name.contains('Lead Systems Architect')), isFalse);
      expect(templates.any((t) => t.name.contains('Engineering Intern')), isFalse);
    });

    test('Saving and modifying templates persists across new storage sessions', () async {
      // Session 1: User customizes Developer template
      const storageSession1 = SalaryTemplateStorage();
      final templates = await storageSession1.loadSalaryTemplates();
      final devTemplate = templates.first;
      devTemplate.basicSalary = 22000.0;
      devTemplate.hra = 3000.0;

      await storageSession1.saveSalaryTemplates([devTemplate]);

      // Session 2: Fresh instance (simulating app reopen)
      const storageSession2 = SalaryTemplateStorage();
      final loadedSession2 = await storageSession2.loadSalaryTemplates();

      expect(loadedSession2.length, 1);
      expect(loadedSession2.first.name, 'Developer');
      expect(loadedSession2.first.basicSalary, 22000.0);
      expect(loadedSession2.first.hra, 3000.0);
    });

    test('AppState initial state has only Developer template', () {
      final appState = AppState();
      expect(appState.salaryTemplates.length, 1);
      expect(appState.salaryTemplates.first.name, 'Developer');
      expect(appState.salaryTemplates.first.id, 'ST-101');
    });
  });
}
