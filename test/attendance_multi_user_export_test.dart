import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/services/attendance_export_service.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:excel/excel.dart';

void main() {
  test('Export attendance with multiple selected users', () {
    final selectedEmployees = ['Daniel Paul', 'Harish', 'Kaviya S'];
    final date = DateTime(2026, 10, 13);
    final allEmployees = <UserProfile>[];

    // 1. Check getRecords returns records for all 3 selected employees
    final records = AttendanceExportService.getRecords(
      selectedEmployeeNames: selectedEmployees,
      startDate: date,
      endDate: date,
      allEmployees: allEmployees,
    );

    expect(records.length, 3);
    final namesInRecords = records.map((r) => r.employeeName).toList();
    expect(namesInRecords, containsAll(selectedEmployees));

    // 2. Build the Excel file bytes
    final excelBytes = AttendanceExportService.buildExcelFile(
      selectedEmployeeNames: selectedEmployees,
      startDate: date,
      endDate: date,
      allEmployees: allEmployees,
    );

    expect(excelBytes, isNotNull);
    expect(excelBytes!.isNotEmpty, true);

    // 3. Decode the generated Excel file and verify rows
    final excel = Excel.decodeBytes(excelBytes);
    final sheet = excel['Daily Attendance Report'];
    expect(sheet, isNotNull);

    // Row 0: Brand
    expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value?.toString(), contains('Innoveity Tech'));

    // Row 1: Subtitle should mention selected employees
    final subtitle = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value?.toString();
    expect(subtitle, contains('Daniel Paul'));
    expect(subtitle, contains('Harish'));

    // Check data rows
    final foundNames = <String>[];
    for (int row = 3; row < 3 + records.length; row++) {
      final nameVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value?.toString();
      if (nameVal != null) {
        foundNames.add(nameVal);
      }
    }

    expect(foundNames, containsAll(selectedEmployees));
  });

  test('Export attendance for multiple users across multiple dates', () {
    final selectedEmployees = ['Daniel Paul', 'Praveen N'];
    final startDate = DateTime(2026, 10, 12);
    final endDate = DateTime(2026, 10, 13);
    final allEmployees = <UserProfile>[];

    final records = AttendanceExportService.getRecords(
      selectedEmployeeNames: selectedEmployees,
      startDate: startDate,
      endDate: endDate,
      allEmployees: allEmployees,
    );

    // 2 employees * 2 days = 4 records
    expect(records.length, 4);

    final excelBytes = AttendanceExportService.buildExcelFile(
      selectedEmployeeNames: selectedEmployees,
      startDate: startDate,
      endDate: endDate,
      allEmployees: allEmployees,
    );

    expect(excelBytes, isNotNull);
    expect(excelBytes!.isNotEmpty, true);
  });
}
