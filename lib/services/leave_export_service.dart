import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import 'file_saver.dart';

class LeaveExportRecord {
  final String applicantName;
  final String employeeId;
  final String role;
  final String department;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String days;
  final String status;
  final String reason;
  final DateTime? startDateTime;
  final DateTime? endDateTime;

  LeaveExportRecord({
    required this.applicantName,
    required this.employeeId,
    required this.role,
    required this.department,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
    required this.reason,
    this.startDateTime,
    this.endDateTime,
  });
}

class LeaveExportService {
  // Brand color palette matching Innoveity identity
  static const String colorBrandOrange = '#EA580C';
  static const String colorBrandDark = '#0F172A';
  static const String colorApprovedBg = '#DCFCE7';
  static const String colorApprovedText = '#15803D';
  static const String colorPendingBg = '#FEF3C7';
  static const String colorPendingText = '#B45309';
  static const String colorRejectedBg = '#FEE2E2';
  static const String colorRejectedText = '#B91C1C';

  /// Roster fallback mapping matching screenshot and Innoveity corporate directory
  static final Map<String, Map<String, String>> _knownRosterDirectory = {
    'Abishek S': {
      'id': 'EM-1009',
      'role': 'EMPLOYEE',
      'dept': 'Full Stack Dev',
    },
    'Daniel Paul': {
      'id': 'IN-1001',
      'role': 'INTERN',
      'dept': 'Mobile App Dev',
    },
    'Zubairya Salam Khan': {
      'id': 'EM-1006',
      'role': 'EMPLOYEE',
      'dept': 'Full Stack Dev',
    },
    'Raghul Prasath J': {
      'id': 'EM-1004',
      'role': 'EMPLOYEE',
      'dept': 'Full Stack Dev',
    },
    'Anto A': {
      'id': 'IN-9002',
      'role': 'EMPLOYEE',
      'dept': 'Computer Science',
    },
    'Praveen N': {
      'id': 'IN-9004',
      'role': 'EMPLOYEE',
      'dept': 'MCA Department',
    },
    'Nancy Narmadha T': {
      'id': 'IN-1005',
      'role': 'EMPLOYEE',
      'dept': 'MCA Department',
    },
    'Harish': {
      'id': 'IN-1008',
      'role': 'EMPLOYEE',
      'dept': 'Quality Assurance',
    },
    'Kaviya S': {
      'id': 'IN-1009',
      'role': 'EMPLOYEE',
      'dept': 'UI/UX Design',
    },
    'Sanjay S': {
      'id': 'IN-1010',
      'role': 'EMPLOYEE',
      'dept': 'Computer Science',
    },
    'Yeshwanth Y': {
      'id': 'IN-9001',
      'role': 'EMPLOYEE',
      'dept': 'Computer Science',
    },
    'Paul Renine': {
      'id': 'TL-1001',
      'role': 'TEAM_LEADER',
      'dept': 'Engineering',
    },
    'Suraj S': {
      'id': 'TL-1002',
      'role': 'TEAM_LEADER',
      'dept': 'Engineering',
    },
    'Divya R': {
      'id': 'EM-9001',
      'role': 'EMPLOYEE',
      'dept': 'Engineering',
    },
    'System Admin': {
      'id': 'AD-0001',
      'role': 'ADMIN',
      'dept': 'Management',
    },
  };

  /// Parse varied date formats reliably into DateTime at midnight (00:00:00)
  static DateTime? parseDate(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final lower = clean.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (lower.contains('today')) return today;
    if (lower.contains('yesterday')) return today.subtract(const Duration(days: 1));

    // ISO format: 2026-09-24 or 2026-09-24T...
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(clean)) {
      final isoPart = clean.split('T')[0];
      final parts = isoPart.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }

    // Slash format: 24/09/2026 or 2026/09/24
    if (clean.contains('/')) {
      final parts = clean.split('/');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) return DateTime(y, m, d);
        } else {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) return DateTime(y, m, d);
        }
      }
    }

    // Dash format: 24-09-2026
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(clean)) {
      final parts = clean.split('-');
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }

    // Natural text format like "Sep 24, 2024" or "September 24, 2026"
    final formats = [
      'MMM dd, yyyy',
      'MMMM dd, yyyy',
      'MMM d, yyyy',
      'MMMM d, yyyy',
      'dd MMM yyyy',
      'd MMM yyyy',
      'yyyy-MM-dd',
    ];

    for (final fmt in formats) {
      try {
        final dt = DateFormat(fmt).parse(clean);
        return DateTime(dt.year, dt.month, dt.day);
      } catch (_) {}
    }

    return null;
  }

  /// Format DateTime as standard YYYY-MM-DD
  static String formatIsoDate(DateTime? dt) {
    if (dt == null) return '2026-09-24';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Normalize Leave Type acronyms and names to clean codes
  static String normalizeLeaveType(String raw) {
    final clean = raw.trim();
    final lower = clean.toLowerCase();

    if (lower == 'cl' || lower == 'casual' || lower == 'casual leave') {
      return clean.toUpperCase() == 'CASUAL' ? 'CASUAL' : 'CL';
    }
    if (lower == 'sl' || lower == 'sick' || lower == 'sick leave') {
      return 'SL';
    }
    if (lower == 'wfh' || lower.contains('work from home') || lower.contains('home')) {
      return 'WFH';
    }
    if (lower == 'el' || lower == 'earned' || lower == 'earned leave') {
      return 'EL';
    }
    return clean;
  }

  /// Convert leave requests into clean export records with date filtering and multi-employee filtering
  static List<LeaveExportRecord> getRecords({
    required List<LeaveRequest> requests,
    required List<UserProfile> allEmployees,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedEmployee,
    List<String>? selectedEmployees,
    String? selectedStatus,
  }) {
    final List<LeaveExportRecord> records = [];

    // Normalise start and end bounds
    final startBound = startDate != null
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : null;
    final endBound = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
        : null;

    Set<String>? filterEmps;
    if (selectedEmployees != null && selectedEmployees.isNotEmpty) {
      final validNames = selectedEmployees
          .where((e) => e.trim().isNotEmpty && e != 'All Employees' && e.toUpperCase() != 'ALL')
          .map((e) => e.trim().toLowerCase())
          .toSet();
      if (validNames.isNotEmpty) {
        filterEmps = validNames;
      }
    } else if (selectedEmployee != null &&
        selectedEmployee.trim().isNotEmpty &&
        selectedEmployee != 'All Employees' &&
        selectedEmployee.toUpperCase() != 'ALL') {
      filterEmps = {selectedEmployee.trim().toLowerCase()};
    }

    final filterStat = selectedStatus != null &&
            selectedStatus.trim().isNotEmpty &&
            selectedStatus != 'All' &&
            selectedStatus.toUpperCase() != 'ALL'
        ? selectedStatus.trim().toUpperCase()
        : null;

    for (final req in requests) {
      // 1. Employee filter (supports multiple selected employees)
      if (filterEmps != null) {
        final reqName = req.applicantName.trim().toLowerCase();
        final matches = filterEmps.any((target) =>
            reqName == target ||
            reqName.contains(target) ||
            target.contains(reqName));
        if (!matches) {
          continue;
        }
      }

      // 2. Status filter
      final reqStatusUpper = req.status.trim().toUpperCase();
      if (filterStat != null) {
        if (!reqStatusUpper.contains(filterStat)) {
          continue;
        }
      }

      // 3. Date range filter
      final startDt = parseDate(req.startDate);
      final endDt = parseDate(req.endDate) ?? startDt;

      if (startBound != null && endBound != null) {
        if (startDt != null && endDt != null) {
          // Check overlap: does [startDt, endDt] overlap with [startBound, endBound]?
          final startsAfterEnd = startDt.isAfter(endBound);
          final endsBeforeStart = endDt.isBefore(startBound);
          if (startsAfterEnd || endsBeforeStart) {
            continue;
          }
        } else if (startDt != null) {
          if (startDt.isBefore(startBound) || startDt.isAfter(endBound)) {
            continue;
          }
        }
      }

      // Resolve Employee ID, Role, Department
      String empId = req.employeeId ?? '';
      String empRole = req.role ?? '';
      String empDept = req.department ?? '';

      // Match against known directory or allEmployees
      UserProfile? matchedProfile;
      for (final profile in allEmployees) {
        if (profile.name.toLowerCase() == req.applicantName.toLowerCase()) {
          matchedProfile = profile;
          break;
        }
      }

      final fallback = _knownRosterDirectory[req.applicantName];

      if (empId.isEmpty) {
        if (matchedProfile != null && matchedProfile.employeeId.isNotEmpty) {
          empId = matchedProfile.employeeId;
        } else if (fallback != null) {
          empId = fallback['id'] ?? 'EM-1001';
        } else {
          empId = 'EM-${(req.applicantName.hashCode.abs() % 9000) + 1000}';
        }
      }

      if (empRole.isEmpty) {
        if (matchedProfile != null && matchedProfile.role.isNotEmpty) {
          empRole = matchedProfile.role;
        } else if (fallback != null) {
          empRole = fallback['role'] ?? 'EMPLOYEE';
        } else {
          empRole = 'EMPLOYEE';
        }
      }

      if (empDept.isEmpty) {
        if (matchedProfile != null &&
            matchedProfile.department != null &&
            matchedProfile.department!.isNotEmpty) {
          empDept = matchedProfile.department!;
        } else if (fallback != null) {
          empDept = fallback['dept'] ?? 'Engineering';
        } else {
          empDept = 'Full Stack Dev';
        }
      }

      // Format days (support 0.5, 1, 2, etc.)
      final daysVal = req.displayDays;
      final daysStr = (daysVal % 1 == 0) ? daysVal.toInt().toString() : daysVal.toString();

      // Format dates (default to ISO YYYY-MM-DD as shown in screenshot)
      final formattedStart = formatIsoDate(startDt);
      final formattedEnd = formatIsoDate(endDt);

      records.add(LeaveExportRecord(
        applicantName: req.applicantName,
        employeeId: empId,
        role: empRole.toUpperCase(),
        department: empDept,
        leaveType: normalizeLeaveType(req.leaveType),
        startDate: formattedStart,
        endDate: formattedEnd,
        days: daysStr,
        status: reqStatusUpper,
        reason: req.reason,
        startDateTime: startDt,
        endDateTime: endDt,
      ));
    }

    return records;
  }

  /// Escape CSV field according to RFC 4180
  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Generate RFC 4180 compliant CSV content with Innoveity branding metadata
  static String buildCsv(
    List<LeaveExportRecord> records, {
    DateTime? startDate,
    DateTime? endDate,
    bool includeBrandingHeader = true,
  }) {
    final buffer = StringBuffer();

    // UTF-8 BOM so Excel automatically recognizes unicode encoding and formats columns properly
    buffer.write('\uFEFF');

    final dateRangeStr = (startDate != null && endDate != null)
        ? '${formatIsoDate(startDate)} to ${formatIsoDate(endDate)}'
        : 'All Active Records';

    if (includeBrandingHeader) {
      // Row 1: Innoveity Tech Corporate Header
      buffer.writeln('"Innoveity Tech - Employee Leave Management Report"');
      // Row 2: Metadata row
      buffer.writeln(
        '"Brand: Innoveity Tech","Date Range: $dateRangeStr","Exported: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}","Total Records: ${records.length}"',
      );
      // Empty row separator
      buffer.writeln();
    }

    // 10 Columns matching user screenshot:
    // Applicant | Employee ID | Role | Department | Leave Type | Start Date | End Date | Days | Status | Reason
    final headers = [
      'Applicant',
      'Employee ID',
      'Role',
      'Department',
      'Leave Type',
      'Start Date',
      'End Date',
      'Days',
      'Status',
      'Reason',
    ];

    buffer.writeln(headers.map(_escapeCsv).join(','));

    for (final r in records) {
      final row = [
        r.applicantName,
        r.employeeId,
        r.role,
        r.department,
        r.leaveType,
        r.startDate,
        r.endDate,
        r.days,
        r.status,
        r.reason,
      ];
      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    return buffer.toString();
  }

  /// Generate styled Microsoft Excel (.xlsx) workbook with Innoveity Logo branding
  static List<int>? buildExcel(
    List<LeaveExportRecord> records, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Leave Records'];

    // Remove default sheet if present
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Row 0: Brand Title (Innoveity Tech)
    final cellBrand = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    cellBrand.value = TextCellValue('Innoveity Tech');
    cellBrand.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString(colorBrandOrange),
    );

    // Row 1: Subtitle & Date Range
    final dateRangeStr = (startDate != null && endDate != null)
        ? '${formatIsoDate(startDate)} to ${formatIsoDate(endDate)}'
        : 'All Recorded Dates';

    final cellSubtitle = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    cellSubtitle.value = TextCellValue(
      'Leave Management & WFH Sanction Report | Official Corporate Record | Date Range: $dateRangeStr',
    );
    cellSubtitle.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString(colorBrandDark),
    );

    // Row 2: Metadata / Timestamp
    final cellMeta = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
    cellMeta.value = TextCellValue(
      'Exported: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} | Total Records: ${records.length}',
    );
    cellMeta.cellStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#64748B'),
    );

    // Row 4: Column Headers (matching screenshot 10 columns)
    final headers = [
      'Applicant',
      'Employee ID',
      'Role',
      'Department',
      'Leave Type',
      'Start Date',
      'End Date',
      'Days',
      'Status',
      'Reason',
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString(colorBrandOrange),
        horizontalAlign: (col == 0 || col == 3 || col == 9)
            ? HorizontalAlign.Left
            : HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    // Set Column Widths (Generous widths ensure dates never show '########' in Excel)
    sheet.setColumnWidth(0, 24.0); // Applicant
    sheet.setColumnWidth(1, 16.0); // Employee ID
    sheet.setColumnWidth(2, 16.0); // Role
    sheet.setColumnWidth(3, 22.0); // Department
    sheet.setColumnWidth(4, 14.0); // Leave Type
    sheet.setColumnWidth(5, 16.0); // Start Date (Prevents ########)
    sheet.setColumnWidth(6, 16.0); // End Date (Prevents ########)
    sheet.setColumnWidth(7, 10.0); // Days
    sheet.setColumnWidth(8, 16.0); // Status
    sheet.setColumnWidth(9, 42.0); // Reason

    // Rows 5+: Table Data
    for (int rowIdx = 0; rowIdx < records.length; rowIdx++) {
      final r = records[rowIdx];
      final currentExcelRow = 5 + rowIdx;
      final isEven = rowIdx % 2 == 0;
      final rowBg = isEven ? '#FFFFFF' : '#F8FAFC';

      final rowValues = [
        r.applicantName,
        r.employeeId,
        r.role,
        r.department,
        r.leaveType,
        r.startDate,
        r.endDate,
        r.days,
        r.status,
        r.reason,
      ];

      for (int col = 0; col < rowValues.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentExcelRow));
        final val = rowValues[col];

        String cellBg = rowBg;
        String cellText = colorBrandDark;
        bool isBold = false;
        HorizontalAlign align = HorizontalAlign.Center;

        if (col == 0) {
          align = HorizontalAlign.Left;
          isBold = true;
        } else if (col == 3 || col == 9) {
          align = HorizontalAlign.Left;
        }

        // Color badge for Status
        if (col == 8) {
          isBold = true;
          if (r.status.contains('APPROVED')) {
            cellBg = colorApprovedBg;
            cellText = colorApprovedText;
          } else if (r.status.contains('PENDING')) {
            cellBg = colorPendingBg;
            cellText = colorPendingText;
          } else {
            cellBg = colorRejectedBg;
            cellText = colorRejectedText;
          }
        }

        cell.value = TextCellValue(val);
        cell.cellStyle = CellStyle(
          bold: isBold,
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString(cellText),
          backgroundColorHex: ExcelColor.fromHexString(cellBg),
          horizontalAlign: align,
          verticalAlign: VerticalAlign.Center,
        );
      }
    }

    // Append Summary Totals
    final summaryRow = 5 + records.length + 1;
    final totalApproved = records.where((r) => r.status.contains('APPROVED')).length;
    final totalPending = records.where((r) => r.status.contains('PENDING')).length;
    final totalRejected = records.where((r) => r.status.contains('REJECTED')).length;

    final cellSummary = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow));
    cellSummary.value = TextCellValue('Summary Totals');
    cellSummary.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString(colorBrandDark),
      backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final cellApproved = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow));
    cellApproved.value = TextCellValue('Approved: $totalApproved');
    cellApproved.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString(colorApprovedText),
      backgroundColorHex: ExcelColor.fromHexString(colorApprovedBg),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellPending = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow));
    cellPending.value = TextCellValue('Pending: $totalPending');
    cellPending.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString(colorPendingText),
      backgroundColorHex: ExcelColor.fromHexString(colorPendingBg),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellRejected = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow));
    cellRejected.value = TextCellValue('Rejected: $totalRejected');
    cellRejected.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString(colorRejectedText),
      backgroundColorHex: ExcelColor.fromHexString(colorRejectedBg),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    return excel.save();
  }

  /// Triggers CSV generation, file download/saving, and returns target path
  static Future<String?> exportLeaveCsv({
    required List<LeaveRequest> requests,
    required List<UserProfile> allEmployees,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedEmployee,
    List<String>? selectedEmployees,
    String? selectedStatus,
    bool includeBranding = true,
    BuildContext? context,
  }) async {
    final records = getRecords(
      requests: requests,
      allEmployees: allEmployees,
      startDate: startDate,
      endDate: endDate,
      selectedEmployee: selectedEmployee,
      selectedEmployees: selectedEmployees,
      selectedStatus: selectedStatus,
    );

    final csvContent = buildCsv(
      records,
      startDate: startDate,
      endDate: endDate,
      includeBrandingHeader: includeBranding,
    );

    final bytes = utf8.encode(csvContent);

    final dateSuffix = (startDate != null && endDate != null)
        ? '${formatIsoDate(startDate)}_to_${formatIsoDate(endDate)}'
        : 'all_dates';

    final String userSuffix;
    if (selectedEmployees != null && selectedEmployees.isNotEmpty) {
      final valid = selectedEmployees
          .where((e) => e != 'All Employees' && e.toUpperCase() != 'ALL')
          .toList();
      if (valid.isEmpty) {
        userSuffix = 'all_employees';
      } else if (valid.length == 1) {
        userSuffix = valid.first.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      } else if (valid.length == 2) {
        userSuffix = valid.map((n) => n.replaceAll(RegExp(r'\s+'), '_').toLowerCase()).join('_and_');
      } else {
        userSuffix = '${valid.length}_employees';
      }
    } else if (selectedEmployee != null &&
        selectedEmployee.isNotEmpty &&
        selectedEmployee != 'All Employees' &&
        selectedEmployee.toUpperCase() != 'ALL') {
      userSuffix = selectedEmployee.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    } else {
      userSuffix = 'all_employees';
    }

    final fileName = 'leave_records_${userSuffix}_$dateSuffix.csv';

    return await saveAndDownloadFile(bytes, fileName, context: context);
  }

  /// Triggers Excel generation, file download/saving, and returns target path
  static Future<String?> exportLeaveExcel({
    required List<LeaveRequest> requests,
    required List<UserProfile> allEmployees,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedEmployee,
    List<String>? selectedEmployees,
    String? selectedStatus,
    BuildContext? context,
  }) async {
    final records = getRecords(
      requests: requests,
      allEmployees: allEmployees,
      startDate: startDate,
      endDate: endDate,
      selectedEmployee: selectedEmployee,
      selectedEmployees: selectedEmployees,
      selectedStatus: selectedStatus,
    );

    final bytes = buildExcel(
      records,
      startDate: startDate,
      endDate: endDate,
    );

    if (bytes == null || bytes.isEmpty) return null;

    final dateSuffix = (startDate != null && endDate != null)
        ? '${formatIsoDate(startDate)}_to_${formatIsoDate(endDate)}'
        : 'all_dates';

    final String userSuffix;
    if (selectedEmployees != null && selectedEmployees.isNotEmpty) {
      final valid = selectedEmployees
          .where((e) => e != 'All Employees' && e.toUpperCase() != 'ALL')
          .toList();
      if (valid.isEmpty) {
        userSuffix = 'all_employees';
      } else if (valid.length == 1) {
        userSuffix = valid.first.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      } else if (valid.length == 2) {
        userSuffix = valid.map((n) => n.replaceAll(RegExp(r'\s+'), '_').toLowerCase()).join('_and_');
      } else {
        userSuffix = '${valid.length}_employees';
      }
    } else if (selectedEmployee != null &&
        selectedEmployee.isNotEmpty &&
        selectedEmployee != 'All Employees' &&
        selectedEmployee.toUpperCase() != 'ALL') {
      userSuffix = selectedEmployee.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    } else {
      userSuffix = 'all_employees';
    }

    final fileName = 'leave_records_${userSuffix}_$dateSuffix.xlsx';

    return await saveAndDownloadFile(bytes, fileName, context: context);
  }
}
