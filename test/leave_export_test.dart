import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/services/leave_export_service.dart';

void main() {
  group('LeaveExportService Unit Tests', () {
    final sampleRequests = [
      LeaveRequest(
        id: 'LR-1001',
        leaveType: 'CL',
        startDate: '2026-09-24',
        endDate: '2026-09-24',
        daysCount: 1,
        days: 1.0,
        status: 'Pending',
        reason: 'Health Issue',
        applicantName: 'Abishek S',
        employeeId: 'EM-1009',
        role: 'EMPLOYEE',
        department: 'Full Stack Dev',
      ),
      LeaveRequest(
        id: 'LR-1002',
        leaveType: 'CASUAL',
        startDate: '2026-09-24',
        endDate: '2026-09-24',
        daysCount: 1,
        days: 1.0,
        status: 'Approved',
        reason: 'Personal medical reasons',
        applicantName: 'Daniel Paul',
        employeeId: 'IN-1001',
        role: 'INTERN',
        department: 'Mobile App Dev',
      ),
      LeaveRequest(
        id: 'LR-1003',
        leaveType: 'SL',
        startDate: '2026-09-24',
        endDate: '2026-09-24',
        daysCount: 1,
        days: 0.5,
        status: 'Approved',
        reason: 'Need to go outside with personal reason',
        applicantName: 'Zubairya Salam Khan',
        employeeId: 'EM-1006',
        role: 'EMPLOYEE',
        department: 'Full Stack Dev',
      ),
      LeaveRequest(
        id: 'LR-1004',
        leaveType: 'WFH',
        startDate: '2026-09-24',
        endDate: '2026-09-24',
        daysCount: 1,
        days: 1.0,
        status: 'Approved',
        reason: 'Personal work',
        applicantName: 'Daniel Paul',
        employeeId: 'IN-1001',
        role: 'INTERN',
        department: 'Mobile App Dev',
      ),
      LeaveRequest(
        id: 'LR-1005',
        leaveType: 'CL',
        startDate: '2026-09-24',
        endDate: '2026-09-24',
        daysCount: 1,
        days: 1.0,
        status: 'Approved',
        reason: "Good morning, Sir. I am currently out of station...",
        applicantName: 'Zubairya Salam Khan',
        employeeId: 'EM-1006',
        role: 'EMPLOYEE',
        department: 'Full Stack Dev',
      ),
      LeaveRequest(
        id: 'LR-1006',
        leaveType: 'SL',
        startDate: '2026-09-24',
        endDate: '2026-09-24',
        daysCount: 1,
        days: 1.0,
        status: 'Approved',
        reason: 'Cold and dizziness.',
        applicantName: 'Raghul Prasath J',
        employeeId: 'EM-1004',
        role: 'EMPLOYEE',
        department: 'Full Stack Dev',
      ),
      LeaveRequest(
        id: 'LR-892',
        leaveType: 'Casual Leave',
        startDate: '2026-09-12',
        endDate: '2026-09-13',
        daysCount: 2,
        days: 2.0,
        status: 'Approved',
        reason: 'Family personal event',
        applicantName: 'Daniel Paul',
        employeeId: 'IN-1001',
        role: 'INTERN',
        department: 'Mobile App Dev',
      ),
    ];

    test('parseDate handles various formats reliably', () {
      final iso = LeaveExportService.parseDate('2026-09-24');
      expect(iso, equals(DateTime(2026, 9, 24)));

      final slash = LeaveExportService.parseDate('24/09/2026');
      expect(slash, equals(DateTime(2026, 9, 24)));

      final natural = LeaveExportService.parseDate('Sep 24, 2026');
      expect(natural, equals(DateTime(2026, 9, 24)));
    });

    test('getRecords filters accurately by selected date range', () {
      // Test exact date range: 2026-09-24 to 2026-09-24
      final exactDayRecords = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        startDate: DateTime(2026, 9, 24),
        endDate: DateTime(2026, 9, 24),
      );
      // All 6 records from 2026-09-24 should be returned, LR-892 (Sep 12-13) excluded
      expect(exactDayRecords.length, equals(6));

      // Test wider date range: 2026-09-01 to 2026-09-30
      final fullMonthRecords = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );
      expect(fullMonthRecords.length, equals(7));

      // Test non-matching date range: October 2026
      final octRecords = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
      );
      expect(octRecords.isEmpty, isTrue);
    });

    test('getRecords filters accurately by single employee and status', () {
      final danielOnly = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        selectedEmployee: 'Daniel Paul',
      );
      expect(danielOnly.length, equals(3));
      expect(danielOnly.every((r) => r.applicantName == 'Daniel Paul'), isTrue);

      final pendingOnly = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        selectedStatus: 'PENDING',
      );
      expect(pendingOnly.length, equals(1));
      expect(pendingOnly.first.applicantName, equals('Abishek S'));
      expect(pendingOnly.first.employeeId, equals('EM-1009'));
    });

    test('getRecords filters accurately by multiple selected employees', () {
      // Select 2 specific users: Abishek S and Zubairya Salam Khan
      final multiUsers = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        selectedEmployees: ['Abishek S', 'Zubairya Salam Khan'],
      );
      // Abishek S (1) + Zubairya Salam Khan (2) = 3 records
      expect(multiUsers.length, equals(3));
      expect(
        multiUsers.every((r) => r.applicantName == 'Abishek S' || r.applicantName == 'Zubairya Salam Khan'),
        isTrue,
      );

      // Select 3 specific users with a date range filter
      final multiWithDate = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        startDate: DateTime(2026, 9, 24),
        endDate: DateTime(2026, 9, 24),
        selectedEmployees: ['Daniel Paul', 'Raghul Prasath J'],
      );
      // Daniel Paul has 2 leaves on Sep 24 (1 CASUAL, 1 WFH)
      // Raghul Prasath J has 1 leave on Sep 24 (1 SL)
      // LR-892 (Daniel Paul on Sep 12) is outside date range so excluded
      expect(multiWithDate.length, equals(3));
      expect(
        multiWithDate.every((r) => r.applicantName == 'Daniel Paul' || r.applicantName == 'Raghul Prasath J'),
        isTrue,
      );
    });

    test('buildCsv produces 10 columns matching user screenshot and UTF-8 BOM', () {
      final records = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        startDate: DateTime(2026, 9, 24),
        endDate: DateTime(2026, 9, 24),
      );

      final csv = LeaveExportService.buildCsv(records, includeBrandingHeader: true);

      // Verify UTF-8 BOM
      expect(csv.startsWith('\uFEFF'), isTrue);

      // Verify Innoveity Tech header branding
      expect(csv.contains('Innoveity Tech - Employee Leave Management Report'), isTrue);

      // Verify exact 10 columns
      expect(
        csv.contains('Applicant,Employee ID,Role,Department,Leave Type,Start Date,End Date,Days,Status,Reason'),
        isTrue,
      );

      // Verify rows from screenshot
      expect(csv.contains('Abishek S,EM-1009,EMPLOYEE,Full Stack Dev,CL,2026-09-24,2026-09-24,1,PENDING,Health Issue'), isTrue);
      expect(csv.contains('Daniel Paul,IN-1001,INTERN,Mobile App Dev,CASUAL,2026-09-24,2026-09-24,1,APPROVED,Personal medical reasons'), isTrue);
      expect(csv.contains('Zubairya Salam Khan,EM-1006,EMPLOYEE,Full Stack Dev,SL,2026-09-24,2026-09-24,0.5,APPROVED'), isTrue);
      expect(csv.contains('Raghul Prasath J,EM-1004,EMPLOYEE,Full Stack Dev,SL,2026-09-24,2026-09-24,1,APPROVED,Cold and dizziness.'), isTrue);
    });

    test('buildExcel produces valid .xlsx byte buffer with brand styling', () {
      final records = LeaveExportService.getRecords(
        requests: sampleRequests,
        allEmployees: [],
        startDate: DateTime(2026, 9, 24),
        endDate: DateTime(2026, 9, 24),
      );

      final excelBytes = LeaveExportService.buildExcel(records);
      expect(excelBytes, isNotNull);
      expect(excelBytes!.isNotEmpty, isTrue);
      // Valid zip/xlsx header magic number: PK (0x50, 0x4B)
      expect(excelBytes[0], equals(0x50));
      expect(excelBytes[1], equals(0x4B));
    });
  });
}
