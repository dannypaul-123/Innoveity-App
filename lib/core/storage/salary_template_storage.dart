import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_models.dart';

class SalaryTemplateStorage {
  static const _storageKey = 'saved_salary_structure_templates_v2';
  static const _migrationKey = 'migrated_salary_templates_developer_only_v2';
  static final Map<String, String> _memoryCache = {};

  const SalaryTemplateStorage();

  static SalaryTemplate get defaultDeveloperTemplate => SalaryTemplate(
    id: 'ST-101',
    name: 'Developer',
    role: 'EMPLOYEE',
    description: '-',
    basicSalary: 20000.0,
    hra: 0.0,
    da: 0.0,
    specialAllowance: 0.0,
    bonus: 0.0,
    pfPercentage: 0.0,
    taxPercentage: 0.0,
    deductions: 0.0,
    assignedUsersCount: 7,
  );

  Future<File?> _getTemplatesFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/innoveity_salary_templates.json');
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Persists the salary templates list to disk & SharedPreferences
  Future<void> saveSalaryTemplates(List<SalaryTemplate> templates) async {
    try {
      final jsonString = jsonEncode(templates.map((t) => t.toJson()).toList());
      _memoryCache[_storageKey] = jsonString;

      // 1. SharedPreferences (survives app restart, APK runs)
      try {
        final prefs = await _getPrefs();
        await prefs?.setString(_storageKey, jsonString);
        await prefs?.setBool(_migrationKey, true);
      } catch (e) {
        debugPrint('SharedPreferences persist error for salary templates: $e');
      }

      // 2. Direct File in App Documents Directory
      try {
        final file = await _getTemplatesFile();
        if (file != null) {
          await file.writeAsString(jsonString, flush: true);
        }
      } catch (e) {
        debugPrint('File persist error for salary templates: $e');
      }
    } catch (e) {
      debugPrint('Error saving salary templates: $e');
    }
  }

  /// Loads the saved salary templates, ensuring all non-developer default templates are removed
  Future<List<SalaryTemplate>> loadSalaryTemplates() async {
    try {
      String? rawJson;

      // 1. Check Memory Cache
      if (_memoryCache[_storageKey] != null && _memoryCache[_storageKey]!.isNotEmpty) {
        rawJson = _memoryCache[_storageKey];
      }

      // 2. Check SharedPreferences
      if (rawJson == null) {
        try {
          final prefs = await _getPrefs();
          rawJson = prefs?.getString(_storageKey);
        } catch (e) {
          debugPrint('SharedPreferences read error for salary templates: $e');
        }
      }

      // 3. Check Local File
      if (rawJson == null) {
        try {
          final file = await _getTemplatesFile();
          if (file != null && await file.exists()) {
            rawJson = await file.readAsString();
          }
        } catch (e) {
          debugPrint('File read error for salary templates: $e');
        }
      }

      if (rawJson != null && rawJson.isNotEmpty && rawJson != '[]') {
        final List decoded = jsonDecode(rawJson);
        final templates = decoded.map((item) => SalaryTemplate.fromJson(Map<String, dynamic>.from(item))).toList();

        // Filter out legacy non-developer seed templates ('ST-102', 'ST-103', 'ST-104')
        final sanitized = templates.where((t) {
          final idLower = t.id.toLowerCase();
          final nameLower = t.name.toLowerCase().trim();
          if (idLower == 'st-102' || idLower == 'st-103' || idLower == 'st-104') return false;
          if (nameLower == 'senior frontend engineer' ||
              nameLower == 'lead systems architect' ||
              nameLower == 'engineering intern') {
            return false;
          }
          return true;
        }).toList();

        // If after sanitizing no Developer exists, ensure Developer is present
        final hasDeveloper = sanitized.any((t) => t.name.toLowerCase().trim() == 'developer');
        if (!hasDeveloper) {
          sanitized.insert(0, defaultDeveloperTemplate);
        }

        // Persist the sanitized list so future loads are clean
        await saveSalaryTemplates(sanitized);
        return sanitized;
      }
    } catch (e) {
      debugPrint('Error loading salary templates: $e');
    }

    // Default: only Developer template
    final defaults = [defaultDeveloperTemplate];
    await saveSalaryTemplates(defaults);
    return defaults;
  }
}
