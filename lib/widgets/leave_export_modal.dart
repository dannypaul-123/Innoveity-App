import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/leave_export_service.dart';
import '../theme/app_colors.dart';

class LeaveExportModal extends StatefulWidget {
  final List<LeaveRequest> requests;
  final List<UserProfile> allEmployees;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialEmployee;
  final List<String>? initialSelectedEmployees;

  const LeaveExportModal({
    super.key,
    required this.requests,
    required this.allEmployees,
    this.initialStartDate,
    this.initialEndDate,
    this.initialEmployee,
    this.initialSelectedEmployees,
  });

  static Future<void> show(
    BuildContext context, {
    required List<LeaveRequest> requests,
    required List<UserProfile> allEmployees,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String? initialEmployee,
    List<String>? initialSelectedEmployees,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LeaveExportModal(
        requests: requests,
        allEmployees: allEmployees,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        initialEmployee: initialEmployee,
        initialSelectedEmployees: initialSelectedEmployees,
      ),
    );
  }

  @override
  State<LeaveExportModal> createState() => _LeaveExportModalState();
}

class _LeaveExportModalState extends State<LeaveExportModal> {
  DateTime? _startDate;
  DateTime? _endDate;
  late Set<String> _selectedUsers;
  String _selectedStatus = 'ALL';
  bool _includeBrandingHeader = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Default to September 2026 or provided initial dates
    _startDate = widget.initialStartDate ?? DateTime(2026, 9, 1);
    _endDate = widget.initialEndDate ?? DateTime(2026, 9, 30);

    final allNames = _allEmployeeNames;
    if (widget.initialSelectedEmployees != null && widget.initialSelectedEmployees!.isNotEmpty) {
      _selectedUsers = widget.initialSelectedEmployees!.toSet();
    } else if (widget.initialEmployee != null &&
        widget.initialEmployee != 'All Employees' &&
        widget.initialEmployee != 'ALL' &&
        widget.initialEmployee!.trim().isNotEmpty) {
      _selectedUsers = {widget.initialEmployee!};
    } else {
      _selectedUsers = allNames.toSet();
    }
  }

  List<String> get _allEmployeeNames {
    final list = <String>[];
    final seen = <String>{};

    // Include applicants from requests first
    for (final req in widget.requests) {
      final name = req.applicantName.trim();
      if (name.isNotEmpty && name != 'Employee' && !seen.contains(name)) {
        seen.add(name);
        list.add(name);
      }
    }

    // Include employees from corporate directory
    for (final emp in widget.allEmployees) {
      final name = emp.name.trim();
      if (name.isNotEmpty && name != 'All Employees' && !seen.contains(name)) {
        seen.add(name);
        list.add(name);
      }
    }

    // Ensure known roster members are present
    final knownOrder = [
      'Abishek S',
      'Daniel Paul',
      'Zubairya Salam Khan',
      'Raghul Prasath J',
      'Anto A',
      'Praveen N',
      'Nancy Narmadha T',
      'Harish',
      'Kaviya S',
      'Sanjay S',
      'Yeshwanth Y',
      'Paul Renine',
      'Suraj S',
      'Divya R',
      'System Admin',
    ];
    for (final name in knownOrder) {
      if (!seen.contains(name)) {
        seen.add(name);
        list.add(name);
      }
    }

    return list;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'All';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  Future<void> _pickDateRange() async {
    final initialRange = (_startDate != null && _endDate != null)
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2028, 12, 31),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFEA580C),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      final now = DateTime.now();
      switch (preset) {
        case 'screenshot':
          _startDate = DateTime(2026, 9, 1);
          _endDate = DateTime(2026, 9, 30);
          break;
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day);
          break;
        case 'this_month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'all':
          _startDate = null;
          _endDate = null;
          break;
      }
    });
  }

  Future<void> _openMultiUserPicker() async {
    final allNames = _allEmployeeNames;
    Set<String> tempSelected = Set.from(_selectedUsers);
    String searchQuery = '';

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final filteredNames = allNames
                .where((name) => name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            final isAllFilteredSelected = filteredNames.isNotEmpty &&
                filteredNames.every((name) => tempSelected.contains(name));

            return Dialog(
              backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: Color(0xFFEA580C), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Employees',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '${tempSelected.length} of ${allNames.length} selected',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(dialogCtx, null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (q) => setDialogState(() => searchQuery = q.trim()),
                                decoration: const InputDecoration(
                                  hintText: 'Search by employee name...',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              InkWell(
                                onTap: () => setDialogState(() => searchQuery = ''),
                                child: const Icon(Icons.clear, size: 16, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Bar: Select All / Clear All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                if (isAllFilteredSelected) {
                                  for (final n in filteredNames) {
                                    tempSelected.remove(n);
                                  }
                                } else {
                                  for (final n in filteredNames) {
                                    tempSelected.add(n);
                                  }
                                }
                              });
                            },
                            icon: Icon(
                              isAllFilteredSelected ? Icons.deselect : Icons.select_all_rounded,
                              size: 16,
                              color: const Color(0xFFEA580C),
                            ),
                            label: Text(
                              isAllFilteredSelected ? 'Deselect Shown' : 'Select All Shown',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                tempSelected.clear();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Scrollable Employee Checkbox List
                      Expanded(
                        child: filteredNames.isEmpty
                            ? Center(
                                child: Text(
                                  'No employees match "$searchQuery"',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredNames.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (ctx, idx) {
                                  final name = filteredNames[idx];
                                  final isChecked = tempSelected.contains(name);

                                  return CheckboxListTile(
                                    value: isChecked,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          tempSelected.add(name);
                                        } else {
                                          tempSelected.remove(name);
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFFEA580C),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                        color: isDark ? Colors.white : AppColors.textDark,
                                      ),
                                    ),
                                    secondary: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isChecked
                                          ? const Color(0xFFEA580C).withValues(alpha: 0.15)
                                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      child: Text(
                                        name.isNotEmpty ? name[0] : '?',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isChecked
                                              ? const Color(0xFFEA580C)
                                              : (isDark ? Colors.white70 : AppColors.textDark),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Dialog Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogCtx, null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 12.5)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogCtx, tempSelected),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPine,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply (${tempSelected.length})',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedUsers = result;
      });
    }
  }

  List<LeaveExportRecord> get _filteredRecords {
    return LeaveExportService.getRecords(
      requests: widget.requests,
      allEmployees: widget.allEmployees,
      startDate: _startDate,
      endDate: _endDate,
      selectedEmployees: _selectedUsers.toList(),
      selectedStatus: _selectedStatus,
    );
  }

  Future<void> _handleExportCsv() async {
    if (_isExporting || _selectedUsers.isEmpty) return;
    setState(() => _isExporting = true);

    try {
      final savedPath = await LeaveExportService.exportLeaveCsv(
        requests: widget.requests,
        allEmployees: widget.allEmployees,
        startDate: _startDate,
        endDate: _endDate,
        selectedEmployees: _selectedUsers.toList(),
        selectedStatus: _selectedStatus,
        includeBranding: _includeBrandingHeader,
        context: context,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      if (savedPath != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Leave CSV exported successfully!\n$savedPath',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<void> _handleExportExcel() async {
    if (_isExporting || _selectedUsers.isEmpty) return;
    setState(() => _isExporting = true);

    try {
      final savedPath = await LeaveExportService.exportLeaveExcel(
        requests: widget.requests,
        allEmployees: widget.allEmployees,
        startDate: _startDate,
        endDate: _endDate,
        selectedEmployees: _selectedUsers.toList(),
        selectedStatus: _selectedStatus,
        context: context,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      if (savedPath != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Leave Excel (.xlsx) exported successfully!\n$savedPath',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allNames = _allEmployeeNames;
    final isAllSelected = _selectedUsers.length == allNames.length;
    final records = _filteredRecords;

    final dateRangeLabel = (_startDate != null && _endDate != null)
        ? '${_formatDate(_startDate)}  ➔  ${_formatDate(_endDate)}'
        : 'All Recorded Dates';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.headerDarkPine : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with Innoveity Logo
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.insert_chart_outlined,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Export Leave Records',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CSV / Excel',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Official Innoveity format with corporate branding & filters',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 1. Date Range Section
              Text(
                'DATE RANGE FILTER',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.emeraldMintText : AppColors.primaryPine,
                ),
              ),
              const SizedBox(height: 6),

              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, color: Color(0xFFEA580C), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateRangeLabel,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Tap to select custom start and end date range',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Quick Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip(
                      label: 'Sep 2026 (Screenshot Data)',
                      isActive: _startDate?.year == 2026 && _startDate?.month == 9,
                      onTap: () => _applyPreset('screenshot'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildPresetChip(
                      label: 'Today',
                      isActive: _startDate != null &&
                          _endDate != null &&
                          _startDate == _endDate &&
                          _startDate!.day == DateTime.now().day,
                      onTap: () => _applyPreset('today'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildPresetChip(
                      label: 'This Month',
                      isActive: _startDate?.month == DateTime.now().month &&
                          _startDate?.year == DateTime.now().year,
                      onTap: () => _applyPreset('this_month'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildPresetChip(
                      label: 'All Dates',
                      isActive: _startDate == null && _endDate == null,
                      onTap: () => _applyPreset('all'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Multi-Employee Selection Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'EMPLOYEES TO EXPORT',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.emeraldMintText : AppColors.primaryPine,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedUsers.isEmpty
                              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                              : const Color(0xFFEA580C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedUsers.length} of ${allNames.length} selected',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _selectedUsers.isEmpty
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isAllSelected) {
                          _selectedUsers.clear();
                        } else {
                          _selectedUsers = allNames.toSet();
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        isAllSelected ? 'Clear All' : 'Select All',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Main Multi-Employee Selector Box (Tappable)
              InkWell(
                onTap: _openMultiUserPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedUsers.isEmpty
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFEA580C).withValues(alpha: 0.4),
                      width: _selectedUsers.isEmpty ? 1.5 : 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.group_add_rounded, size: 20, color: Color(0xFFEA580C)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedUsers.isEmpty
                                  ? 'No employees selected'
                                  : isAllSelected
                                      ? 'All Employees (${allNames.length})'
                                      : '${_selectedUsers.length} Employees Selected',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: _selectedUsers.isEmpty
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedUsers.isEmpty
                                  ? 'Tap to select one or multiple employees'
                                  : isAllSelected
                                      ? 'Exporting leave requests for all employees'
                                      : _selectedUsers.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected User Chips Strip
              if (_selectedUsers.isNotEmpty && !isAllSelected) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._selectedUsers.map((name) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFFC2410C),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedUsers.remove(name);
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Add more button
                      InkWell(
                        onTap: _openMultiUserPicker,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.add, size: 14, color: Color(0xFFEA580C)),
                              SizedBox(width: 2),
                              Text(
                                'Add',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // 3. Status Filter Row
              Row(
                children: [
                  Text(
                    'STATUS FILTER: ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.emeraldMintText : AppColors.primaryPine,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                          dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Statuses (Approved, Pending, Rejected)')),
                            DropdownMenuItem(value: 'APPROVED', child: Text('Approved Only')),
                            DropdownMenuItem(value: 'PENDING', child: Text('Pending Only')),
                            DropdownMenuItem(value: 'REJECTED', child: Text('Rejected Only')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 4. Live Preview Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EXPORT PREVIEW (${records.length} RECORDS)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.emeraldMintText : AppColors.primaryPine,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: records.isEmpty
                                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                : const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            records.isEmpty ? 'No Matches' : '${records.length} Found',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: records.isEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (records.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            _selectedUsers.isEmpty
                                ? 'Please select at least one employee above to view and export leave data.'
                                : 'No leave requests match the selected date range & filters.\nTry selecting "All Dates" or "Sep 2026".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Scrollable Preview Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          columnWidths: const {
                            0: IntrinsicColumnWidth(),
                            1: IntrinsicColumnWidth(),
                            2: IntrinsicColumnWidth(),
                            3: IntrinsicColumnWidth(),
                            4: IntrinsicColumnWidth(),
                            5: IntrinsicColumnWidth(),
                            6: IntrinsicColumnWidth(),
                            7: IntrinsicColumnWidth(),
                            8: IntrinsicColumnWidth(),
                            9: FixedColumnWidth(180),
                          },
                          children: [
                            // Table Header
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              children: [
                                _buildPreviewHeader('Applicant'),
                                _buildPreviewHeader('Employee ID'),
                                _buildPreviewHeader('Role'),
                                _buildPreviewHeader('Department'),
                                _buildPreviewHeader('Leave Type'),
                                _buildPreviewHeader('Start Date'),
                                _buildPreviewHeader('End Date'),
                                _buildPreviewHeader('Days'),
                                _buildPreviewHeader('Status'),
                                _buildPreviewHeader('Reason'),
                              ],
                            ),
                            // Data Rows (First 5 records preview)
                            ...records.take(5).map((r) {
                              return TableRow(
                                children: [
                                  _buildPreviewCell(r.applicantName, isDark, bold: true),
                                  _buildPreviewCell(r.employeeId, isDark),
                                  _buildPreviewCell(r.role, isDark),
                                  _buildPreviewCell(r.department, isDark),
                                  _buildPreviewCell(r.leaveType, isDark, bold: true),
                                  _buildPreviewCell(r.startDate, isDark),
                                  _buildPreviewCell(r.endDate, isDark),
                                  _buildPreviewCell(r.days, isDark),
                                  _buildStatusCell(r.status),
                                  _buildPreviewCell(r.reason, isDark),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      if (records.length > 5) ...[
                        const SizedBox(height: 6),
                        Text(
                          '+ ${records.length - 5} more records will be exported',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Include Branding Header checkbox
              Row(
                children: [
                  Checkbox(
                    value: _includeBrandingHeader,
                    activeColor: const Color(0xFFEA580C),
                    onChanged: (val) {
                      setState(() => _includeBrandingHeader = val ?? true);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Include Innoveity Tech logo branding header in CSV',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 5. Action Buttons
              Row(
                children: [
                  // Primary Export CSV Button
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: (_isExporting || records.isEmpty) ? null : _handleExportCsv,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.file_download, color: Colors.white, size: 18),
                      label: Text(
                        _isExporting ? 'Exporting...' : 'Export CSV (${records.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPine,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Secondary Export Excel Button
                  Expanded(
                    flex: 5,
                    child: OutlinedButton.icon(
                      onPressed: (_isExporting || records.isEmpty) ? null : _handleExportExcel,
                      icon: const Icon(Icons.table_view_rounded, color: Color(0xFFEA580C), size: 18),
                      label: const Text(
                        'Excel (.xlsx)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFEA580C)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFEA580C), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFEA580C)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFEA580C) : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEA580C),
        ),
      ),
    );
  }

  Widget _buildPreviewCell(String text, bool isDark, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    Color bg;
    Color text;

    if (status.contains('APPROVED')) {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
    } else if (status.contains('PENDING')) {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFB91C1C);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: text),
        ),
      ),
    );
  }
}
