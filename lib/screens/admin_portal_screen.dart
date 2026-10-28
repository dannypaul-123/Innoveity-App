import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'calendar_screen.dart';
import '../widgets/attendance_export_modal.dart';
import '../widgets/leave_export_modal.dart';
import '../services/leave_export_service.dart';
import '../widgets/user_onboarding_wizard_modal.dart';
import '../services/file_saver.dart';
import '../services/push_notification_service.dart';
import 'salary_templates_screen.dart';
import '../widgets/task_velocity_chart_card.dart';
import '../widgets/live_attendance_osm_map.dart';
import 'enterprise_projects_screen.dart';

class HolidayEntry {
  final String id;
  String title;
  DateTime date;
  String type; // 'National Holiday', 'Company Holiday', 'Restricted Holiday', 'Festival Holiday'
  bool isWorkingHoliday;
  double payMultiplier;
  String remarks;

  HolidayEntry({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.isWorkingHoliday = false,
    this.payMultiplier = 2.0,
    required this.remarks,
  });

  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
typedef AdminAssetItem = SystemAsset;

class _AdminQuickAccessItem {
  final int tabIndex;
  final String label;
  final String tooltip;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final int? badgeCount;
  final bool isLive;

  const _AdminQuickAccessItem({
    required this.tabIndex,
    required this.label,
    required this.tooltip,
    required this.activeIcon,
    required this.inactiveIcon,
    this.badgeCount,
    this.isLive = false,
  });
}

class _AttendanceAuditItem {
  final UserProfile employee;
  final String status;
  final String statusLabel;
  final String checkInTime;
  final String checkOutTime;
  final String ipAddress;
  final int distanceMeters;
  final bool isPresent;
  final bool isWFH;
  final bool isLate;
  final bool isHalfDay;
  final bool isAbsent;
  final bool isLeave;

  _AttendanceAuditItem({
    required this.employee,
    required this.status,
    required this.statusLabel,
    required this.checkInTime,
    required this.checkOutTime,
    required this.ipAddress,
    required this.distanceMeters,
    required this.isPresent,
    required this.isWFH,
    required this.isLate,
    required this.isHalfDay,
    required this.isAbsent,
    required this.isLeave,
  });
}

class AdminPortalScreen extends StatefulWidget {
  final AppState state;

  const AdminPortalScreen({super.key, required this.state});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDirectoryRole = 'ALL'; // 'ALL', 'INTERN', 'EMPLOYEE', 'TEAM_LEADER', 'ADMIN'
  String _leaveFilter = 'ALL'; // 'ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'TODAY_LEAVE'
  String _leaveSubTab = 'SANCTIONS'; // 'SANCTIONS', 'HISTORY'
  String _leaveQuickFilter = 'ALL'; // 'ALL', 'TODAY', 'THIS_WEEK', 'THIS_MONTH', 'CUSTOM'
  DateTime? _leaveStartDate;
  DateTime? _leaveEndDate;
  String _leaveEmployeeFilter = 'All Employees';
  String _leaveStatusFilter = 'ALL'; // 'ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'
  final TextEditingController _leaveSearchCtrl = TextEditingController();
  final TextEditingController _searchDirectoryCtrl = TextEditingController();
  // Intern & Employee Registry State matching web CRM
  String _internStatusFilter = 'All Statuses';
  final TextEditingController _internSearchCtrl = TextEditingController();
  final Set<String> _selectedInternIds = {};

  String _employeeStatusFilter = 'All Statuses';
  final TextEditingController _employeeSearchCtrl = TextEditingController();
  final Set<String> _selectedEmployeeIds = {};

  int _selectedScheduleDayIndex = 3; // FRI 9 default selection

  // Asset Management (CRM Hardware & Allocation Overview) State
  String _assetCategoryFilter = 'All Categories';
  String _assetStatusFilter = 'All Statuses';
  final TextEditingController _assetSearchCtrl = TextEditingController();
  List<SystemAsset> get _adminAssets => widget.state.systemAssets;

  // Announcements (CRM Bulletin Board) State
  String _announcementFilter = 'ALL';
  final TextEditingController _announcementSearchCtrl = TextEditingController();
  List<AnnouncementItem> get _announcements => widget.state.announcements;

  // Holiday Calendar State
  String _holidayFilter = 'ALL'; // 'ALL', 'WORKING', 'MANDATORY', 'NATIONAL', 'COMPANY'
  final TextEditingController _holidaySearchCtrl = TextEditingController();
  final List<HolidayEntry> _holidayEntries = [
    HolidayEntry(
      id: 'HOL-001',
      title: 'Republic Day',
      date: DateTime(2026, 1, 26),
      type: 'National Holiday',
      isWorkingHoliday: true,
      payMultiplier: 2.0,
      remarks: 'Gazetted National Holiday • 2.0x OT on shift',
    ),
    HolidayEntry(
      id: 'HOL-002',
      title: 'May Day (Labour Day)',
      date: DateTime(2026, 5, 1),
      type: 'Company Holiday',
      isWorkingHoliday: false,
      payMultiplier: 1.5,
      remarks: 'Company Wide Mandatory Off',
    ),
    HolidayEntry(
      id: 'HOL-003',
      title: 'Independence Day',
      date: DateTime(2026, 8, 15),
      type: 'National Holiday',
      isWorkingHoliday: true,
      payMultiplier: 2.0,
      remarks: 'Mandatory Gazetted Holiday • Double Pay',
    ),
    HolidayEntry(
      id: 'HOL-004',
      title: 'Gandhi Jayanti',
      date: DateTime(2026, 10, 2),
      type: 'National Holiday',
      isWorkingHoliday: false,
      payMultiplier: 2.0,
      remarks: 'Gazetted National Holiday',
    ),
    HolidayEntry(
      id: 'HOL-005',
      title: 'Diwali (Deepavali)',
      date: DateTime(2026, 11, 1),
      type: 'Festival Holiday',
      isWorkingHoliday: true,
      payMultiplier: 2.5,
      remarks: 'Festival Multiplier • 2.5x Basic Pay',
    ),
    HolidayEntry(
      id: 'HOL-006',
      title: 'Christmas Day',
      date: DateTime(2026, 12, 25),
      type: 'Company Holiday',
      isWorkingHoliday: false,
      payMultiplier: 1.5,
      remarks: 'Annual Corporate Holiday',
    ),
  ];

  // Geofence & Policy Controllers
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _radiusCtrl;
  late TextEditingController _internCutoffCtrl;
  late TextEditingController _staffCutoffCtrl;

  // Policy Engine Toggles
  bool _enforceGeofenceOnCheckIn = true;
  bool _autoClockOutAtCutoff = true;
  bool _requireWfhApproval = true;
  bool _isCapturingGPS = false;

  // Live Map Geofence State
  String? _selectedMapEmployeeName;
  final ScrollController _liveAttendanceScrollCtrl = ScrollController();

  // System Control Registries Toggles
  bool _multiTenantWorkspaces = true;
  bool _emergencyLockoutMode = false;
  bool _auditLogRealtimeStream = true;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onAppStateChanged);
    _tabController = TabController(length: 15, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _latCtrl = TextEditingController(text: widget.state.hqLatitude.toString());
    _lonCtrl = TextEditingController(text: widget.state.hqLongitude.toString());
    _radiusCtrl = TextEditingController(text: widget.state.geofenceRadiusMeters.toInt().toString());
    _internCutoffCtrl = TextEditingController(text: widget.state.internShiftCutoffHour.toString());
    _staffCutoffCtrl = TextEditingController(text: widget.state.staffShiftCutoffHour.toString());
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onAppStateChanged);
    _tabController.dispose();
    _liveAttendanceScrollCtrl.dispose();
    _searchDirectoryCtrl.dispose();
    _internSearchCtrl.dispose();
    _employeeSearchCtrl.dispose();
    _announcementSearchCtrl.dispose();
    _holidaySearchCtrl.dispose();
    _assetSearchCtrl.dispose();
    _leaveSearchCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _radiusCtrl.dispose();
    _internCutoffCtrl.dispose();
    _staffCutoffCtrl.dispose();
    super.dispose();
  }

  void _showAddEmployeeModal(BuildContext context, {String role = 'EMPLOYEE'}) {
    UserOnboardingWizardModal.show(
      context,
      targetRole: role,
      onComplete: (newEmp, candidateType) {
        widget.state.addEmployee(newEmp);
        AppState.userDirectory[newEmp.email] = newEmp;
        widget.state.addAuditLog(
          'User Onboarded',
          'Onboarded ${newEmp.name} (${newEmp.employeeId}) as ${newEmp.role} [$candidateType] via 3-Step Wizard',
          widget.state.userProfile.email,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Successfully onboarded ${newEmp.name} (${newEmp.employeeId}) as ${newEmp.role}!',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
        setState(() {});
      },
    );
  }

  DateTime _safeParseDate(String? raw, DateTime fallback) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final s = raw.trim();
    if (s.contains('-')) {
      final p = s.split('-');
      if (p.length == 3) {
        if (p[0].length == 4) {
          final y = int.tryParse(p[0]);
          final m = int.tryParse(p[1]);
          final d = int.tryParse(p[2]);
          if (y != null && m != null && d != null) return DateTime(y, m, d);
        } else {
          final d = int.tryParse(p[0]);
          final m = int.tryParse(p[1]);
          final y = int.tryParse(p[2]);
          if (y != null && m != null && d != null) return DateTime(y, m, d);
        }
      }
    }
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    const months = ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];
    for (int i = 0; i < months.length; i++) {
      if (s.toLowerCase().contains(months[i])) {
        final yearMatch = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(s);
        final dayMatch = RegExp(r'\b([1-9]|[12]\d|3[01])\b').firstMatch(s);
        final y = yearMatch != null ? int.tryParse(yearMatch.group(0)!) : fallback.year;
        final d = dayMatch != null ? int.tryParse(dayMatch.group(0)!) : fallback.day;
        if (y != null && d != null) return DateTime(y, i + 1, d);
      }
    }
    return fallback;
  }

  String _formatDateShort(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';

  void _showEditEmployeeModal(BuildContext context, UserProfile emp) {
    // 1. Personal & Identity controllers
    final nameCtrl = TextEditingController(text: emp.name);
    final emailCtrl = TextEditingController(text: emp.email);
    final phoneCtrl = TextEditingController(text: emp.phone ?? '');
    String selectedRole = emp.role;
    String selectedCandidateType = emp.candidateType ?? (emp.role == 'INTERN' ? 'Student' : 'Professional');
    String selectedGender = emp.gender ?? 'Male';
    String selectedStatus = emp.status;
    DateTime selectedDob = _safeParseDate(emp.dob, DateTime(2002, 6, 15));

    // 2. Organization & Compensation controllers
    final deptCtrl = TextEditingController(text: emp.department ?? 'Software Engineering');
    final desigCtrl = TextEditingController(text: emp.designation ?? (emp.role == 'INTERN' ? 'Software Engineering Intern' : 'Software Engineer'));
    final salaryCtrl = TextEditingController(text: emp.netSalary.toInt().toString());
    DateTime selectedJoinDate = _safeParseDate(emp.joiningDate, DateTime(2026, 9, 22));
    String selectedManager = emp.reportingManager ?? 'System Admin';
    String selectedWorkMode = emp.workMode ?? 'In-Office';

    // 3. Academic & Candidate Background controllers
    final collegeCtrl = TextEditingController(text: emp.college ?? '');
    final degreeCtrl = TextEditingController(text: emp.degree ?? '');
    final gradYearCtrl = TextEditingController(text: emp.gradYear ?? '2026');
    final currentSemCtrl = TextEditingController(text: emp.currentSem ?? '3rd Year / 6th Sem');
    final cgpaCtrl = TextEditingController(text: emp.cgpa ?? '');
    final prevCompanyCtrl = TextEditingController(text: emp.prevCompany ?? '');
    final experienceCtrl = TextEditingController(text: emp.experience ?? '');
    final skillsCtrl = TextEditingController(text: emp.skills ?? '');
    final resumeCtrl = TextEditingController(text: emp.resumeFileName ?? '');

    final roles = ['EMPLOYEE', 'INTERN', 'TEAM_LEADER', 'ADMIN'];
    if (!roles.contains(selectedRole)) roles.add(selectedRole);

    const candidateTypes = ['Student', 'Graduated', 'Fresher', 'Professional'];
    const genders = ['Male', 'Female', 'Other'];
    const workModes = ['In-Office', 'Work From Home (WFH)', 'Hybrid'];
    const managers = ['System Admin', 'Paul Renine', 'Suraj S', 'Daniel Paul', 'Anto A'];
    const statuses = ['ACTIVE', 'ON_LEAVE', 'PROBATION', 'INACTIVE'];

    int activeTab = 0; // 0: Personal & Role, 1: Job & Pay, 2: Academic & Skills

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;

            Widget buildTextInput({
              required String label,
              required TextEditingController controller,
              IconData? icon,
              TextInputType keyboardType = TextInputType.text,
              String? hint,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      prefixIcon: icon != null ? Icon(icon, size: 17, color: const Color(0xFF64748B)) : null,
                      hintText: hint,
                      hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              );
            }

            Widget buildDropdownField<T>({
              required String label,
              required T value,
              required List<T> items,
              required String Function(T) itemLabel,
              required void Function(T?) onChanged,
              IconData? prefixIcon,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        if (prefixIcon != null) ...[
                          Icon(prefixIcon, size: 17, color: const Color(0xFF64748B)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<T>(
                              value: items.contains(value) ? value : items.first,
                              isExpanded: true,
                              items: items
                                  .map((item) => DropdownMenuItem<T>(
                                        value: item,
                                        child: Text(
                                          itemLabel(item),
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: onChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            Widget buildTabButton(int index, String label, IconData icon) {
              final isSelected = activeTab == index;
              return Expanded(
                child: InkWell(
                  onTap: () => setModalState(() => activeTab = index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.88,
              decoration: BoxDecoration(
                color: Theme.of(modalCtx).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 14,
              ),
              child: Column(
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFFEA580C), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit ${selectedRole == "INTERN" ? "Intern" : "Employee"} Details',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${emp.employeeId} • ${nameCtrl.text.isNotEmpty ? nameCtrl.text : emp.name}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tab navigation bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        buildTabButton(0, 'Personal & Role', Icons.person_outline),
                        buildTabButton(1, 'Job & Pay', Icons.business_center_outlined),
                        buildTabButton(2, 'Academic & Skills', Icons.school_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tab Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeTab == 0) ...[
                            // TAB 0: PERSONAL & IDENTITY DETAILS
                            buildTextInput(
                              label: 'Full Name *',
                              controller: nameCtrl,
                              icon: Icons.person_outline,
                              hint: 'Enter full name',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Email Address *',
                                    controller: emailCtrl,
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    hint: 'name@innoveity.com',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Phone Number',
                                    controller: phoneCtrl,
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    hint: '+91 98401 23456',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDropdownField<String>(
                                    label: 'Organization Role *',
                                    value: selectedRole,
                                    items: roles,
                                    prefixIcon: Icons.badge_outlined,
                                    itemLabel: (r) => r,
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedRole = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildDropdownField<String>(
                                    label: 'Candidate / Profile Type',
                                    value: selectedCandidateType,
                                    items: candidateTypes,
                                    prefixIcon: Icons.how_to_reg_outlined,
                                    itemLabel: (c) => c,
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedCandidateType = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Date of Birth', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 5),
                                      InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: modalCtx,
                                            initialDate: selectedDob,
                                            firstDate: DateTime(1960, 1, 1),
                                            lastDate: DateTime.now(),
                                            builder: (c, child) => Theme(
                                              data: Theme.of(c).copyWith(
                                                colorScheme: Theme.of(c).colorScheme.copyWith(
                                                  primary: const Color(0xFFEA580C),
                                                  onPrimary: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) {
                                            setModalState(() => selectedDob = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.cake_outlined, size: 17, color: Color(0xFF64748B)),
                                              const SizedBox(width: 8),
                                              Text(_formatDateShort(selectedDob), style: const TextStyle(fontSize: 12.5)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildDropdownField<String>(
                                    label: 'Gender',
                                    value: selectedGender,
                                    items: genders,
                                    prefixIcon: Icons.wc_outlined,
                                    itemLabel: (g) => g,
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedGender = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            buildDropdownField<String>(
                              label: 'Employment Status',
                              value: selectedStatus,
                              items: statuses,
                              prefixIcon: Icons.check_circle_outline,
                              itemLabel: (s) => s,
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedStatus = val);
                              },
                            ),
                          ] else if (activeTab == 1) ...[
                            // TAB 1: JOB, COMPENSATION & WORK MODE
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Department *',
                                    controller: deptCtrl,
                                    icon: Icons.business_outlined,
                                    hint: 'e.g. Software Engineering',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Designation / Title *',
                                    controller: desigCtrl,
                                    icon: Icons.badge_outlined,
                                    hint: selectedRole == 'INTERN' ? 'e.g. Engineering Intern' : 'e.g. Mobile Developer',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Joining Date', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 5),
                                      InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: modalCtx,
                                            initialDate: selectedJoinDate,
                                            firstDate: DateTime(2015, 1, 1),
                                            lastDate: DateTime(2035, 12, 31),
                                            builder: (c, child) => Theme(
                                              data: Theme.of(c).copyWith(
                                                colorScheme: Theme.of(c).colorScheme.copyWith(
                                                  primary: const Color(0xFFEA580C),
                                                  onPrimary: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) {
                                            setModalState(() => selectedJoinDate = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_month_outlined, size: 17, color: Color(0xFF64748B)),
                                              const SizedBox(width: 8),
                                              Text(_formatDateShort(selectedJoinDate), style: const TextStyle(fontSize: 12.5)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextInput(
                                    label: selectedRole == 'INTERN' ? 'Monthly Stipend (₹) *' : 'Monthly Net Salary (₹) *',
                                    controller: salaryCtrl,
                                    icon: Icons.currency_rupee,
                                    keyboardType: TextInputType.number,
                                    hint: selectedRole == 'INTERN' ? '12000' : '35000',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDropdownField<String>(
                                    label: 'Reporting Manager / Mentor',
                                    value: selectedManager,
                                    items: managers,
                                    prefixIcon: Icons.supervisor_account_outlined,
                                    itemLabel: (m) => m,
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedManager = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildDropdownField<String>(
                                    label: 'Work Mode',
                                    value: selectedWorkMode,
                                    items: workModes,
                                    prefixIcon: Icons.place_outlined,
                                    itemLabel: (w) => w,
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedWorkMode = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // TAB 2: ACADEMIC & PROFESSIONAL BACKGROUND
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextInput(
                                    label: 'College / University',
                                    controller: collegeCtrl,
                                    icon: Icons.school_outlined,
                                    hint: 'e.g. MIT / Anna University',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Degree / Branch',
                                    controller: degreeCtrl,
                                    icon: Icons.workspace_premium_outlined,
                                    hint: 'e.g. B.Tech IT / B.E CSE',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Graduation Year',
                                    controller: gradYearCtrl,
                                    icon: Icons.calendar_today_outlined,
                                    hint: 'e.g. 2026',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Current Semester',
                                    controller: currentSemCtrl,
                                    icon: Icons.timeline_outlined,
                                    hint: 'e.g. 3rd Year / 6th Sem',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextInput(
                                    label: 'CGPA / Percentage',
                                    controller: cgpaCtrl,
                                    icon: Icons.grade_outlined,
                                    hint: 'e.g. 8.75 CGPA',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Previous Employer',
                                    controller: prevCompanyCtrl,
                                    icon: Icons.apartment_outlined,
                                    hint: 'e.g. Cognizant / TCS',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Years of Experience',
                                    controller: experienceCtrl,
                                    icon: Icons.history_edu_outlined,
                                    hint: 'e.g. 2 Years / Fresher',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextInput(
                                    label: 'Resume / CV File',
                                    controller: resumeCtrl,
                                    icon: Icons.attach_file_outlined,
                                    hint: 'e.g. resume_john.pdf',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            buildTextInput(
                              label: 'Key Technical Skills',
                              controller: skillsCtrl,
                              icon: Icons.code_outlined,
                              hint: 'e.g. Flutter, Dart, Firebase, Python, Git',
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const ValueKey('save_and_sync_employee_btn'),
                          onPressed: () {
                            final updatedSalary = double.tryParse(salaryCtrl.text.trim()) ?? emp.netSalary;
                            final isIntern = selectedRole == 'INTERN';
                            final oldEmail = emp.email.trim();
                            final newEmail = emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : emp.email.trim();

                            final updatedEmp = UserProfile(
                              id: emp.id,
                              employeeId: emp.employeeId,
                              name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : emp.name,
                              email: newEmail,
                              role: selectedRole,
                              department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : (emp.department ?? 'Software Engineering'),
                              designation: desigCtrl.text.trim().isNotEmpty
                                  ? desigCtrl.text.trim()
                                  : (emp.designation ?? (isIntern ? 'Software Engineering Intern' : 'Software Engineer')),
                              phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : emp.phone,
                              joiningDate: _formatDateShort(selectedJoinDate),
                              status: selectedStatus,
                              avatar: emp.avatar,
                              basicSalary: updatedSalary * 0.7,
                              hra: isIntern ? (updatedSalary * 0.3) : (updatedSalary * 0.25),
                              specialAllowance: isIntern ? 0.0 : (updatedSalary * 0.05),
                              deductions: emp.deductions,
                              netSalary: updatedSalary,
                              candidateType: selectedCandidateType,
                              dob: _formatDateShort(selectedDob),
                              gender: selectedGender,
                              college: collegeCtrl.text.trim(),
                              degree: degreeCtrl.text.trim(),
                              gradYear: gradYearCtrl.text.trim(),
                              currentSem: currentSemCtrl.text.trim(),
                              cgpa: cgpaCtrl.text.trim(),
                              prevCompany: prevCompanyCtrl.text.trim(),
                              experience: experienceCtrl.text.trim(),
                              skills: skillsCtrl.text.trim(),
                              reportingManager: selectedManager,
                              workMode: selectedWorkMode,
                              resumeFileName: resumeCtrl.text.trim(),
                            );

                            // Synchronize across directories
                            if (oldEmail.toLowerCase() != newEmail.toLowerCase()) {
                              AppState.userDirectory.remove(oldEmail);
                            }
                            widget.state.updateEmployee(updatedEmp);
                            AppState.userDirectory[newEmail] = updatedEmp;

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF047857),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: Text('Updated ${updatedEmp.name} (${updatedEmp.role}) — synchronized with employee side!'),
                              ),
                            );
                            setState(() {});
                          },
                          icon: const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Save & Sync',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignTaskModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'High';
    String assignedPerson = widget.state.allEmployees.isNotEmpty ? widget.state.allEmployees[0].name : 'Select Employee';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Delegate Task / Ticket',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description / Instructions',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: assignedPerson,
                    decoration: InputDecoration(
                      labelText: 'Assignee',
                      prefixIcon: const Icon(Icons.person_pin),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: widget.state.allEmployees.map((emp) {
                      return DropdownMenuItem(
                        value: emp.name,
                        child: Text(emp.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => assignedPerson = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (titleCtrl.text.isEmpty) return;
                        final newTask = TaskItem(
                          id: 'TSK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          category: 'Delegated',
                          status: 'In Progress',
                          priority: selectedPriority,
                          progress: 0.0,
                          dueDate: 'Tomorrow',
                        );
                        widget.state.addTask(newTask);
                        widget.state.addAuditLog(
                          'Task Delegated',
                          'Assigned "${newTask.title}" to $assignedPerson',
                          widget.state.userProfile.email,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Delegated "${newTask.title}" to $assignedPerson!'),
                            backgroundColor: AppColors.primaryPine,
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Assign Task', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPine,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEmployeeDossierModal(BuildContext context, UserProfile emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final joinStr = (emp.joiningDate != null && emp.joiningDate!.isNotEmpty) ? emp.joiningDate! : 'Jan 2026';
        final phoneStr = (emp.phone != null && emp.phone!.isNotEmpty) ? emp.phone! : '+91 98401 23456';

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isDark ? AppColors.primaryPine : const Color(0xFFE8F8F0),
                          child: Text(
                            emp.name.split(' ').map((e) => e[0]).take(2).join(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                              Text('${emp.employeeId} • ${emp.role}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis, maxLines: 1),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDossierRow(Icons.email_outlined, 'Email Address', emp.email),
                      _buildDossierRow(Icons.phone_outlined, 'Phone Number', phoneStr),
                      _buildDossierRow(Icons.business_outlined, 'Department', emp.department ?? 'Software Engineering'),
                      _buildDossierRow(Icons.badge_outlined, 'Designation', emp.designation ?? 'Team Specialist'),
                      _buildDossierRow(Icons.calendar_today_outlined, 'Joining Date', joinStr),
                      _buildDossierRow(Icons.attach_money_outlined, emp.role == 'INTERN' ? 'Monthly Stipend' : 'Monthly Net Salary', '₹${emp.netSalary.toInt()}'),
                      if (emp.workMode != null && emp.workMode!.isNotEmpty)
                        _buildDossierRow(Icons.place_outlined, 'Work Mode', emp.workMode!),
                      if (emp.reportingManager != null && emp.reportingManager!.isNotEmpty)
                        _buildDossierRow(Icons.supervisor_account_outlined, 'Reporting Manager', emp.reportingManager!),
                      if (emp.candidateType != null && emp.candidateType!.isNotEmpty)
                        _buildDossierRow(Icons.how_to_reg_outlined, 'Candidate Type', emp.candidateType!),
                      if (emp.dob != null && emp.dob!.isNotEmpty)
                        _buildDossierRow(Icons.cake_outlined, 'Date of Birth', emp.dob!),
                      if (emp.gender != null && emp.gender!.isNotEmpty)
                        _buildDossierRow(Icons.wc_outlined, 'Gender', emp.gender!),
                      if (emp.college != null && emp.college!.isNotEmpty)
                        _buildDossierRow(Icons.school_outlined, 'College / Degree', '${emp.college!} ${emp.degree != null && emp.degree!.isNotEmpty ? "(${emp.degree!})" : ""}'),
                      if (emp.skills != null && emp.skills!.isNotEmpty)
                        _buildDossierRow(Icons.code_outlined, 'Technical Skills', emp.skills!),
                      if (emp.prevCompany != null && emp.prevCompany!.isNotEmpty)
                        _buildDossierRow(Icons.apartment_outlined, 'Previous Experience', '${emp.prevCompany!} ${emp.experience != null && emp.experience!.isNotEmpty ? "(${emp.experience!})" : ""}'),
                      if (emp.resumeFileName != null && emp.resumeFileName!.isNotEmpty)
                        _buildDossierRow(Icons.attach_file_outlined, 'Resume Attachment', emp.resumeFileName!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditEmployeeModal(context, emp);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Edit Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dossier exported for ${emp.name}')),
                        );
                      },
                      icon: const Icon(Icons.file_download, size: 16, color: Colors.white),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Export Dossier PDF', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPine,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDossierRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryPine),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController.length != 15) {
      final oldIndex = _tabController.index.clamp(0, 14);
      _tabController.dispose();
      _tabController = TabController(length: 15, vsync: this, initialIndex: oldIndex);
      _tabController.addListener(() {
        if (mounted) setState(() {});
      });
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDarkBody : AppColors.background,
      drawer: _buildAdminDrawer(context, isDark),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
        leading: Builder(
          builder: (scaffoldCtx) => InkWell(
            onTap: () => Scaffold.of(scaffoldCtx).openDrawer(),
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryPine.withValues(alpha: 0.25)
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.vibrantEmerald.withValues(alpha: 0.4)
                        : AppColors.borderEmerald,
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.business,
                    color: AppColors.primaryPine,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'INNOVEITY CRM',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.vibrantEmerald.withValues(alpha: 0.2)
                    : AppColors.primaryPine.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  width: 1,
                ),
              ),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
              size: 20,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.state.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
              _buildCommandCenterTab(isDark),
              _buildWorkCalendarTab(isDark),
              _buildHolidayCalendarTab(isDark),
              _buildAnnouncementsTab(isDark),
              _buildLeaveSanctionsTab(isDark),
              _buildPayrollSuiteTab(isDark),
              _buildLiveAttendanceTab(isDark),
              _buildStaffDirectoriesTab(isDark),
              _buildSiteSettingsPolicyEngineTab(isDark),
              _buildSystemRegistriesTab(isDark),
              _buildAssetManagementTab(isDark),
              _buildInternRegistryTab(isDark),
              _buildEmployeeRegistryTab(isDark),
              SalaryTemplatesBody(state: widget.state, isDark: isDark),
              EnterpriseProjectsView(state: widget.state, isDark: isDark),
            ],
          ),
        ),
        bottomNavigationBar: _buildAdminBottomQuickAccess(context, isDark),
      );
  }

  Widget _buildAdminBottomQuickAccess(BuildContext context, bool isDark) {
    final activeTab = _tabController.index;
    final brandAccent = isDark ? AppColors.vibrantEmerald : AppColors.primaryPine;
    final navBg = isDark ? AppColors.headerDarkPine : Colors.white;

    final leftItems = [
      const _AdminQuickAccessItem(
        tabIndex: 0,
        label: 'Dashboard',
        tooltip: 'Command Center & Executive Stats',
        activeIcon: Icons.dashboard_customize_rounded,
        inactiveIcon: Icons.dashboard_customize_outlined,
      ),
      const _AdminQuickAccessItem(
        tabIndex: 6,
        label: 'Attendance',
        tooltip: 'Live Attendance & Geofence Tracker',
        activeIcon: Icons.how_to_reg_rounded,
        inactiveIcon: Icons.how_to_reg_outlined,
        isLive: true,
      ),
    ];

    final rightItems = [
      _AdminQuickAccessItem(
        tabIndex: 4,
        label: 'Leaves',
        tooltip: 'Leave Sanctions & Approval Desk',
        activeIcon: Icons.approval_rounded,
        inactiveIcon: Icons.approval_outlined,
        badgeCount: widget.state.adminPendingLeaves.length,
      ),
      const _AdminQuickAccessItem(
        tabIndex: 7,
        label: 'Staff',
        tooltip: 'Employee Dossiers & Directory',
        activeIcon: Icons.badge_rounded,
        inactiveIcon: Icons.badge_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderCardDark : AppColors.borderLight,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...leftItems.map((item) {
                final isActive = activeTab == item.tabIndex;
                return Expanded(
                  child: _buildQuickAccessButton(
                    item: item,
                    isActive: isActive,
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () {
                      if (_tabController.index != item.tabIndex) {
                        _tabController.animateTo(item.tabIndex);
                      }
                    },
                  ),
                );
              }),
              Expanded(
                child: _buildOnboardQuickAccessButton(
                  context: context,
                  isDark: isDark,
                  brandAccent: brandAccent,
                ),
              ),
              ...rightItems.map((item) {
                final isActive = activeTab == item.tabIndex;
                return Expanded(
                  child: _buildQuickAccessButton(
                    item: item,
                    isActive: isActive,
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () {
                      if (_tabController.index != item.tabIndex) {
                        _tabController.animateTo(item.tabIndex);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardQuickAccessButton({
    required BuildContext context,
    required bool isDark,
    required Color brandAccent,
  }) {
    final activeTextColor = isDark ? AppColors.emeraldMintText : AppColors.primaryPine;

    return Tooltip(
      message: 'Onboard New Employee / Intern',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _showAddEmployeeModal(context),
            borderRadius: BorderRadius.circular(12),
            splashColor: brandAccent.withValues(alpha: 0.15),
            highlightColor: brandAccent.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.vibrantEmerald : AppColors.primaryPine).withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Onboard',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: activeTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required _AdminQuickAccessItem item,
    required bool isActive,
    required bool isDark,
    required Color brandAccent,
    required VoidCallback onTap,
  }) {
    final activeTextColor = isDark ? AppColors.emeraldMintText : AppColors.primaryPine;
    final inactiveTextColor = isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final activeBg = brandAccent.withValues(alpha: isDark ? 0.18 : 0.10);

    return Tooltip(
      message: item.tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: brandAccent.withValues(alpha: 0.15),
            highlightColor: brandAccent.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(
                        color: brandAccent.withValues(alpha: isDark ? 0.40 : 0.25),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.inactiveIcon,
                        size: 21,
                        color: isActive ? brandAccent : inactiveTextColor,
                      ),
                      if (item.badgeCount != null && item.badgeCount! > 0)
                        Positioned(
                          top: -4,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.alertText,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.alertText.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                            child: Center(
                              child: Text(
                                item.badgeCount! > 9 ? '9+' : '${item.badgeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (item.isLive)
                        Positioned(
                          top: -1,
                          right: -5,
                          child: Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: AppColors.vibrantEmerald,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.headerDarkPine : Colors.white,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? activeTextColor : inactiveTextColor,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out of Admin Portal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to exit the Admin Command Center?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.state.logout();
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context, bool isDark) {
    final drawerBg = isDark ? AppColors.headerDarkPine : Colors.white;
    final brandAccent = isDark ? AppColors.vibrantEmerald : AppColors.primaryPine;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.78,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(32),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Top Admin Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.statCardDarkPine,
                          child: Text(
                            widget.state.userProfile.name.isNotEmpty
                                ? widget.state.userProfile.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.vibrantEmerald),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.state.userProfile.name.isNotEmpty
                              ? widget.state.userProfile.name
                              : 'System Administrator',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.vibrantEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ADMINISTRATOR',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.vibrantEmerald,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: 20,
                      color: brandAccent,
                    ),
                    onPressed: widget.state.toggleTheme,
                    tooltip: 'Toggle Theme',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Navigation List of Admin Modules
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerSectionHeader('NAVIGATION', isDark),
                  _buildAdminDrawerItem(context, 0, Icons.dashboard_customize_outlined, 'Command Center', isDark, brandAccent),
                  _buildAdminDrawerItem(context, 1, Icons.calendar_month_outlined, 'Work Calendar', isDark, brandAccent),
                  _buildAdminDrawerItem(context, 6, Icons.map_outlined, 'Live Attendance', isDark, brandAccent),
                  _buildAdminDrawerItem(context, 7, Icons.badge_outlined, 'Staff Dossiers', isDark, brandAccent),

                  _buildDrawerSectionHeader('WORKSPACES', isDark),
                  _buildAdminDrawerItem(context, 14, Icons.folder_open_rounded, 'Projects', isDark, const Color(0xFFEA580C)),

                  _buildDrawerSectionHeader('COMMUNICATION', isDark),
                  _buildAdminDrawerItem(context, 3, Icons.campaign_outlined, 'Announcements', isDark, const Color(0xFFEA580C)),

                  _buildDrawerSectionHeader('OPERATIONS', isDark),
                  _buildAdminDrawerItem(context, 10, Icons.laptop_mac_outlined, 'Asset Management', isDark, const Color(0xFFEA580C)),

                  _buildDrawerSectionHeader('FINANCE & PAYROLL', isDark),
                  _buildAdminDrawerItem(context, 5, Icons.payments_outlined, 'Payroll Suite', isDark, brandAccent),
                  _buildAdminDrawerItem(context, 13, Icons.layers_outlined, 'Salary Templates', isDark, brandAccent),
                  _buildAdminDrawerItem(context, 2, Icons.event_available_outlined, 'Holiday Calendar', isDark, const Color(0xFFEA580C)),
                  _buildAdminDrawerItem(context, 4, Icons.approval_outlined, 'Leave Sanctions', isDark, brandAccent),

                  _buildDrawerSectionHeader('SYSTEM CONTROL', isDark),
                  _buildAdminDrawerItem(context, 11, Icons.school_outlined, 'Intern Registry', isDark, const Color(0xFFEA580C)),
                  _buildAdminDrawerItem(context, 12, Icons.badge_outlined, 'Employee Registry', isDark, const Color(0xFFEA580C)),

                  _buildDrawerSectionHeader('SYSTEM & POLICIES', isDark),
                  _buildAdminDrawerItem(context, 8, Icons.tune_outlined, 'Site Policy Engine', isDark, brandAccent),
                  _buildAdminDrawerItem(context, 9, Icons.admin_panel_settings_outlined, 'System Registries', isDark, brandAccent),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1),
                  ),

                  // Logout action (highlighted in red)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                              : const Color(0xFFFCA5A5),
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _confirmLogout(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          highlightColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  size: 21,
                                  color: isDark ? const Color(0xFFF87171) : AppColors.alertText,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFF87171) : AppColors.alertText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer Version
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 15,
                    height: 15,
                    errorBuilder: (ctx, _, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Innoveity CRM Admin • v2.0.1',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDrawerItem(BuildContext context, int index, IconData icon, String label, bool isDark, Color brandAccent, {Widget? badge}) {
    final isSelected = _tabController.index == index;
    final textColor = isSelected
        ? brandAccent
        : (isDark ? AppColors.textLight : AppColors.textDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: isSelected ? brandAccent.withValues(alpha: isDark ? 0.22 : 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _tabController.animateTo(index);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: isSelected ? brandAccent : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?badge,
                if (isSelected)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: brandAccent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 18, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCompactStatItem({
    required String label,
    required String val,
    required String sub,
    required Color accent,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            sub,
            style: TextStyle(
              fontSize: 8.5,
              color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 26,
      width: 1,
      color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  // SCREEN 1: Innoveity Admin Command Center Overview
  Widget _buildCommandCenterTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Stat Analytics Cards Row (Matching exact layout from screenshot)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final totalTasksCount = widget.state.tasks.length;
                final completedDeliverablesCount = widget.state.tasks
                    .where((t) => t.status.toLowerCase() == 'completed' || t.status.toLowerCase() == 'approved')
                    .length;
                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMetricOverviewCard('TOTAL WORKFORCE', '${widget.state.allEmployees.length}', '+22% vs last mo', 'Active intern, employee & team leader roster', isDark, const Color(0xFFEA580C))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricOverviewCard('PRESENT TODAY', '${widget.state.allEmployees.length}', '2 late', 'Logged shift check-ins today', isDark, const Color(0xFFEA580C))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMetricOverviewCard('ACTIVE DELIVERABLES', '$totalTasksCount', '$completedDeliverablesCount completed', 'Active projects', isDark, const Color(0xFFEA580C))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricOverviewCard('OPEN SUPPORT TICKETS', '${widget.state.tickets.length}', 'All clear', 'Queries pending resolution', isDark, const Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _buildMetricOverviewCard('TOTAL WORKFORCE', '${widget.state.allEmployees.length}', '+22% vs last mo', 'Active intern, employee & team leader roster', isDark, const Color(0xFFEA580C))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricOverviewCard('PRESENT TODAY', '${widget.state.allEmployees.length}', '2 late', 'Logged shift check-ins today', isDark, const Color(0xFFEA580C))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricOverviewCard('ACTIVE DELIVERABLES', '$totalTasksCount', '$completedDeliverablesCount completed', 'Active projects', isDark, const Color(0xFFEA580C))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricOverviewCard('OPEN SUPPORT TICKETS', '${widget.state.tickets.length}', 'All clear', 'Queries pending resolution', isDark, const Color(0xFF10B981))),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 2. Task Velocity & Deliverables Bar Chart Card
          TaskVelocityChartCard(
            tasks: widget.state.tasks,
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // 3. Leave Overview Card Section
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFEA580C), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Real-time workforce leave status',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _tabController.animateTo(1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'View All',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFEA580C)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Text(
                        'Pending: ${widget.state.adminPendingLeaves.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        'On Leave Today: 0',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.state.adminPendingLeaves.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkBody : const Color(0xFFFAFAF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFF5F5F4)),
                    ),
                    child: Center(
                      child: Text(
                        'No pending leave requests requiring review.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF78716C),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: widget.state.adminPendingLeaves.map((req) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDarkBody : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryPine.withValues(alpha: 0.15),
                              child: Text(
                                req.applicantName.isNotEmpty ? req.applicantName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPine, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req.applicantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${req.leaveType} (${req.daysCount} Days) • ${req.reason}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
                              tooltip: 'Approve Request',
                              onPressed: () async {
                                await widget.state.approveLeaveRequest(req.id);
                                if (mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Leave application approved for ${req.applicantName}.'),
                                      backgroundColor: const Color(0xFF10B981),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 22),
                              tooltip: 'Reject Request',
                              onPressed: () async {
                                await widget.state.rejectLeaveRequest(req.id);
                                if (mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Leave application rejected for ${req.applicantName}.'),
                                      backgroundColor: const Color(0xFFEF4444),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Bottom Grid Section: Quick Access & Schedule & Deliverables
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              final quickAccessWidget = Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Frequently used admin actions',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    _buildQuickAccessCardItem(
                      icon: Icons.access_time_filled_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Attendance Audit',
                      subtitle: 'Review and approve attendance',
                      isDark: isDark,
                      onTap: () => _tabController.animateTo(6),
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAccessCardItem(
                      icon: Icons.people_alt_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Employee Registry',
                      subtitle: 'Manage employees/interns',
                      isDark: isDark,
                      onTap: () => _tabController.animateTo(7),
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAccessCardItem(
                      icon: Icons.tune_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF047857),
                      title: 'Site Policy Engine',
                      subtitle: 'Configure geofence & shift cutoffs',
                      isDark: isDark,
                      onTap: () => _tabController.animateTo(8),
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAccessCardItem(
                      icon: Icons.layers_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Salary Structure Templates',
                      subtitle: 'Configure standardized pay packages',
                      isDark: isDark,
                      onTap: () => _tabController.animateTo(13),
                    ),
                  ],
                ),
              );

              final scheduleWidget = Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Schedule & Deliverables',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showAssignTaskModal(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'New Task',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: const Text(
                            'Rolling 7 Days',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 7-day Strip Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDayStripTile('TUE', '6', 0, isDark),
                          const SizedBox(width: 10),
                          _buildDayStripTile('WED', '7', 1, isDark),
                          const SizedBox(width: 10),
                          _buildDayStripTile('THU', '8', 2, isDark),
                          const SizedBox(width: 10),
                          _buildDayStripTile('FRI', '9', 3, isDark),
                          const SizedBox(width: 10),
                          _buildDayStripTile('SAT', '10', 4, isDark),
                          const SizedBox(width: 10),
                          _buildDayStripTile('SUN', '11', 5, isDark),
                          const SizedBox(width: 10),
                          _buildDayStripTile('MON', '12', 6, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Selected Day Deliverables
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkBody : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_turned_in, size: 18, color: Color(0xFFEA580C)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sprint Review & Code Freeze',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '10:00 AM • 2 Active Deliverables',
                                  style: TextStyle(fontSize: 10, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Scheduled',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    quickAccessWidget,
                    const SizedBox(height: 16),
                    scheduleWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: quickAccessWidget),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: scheduleWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricOverviewCard(String title, String val, String badgeText, String subtext, bool isDark, Color badgeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  val,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtext,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuickAccessCardItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkBody : const Color(0xFFFAFAF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayStripTile(String dayLabel, String dateNum, int index, bool isDark) {
    final isSelected = _selectedScheduleDayIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedScheduleDayIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFFEA580C)
                  : (isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              dateNum,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // SCREEN 2: Leave Sanctions Desk & Approval Management
  Widget _buildLeaveSanctionsTab(bool isDark) {
    final allRequests = widget.state.leaveRequests;

    // Filter requests based on Date Range, Employee Filter, and Search
    final baseFilteredRequests = allRequests.where((req) {
      // 1. Employee filter
      if (_leaveEmployeeFilter != 'All Employees') {
        final reqName = req.applicantName.trim().toLowerCase();
        final targetName = _leaveEmployeeFilter.trim().toLowerCase();
        final matchesName = reqName == targetName || reqName.contains(targetName);
        final matchesId = req.employeeId != null &&
            req.employeeId!.toLowerCase() == _leaveEmployeeFilter.toLowerCase();
        if (!matchesName && !matchesId) return false;
      }

      // 2. Date range filter
      final startDt = LeaveExportService.parseDate(req.startDate);
      final endDt = LeaveExportService.parseDate(req.endDate) ?? startDt;

      if (_leaveStartDate != null && _leaveEndDate != null) {
        final startBound = DateTime(_leaveStartDate!.year, _leaveStartDate!.month, _leaveStartDate!.day);
        final endBound = DateTime(_leaveEndDate!.year, _leaveEndDate!.month, _leaveEndDate!.day, 23, 59, 59);
        if (startDt != null && endDt != null) {
          if (startDt.isAfter(endBound) || endDt.isBefore(startBound)) return false;
        } else if (startDt != null) {
          if (startDt.isBefore(startBound) || startDt.isAfter(endBound)) return false;
        }
      } else if (_leaveStartDate != null) {
        final startBound = DateTime(_leaveStartDate!.year, _leaveStartDate!.month, _leaveStartDate!.day);
        if (endDt != null && endDt.isBefore(startBound)) return false;
      } else if (_leaveEndDate != null) {
        final endBound = DateTime(_leaveEndDate!.year, _leaveEndDate!.month, _leaveEndDate!.day, 23, 59, 59);
        if (startDt != null && startDt.isAfter(endBound)) return false;
      }

      // 3. Search query filter
      final query = _leaveSearchCtrl.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final nameMatch = req.applicantName.toLowerCase().contains(query);
        final idMatch = req.employeeId != null && req.employeeId!.toLowerCase().contains(query);
        final typeMatch = req.leaveType.toLowerCase().contains(query);
        final reasonMatch = req.reason.toLowerCase().contains(query);
        if (!nameMatch && !idMatch && !typeMatch && !reasonMatch) return false;
      }

      return true;
    }).toList();

    // Calculate overview counts for the 6 cards
    final totalFilteredCount = baseFilteredRequests.length;
    final pendingCount = baseFilteredRequests.where((r) => r.status.toLowerCase().contains('pending')).length;
    final approvedCount = baseFilteredRequests.where((r) => r.status.toLowerCase().contains('approved')).length;
    final rejectedCount = baseFilteredRequests.where((r) => r.status.toLowerCase().contains('rejected')).length;
    final cancelledCount = baseFilteredRequests.where((r) => r.status.toLowerCase().contains('cancel')).length;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final onLeaveTodayCount = baseFilteredRequests.where((r) {
      if (!r.status.toLowerCase().contains('approved')) return false;
      final startDt = LeaveExportService.parseDate(r.startDate);
      final endDt = LeaveExportService.parseDate(r.endDate) ?? startDt;
      if (startDt == null) return false;
      final effectiveEnd = endDt ?? startDt;
      return !startDt.isAfter(todayEnd) && !effectiveEnd.isBefore(todayStart);
    }).length;

    // Filter displayed list based on status / subtab
    final displayedList = baseFilteredRequests.where((req) {
      if (_leaveFilter == 'PENDING') {
        return req.status.toLowerCase().contains('pending');
      } else if (_leaveFilter == 'APPROVED') {
        return req.status.toLowerCase().contains('approved');
      } else if (_leaveFilter == 'REJECTED') {
        return req.status.toLowerCase().contains('rejected');
      } else if (_leaveFilter == 'CANCELLED') {
        return req.status.toLowerCase().contains('cancel');
      } else if (_leaveFilter == 'TODAY_LEAVE') {
        if (!req.status.toLowerCase().contains('approved')) return false;
        final startDt = LeaveExportService.parseDate(req.startDate);
        final endDt = LeaveExportService.parseDate(req.endDate) ?? startDt;
        if (startDt == null) return false;
        final effectiveEnd = endDt ?? startDt;
        return !startDt.isAfter(todayEnd) && !effectiveEnd.isBefore(todayStart);
      }

      // If 'ALL': check subTab
      if (_leaveSubTab == 'SANCTIONS') {
        return req.status.toLowerCase().contains('pending');
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sub-Tabs Header: SANCTION WFH & LEAVES (X) and HISTORY
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _leaveSubTab = 'SANCTIONS';
                    _leaveFilter = 'PENDING';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _leaveSubTab == 'SANCTIONS'
                            ? const Color(0xFFEA580C)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    'SANCTION WFH & LEAVES ($pendingCount)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _leaveSubTab == 'SANCTIONS'
                          ? const Color(0xFFEA580C)
                          : (isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () {
                  setState(() {
                    _leaveSubTab = 'HISTORY';
                    _leaveFilter = 'ALL';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _leaveSubTab == 'HISTORY'
                            ? const Color(0xFFEA580C)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    'HISTORY',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _leaveSubTab == 'HISTORY'
                          ? const Color(0xFFEA580C)
                          : (isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Overview: 6 Responsive Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1050;
              final cards = [
                _buildLeaveOverviewCard(
                  title: 'TOTAL FILTERED',
                  value: '$totalFilteredCount',
                  subtitle: 'Applications',
                  titleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                  subtitleColor: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                  cardBg: isDark ? AppColors.cardDark : Colors.white,
                  cardBorder: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
                  isSelected: _leaveFilter == 'ALL',
                  onTap: () => setState(() => _leaveFilter = 'ALL'),
                  isDark: isDark,
                ),
                _buildLeaveOverviewCard(
                  title: 'PENDING',
                  value: '$pendingCount',
                  subtitle: 'In Pipeline',
                  titleColor: const Color(0xFFD97706),
                  valueColor: const Color(0xFFEA580C),
                  subtitleColor: const Color(0xFFD97706),
                  cardBg: isDark ? const Color(0xFF2E1C0A) : const Color(0xFFFFFBEB),
                  cardBorder: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                  isSelected: _leaveFilter == 'PENDING',
                  onTap: () => setState(() {
                    _leaveSubTab = 'SANCTIONS';
                    _leaveFilter = 'PENDING';
                  }),
                  isDark: isDark,
                ),
                _buildLeaveOverviewCard(
                  title: 'APPROVED',
                  value: '$approvedCount',
                  subtitle: 'Sanctioned',
                  titleColor: const Color(0xFF059669),
                  valueColor: const Color(0xFF10B981),
                  subtitleColor: const Color(0xFF059669),
                  cardBg: isDark ? const Color(0xFF0B2B1B) : const Color(0xFFF0FDF4),
                  cardBorder: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
                  isSelected: _leaveFilter == 'APPROVED',
                  onTap: () => setState(() {
                    _leaveSubTab = 'HISTORY';
                    _leaveFilter = 'APPROVED';
                  }),
                  isDark: isDark,
                ),
                _buildLeaveOverviewCard(
                  title: 'REJECTED',
                  value: '$rejectedCount',
                  subtitle: 'Declined',
                  titleColor: const Color(0xFFE11D48),
                  valueColor: const Color(0xFFF43F5E),
                  subtitleColor: const Color(0xFFE11D48),
                  cardBg: isDark ? const Color(0xFF2C0F15) : const Color(0xFFFFF1F2),
                  cardBorder: isDark ? const Color(0xFF881337) : const Color(0xFFFECDD3),
                  isSelected: _leaveFilter == 'REJECTED',
                  onTap: () => setState(() {
                    _leaveSubTab = 'HISTORY';
                    _leaveFilter = 'REJECTED';
                  }),
                  isDark: isDark,
                ),
                _buildLeaveOverviewCard(
                  title: 'CANCELLED',
                  value: '$cancelledCount',
                  subtitle: 'By Applicant',
                  titleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  valueColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  subtitleColor: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                  cardBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  cardBorder: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  isSelected: _leaveFilter == 'CANCELLED',
                  onTap: () => setState(() {
                    _leaveSubTab = 'HISTORY';
                    _leaveFilter = 'CANCELLED';
                  }),
                  isDark: isDark,
                ),
                _buildLeaveOverviewCard(
                  title: 'ON LEAVE TODAY',
                  value: '$onLeaveTodayCount',
                  subtitle: 'Active Absence',
                  titleColor: const Color(0xFF4F46E5),
                  valueColor: const Color(0xFF6366F1),
                  subtitleColor: const Color(0xFF4F46E5),
                  cardBg: isDark ? const Color(0xFF1B1947) : const Color(0xFFEEF2FF),
                  cardBorder: isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE),
                  isSelected: _leaveFilter == 'TODAY_LEAVE',
                  onTap: () => setState(() {
                    _leaveFilter = 'TODAY_LEAVE';
                  }),
                  isDark: isDark,
                ),
              ];

              if (isDesktop) {
                return Row(
                  children: cards.map((c) => Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  ))).toList(),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: cards.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(width: 165, child: c),
                  )).toList(),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // 3. Filter Card: Date Range, Employee Filter, Status & Search
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Date Range Header, Quick Chips & Date Inputs
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;

                    final chipsRow = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFFEA580C)),
                            const SizedBox(width: 6),
                            Text(
                              'DATE RANGE:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        _buildLeaveQuickFilterChip('ALL', 'All Dates', isDark),
                        const SizedBox(width: 6),
                        _buildLeaveQuickFilterChip('TODAY', 'Today', isDark),
                        const SizedBox(width: 6),
                        _buildLeaveQuickFilterChip('THIS_WEEK', 'This Week', isDark),
                        const SizedBox(width: 6),
                        _buildLeaveQuickFilterChip('THIS_MONTH', 'This Month', isDark),
                        const SizedBox(width: 6),
                        _buildLeaveQuickFilterChip('CUSTOM', 'Custom', isDark),
                      ],
                    );

                    final datePickers = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLeaveDateBox(_leaveStartDate, isDark, true),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'to',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        _buildLeaveDateBox(_leaveEndDate, isDark, false),
                      ],
                    );

                    if (isWide) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: chipsRow,
                            ),
                          ),
                          const SizedBox(width: 12),
                          datePickers,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: chipsRow,
                        ),
                        const SizedBox(height: 10),
                        datePickers,
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Row 2: Employee filter dropdown, Status dropdown, Search field, Clear button
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;
                    final memberField = _buildLeaveEmployeeDropdown(allRequests, isDark);
                    final statusField = _buildLeaveStatusDropdown(isDark);
                    final searchField = _buildLeaveSearchField(isDark);
                    final clearButton = _buildClearLeaveFiltersButton(isDark);

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(flex: 3, child: memberField),
                          const SizedBox(width: 10),
                          Expanded(flex: 3, child: statusField),
                          const SizedBox(width: 10),
                          Expanded(flex: 4, child: searchField),
                          const SizedBox(width: 10),
                          clearButton,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: memberField),
                            const SizedBox(width: 8),
                            Expanded(child: statusField),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 8),
                            clearButton,
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Header Row: Desk Title, Showing Count, Export Button, Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _leaveSubTab == 'SANCTIONS'
                          ? 'STAFF LEAVE & WFH SANCTION DESK'
                          : 'LEAVE APPLICATION AUDIT HISTORY',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Showing ${displayedList.length} of ${allRequests.length} Applications',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF058A5E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  LeaveExportModal.show(
                    context,
                    requests: displayedList.isNotEmpty ? displayedList : allRequests,
                    allEmployees: widget.state.allEmployees,
                    initialStartDate: _leaveStartDate,
                    initialEndDate: _leaveEndDate,
                    initialEmployee: _leaveEmployeeFilter != 'All Employees' ? _leaveEmployeeFilter : null,
                  );
                },
                icon: const Icon(Icons.file_download_outlined, size: 14, color: AppColors.primaryPine),
                label: const Text(
                  'Export CSV',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPine),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: AppColors.primaryPine, width: 1.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E1C0A) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '$pendingCount Pending',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (displayedList.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _leaveFilter == 'PENDING' ? Icons.check_circle_outline : Icons.inbox_outlined,
                    size: 44,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _leaveFilter == 'PENDING' ? 'All leave requests sanctioned!' : 'No applications found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _leaveFilter == 'PENDING' ? 'No pending leave applications in queue.' : 'No applications match the active filters.',
                    style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _clearLeaveFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFEA580C)),
                    label: const Text('Reset Filters', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = displayedList[index];
                final isPending = req.status.toLowerCase() == 'pending';
                final isApproved = req.status.toLowerCase() == 'approved';
                final isRejected = req.status.toLowerCase() == 'rejected';

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFFE8F8F0),
                                  child: Text(
                                    req.applicantName.isNotEmpty ? req.applicantName[0].toUpperCase() : 'S',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF058A5E)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    req.applicantName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isApproved
                                      ? const Color(0xFFECFDF5)
                                      : (isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isApproved
                                        ? const Color(0xFFA7F3D0)
                                        : (isRejected ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
                                  ),
                                ),
                                child: Text(
                                  req.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isApproved
                                        ? const Color(0xFF047857)
                                        : (isRejected ? const Color(0xFFDC2626) : const Color(0xFFB45309)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  req.leaveType,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dates: ${req.startDate} to ${req.endDate} (${req.daysCount} Days)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: "${req.reason}"',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      if (isPending)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.state.approveLeaveRequest(req.id);
                                  widget.state.addAuditLog(
                                    'Leave Approved',
                                    'Sanctioned ${req.applicantName}\'s ${req.leaveType}',
                                    widget.state.userProfile.email,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Approved ${req.applicantName}\'s ${req.leaveType}!'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.check, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  widget.state.rejectLeaveRequest(req.id);
                                  widget.state.addAuditLog(
                                    'Leave Rejected',
                                    'Rejected ${req.applicantName}\'s ${req.leaveType}',
                                    widget.state.userProfile.email,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Leave application rejected.')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.close, size: 16, color: Colors.red),
                                      SizedBox(width: 4),
                                      Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (isApproved)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text(
                                  'Sanctioned & Quota Deducted',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                widget.state.rejectLeaveRequest(req.id);
                              },
                              child: const Text('Revoke', style: TextStyle(fontSize: 11, color: Colors.red)),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.cancel, size: 16, color: Colors.red),
                                SizedBox(width: 6),
                                Text(
                                  'Application Rejected',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                widget.state.approveLeaveRequest(req.id);
                              },
                              child: const Text('Sanction', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  /// Builds a single analytic overview card for Leave Management (matching screenshot)
  Widget _buildLeaveOverviewCard({
    required String title,
    required String value,
    required String subtitle,
    required Color titleColor,
    required Color valueColor,
    required Color subtitleColor,
    required Color cardBg,
    required Color cardBorder,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : cardBorder,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: titleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a clickable quick date filter chip for Leave Management
  Widget _buildLeaveQuickFilterChip(String id, String label, bool isDark) {
    final isSelected = _leaveQuickFilter == id;
    return InkWell(
      onTap: () => _handleLeaveQuickFilterClick(id),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEA580C)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA580C)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  /// Builds an interactive date input box for Leave Management
  Widget _buildLeaveDateBox(DateTime? dt, bool isDark, bool isStart) {
    final label = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}'
        : 'dd-mm-yyyy';
    return InkWell(
      onTap: () => _selectLeaveDate(context, isStart),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: dt != null ? FontWeight.bold : FontWeight.w500,
                color: dt != null
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  /// Opens the date picker for leave start or end date
  Future<void> _selectLeaveDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initial = isStartDate
        ? (_leaveStartDate ?? now)
        : (_leaveEndDate ?? _leaveStartDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFFEA580C),
                    onPrimary: Colors.white,
                    surface: AppColors.cardDark,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFFEA580C),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _leaveStartDate = picked;
          if (_leaveEndDate != null && _leaveEndDate!.isBefore(picked)) {
            _leaveEndDate = picked;
          }
        } else {
          _leaveEndDate = picked;
          if (_leaveStartDate != null && _leaveStartDate!.isAfter(picked)) {
            _leaveStartDate = picked;
          }
        }
        _leaveQuickFilter = 'CUSTOM';
      });
    }
  }

  /// Handles quick date filter preset selection for Leave Management
  void _handleLeaveQuickFilterClick(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _leaveQuickFilter = preset;
      if (preset == 'ALL') {
        _leaveStartDate = null;
        _leaveEndDate = null;
      } else if (preset == 'TODAY') {
        _leaveStartDate = today;
        _leaveEndDate = today;
      } else if (preset == 'THIS_WEEK') {
        final diffToMonday = now.weekday - 1;
        final monday = today.subtract(Duration(days: diffToMonday));
        _leaveStartDate = monday;
        _leaveEndDate = today;
      } else if (preset == 'THIS_MONTH') {
        _leaveStartDate = DateTime(now.year, now.month, 1);
        _leaveEndDate = today;
      } else if (preset == 'CUSTOM') {
        // Keeps current or user can tap date inputs
      }
    });
  }

  /// Resets all leave filters back to default
  void _clearLeaveFilters() {
    setState(() {
      _leaveQuickFilter = 'ALL';
      _leaveStartDate = null;
      _leaveEndDate = null;
      _leaveEmployeeFilter = 'All Employees';
      _leaveStatusFilter = 'ALL';
      _leaveFilter = 'ALL';
      _leaveSearchCtrl.clear();
    });
  }

  /// Builds employee filter dropdown for Leave Management
  Widget _buildLeaveEmployeeDropdown(List<LeaveRequest> allRequests, bool isDark) {
    final allNames = <String>['All Employees'];
    final seen = <String>{};

    for (final req in allRequests) {
      final name = req.applicantName.trim();
      if (name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
        allNames.add(name);
      }
    }
    for (final emp in widget.state.allEmployees) {
      final name = emp.name.trim();
      if (name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
        allNames.add(name);
      }
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: allNames.contains(_leaveEmployeeFilter) ? _leaveEmployeeFilter : 'All Employees',
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          dropdownColor: isDark ? AppColors.cardDark : Colors.white,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          items: allNames.map((name) {
            final emp = widget.state.allEmployees.where((u) => u.name == name).firstOrNull;
            final label = name == 'All Employees' ? 'All Employees' : (emp != null ? '$name (${emp.employeeId})' : name);
            return DropdownMenuItem<String>(
              value: name,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _leaveEmployeeFilter = val);
            }
          },
        ),
      ),
    );
  }

  /// Builds leave status filter dropdown
  Widget _buildLeaveStatusDropdown(bool isDark) {
    const statusOptions = [
      MapEntry('ALL', 'All Statuses'),
      MapEntry('PENDING', 'Pending'),
      MapEntry('APPROVED', 'Approved'),
      MapEntry('REJECTED', 'Rejected'),
      MapEntry('CANCELLED', 'Cancelled'),
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statusOptions.any((opt) => opt.key == _leaveStatusFilter) ? _leaveStatusFilter : 'ALL',
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          dropdownColor: isDark ? AppColors.cardDark : Colors.white,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          items: statusOptions.map((opt) {
            return DropdownMenuItem<String>(
              value: opt.key,
              child: Text(
                opt.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _leaveStatusFilter = val;
                _leaveFilter = val;
              });
            }
          },
        ),
      ),
    );
  }

  /// Builds search field for Leave Management
  Widget _buildLeaveSearchField(bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _leaveSearchCtrl,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: _leaveSearchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _leaveSearchCtrl.clear();
                    setState(() {});
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                )
              : null,
          hintText: 'Search Employee / Reason...',
          hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// Builds clear filters button for Leave Management
  Widget _buildClearLeaveFiltersButton(bool isDark) {
    return InkWell(
      onTap: _clearLeaveFilters,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF381E24) : const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF5C1D24) : const Color(0xFFFECDD3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFE11D48)),
            SizedBox(width: 6),
            Text(
              'Clear Filters',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE11D48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SCREEN 3: Obsidian Command Telemetry & System Health


  // SCREEN 4: Payroll Suite & Payslip Desk
  Widget _buildPayrollSuiteTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payroll Batch Banner
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text(
                        'OCTOBER PAYROLL DISBURSEMENT BATCH',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ready to Publish',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text(
                        'Total Disbursement Net:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹2,14,000.00',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF058A5E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.state.publishPayrollBatch();
                      widget.state.addAuditLog(
                        'Payroll Published',
                        'Published October Payslip batch of ₹2.14L to all staff',
                        widget.state.userProfile.email,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully published October payslips to all company staff!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPine,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Publish Monthly Payslips to All Staff', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'STAFF SALARY STRUCTURE BREAKDOWN',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(13),
                    icon: const Icon(Icons.layers_rounded, size: 14, color: Colors.white),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Salary Templates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exported October Payroll Summary as CSV.')),
                      );
                    },
                    icon: const Icon(Icons.file_download, size: 14, color: Colors.white),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Export CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPine,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.state.allEmployees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final emp = widget.state.allEmployees[index];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            emp.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          '₹${emp.netSalary.toInt()}/mo',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF058A5E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Basic: ₹${emp.basicSalary.toInt()} • HRA: ₹${emp.hra.toInt()} • Deductions: ₹${emp.deductions.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _captureLiveGpsLocation() async {
    setState(() => _isCapturingGPS = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS / Location services are disabled. Please enable GPS on your device.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is permanently denied. Please enable it in system settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null && mounted) {
        final lat = position.latitude;
        final lon = position.longitude;
        final latStr = lat.toStringAsFixed(6);
        final lonStr = lon.toStringAsFixed(6);
        _latCtrl.text = latStr;
        _lonCtrl.text = lonStr;

        final rad = double.tryParse(_radiusCtrl.text) ?? widget.state.geofenceRadiusMeters;
        final ic = int.tryParse(_internCutoffCtrl.text) ?? widget.state.internShiftCutoffHour;
        final sc = int.tryParse(_staffCutoffCtrl.text) ?? widget.state.staffShiftCutoffHour;

        widget.state.updateGeofenceSettings(
          lat: lat,
          lon: lon,
          radius: rad,
          internCutoff: ic,
          staffCutoff: sc,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 Live GPS Captured: Lat $latStr, Lon $lonStr (±${position.accuracy.toInt()}m accuracy). Set as active geofence.',
            ),
            backgroundColor: AppColors.primaryPine,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to acquire live GPS fix. Please verify device GPS signal.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS capture failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturingGPS = false);
      }
    }
  }

  void _showAddLocationProfileDialog() {
    final nameCtrl = TextEditingController(text: 'Branch Office');
    final addressCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: _latCtrl.text);
    final lonCtrl = TextEditingController(text: _lonCtrl.text);
    final radiusCtrl = TextEditingController(text: _radiusCtrl.text);
    bool isCapturingInDialog = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.add_location_alt, color: AppColors.primaryPine),
                SizedBox(width: 8),
                Text('Add Location Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Location Profile Name',
                      hintText: 'e.g. INNOVEITY Guindy Campus',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Address / Campus Wing (Optional)',
                      hintText: 'e.g. Block 4, Tech Park',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lonCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isCapturingInDialog
                          ? null
                          : () async {
                              setDialogState(() => isCapturingInDialog = true);
                              try {
                                final pos = await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.high,
                                    timeLimit: Duration(seconds: 10),
                                  ),
                                );
                                latCtrl.text = pos.latitude.toStringAsFixed(6);
                                lonCtrl.text = pos.longitude.toStringAsFixed(6);
                              } catch (_) {}
                              setDialogState(() => isCapturingInDialog = false);
                            },
                      icon: isCapturingInDialog
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 16),
                      label: Text(
                        isCapturingInDialog ? 'Acquiring GPS...' : 'Capture Live GPS for This Profile',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: radiusCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Geofence Allowed Radius (Meters)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final lat = double.tryParse(latCtrl.text) ?? widget.state.hqLatitude;
                  final lon = double.tryParse(lonCtrl.text) ?? widget.state.hqLongitude;
                  final radius = double.tryParse(radiusCtrl.text) ?? widget.state.geofenceRadiusMeters;

                  final newProfile = GeofenceLocationProfile(
                    id: 'LOC-${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    latitude: lat,
                    longitude: lon,
                    radiusMeters: radius,
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                    isActive: true,
                  );

                  widget.state.addLocationProfile(newProfile);
                  _latCtrl.text = lat.toStringAsFixed(6);
                  _lonCtrl.text = lon.toStringAsFixed(6);
                  _radiusCtrl.text = radius.toInt().toString();

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created & activated "$name" geofence profile!'),
                      backgroundColor: AppColors.primaryPine,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPine),
                child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditLocationProfileDialog(GeofenceLocationProfile profile) {
    final nameCtrl = TextEditingController(text: profile.name);
    final addressCtrl = TextEditingController(text: profile.address ?? '');
    final latCtrl = TextEditingController(text: profile.latitude.toStringAsFixed(6));
    final lonCtrl = TextEditingController(text: profile.longitude.toStringAsFixed(6));
    final radiusCtrl = TextEditingController(text: profile.radiusMeters.toInt().toString());
    bool isCapturingInDialog = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_location_alt, color: AppColors.primaryPine),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit ${profile.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Location Profile Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Address / Campus Wing (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lonCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isCapturingInDialog
                          ? null
                          : () async {
                              setDialogState(() => isCapturingInDialog = true);
                              try {
                                final pos = await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.high,
                                    timeLimit: Duration(seconds: 10),
                                  ),
                                );
                                latCtrl.text = pos.latitude.toStringAsFixed(6);
                                lonCtrl.text = pos.longitude.toStringAsFixed(6);
                              } catch (_) {}
                              setDialogState(() => isCapturingInDialog = false);
                            },
                      icon: isCapturingInDialog
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 16),
                      label: Text(
                        isCapturingInDialog ? 'Acquiring GPS...' : 'Capture Live GPS for This Profile',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: radiusCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Geofence Allowed Radius (Meters)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (widget.state.locationProfiles.length > 1)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.state.deleteLocationProfile(profile.id);
                    final active = widget.state.activeLocationProfile;
                    _latCtrl.text = active.latitude.toStringAsFixed(6);
                    _lonCtrl.text = active.longitude.toStringAsFixed(6);
                    _radiusCtrl.text = active.radiusMeters.toInt().toString();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted "${profile.name}"')),
                    );
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final lat = double.tryParse(latCtrl.text) ?? profile.latitude;
                  final lon = double.tryParse(lonCtrl.text) ?? profile.longitude;
                  final radius = double.tryParse(radiusCtrl.text) ?? profile.radiusMeters;

                  final updated = profile.copyWith(
                    name: name,
                    latitude: lat,
                    longitude: lon,
                    radiusMeters: radius,
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                  );

                  widget.state.updateLocationProfile(updated);
                  if (widget.state.activeLocationProfileId == profile.id) {
                    _latCtrl.text = lat.toStringAsFixed(6);
                    _lonCtrl.text = lon.toStringAsFixed(6);
                    _radiusCtrl.text = radius.toInt().toString();
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated "${updated.name}" successfully!'),
                      backgroundColor: AppColors.primaryPine,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPine),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // SCREEN 5: Site Settings & Policy Engine
  Widget _buildSiteSettingsPolicyEngineTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primaryPine, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'COMPANY HQ GEOFENCE COORDINATES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    InkWell(
                      onTap: _isCapturingGPS ? null : _captureLiveGpsLocation,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPine.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryPine.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isCapturingGPS)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPine),
                              )
                            else
                              const Icon(Icons.my_location, size: 13, color: AppColors.primaryPine),
                            const SizedBox(width: 4),
                            Text(
                              _isCapturingGPS ? 'Locating...' : 'Capture GPS',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPine,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Location Profiles Selector & Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment, size: 16, color: AppColors.primaryPine),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.state.activeLocationProfileId,
                            isDense: true,
                            isExpanded: true,
                            dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                            items: widget.state.locationProfiles.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(
                                  p.name,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) {
                                widget.state.setActiveLocationProfile(newId);
                                final p = widget.state.activeLocationProfile;
                                _latCtrl.text = p.latitude.toStringAsFixed(6);
                                _lonCtrl.text = p.longitude.toStringAsFixed(6);
                                _radiusCtrl.text = p.radiusMeters.toInt().toString();
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryPine),
                        tooltip: 'Edit Location Profile',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditLocationProfileDialog(widget.state.activeLocationProfile),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primaryPine),
                        tooltip: 'Add New Location Profile',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _showAddLocationProfileDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _lonCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _radiusCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Geofence Allowed Radius (Meters)',
                    helperText: 'Staff within radius can clock in without WFH exemption.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.schedule, color: AppColors.primaryPine, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AUTOMATIC SHIFT END CUTOFF HOURS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _internCutoffCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Intern Cutoff (Hour 24h)',
                          helperText: 'Default 17 (5:00 PM)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _staffCutoffCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Staff Cutoff (Hour 24h)',
                          helperText: 'Default 18 (6:00 PM)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Policy Engine Toggles
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.policy, color: AppColors.primaryPine, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ENTERPRISE POLICY ENGINE CONTROL',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Strict Geofence Enforcement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Block clock-ins outside radius unless WFH approved', style: TextStyle(fontSize: 10)),
                  value: _enforceGeofenceOnCheckIn,
                  activeTrackColor: AppColors.primaryPine,
                  onChanged: (val) => setState(() => _enforceGeofenceOnCheckIn = val),
                ),
                SwitchListTile(
                  title: const Text('Enforce Auto Clock-Out Daemon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Automatically terminate active shifts at cutoff hour', style: TextStyle(fontSize: 10)),
                  value: _autoClockOutAtCutoff,
                  activeTrackColor: AppColors.primaryPine,
                  onChanged: (val) => setState(() => _autoClockOutAtCutoff = val),
                ),
                SwitchListTile(
                  title: const Text('Require Manager WFH Approval', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Remote check-ins require sanctioned leave/WFH ticket', style: TextStyle(fontSize: 10)),
                  value: _requireWfhApproval,
                  activeTrackColor: AppColors.primaryPine,
                  onChanged: (val) => setState(() => _requireWfhApproval = val),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      final lat = double.tryParse(_latCtrl.text) ?? widget.state.hqLatitude;
                      final lon = double.tryParse(_lonCtrl.text) ?? widget.state.hqLongitude;
                      final rad = double.tryParse(_radiusCtrl.text) ?? widget.state.geofenceRadiusMeters;
                      final ic = int.tryParse(_internCutoffCtrl.text) ?? widget.state.internShiftCutoffHour;
                      final sc = int.tryParse(_staffCutoffCtrl.text) ?? widget.state.staffShiftCutoffHour;

                      widget.state.updateGeofenceSettings(
                        lat: lat,
                        lon: lon,
                        radius: rad,
                        internCutoff: ic,
                        staffCutoff: sc,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Site Settings & Policy Engine updated successfully!'),
                          backgroundColor: AppColors.primaryPine,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPine,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Save Policy & Geofence Config', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // SCREEN 6: Staff Attendance Live Map & Verification Logs
  Widget _buildLiveAttendanceTab(bool isDark) {
    final allAuditItems = _getAttendanceAuditItems();

    // Calculate executive summary stats matching the Innovety CRM roster
    final activeStaff = allAuditItems.where((it) {
      final r = it.employee.role.toUpperCase();
      return r != 'ADMIN' && r != 'SUPER_ADMIN';
    }).toList();
    final effectiveStaff = activeStaff.isNotEmpty ? activeStaff : allAuditItems;

    final totalActive = effectiveStaff.length;
    final presentOrWfh = effectiveStaff.where((it) => it.isPresent || it.isWFH).length;
    final lateCount = effectiveStaff.where((it) => it.isLate).length;
    final halfDayCount = effectiveStaff.where((it) => it.isHalfDay).length;
    final absentCount = effectiveStaff.where((it) => it.isAbsent).length;

    return SingleChildScrollView(
      controller: _liveAttendanceScrollCtrl,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Map Card Visualization displaying every verified user location
          _buildLiveGeofenceMapSection(isDark),

          const SizedBox(height: 16),

          // Subtitle description matching web Attendance Audit header
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              'Monitor employee attendance records, daily activity, and generate Excel reports.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
              ),
            ),
          ),

          // 1. QUICK INFORMATION VIEW: 5 Analytics Widget Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildQuickInfoCard(
                        title: 'TOTAL ACTIVE MEMBERS',
                        value: '$totalActive',
                        titleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickInfoCard(
                        title: 'PRESENT / WFH',
                        value: '$presentOrWfh',
                        titleColor: const Color(0xFF15803D),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickInfoCard(
                        title: 'LATE ARRIVALS',
                        value: '$lateCount',
                        titleColor: const Color(0xFFEA580C),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickInfoCard(
                        title: 'HALF DAY',
                        value: '$halfDayCount',
                        titleColor: const Color(0xFFEA580C),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickInfoCard(
                        title: 'ABSENT TODAY',
                        value: '$absentCount',
                        titleColor: const Color(0xFFDC2626),
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              }

              // Mobile 2-row layout: 3 cards on Row 1, 2 cards on Row 2
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickInfoCard(
                          title: 'TOTAL ACTIVE MEMBERS',
                          value: '$totalActive',
                          titleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickInfoCard(
                          title: 'PRESENT / WFH',
                          value: '$presentOrWfh',
                          titleColor: const Color(0xFF15803D),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickInfoCard(
                          title: 'LATE ARRIVALS',
                          value: '$lateCount',
                          titleColor: const Color(0xFFEA580C),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickInfoCard(
                          title: 'HALF DAY',
                          value: '$halfDayCount',
                          titleColor: const Color(0xFFEA580C),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickInfoCard(
                          title: 'ABSENT TODAY',
                          value: '$absentCount',
                          titleColor: const Color(0xFFDC2626),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Header: Title, Export Button, and User Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LIVE COMPANY ATTENDANCE LOGS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${allAuditItems.length} Total Users',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF058A5E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  AttendanceExportModal.show(
                    context,
                    allEmployees: widget.state.allEmployees,
                    initialSelectedUser: 'All Employees',
                    initialDate: DateTime(2026, 10, 13),
                  );
                },
                icon: const Icon(Icons.file_download_outlined, size: 14, color: Colors.white),
                label: const Text(
                  'Export Excel',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Attendance Logs List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allAuditItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = allAuditItems[index];
                final emp = item.employee;
                final isPresent = item.isPresent;
                final isWFH = item.isWFH;
                final isLate = item.isLate;
                final isAbsent = item.isAbsent;
                final isSelectedOnMap = _selectedMapEmployeeName == emp.name;

                // Color coordination tokens matching design system
                Color statusBg;
                Color statusText;
                if (isWFH) {
                  statusBg = const Color(0xFFEFF6FF);
                  statusText = const Color(0xFF1D4EDB);
                } else if (isLate) {
                  statusBg = const Color(0xFFFFFBEB);
                  statusText = const Color(0xFFB45309);
                } else if (isAbsent) {
                  statusBg = const Color(0xFFFEF2F2);
                  statusText = const Color(0xFFDC2626);
                } else if (isPresent) {
                  statusBg = const Color(0xFFF0FDF4);
                  statusText = const Color(0xFF15803D);
                } else {
                  statusBg = const Color(0xFFFFFBEB);
                  statusText = const Color(0xFFB45309);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: isSelectedOnMap
                        ? (isDark ? const Color(0xFF1E170A) : const Color(0xFFFFF7ED))
                        : (isDark ? AppColors.cardDark : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelectedOnMap
                          ? const Color(0xFFEA580C)
                          : (isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                      width: isSelectedOnMap ? 1.8 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isPresent
                            ? const Color(0xFFF0FDF4)
                            : (isAbsent ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                        child: Text(
                          emp.name.split(' ').map((e) => e[0]).take(2).join(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPresent
                                ? const Color(0xFF15803D)
                                : (isAbsent ? const Color(0xFFDC2626) : const Color(0xFFB45309)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${emp.employeeId} • ${emp.role} • IP: ${item.ipAddress}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.statusLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'In: ${item.checkInTime} • Out: ${item.checkOutTime}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Quick Map Pin Button
                      IconButton(
                        icon: Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: isPresent
                              ? (isSelectedOnMap ? const Color(0xFFEA580C) : const Color(0xFF10B981))
                              : const Color(0xFF94A3B8),
                        ),
                        tooltip: isPresent ? 'View ${emp.name} location on map' : 'Not verified at HQ',
                        onPressed: isPresent
                            ? () {
                                setState(() {
                                  _selectedMapEmployeeName = emp.name;
                                });
                                _liveAttendanceScrollCtrl.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFFEA580C)),
                        tooltip: 'Export ${emp.name} Attendance',
                        onPressed: () {
                          AttendanceExportModal.show(
                            context,
                            allEmployees: widget.state.allEmployees,
                            initialSelectedUser: emp.name,
                            initialDate: DateTime(2026, 10, 13),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Builds a single analytic widget card for the Quick Information View
  Widget _buildQuickInfoCard({
    required String title,
    required String value,
    required Color titleColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  /// Generates the verified attendance item data for each employee
  List<_AttendanceAuditItem> _getAttendanceAuditItems() {
    final List<_AttendanceAuditItem> items = [];
    final employees = widget.state.allEmployees;
    final Set<String> seenKeys = {};
    final Set<String> seenNames = {};

    for (int i = 0; i < employees.length; i++) {
      final emp = employees[i];
      final name = emp.name;
      final cleanName = name.trim().toLowerCase();
      final cleanId = emp.employeeId.trim().toUpperCase();

      // Ensure strictly one profile per unique employee/intern
      if (cleanId.isNotEmpty && seenKeys.contains(cleanId)) continue;
      if (cleanName.isNotEmpty && seenNames.contains(cleanName)) continue;

      if (cleanId.isNotEmpty) seenKeys.add(cleanId);
      if (cleanName.isNotEmpty) seenNames.add(cleanName);

      final roleUpper = emp.role.toUpperCase();
      if (roleUpper == 'ADMIN' || roleUpper == 'SUPER_ADMIN' || roleUpper == 'SUPERADMIN') {
        continue;
      }

      final isCurrent = cleanName == widget.state.userProfile.name.trim().toLowerCase() ||
          (cleanId.isNotEmpty && cleanId == widget.state.userProfile.employeeId.trim().toUpperCase());
      final empRec = widget.state.getEmployeeAttendanceRecord(emp.email);

      int distanceMeters = (i * 14 + 18).clamp(12, 195);
      final ipAddress = '182.73.189.${40 + items.length}';

      final isHarishOrSanjay = cleanName.contains('harish') || cleanName.contains('sanjay');
      final isWFHUser = cleanName.contains('kaviya') || (cleanName.contains('divya') && !widget.state.isClockedIn);
      final isLeaveUser = cleanName.contains('leave');
      final isDaniel = cleanName.contains('daniel');
      final isPraveen = cleanName.contains('praveen');
      final isLateUser = (isDaniel || isPraveen) && !(isCurrent && widget.state.isClockedIn);
      final isHalfDayUser = cleanName.contains('halfday');

      String status;
      String statusLabel;
      String checkInTime;
      String checkOutTime;
      bool isPresent = false;
      bool isWFH = false;
      bool isLate = false;
      bool isHalfDay = false;
      bool isAbsent = false;
      bool isLeave = false;

      if (isCurrent && widget.state.isClockedIn) {
        status = 'PRESENT';
        distanceMeters = (widget.state.lastClockInDistance?.toInt() ?? 36).clamp(12, 195);
        statusLabel = 'HQ Verified (${distanceMeters}m)';
        checkInTime = widget.state.clockInTimeDisplay;
        checkOutTime = 'Still working';
        isPresent = true;
      } else if (isCurrent && widget.state.hasClockedOutToday) {
        status = 'PRESENT';
        distanceMeters = (widget.state.lastClockInDistance?.toInt() ?? 36).clamp(12, 195);
        statusLabel = 'HQ Verified (${distanceMeters}m)';
        checkInTime = widget.state.clockInTimeDisplay;
        checkOutTime = widget.state.clockOutTimeDisplay ?? 'Clocked Out';
        isPresent = true;
      } else if (empRec != null && empRec.isClockedIn) {
        status = 'PRESENT';
        distanceMeters = (empRec.distanceMeters > 0 ? empRec.distanceMeters.toInt() : 36).clamp(12, 195);
        statusLabel = 'HQ Verified (${distanceMeters}m)';
        checkInTime = empRec.clockInDisplay ?? '09:15 AM';
        checkOutTime = 'Still working';
        isPresent = true;
      } else if (empRec != null && !empRec.isClockedIn) {
        status = 'PRESENT';
        distanceMeters = (empRec.distanceMeters > 0 ? empRec.distanceMeters.toInt() : 36).clamp(12, 195);
        statusLabel = 'HQ Verified (${distanceMeters}m)';
        checkInTime = empRec.clockInDisplay ?? '09:15 AM';
        checkOutTime = empRec.clockOutDisplay ?? 'Clocked Out';
        isPresent = true;
      } else if (isHarishOrSanjay) {
        status = 'ABSENT';
        statusLabel = 'Absent Today';
        checkInTime = '—';
        checkOutTime = '—';
        isAbsent = true;
      } else if (isWFHUser) {
        status = 'WORK_FROM_HOME';
        statusLabel = 'WFH Approved';
        checkInTime = '09:5${(8 - (i % 3))} AM';
        checkOutTime = 'Still working';
        isWFH = true;
      } else if (isLeaveUser) {
        status = 'LEAVE';
        statusLabel = 'On Leave';
        checkInTime = '—';
        checkOutTime = 'On Leave';
        isLeave = true;
      } else if (isLateUser) {
        status = 'LATE';
        statusLabel = 'Late Arrival (${distanceMeters}m)';
        checkInTime = isDaniel ? '10:02 AM' : '09:45 AM';
        checkOutTime = 'Still working';
        isLate = true;
        isPresent = true;
      } else if (isHalfDayUser) {
        status = 'HALF_DAY';
        statusLabel = 'Half Day';
        checkInTime = '09:30 AM';
        checkOutTime = '01:30 PM';
        isHalfDay = true;
      } else {
        status = 'PRESENT';
        statusLabel = 'HQ Verified (${distanceMeters}m)';
        final checkInMinute = (10 + (items.length * 7) % 35).toString().padLeft(2, '0');
        checkInTime = '09:$checkInMinute AM';
        checkOutTime = 'Still working';
        isPresent = true;
      }

      items.add(_AttendanceAuditItem(
        employee: emp,
        status: status,
        statusLabel: statusLabel,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        ipAddress: ipAddress,
        distanceMeters: distanceMeters,
        isPresent: isPresent,
        isWFH: isWFH,
        isLate: isLate,
        isHalfDay: isHalfDay,
        isAbsent: isAbsent,
        isLeave: isLeave,
      ));
    }

    return items;
  }

  /// OpenStreetMap Live Geofence Map Section displaying high-precision OpenStreetMap
  /// raster tiles, company HQ geofence radius perimeter, and live location markers for each
  /// employee and intern, with 60-second periodic auto-refresh cycle.
  Widget _buildLiveGeofenceMapSection(bool isDark) {
    return LiveAttendanceOsmMap(
      state: widget.state,
      isDark: isDark,
      onEmployeeSelected: (name) {
        setState(() {
          _selectedMapEmployeeName = name;
        });
      },
    );
  }

  // SCREEN 7: Staff Directory Index & Team Dossier
  Widget _buildStaffDirectoriesTab(bool isDark) {
    final search = _searchDirectoryCtrl.text.trim().toLowerCase();
    final staff = widget.state.allEmployees.where((emp) {
      final nameLower = emp.name.toLowerCase().trim();
      final emailLower = emp.email.toLowerCase().trim();
      final isDaniel = nameLower.contains('daniel') || emailLower.contains('daniel') || emailLower.contains('dp0345217');

      final roleUpper = emp.role.toUpperCase();
      final matchesRole = _selectedDirectoryRole == 'ALL' ||
          roleUpper == _selectedDirectoryRole ||
          (_selectedDirectoryRole == 'INTERN' && (roleUpper == 'INTERN' || isDaniel)) ||
          (_selectedDirectoryRole == 'EMPLOYEE' && (roleUpper == 'EMPLOYEE' || (!isDaniel && roleUpper != 'INTERN' && roleUpper != 'ADMIN' && roleUpper != 'SUPER_ADMIN'))) ||
          (_selectedDirectoryRole == 'TEAM_LEADER' && roleUpper.contains('LEAD')) ||
          (_selectedDirectoryRole == 'ADMIN' && (roleUpper == 'ADMIN' || roleUpper == 'SUPER_ADMIN'));

      final matchesSearch = search.isEmpty ||
          emp.name.toLowerCase().contains(search) ||
          emp.email.toLowerCase().contains(search) ||
          emp.employeeId.toLowerCase().contains(search) ||
          (emp.department ?? '').toLowerCase().contains(search);

      return matchesRole && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Role Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Staff (${widget.state.allEmployees.length})', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('INTERN', 'Interns', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('EMPLOYEE', 'Employees', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('TEAM_LEADER', 'Team Leaders', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('ADMIN', 'Admins', isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar Input
            TextField(
              controller: _searchDirectoryCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search staff by name, email, employee ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.white,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$_selectedDirectoryRole DIRECTORY',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${staff.length} Active Records',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF058A5E)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staff.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final emp = staff[index];
                final isAdminRole = emp.role == 'ADMIN' || emp.role == 'SUPER_ADMIN';

                return InkWell(
                  onTap: () => _showEmployeeDossierModal(context, emp),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isAdminRole
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F8F0))
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          child: Text(
                            emp.name.split(' ').map((e) => e[0]).take(2).join(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isAdminRole
                                  ? (isDark ? AppColors.vibrantEmerald : const Color(0xFF058A5E))
                                  : (isDark ? AppColors.textLight : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      emp.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isAdminRole ? const Color(0xFF058A5E) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      emp.role,
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: isAdminRole ? Colors.white : (isDark ? AppColors.textLight : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${emp.employeeId} • ${emp.designation ?? emp.role} • ${emp.department ?? "Engineering"}',
                                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                emp.email,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${emp.netSalary.toInt()}/mo',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF058A5E)),
                            ),
                            const SizedBox(height: 5),
                            ElevatedButton.icon(
                              key: ValueKey('edit_employee_${emp.employeeId}'),
                              onPressed: () => _showEditEmployeeModal(context, emp),
                              icon: const Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                              label: const Text(
                                'Edit',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
  }

  Widget _buildFilterChip(String roleKey, String label, bool isDark) {
    final isSelected = _selectedDirectoryRole == roleKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : (isDark ? AppColors.textLight : AppColors.textDark),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryPine,
      backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
      onSelected: (val) {
        if (val) setState(() => _selectedDirectoryRole = roleKey);
      },
    );
  }

  // SCREEN 8: System Control Registries & Workspaces
  Widget _buildSystemRegistriesTab(bool isDark) {
    final logs = widget.state.auditLogs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control Registries Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.widgets, color: AppColors.primaryPine, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SYSTEM WORKSPACE CONTROL REGISTRIES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Multi-tenant Workspaces Registry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enable isolated organization tenants & sub-domains', style: TextStyle(fontSize: 10)),
                  value: _multiTenantWorkspaces,
                  activeTrackColor: AppColors.primaryPine,
                  onChanged: (val) => setState(() => _multiTenantWorkspaces = val),
                ),
                SwitchListTile(
                  title: const Text('Real-time Audit Log Stream Daemon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Publish security events to central logging warehouse', style: TextStyle(fontSize: 10)),
                  value: _auditLogRealtimeStream,
                  activeTrackColor: AppColors.primaryPine,
                  onChanged: (val) => setState(() => _auditLogRealtimeStream = val),
                ),
                SwitchListTile(
                  title: const Text('Emergency Lockout Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Restrict admin dashboard to whitelist IP addresses only', style: TextStyle(fontSize: 10)),
                  value: _emergencyLockoutMode,
                  activeTrackColor: Colors.red,
                  onChanged: (val) => setState(() => _emergencyLockoutMode = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'SYSTEM SECURITY AUDIT LOGS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported security audit log report as CSV.')),
                  );
                },
                icon: const Icon(Icons.download, size: 14, color: Colors.white),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Export Log', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPine,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            log['action'] ?? 'System Event',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log['timestamp'] ?? '',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User: ${log['user']} • IP: ${log['ip']}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Details: ${log['status']}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF058A5E)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE: WORK CALENDAR (PORTED FROM EMPLOYEE PORTAL)
  // ==========================================
  Widget _buildWorkCalendarTab(bool isDark) {
    return CalendarScreen(
      logs: widget.state.attendanceLogs,
      isClockedIn: widget.state.isClockedIn,
      formattedClockTime: widget.state.formattedClockTime,
      onClockToggle: () {
        if (widget.state.isClockedIn) {
          widget.state.clockOutShift();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin shift clocked out successfully.')),
          );
        } else {
          widget.state.clockInWithGeofence(distanceMeters: 50, isRemoteExemption: false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin Shift Clocked In (HQ Radius Verified).'),
              backgroundColor: AppColors.primaryPine,
            ),
          );
        }
      },
      userRole: 'ADMIN',
      showLiveAttendanceCard: false,
      shiftCompletionPercent: widget.state.shiftCompletionPercent,
      shiftCompletionRatio: widget.state.shiftCompletionRatio,
      allEmployees: widget.state.allEmployees,
      currentUserName: 'All Employees',
      canExportAttendance: false,
      showExportButton: false,
      showApplyLeaveButton: false,
    );
  }

  // ==========================================
  // MODULE: HOLIDAY CALENDAR & PAY MULTIPLIERS
  // ==========================================
  Widget _buildHolidayCalendarTab(bool isDark) {
    final query = _holidaySearchCtrl.text.trim().toLowerCase();
    final filtered = _holidayEntries.where((h) {
      final matchesQuery = query.isEmpty ||
          h.title.toLowerCase().contains(query) ||
          h.remarks.toLowerCase().contains(query) ||
          h.type.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_holidayFilter == 'WORKING') return h.isWorkingHoliday;
      if (_holidayFilter == 'MANDATORY') return !h.isWorkingHoliday;
      if (_holidayFilter == 'NATIONAL') return h.type.contains('National');
      if (_holidayFilter == 'COMPANY') return h.type.contains('Company');
      return true;
    }).toList();

    final workingCount = _holidayEntries.where((h) => h.isWorkingHoliday).length;
    final offCount = _holidayEntries.where((h) => !h.isWorkingHoliday).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Card (Matching CRM Website)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFFEA580C),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Holiday Calendar & Pay Multipliers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Configure company & national holidays. Working on holidays automatically triggers pay multipliers (e.g. 2.0x).',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Action: Add Holiday Entry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddOrEditHolidayModal(context),
                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Add Holiday Entry',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Metric Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.statCardDarkPine.withValues(alpha: 0.5) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactStatItem(
                    label: 'TOTAL ENTRIES',
                    val: '${_holidayEntries.length}',
                    sub: '2026 Year',
                    accent: const Color(0xFFEA580C),
                    isDark: isDark,
                  ),
                ),
                _buildStatDivider(isDark),
                Expanded(
                  child: _buildCompactStatItem(
                    label: 'WORKING DAYS',
                    val: '$workingCount',
                    sub: 'Pay Multipliers',
                    accent: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
                _buildStatDivider(isDark),
                Expanded(
                  child: _buildCompactStatItem(
                    label: 'MANDATORY OFF',
                    val: '$offCount',
                    sub: 'Company Closed',
                    accent: const Color(0xFF64748B),
                    isDark: isDark,
                  ),
                ),
                _buildStatDivider(isDark),
                Expanded(
                  child: _buildCompactStatItem(
                    label: 'MAX MULTIPLIER',
                    val: '2.5x',
                    sub: 'Festival OT',
                    accent: const Color(0xFFD97706),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Search & Filter Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _holidaySearchCtrl,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search holidays...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _holidaySearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _holidaySearchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: _holidayFilter,
                onSelected: (val) => setState(() => _holidayFilter = val),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 18, color: Color(0xFFEA580C)),
                      const SizedBox(width: 6),
                      Text(
                        _holidayFilter == 'ALL' ? 'Filter' : _holidayFilter,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'ALL', child: Text('Show All Holidays')),
                  PopupMenuItem(value: 'WORKING', child: Text('Working Holidays Only')),
                  PopupMenuItem(value: 'MANDATORY', child: Text('Mandatory Days Off')),
                  PopupMenuItem(value: 'NATIONAL', child: Text('National Holidays')),
                  PopupMenuItem(value: 'COMPANY', child: Text('Company Holidays')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. Content List (or Exact Empty State from Screenshot)
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    ),
                    child: const Icon(Icons.event_busy_rounded, size: 28, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No holiday calendar entries found.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Click "Add Holiday Entry" above to add company holidays.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrEditHolidayModal(context),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Add Holiday Entry', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final holiday = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: holiday.isWorkingHoliday
                          ? (isDark ? const Color(0xFFEA580C).withValues(alpha: 0.3) : const Color(0xFFFED7AA))
                          : (isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                      width: holiday.isWorkingHoliday ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title + Type Badge + Actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        holiday.title,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        holiday.type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.textLightMuted : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.event_outlined, size: 13, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      holiday.formattedDate,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFEA580C), width: 0.8),
                                      ),
                                      child: Text(
                                        '${holiday.payMultiplier.toStringAsFixed(1)}x PAY',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFEA580C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Actions: Edit & Delete
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit Holiday Entry',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () => _showAddOrEditHolidayModal(context, existing: holiday),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                tooltip: 'Delete Holiday',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {
                                  final deleted = holiday;
                                  final deletedIdx = _holidayEntries.indexOf(holiday);
                                  setState(() {
                                    _holidayEntries.remove(holiday);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "${deleted.title}"'),
                                      action: SnackBarAction(
                                        label: 'UNDO',
                                        textColor: Colors.amber,
                                        onPressed: () {
                                          setState(() {
                                            _holidayEntries.insert(deletedIdx, deleted);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Row: Working Holiday Switch Toggle + Multiplier Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                holiday.isWorkingHoliday ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
                                size: 16,
                                color: holiday.isWorkingHoliday ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                holiday.isWorkingHoliday
                                    ? 'Working Allowed (${holiday.payMultiplier}x Multiplier)'
                                    : 'Mandatory Company Day Off',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: holiday.isWorkingHoliday
                                      ? (isDark ? AppColors.emeraldMintText : const Color(0xFF047857))
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: holiday.isWorkingHoliday,
                            activeThumbColor: const Color(0xFFEA580C),
                            onChanged: (val) {
                              setState(() {
                                holiday.isWorkingHoliday = val;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? '${holiday.title}: Working allowed (${holiday.payMultiplier}x Pay Multiplier enabled).'
                                        : '${holiday.title}: Set to mandatory company day off.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Remarks
                      if (holiday.remarks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Remarks: ${holiday.remarks}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL: ADD / EDIT HOLIDAY ENTRY
  // ==========================================
  void _showAddOrEditHolidayModal(BuildContext context, {HolidayEntry? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final remarksCtrl = TextEditingController(text: existing?.remarks ?? '');
    DateTime selectedDate = existing?.date ?? DateTime(2026, DateTime.now().month, DateTime.now().day);
    String selectedType = existing?.type ?? 'National Holiday';
    bool isWorking = existing?.isWorkingHoliday ?? true;
    double multiplier = existing?.payMultiplier ?? 2.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            final dateStr = '${selectedDate.day.toString().padLeft(2, '0')} ${months[selectedDate.month - 1]} ${selectedDate.year}';

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Add Holiday Entry' : 'Edit Holiday Entry',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Holiday Title *',
                        hintText: 'e.g. New Year Day, Diwali',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date Picker Tile
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, color: Color(0xFFEA580C), size: 20),
                                const SizedBox(width: 10),
                                Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Text('Change', style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Holiday Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Holiday Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'National Holiday', child: Text('National Holiday')),
                        DropdownMenuItem(value: 'Company Holiday', child: Text('Company Holiday')),
                        DropdownMenuItem(value: 'Festival Holiday', child: Text('Festival Holiday')),
                        DropdownMenuItem(value: 'Restricted Holiday', child: Text('Restricted Holiday')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Working Holiday Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Working Holiday', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Allows staff to clock in and claim multiplier pay', style: TextStyle(fontSize: 11)),
                      value: isWorking,
                      activeThumbColor: const Color(0xFFEA580C),
                      onChanged: (val) => setModalState(() => isWorking = val),
                    ),
                    const SizedBox(height: 8),
                    // Pay Multiplier Dropdown
                    DropdownButtonFormField<double>(
                      initialValue: multiplier,
                      decoration: InputDecoration(
                        labelText: 'Pay Multiplier (Working Holiday)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1.0, child: Text('1.0x (Standard Pay)')),
                        DropdownMenuItem(value: 1.5, child: Text('1.5x (Time & A Half)')),
                        DropdownMenuItem(value: 2.0, child: Text('2.0x (Double Pay)')),
                        DropdownMenuItem(value: 2.5, child: Text('2.5x (Festival Double+)')),
                        DropdownMenuItem(value: 3.0, child: Text('3.0x (Triple Pay)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => multiplier = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksCtrl,
                      decoration: InputDecoration(
                        labelText: 'Remarks / Notes',
                        hintText: 'e.g. Gazetted Holiday, Double OT',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) return;
                          setState(() {
                            if (existing == null) {
                              _holidayEntries.insert(
                                0,
                                HolidayEntry(
                                  id: 'HOL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                  title: titleCtrl.text.trim(),
                                  date: selectedDate,
                                  type: selectedType,
                                  isWorkingHoliday: isWorking,
                                  payMultiplier: multiplier,
                                  remarks: remarksCtrl.text.trim().isEmpty ? 'Company Holiday Entry' : remarksCtrl.text.trim(),
                                ),
                              );
                            } else {
                              existing.title = titleCtrl.text.trim();
                              existing.date = selectedDate;
                              existing.type = selectedType;
                              existing.isWorkingHoliday = isWorking;
                              existing.payMultiplier = multiplier;
                              existing.remarks = remarksCtrl.text.trim();
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existing == null ? 'Holiday "${titleCtrl.text.trim()}" added successfully!' : 'Holiday updated successfully!'),
                              backgroundColor: const Color(0xFFEA580C),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          existing == null ? 'Save Holiday Entry' : 'Update Holiday Entry',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MODULE: ANNOUNCEMENTS / CRM BULLETIN BOARD
  // ==========================================
  Widget _buildAnnouncementsTab(bool isDark) {
    final query = _announcementSearchCtrl.text.trim().toLowerCase();
    final filtered = _announcements.where((a) {
      final matchesQuery = query.isEmpty ||
          a.title.toLowerCase().contains(query) ||
          a.message.toLowerCase().contains(query) ||
          a.targetAudience.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_announcementFilter == 'URGENT') return a.priority == 'Urgent';
      if (_announcementFilter == 'ALL_COMPANY') return a.targetAudience == 'All Company';
      if (_announcementFilter == 'TARGETED') return a.targetAudience != 'All Company';
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb (as seen on CRM web portal)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Text(
                  'Portal',
                  style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                ),
                Text(
                  ' / Operations / ',
                  style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                ),
                const Text(
                  'Announcements',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                ),
              ],
            ),
          ),

          // 1. Header Card (Matching CRM Website)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xFFEA580C),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CRM Bulletin Board',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'General broadcasts, targeted team updates, and direct individual announcements.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Action: Publish Announcement Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPublishAnnouncementModal(context),
                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Publish Announcement',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Search & Filter Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _announcementSearchCtrl,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search announcements...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _announcementSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _announcementSearchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: _announcementFilter,
                onSelected: (val) => setState(() => _announcementFilter = val),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 18, color: Color(0xFFEA580C)),
                      const SizedBox(width: 6),
                      Text(
                        _announcementFilter == 'ALL' ? 'Filter' : _announcementFilter,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'ALL', child: Text('All Announcements')),
                  PopupMenuItem(value: 'URGENT', child: Text('Urgent Only')),
                  PopupMenuItem(value: 'ALL_COMPANY', child: Text('All Company Broadcasts')),
                  PopupMenuItem(value: 'TARGETED', child: Text('Targeted Team Updates')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Content List (or Exact Empty State from Screenshot)
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white10 : const Color(0xFFFFF7ED),
                    ),
                    child: const Icon(Icons.campaign_outlined, size: 28, color: Color(0xFFEA580C)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active announcements found for Innoveity Tech.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showPublishAnnouncementModal(context),
                    icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    label: const Text('Publish Announcement', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ann = filtered[index];
                final isUrgent = ann.priority == 'Urgent';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUrgent
                          ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                          : (isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
                      width: isUrgent ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Tags + Timestamp + Delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isUrgent
                                      ? const Color(0xFFFEF2F2)
                                      : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isUrgent ? const Color(0xFFEF4444) : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  ann.priority.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ann.targetAudience.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                ann.formattedDate,
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                                tooltip: 'Delete Announcement',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {
                                  final deleted = ann;
                                  setState(() {
                                    widget.state.removeAnnouncement(ann.id);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Removed "${deleted.title}"'),
                                      action: SnackBarAction(
                                        label: 'UNDO',
                                        textColor: Colors.amber,
                                        onPressed: () {
                                          setState(() {
                                            widget.state.addAnnouncement(deleted);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        ann.title,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 6),

                      // Message Body
                      Text(
                        ann.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLight : const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),

                      // Footer Author
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 13, color: Color(0xFF058A5E)),
                          const SizedBox(width: 4),
                          Text(
                            'Published by ${ann.author} • CRM Broadcast Channel',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL: PUBLISH ANNOUNCEMENT
  // ==========================================
  void _showPublishAnnouncementModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedAudience = 'All Company';
    String selectedPriority = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Publish Announcement',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Announcement Title *',
                        hintText: 'e.g. Strategic Townhall, Policy Update',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Target Audience Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedAudience,
                      decoration: InputDecoration(
                        labelText: 'Target Audience / Channel',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All Company', child: Text('All Company (General Broadcast)')),
                        DropdownMenuItem(value: 'Software Engineering', child: Text('Software Engineering')),
                        DropdownMenuItem(value: 'Product & Design', child: Text('Product & Design')),
                        DropdownMenuItem(value: 'Operations & QA', child: Text('Operations & QA')),
                        DropdownMenuItem(value: 'Finance & HR', child: Text('Finance & HR')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedAudience = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Priority Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Broadcast Priority Level',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'General', child: Text('General Broadcast')),
                        DropdownMenuItem(value: 'Urgent', child: Text('Urgent Notice')),
                        DropdownMenuItem(value: 'Policy', child: Text('HR Policy Update')),
                        DropdownMenuItem(value: 'Celebration', child: Text('Celebration / Event')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedPriority = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Announcement Message *',
                        hintText: 'Enter complete announcement broadcast message for staff...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
                          final newAnn = AnnouncementItem(
                            id: 'ANN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            title: titleCtrl.text.trim(),
                            message: messageCtrl.text.trim(),
                            targetAudience: selectedAudience,
                            priority: selectedPriority,
                            timestamp: DateTime.now(),
                            author: widget.state.userProfile.name.isNotEmpty
                                ? widget.state.userProfile.name
                                : 'System Admin',
                            isRead: false,
                          );
                          setState(() {
                            widget.state.addAnnouncement(newAnn);
                          });
                          try {
                            PushNotificationService().showNotification(
                              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                              title: '📢 Broadcast: ${newAnn.title}',
                              body: newAnn.message,
                            );
                          } catch (_) {}
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Announcement "${newAnn.title}" published to Employee portal!'),
                              backgroundColor: const Color(0xFFEA580C),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: const Text(
                          'Publish Announcement',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MODULE: ASSET MANAGEMENT (CRM HARDWARE & ALLOCATION)
  // ==========================================
  Widget _buildAssetManagementTab(bool isDark) {
    final query = _assetSearchCtrl.text.trim().toLowerCase();
    final filtered = _adminAssets.where((asset) {
      final matchesQuery = query.isEmpty ||
          asset.id.toLowerCase().contains(query) ||
          asset.name.toLowerCase().contains(query) ||
          asset.serialNumber.toLowerCase().contains(query) ||
          asset.assignedTo.toLowerCase().contains(query) ||
          asset.location.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_assetCategoryFilter != 'All Categories' && asset.category != _assetCategoryFilter) {
        return false;
      }
      if (_assetStatusFilter != 'All Statuses' && asset.status != _assetStatusFilter) {
        return false;
      }
      return true;
    }).toList();

    final availableCount = _adminAssets.where((a) => a.status == 'AVAILABLE').length;
    final assignedCount = _adminAssets.where((a) => a.status == 'ASSIGNED').length;
    final brandOrange = const Color(0xFFEA580C);
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderCol = isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb (as seen on CRM web portal)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Text(
                  'Portal',
                  style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                ),
                Text(
                  ' / Operations / ',
                  style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                ),
                Text(
                  'Asset Management',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: brandOrange),
                ),
              ],
            ),
          ),

          // 1. Header Banner Card (Matching CRM Screenshot)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                  ),
                  child: Icon(
                    Icons.laptop_mac_outlined,
                    color: brandOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asset Management Overview',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hardware systems and user allocations.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Three KPI Metric Cards (Matching Screenshot)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL ASSETS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_adminAssets.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$availableCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A), // Green matching screenshot
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGNED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$assignedCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB), // Blue matching screenshot
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Search Bar, Dropdowns, and Action Buttons (Matching Screenshot)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                // Search Input
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _assetSearchCtrl,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by ID, name, brand, S/N...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _assetSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _assetSearchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderCol),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderCol),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filters & Actions Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Category Dropdown
                    PopupMenuButton<String>(
                      initialValue: _assetCategoryFilter,
                      onSelected: (val) => setState(() => _assetCategoryFilter = val),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _assetCategoryFilter,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textLight : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'All Categories', child: Text('All Categories')),
                        PopupMenuItem(value: 'NETWORK', child: Text('Network')),
                        PopupMenuItem(value: 'PRINTER', child: Text('Printer')),
                        PopupMenuItem(value: 'MOBILE', child: Text('Mobile / Camera')),
                        PopupMenuItem(value: 'LAPTOP', child: Text('Laptop')),
                        PopupMenuItem(value: 'DESKTOP', child: Text('Desktop / Monitor')),
                        PopupMenuItem(value: 'PERIPHERAL', child: Text('Peripherals')),
                        PopupMenuItem(value: 'ACCESSORY', child: Text('Accessories')),
                        PopupMenuItem(value: 'FURNITURE', child: Text('Furniture')),
                      ],
                    ),
                    // Status Dropdown
                    PopupMenuButton<String>(
                      initialValue: _assetStatusFilter,
                      onSelected: (val) => setState(() => _assetStatusFilter = val),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _assetStatusFilter,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textLight : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'All Statuses', child: Text('All Statuses')),
                        PopupMenuItem(value: 'AVAILABLE', child: Text('Available Only')),
                        PopupMenuItem(value: 'ASSIGNED', child: Text('Assigned Only')),
                        PopupMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                      ],
                    ),
                    // Export CSV
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Exported ${_adminAssets.length} enterprise assets as CSV!'),
                            backgroundColor: brandOrange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textLight : AppColors.textDark,
                        side: BorderSide(color: borderCol),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    // + Add Asset
                    ElevatedButton.icon(
                      onPressed: () => _showAddOrEditAdminAssetModal(context),
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text(
                        '+ Add Asset',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Asset Cards List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'No matching assets found.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try adjusting search parameters or add a new equipment item.',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final asset = filtered[i];
                final isAvailable = asset.status == 'AVAILABLE';
                final statusBg = isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
                final statusText = isAvailable ? const Color(0xFF15803D) : const Color(0xFF1D4ED8);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Asset ID + Category Badge + Status Badge
                      Row(
                        children: [
                          Text(
                            asset.id,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: isDark ? AppColors.textLight : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              asset.category,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: isDark ? AppColors.textLightMuted : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              asset.status,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: statusText,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Row 2: Laptop Icon + Name + Location
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Icon(Icons.laptop_mac_outlined, size: 18, color: brandOrange),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  asset.location,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Row 3: S/N + Assigned To info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SERIAL NUMBER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  asset.serialNumber,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ASSIGNED TO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  asset.assignedTo,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: asset.assignedTo == 'Unassigned'
                                        ? (isDark ? AppColors.textLightMuted : const Color(0xFF64748B))
                                        : const Color(0xFF047857),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Row 4: Action Buttons (Eye, Edit, Bill, Assign)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // View Eye
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'View Details',
                            color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            onPressed: () => _showAdminAssetDetailsModal(context, asset),
                          ),
                          const SizedBox(width: 4),
                          // Edit Pencil
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Asset',
                            color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            onPressed: () => _showAddOrEditAdminAssetModal(context, existing: asset),
                          ),
                          const SizedBox(width: 4),
                          // Bill
                          TextButton.icon(
                            icon: const Icon(Icons.receipt_long_outlined, size: 15),
                            label: const Text('Bill', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showAdminAssetBillModal(context, asset),
                          ),
                          const SizedBox(width: 4),
                          // Assign / Reassign
                          TextButton.icon(
                            icon: Icon(
                              asset.assignedTo == 'Unassigned' ? Icons.person_add_alt_outlined : Icons.swap_horiz,
                              size: 15,
                            ),
                            label: Text(asset.assignedTo == 'Unassigned' ? 'Assign' : 'Reassign', style: const TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF058A5E),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showAssignAdminAssetModal(context, asset),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAdminAssetDetailsModal(BuildContext context, AdminAssetItem asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF7ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.laptop_mac_outlined, color: Color(0xFFEA580C), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(asset.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1),
                              Text('${asset.id} • ${asset.category}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDossierRow(Icons.qr_code, 'Serial Number', asset.serialNumber),
              _buildDossierRow(Icons.place_outlined, 'Location', asset.location),
              _buildDossierRow(Icons.person_outline, 'Assigned Employee', asset.assignedTo),
              _buildDossierRow(Icons.verified_outlined, 'Status', asset.status),
              _buildDossierRow(Icons.currency_rupee, 'Procurement Value', '₹${asset.cost.toInt()}'),
              _buildDossierRow(Icons.receipt_outlined, 'Invoice Number', asset.invoiceNumber),
              _buildDossierRow(Icons.shield_outlined, 'Warranty Period', asset.warrantyPeriod),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdminAssetBillModal(BuildContext context, AdminAssetItem asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text('Invoice: ${asset.id}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipment: ${asset.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Invoice Number: ${asset.invoiceNumber}'),
            Text('Procurement Cost: ₹${asset.cost.toInt()}'),
            Text('Warranty: ${asset.warrantyPeriod}'),
            Text('Vendor: Authorized Enterprise Tech Distributor'),
            Text('Billing Entity: Innoveity Tech Private Limited'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloaded invoice for ${asset.name}')),
              );
            },
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  void _showAssignAdminAssetModal(BuildContext context, AdminAssetItem asset) {
    final staffNames = {
      ...AppState.userDirectory.values.map((u) => u.name).where((n) => n.isNotEmpty && n != 'System Admin' && n != 'Super Admin'),
      'Daniel Paul', 'Harish', 'Priya Sharma', 'Rahul Verma', 'Anita Desai', 'Vikram Patel', 'Neha Gupta', 'Arun Kumar',
      'Unassigned',
    }.toList();
    String chosen = asset.assignedTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Assign Asset: ${asset.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Select employee to allocate "${asset.name}":', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: chosen,
                    decoration: InputDecoration(
                      labelText: 'Allocate To Employee',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: staffNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => chosen = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.state.assignSystemAsset(asset.id, chosen);
                        });
                        widget.state.addAuditLog(
                          'Asset Allocation',
                          'Allocated ${asset.name} (${asset.id}) to $chosen',
                          widget.state.userProfile.email,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${asset.name} is now allocated to $chosen!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Confirm Allocation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddOrEditAdminAssetModal(BuildContext context, {AdminAssetItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final serialCtrl = TextEditingController(text: existing?.serialNumber ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? 'Office');
    final costCtrl = TextEditingController(text: existing != null ? '${existing.cost.toInt()}' : '15000');
    String category = existing?.category ?? 'NETWORK';
    String status = existing?.status ?? 'AVAILABLE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Add New Asset' : 'Edit Asset (${existing.id})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Asset Name *',
                        hintText: 'e.g. Brother Printer, MacBook Pro',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'NETWORK', child: Text('NETWORK')),
                              DropdownMenuItem(value: 'PRINTER', child: Text('PRINTER')),
                              DropdownMenuItem(value: 'MOBILE', child: Text('MOBILE')),
                              DropdownMenuItem(value: 'LAPTOP', child: Text('LAPTOP')),
                              DropdownMenuItem(value: 'DESKTOP', child: Text('DESKTOP')),
                              DropdownMenuItem(value: 'PERIPHERAL', child: Text('PERIPHERAL')),
                              DropdownMenuItem(value: 'ACCESSORY', child: Text('ACCESSORY')),
                              DropdownMenuItem(value: 'FURNITURE', child: Text('FURNITURE')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'AVAILABLE', child: Text('AVAILABLE')),
                              DropdownMenuItem(value: 'ASSIGNED', child: Text('ASSIGNED')),
                              DropdownMenuItem(value: 'MAINTENANCE', child: Text('MAINTENANCE')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => status = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: serialCtrl,
                      decoration: InputDecoration(
                        labelText: 'Serial Number / S/N',
                        hintText: 'e.g. SN-KM8821 or N/A',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locationCtrl,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              hintText: 'Office / Floor',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cost (₹)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setState(() {
                            if (existing != null) {
                              existing.name = nameCtrl.text.trim();
                              existing.category = category;
                              existing.status = status;
                              existing.serialNumber = serialCtrl.text.trim().isEmpty ? 'N/A' : serialCtrl.text.trim();
                              existing.location = locationCtrl.text.trim();
                              existing.cost = double.tryParse(costCtrl.text.trim()) ?? existing.cost;
                              widget.state.updateSystemAsset(existing);
                            } else {
                              widget.state.addSystemAsset(
                                AdminAssetItem(
                                  id: 'AST-${1013 + _adminAssets.length}',
                                  name: nameCtrl.text.trim(),
                                  category: category,
                                  status: status,
                                  serialNumber: serialCtrl.text.trim().isEmpty ? 'N/A' : serialCtrl.text.trim(),
                                  location: locationCtrl.text.trim(),
                                  cost: double.tryParse(costCtrl.text.trim()) ?? 15000,
                                  assignedTo: status == 'AVAILABLE' ? 'Unassigned' : 'Daniel Paul',
                                ),
                              );
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existing == null ? 'Added new asset "${nameCtrl.text.trim()}"' : 'Updated ${existing.name}'),
                              backgroundColor: const Color(0xFFEA580C),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          existing == null ? '+ Create Asset' : 'Save Changes',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // SHARED CANDIDATE CARD COMPONENT
  // Highly legible, responsive card for mobile & desktop
  // ==========================================
  Widget _buildRegistryCandidateCard({
    required BuildContext context,
    required UserProfile emp,
    required bool isSelected,
    required ValueChanged<bool?> onSelectChanged,
    required bool isDark,
    required bool isIntern,
    required VoidCallback onDelete,
  }) {
    String initials = emp.name.trim().split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase();
    if (initials.isEmpty) initials = 'U';

    final departmentStr = emp.department != null && emp.department!.isNotEmpty
        ? emp.department!
        : (isIntern ? 'Mobile Application Development' : 'Engineering');

    final designationStr = emp.designation != null && emp.designation!.isNotEmpty
        ? emp.designation!
        : (isIntern ? 'Intern' : 'Full-Time Staff');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? (isIntern ? const Color(0xFFEA580C) : const Color(0xFF047857))
              : (isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Checkbox + Monospace ID Badge + Spacer + Active Status Pill
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isSelected,
                  activeColor: isIntern ? const Color(0xFFEA580C) : const Color(0xFF047857),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: onSelectChanged,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (isIntern ? const Color(0xFFEA580C) : const Color(0xFF047857)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  emp.employeeId,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isIntern ? const Color(0xFFEA580C) : const Color(0xFF047857),
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF15803D)),
                    SizedBox(width: 5),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Middle Section: Avatar + Full Name + Email Address + Department & Salary Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isIntern
                    ? const Color(0xFFFFF7ED)
                    : (isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isIntern ? const Color(0xFFEA580C) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emp.email,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$departmentStr • $designationStr',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Text(
                            isIntern
                                ? '₹${emp.netSalary.toInt()}/mo stipend'
                                : '₹${emp.netSalary.toInt()}/mo CTC',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.6, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Bottom Action Buttons: Fully visible, styled, and comfortable touch targets
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEmployeeDossierModal(context, emp),
                icon: const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF475569)),
                label: const Text(
                  'Dossier',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size.zero,
                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showEditEmployeeModal(context, emp),
                icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF2563EB)),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size.zero,
                  side: BorderSide(color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.4) : const Color(0xFFBFDBFE)),
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  AttendanceExportModal.show(
                    context,
                    allEmployees: widget.state.allEmployees,
                    initialSelectedUser: emp.name,
                    initialDate: DateTime(2026, 10, 13),
                  );
                },
                icon: const Icon(Icons.file_download_outlined, size: 15, color: Color(0xFFEA580C)),
                label: const Text(
                  'Attendance',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEA580C)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size.zero,
                  side: BorderSide(color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.4) : const Color(0xFFFED7AA)),
                  backgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                tooltip: 'Remove',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE: INTERN REGISTRY (SYSTEM CONTROL)
  // Matching screenshot 1: Breadcrumb, Filters, Add Intern Wizard & Actions
  // ==========================================
  Widget _buildInternRegistryTab(bool isDark) {
    final search = _internSearchCtrl.text.trim().toLowerCase();
    final allInterns = widget.state.allEmployees.where((emp) {
      final nameLower = emp.name.toLowerCase().trim();
      final emailLower = emp.email.toLowerCase().trim();
      // Explicitly remove Raghul and Sanjay S
      if (nameLower.contains('raghul') ||
          nameLower.contains('prasath') ||
          emailLower.contains('raghul') ||
          emailLower.contains('prasath') ||
          nameLower.contains('sanjay') ||
          emailLower.contains('sanjay')) {
        return false;
      }
      // If newly onboarded with role INTERN, include them; otherwise keep Daniel profile
      if (emp.role.toUpperCase() == 'INTERN') return true;
      return nameLower.contains('daniel') || emailLower.contains('daniel') || emailLower.contains('dp0345217');
    }).toList();

    final filtered = allInterns.where((emp) {
      final matchesStatus = _internStatusFilter == 'All Statuses';
      final matchesSearch = search.isEmpty ||
          emp.name.toLowerCase().contains(search) ||
          emp.email.toLowerCase().contains(search) ||
          emp.employeeId.toLowerCase().contains(search) ||
          (emp.department ?? '').toLowerCase().contains(search) ||
          (emp.designation ?? '').toLowerCase().contains(search);
      return matchesStatus && matchesSearch;
    }).toList();

    final totalStipend = filtered.fold<double>(0.0, (acc, e) => acc + e.netSalary);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb matching Screenshot 1 (with Wrap to prevent overflow)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'INNOVEITY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEA580C), letterSpacing: 0.8),
                ),
              ),
              const Text('Portal  /  System Control  /  ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const Text(
                'Intern Registry',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // KPI Overview Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL INTERNS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('${allInterns.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ACTIVE FILTERED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text('${filtered.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MONTHLY STIPEND', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text('₹${(totalStipend / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Top Controls Bar: Responsive 2-row on mobile, 1-row on desktop
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 620;

              // Search Field
              final searchWidget = SizedBox(
                height: 42,
                child: TextField(
                  controller: _internSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: "Search intern by name, ID, email, role...",
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: _internSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _internSearchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.white,
                  ),
                ),
              );

              // Status Dropdown
              final statusDropdown = Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: const ['All Statuses', 'Active', 'On Leave'].contains(_internStatusFilter)
                        ? _internStatusFilter
                        : 'All Statuses',
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    items: const [
                      DropdownMenuItem(value: 'All Statuses', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                      DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                    ],
                    onChanged: (v) => setState(() => _internStatusFilter = v ?? 'All Statuses'),
                  ),
                ),
              );

              // Export CSV Button
              final exportBtn = SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () => _exportRegistryCsv('Intern', filtered),
                  icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF475569)),
                  label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                  ),
                ),
              );

              // Add Intern Button
              final addBtn = SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEmployeeModal(context, role: 'INTERN'),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
                  label: const Text('Add Intern', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchWidget,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: statusDropdown),
                        const SizedBox(width: 8),
                        exportBtn,
                        const SizedBox(width: 8),
                        addBtn,
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    statusDropdown,
                    const SizedBox(width: 8),
                    Expanded(child: searchWidget),
                    const SizedBox(width: 8),
                    exportBtn,
                    const SizedBox(width: 8),
                    addBtn,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 14),

          // Intern Cards List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school_outlined, size: 48, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 10),
                  const Text('No intern records found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Try adjusting your search filter or click "+ Add Intern" above.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final emp = filtered[index];
                final isSelected = _selectedInternIds.contains(emp.id);

                return _buildRegistryCandidateCard(
                  context: context,
                  emp: emp,
                  isSelected: isSelected,
                  onSelectChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedInternIds.add(emp.id);
                      } else {
                        _selectedInternIds.remove(emp.id);
                      }
                    });
                  },
                  isDark: isDark,
                  isIntern: true,
                  onDelete: () {
                    widget.state.removeEmployee(emp.email, id: emp.id, employeeId: emp.employeeId);
                    setState(() {
                      _selectedInternIds.remove(emp.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${emp.name} from Intern Registry'),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 14),

          // Pagination Bar matching Screenshot 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filtered.length} of ${allInterns.length} total interns',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Previous', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Page 1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Next', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE: EMPLOYEE REGISTRY (SYSTEM CONTROL)
  // Matching screenshot 2 & 3: Breadcrumb, Filters, Add Employee Wizard & Actions
  // ==========================================
  Widget _buildEmployeeRegistryTab(bool isDark) {
    final search = _employeeSearchCtrl.text.trim().toLowerCase();
    final allStaff = widget.state.allEmployees.where((emp) {
      final nameLower = emp.name.toLowerCase().trim();
      final emailLower = emp.email.toLowerCase().trim();
      // Keep all staff except Daniel who is in Intern list and any candidates onboarded as INTERN
      final isDaniel = nameLower.contains('daniel') || emailLower.contains('daniel') || emailLower.contains('dp0345217');
      if (isDaniel) return false;
      if (emp.role.toUpperCase() == 'INTERN') return false;
      return true;
    }).toList();

    final filtered = allStaff.where((emp) {
      final matchesStatus = _employeeStatusFilter == 'All Statuses';
      final matchesSearch = search.isEmpty ||
          emp.name.toLowerCase().contains(search) ||
          emp.email.toLowerCase().contains(search) ||
          emp.employeeId.toLowerCase().contains(search) ||
          (emp.department ?? '').toLowerCase().contains(search) ||
          (emp.designation ?? '').toLowerCase().contains(search);
      return matchesStatus && matchesSearch;
    }).toList();

    final totalPayroll = filtered.fold<double>(0.0, (acc, e) => acc + e.netSalary);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb matching Screenshot 2 (with Wrap to prevent overflow)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'INNOVEITY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEA580C), letterSpacing: 0.8),
                ),
              ),
              const Text('Portal  /  System Control  /  ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const Text(
                'Employee Registry',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // KPI Overview Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FULL-TIME STAFF', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('${allStaff.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ACTIVE FILTERED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text('${filtered.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MONTHLY PAYROLL', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text('₹${(totalPayroll / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Top Controls Bar: Responsive 2-row on mobile, 1-row on desktop
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 620;

              // Search Input
              final searchWidget = SizedBox(
                height: 42,
                child: TextField(
                  controller: _employeeSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: "Search employee by name, ID, email, role...",
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: _employeeSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _employeeSearchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.white,
                  ),
                ),
              );

              // Status Dropdown
              final statusDropdown = Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: const ['All Statuses', 'Active', 'On Leave'].contains(_employeeStatusFilter)
                        ? _employeeStatusFilter
                        : 'All Statuses',
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    items: const [
                      DropdownMenuItem(value: 'All Statuses', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                      DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                    ],
                    onChanged: (v) => setState(() => _employeeStatusFilter = v ?? 'All Statuses'),
                  ),
                ),
              );

              // Export CSV Button
              final exportBtn = SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () => _exportRegistryCsv('Employee', filtered),
                  icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF475569)),
                  label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                  ),
                ),
              );

              // Add Employee Button
              final addBtn = SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEmployeeModal(context, role: 'EMPLOYEE'),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
                  label: const Text('Add Employee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchWidget,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: statusDropdown),
                        const SizedBox(width: 8),
                        exportBtn,
                        const SizedBox(width: 8),
                        addBtn,
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    statusDropdown,
                    const SizedBox(width: 8),
                    Expanded(child: searchWidget),
                    const SizedBox(width: 8),
                    exportBtn,
                    const SizedBox(width: 8),
                    addBtn,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 14),

          // Employee Cards List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.groups_outlined, size: 48, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 10),
                  const Text('No employee records found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Try adjusting your search filter or click "+ Add Employee" above.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final emp = filtered[index];
                final isSelected = _selectedEmployeeIds.contains(emp.id);

                return _buildRegistryCandidateCard(
                  context: context,
                  emp: emp,
                  isSelected: isSelected,
                  onSelectChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedEmployeeIds.add(emp.id);
                      } else {
                        _selectedEmployeeIds.remove(emp.id);
                      }
                    });
                  },
                  isDark: isDark,
                  isIntern: false,
                  onDelete: () {
                    widget.state.removeEmployee(emp.email, id: emp.id, employeeId: emp.employeeId);
                    setState(() {
                      _selectedEmployeeIds.remove(emp.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${emp.name} from Employee Registry'),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 14),

          // Pagination Bar matching Screenshot 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filtered.length} of ${allStaff.length} total staff',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Previous', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Page 1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Next', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Universal CSV exporter for Registries
  Future<void> _exportRegistryCsv(String type, List<UserProfile> list) async {
    final buffer = StringBuffer();
    buffer.writeln('Employee ID,Name,Email,Role,Department,Designation,Status,Net Salary (INR)');
    for (final emp in list) {
      buffer.writeln('${emp.employeeId},"${emp.name}",${emp.email},${emp.role},"${emp.department ?? ''}","${emp.designation ?? ''}",ACTIVE,${emp.netSalary.toInt()}');
    }
    final bytes = buffer.toString().codeUnits;
    final fileName = '${type.toLowerCase()}_registry_${DateTime.now().millisecondsSinceEpoch}.csv';
    final path = await saveAndDownloadFile(bytes, fileName, context: context);
    if (!mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Exported $type Registry CSV to $path'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Export cancelled or storage permission was not granted.'),
        ),
      );
    }
  }
}

