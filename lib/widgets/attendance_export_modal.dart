import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/attendance_export_service.dart';
import '../theme/app_colors.dart';

class AttendanceExportModal extends StatefulWidget {
  final List<UserProfile> allEmployees;
  final String? initialSelectedUser;
  final List<String>? initialSelectedUsers;
  final DateTime? initialDate;

  const AttendanceExportModal({
    super.key,
    required this.allEmployees,
    this.initialSelectedUser,
    this.initialSelectedUsers,
    this.initialDate,
  });

  static Future<void> show(
    BuildContext context, {
    required List<UserProfile> allEmployees,
    String? initialSelectedUser,
    List<String>? initialSelectedUsers,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceExportModal(
        allEmployees: allEmployees,
        initialSelectedUser: initialSelectedUser,
        initialSelectedUsers: initialSelectedUsers,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<AttendanceExportModal> createState() => _AttendanceExportModalState();
}

class _AttendanceExportModalState extends State<AttendanceExportModal> {
  late Set<String> _selectedUsers;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final allNames = _allEmployeeNames;
    if (widget.initialSelectedUsers != null && widget.initialSelectedUsers!.isNotEmpty) {
      _selectedUsers = widget.initialSelectedUsers!.toSet();
    } else if (widget.initialSelectedUser != null &&
        widget.initialSelectedUser != 'All Employees' &&
        widget.initialSelectedUser != 'ALL' &&
        widget.initialSelectedUser!.trim().isNotEmpty) {
      _selectedUsers = {widget.initialSelectedUser!};
    } else {
      _selectedUsers = allNames.toSet();
    }

    final baseDate = widget.initialDate ?? DateTime(2026, 10, 13);
    _startDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    _endDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
  }

  List<String> get _allEmployeeNames {
    final list = <String>[];
    final knownOrder = [
      'Anto A',
      'Daniel Paul',
      'Harish',
      'Kaviya S',
      'Nancy Narmadha T',
      'Praveen N',
      'Raghul Prasath J',
      'Sanjay S',
      'Yeshwanth Y',
      'Zubairya Salam Khan',
      'Paul Renine',
      'Suraj S',
      'Divya R',
      'System Admin',
    ];
    for (final name in knownOrder) {
      if (!list.contains(name)) list.add(name);
    }
    for (final emp in widget.allEmployees) {
      if (emp.name != 'All Employees' && !list.contains(emp.name)) {
        list.add(emp.name);
      }
    }
    return list;
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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

                      // Action Bar: Select All / Deselect All
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
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (ctx, idx) {
                                  final name = filteredNames[idx];
                                  final isChecked = tempSelected.contains(name);
                                  final initials = name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join();

                                  return InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (isChecked) {
                                          tempSelected.remove(name);
                                        } else {
                                          tempSelected.add(name);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: isChecked
                                                ? const Color(0xFFEA580C).withValues(alpha: 0.15)
                                                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                            child: Text(
                                              initials,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isChecked
                                                    ? const Color(0xFFEA580C)
                                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                                                color: isDark ? Colors.white : AppColors.textDark,
                                              ),
                                            ),
                                          ),
                                          Checkbox(
                                            value: isChecked,
                                            activeColor: const Color(0xFFEA580C),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            onChanged: (val) {
                                              setDialogState(() {
                                                if (val == true) {
                                                  tempSelected.add(name);
                                                } else {
                                                  tempSelected.remove(name);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 14),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogCtx, tempSelected),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply Selection (${tempSelected.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                        ),
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

  Future<void> _handleExport() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Please select at least one employee to export attendance records.'),
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final selectedList = _selectedUsers.toList();
      final target = await AttendanceExportService.exportAttendanceExcel(
        selectedEmployeeNames: selectedList,
        startDate: _startDate,
        endDate: _endDate,
        allEmployees: widget.allEmployees,
        context: context,
      );

      if (mounted) {
        if (target == null) {
          setState(() => _isExporting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.alertText,
              content: Text('Export cancelled. Storage permission is required to save to Downloads.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        Navigator.pop(context);
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
                    'Excel file exported for ${selectedList.length} employee${selectedList.length == 1 ? '' : 's'} successfully!\n$target',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.alertText,
            content: Text('Export failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNames = _allEmployeeNames;
    final isAllSelected = _selectedUsers.length == allNames.length && allNames.isNotEmpty;
    final selectedList = _selectedUsers.toList();

    final recordsPreview = AttendanceExportService.getRecords(
      selectedEmployeeNames: selectedList,
      startDate: _startDate,
      endDate: _endDate,
      allEmployees: widget.allEmployees,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.headerDarkPine : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Drag indicator & Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: Color(0xFFEA580C), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Attendance Report',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Download Excel (.xlsx) formatted for Innoveity Tech',
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
            const SizedBox(height: 18),

            // User Selection Multi-Select Picker
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
                          color: _selectedUsers.isEmpty ? const Color(0xFFEF4444) : const Color(0xFFEA580C),
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

            // Main Selector Box (Tappable)
            InkWell(
              onTap: _openMultiUserPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedUsers.isEmpty
                        ? const Color(0xFFEF4444)
                        : (isDark ? AppColors.borderCardDark : AppColors.borderLight),
                    width: _selectedUsers.isEmpty ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                  : (isDark ? Colors.white : AppColors.textDark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedUsers.isEmpty
                                ? 'Tap to choose one or more employees'
                                : isAllSelected
                                    ? 'Includes all active employees & interns'
                                    : '${_selectedUsers.take(3).join(', ')}${_selectedUsers.length > 3 ? ' (+${_selectedUsers.length - 3} more)' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune_rounded, size: 14, color: Color(0xFFEA580C)),
                          const SizedBox(width: 4),
                          Text(
                            _selectedUsers.isEmpty ? 'Select' : 'Manage',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Inline Selected Chips with remove button
            if (_selectedUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._selectedUsers.map((name) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedUsers.remove(name);
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close_rounded, size: 13, color: Color(0xFFEA580C)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    InkWell(
                      onTap: _openMultiUserPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderCardDark : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: isDark ? Colors.white70 : AppColors.textDark),
                            const SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Date Range Selection
            Text(
              'DATE RANGE',
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
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderCardDark : AppColors.borderLight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFFEA580C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _startDate == _endDate
                            ? _formatDate(_startDate)
                            : '${_formatDate(_startDate)}  →  ${_formatDate(_endDate)}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.1),
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

            // Date Range Quick Preset Chips
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('Today (13-10-2026)', () {
                    final today = DateTime(2026, 10, 13);
                    setState(() {
                      _startDate = today;
                      _endDate = today;
                    });
                  }),
                  const SizedBox(width: 6),
                  _buildPresetChip('Yesterday', () {
                    final yesterday = DateTime(2026, 10, 12);
                    setState(() {
                      _startDate = yesterday;
                      _endDate = yesterday;
                    });
                  }),
                  const SizedBox(width: 6),
                  _buildPresetChip('Last 7 Days', () {
                    final end = DateTime(2026, 10, 13);
                    final start = end.subtract(const Duration(days: 6));
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                    });
                  }),
                  const SizedBox(width: 6),
                  _buildPresetChip('October Full Month', () {
                    setState(() {
                      _startDate = DateTime(2026, 10, 1);
                      _endDate = DateTime(2026, 10, 31);
                    });
                  }),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Spreadsheet Preview matching exact screenshot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EXCEL FORMAT PREVIEW',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                  ),
                ),
                Text(
                  _selectedUsers.isEmpty
                      ? '0 rows'
                      : '${recordsPreview.length} rows to export (${_selectedUsers.length} employees)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Excel Container Box
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1 Title: Innoveity Tech
                  const Text(
                    'Innoveity Tech',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEA580C),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 2 Subtitle
                  Text(
                    _selectedUsers.isEmpty
                        ? 'No employees selected'
                        : isAllSelected
                            ? (_startDate == _endDate
                                ? 'Daily Attendance Report  |  Date: ${_formatDate(_startDate)}'
                                : 'Daily Attendance Report  |  Date: ${_formatDate(_startDate)} to ${_formatDate(_endDate)}')
                            : _selectedUsers.length == 1
                                ? 'Attendance Report: ${_selectedUsers.first}  |  Date: ${_formatDate(_startDate)} to ${_formatDate(_endDate)}'
                                : 'Attendance Report: ${_selectedUsers.length} Selected Employees  |  Date: ${_formatDate(_startDate)} to ${_formatDate(_endDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Table Header
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Employee',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'Attendance',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'Login Time',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'Login Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // First 5 Sample Rows Preview or Empty State
                  if (_selectedUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No employees selected.\nPlease select one or more employees above to preview records.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recordsPreview.take(5).length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    itemBuilder: (context, idx) {
                      final r = recordsPreview[idx];
                      final isPresent = r.attendance == 'Present';
                      final isAbsent = r.attendance == 'Absent';
                      final isWfh = r.attendance == 'WFH' || r.attendance == 'Work From Home';

                      final attBg = isPresent
                          ? const Color(0xFFDCFCE7)
                          : (isAbsent
                              ? const Color(0xFFFEE2E2)
                              : (isWfh ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9)));
                      final attText = isPresent
                          ? const Color(0xFF15803D)
                          : (isAbsent
                              ? const Color(0xFFB91C1C)
                              : (isWfh ? const Color(0xFF1D4ED8) : const Color(0xFF64748B)));

                      final isStatusOnTime = r.loginStatus == 'On Time';
                      final isStatusAbsent = r.loginStatus == 'Absent';
                      final isStatusWfh = r.loginStatus == 'WFH' || r.loginStatus == 'Work From Home';
                      final isStatusLate = r.loginStatus == 'Late';

                      final statBg = isStatusOnTime
                          ? const Color(0xFFDCFCE7)
                          : (isStatusAbsent
                              ? const Color(0xFFFEE2E2)
                              : (isStatusWfh
                                  ? const Color(0xFFDBEAFE)
                                  : (isStatusLate ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9))));
                      final statText = isStatusOnTime
                          ? const Color(0xFF15803D)
                          : (isStatusAbsent
                              ? const Color(0xFFB91C1C)
                              : (isStatusWfh
                                  ? const Color(0xFF1D4ED8)
                                  : (isStatusLate ? const Color(0xFFB45309) : const Color(0xFF64748B))));

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                r.employeeName,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: attBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    r.attendance,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: attText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  r.loginTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: r.loginTime == '—' ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    r.loginStatus,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: statText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (recordsPreview.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text(
                        '+ ${recordsPreview.length - 5} more records included in Excel download...',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Color Coordination Legend Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Color Legend:',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        _buildLegendPill('Present', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                        _buildLegendPill('Absent', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
                        _buildLegendPill('WFH', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _isExporting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.white24 : AppColors.borderLight),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (_isExporting || _selectedUsers.isEmpty) ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.file_download_rounded, color: Colors.white, size: 20),
                    label: Text(
                      _isExporting
                          ? 'Generating Excel...'
                          : _selectedUsers.isEmpty
                              ? 'Select Employees'
                              : _selectedUsers.length == 1
                                  ? 'Export Excel (1 Employee)'
                                  : 'Export Excel (${_selectedUsers.length} Employees)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textLight : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendPill(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
