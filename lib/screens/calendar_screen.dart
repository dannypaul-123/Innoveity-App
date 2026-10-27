import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/attendance_export_modal.dart';

class CalendarScreen extends StatefulWidget {
  final List<AttendanceLog> logs;
  final bool isClockedIn;
  final String formattedClockTime;
  final VoidCallback onClockToggle;
  final VoidCallback? onApplyLeave;
  final String userRole;
  final int shiftCompletionPercent;
  final double shiftCompletionRatio;
  final bool showLiveAttendanceCard;
  final List<UserProfile>? allEmployees;
  final String? currentUserName;
  final bool? canExportAttendance;
  final bool showExportButton;
  final bool showApplyLeaveButton;

  const CalendarScreen({
    super.key,
    required this.logs,
    required this.isClockedIn,
    required this.formattedClockTime,
    required this.onClockToggle,
    this.onApplyLeave,
    this.userRole = 'EMPLOYEE',
    this.shiftCompletionPercent = 0,
    this.shiftCompletionRatio = 0.0,
    this.showLiveAttendanceCard = true,
    this.allEmployees,
    this.currentUserName,
    this.canExportAttendance,
    this.showExportButton = false,
    this.showApplyLeaveButton = false,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  int _selectedDayIndex = DateTime.now().day;
  String _selectedView = 'Month';

  bool get _isAdmin {
    final role = widget.userRole.toUpperCase();
    return role == 'ADMIN' || role == 'SUPER_ADMIN' || role == 'SUPERADMIN';
  }

  bool get _canExport => widget.canExportAttendance ?? _isAdmin;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDate = DateTime(now.year, now.month, now.day);
    _selectedDayIndex = now.day;
  }

  static const List<String> _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  DateTime get _safeDate => _focusedDate;

  void _previousMonth() {
    setState(() {
      final d = _safeDate;
      _focusedDate = DateTime(d.year, d.month - 1, 1);
      _selectedDayIndex = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      final d = _safeDate;
      _focusedDate = DateTime(d.year, d.month + 1, 1);
      _selectedDayIndex = 1;
    });
  }

  void _showMonthYearPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDate = _safeDate;
    int tempYear = activeDate.year;
    int tempMonth = activeDate.month;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month & Year',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.primaryPine),
                        onPressed: () {
                          setModalState(() => tempYear--);
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.vibrantEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryPine),
                        ),
                        child: Text(
                          '$tempYear',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPine,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.primaryPine),
                        onPressed: () {
                          setModalState(() => tempYear++);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Month Grid (12 Months)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final mNum = idx + 1;
                      final isSelected = mNum == tempMonth;
                      return InkWell(
                        onTap: () {
                          setModalState(() => tempMonth = mNum);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryPine
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: AppColors.vibrantEmerald, width: 1.5)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _monthNames[mNum].substring(0, 3),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.textLight : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _focusedDate = DateTime(tempYear, tempMonth, 1);
                          _selectedDayIndex = 1;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPine,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Selected Month',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeDate = _safeDate;
    final currentYear = activeDate.year;
    final currentMonth = activeDate.month.clamp(1, 12);
    final currentMonthName = _monthNames[currentMonth];

    // Calendar Calculations
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final firstWeekday = DateTime(currentYear, currentMonth, 1).weekday % 7; // 0: Sun, 1: Mon...
    final daysInPrevMonth = DateTime(currentYear, currentMonth, 0).day;
    final totalGridCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF058A5E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work Calendar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Attendance & Shift Tracker • Auto Clock-Out ${widget.userRole.toUpperCase() == "INTERN" ? "5:00 PM" : "6:00 PM"}',
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
              if (widget.showExportButton && _canExport) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final employees = widget.allEmployees ?? AppState.userDirectory.values.toList();
                    final userRoleUpper = widget.userRole.toUpperCase();
                    final defaultUser = (userRoleUpper == 'ADMIN' || userRoleUpper == 'SUPER_ADMIN')
                        ? 'All Employees'
                        : (widget.currentUserName ?? 'All Employees');
                    AttendanceExportModal.show(
                      context,
                      allEmployees: employees,
                      initialSelectedUser: defaultUser,
                      initialDate: _focusedDate,
                    );
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 14, color: Color(0xFFEA580C)),
                  label: const Text(
                    'Export',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF7ED),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFFDBA74)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (widget.showApplyLeaveButton && widget.onApplyLeave != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: widget.onApplyLeave,
                  icon: const Icon(Icons.add, size: 14, color: Color(0xFF047857)),
                  label: const Text(
                    'Apply Leave',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F8F0),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // 2. Navigation Row: Month Selector Pill + View Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Interactive Month Selector Pill
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20, color: Color(0xFF058A5E)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _previousMonth,
                        tooltip: 'Previous Month',
                      ),
                      InkWell(
                        onTap: () => _showMonthYearPicker(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$currentMonthName $currentYear',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: Color(0xFF058A5E),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF058A5E)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _nextMonth,
                        tooltip: 'Next Month',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // View Selector Controls (Month / Week / Agenda)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Month', 'Week', 'Agenda'].map((v) {
                    final isSel = _selectedView == v;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedView = v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryPine : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          v,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                            color: isSel
                                ? Colors.white
                                : (isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Calendar Grid Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Weekday Header Labels (SU & SA in bold black font)
                Row(
                  children: ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'].map((d) {
                    final isWkndHeader = (d == 'SU' || d == 'SA');
                    return Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isWkndHeader
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Dynamic Month Grid Builder
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: totalGridCells,
                  itemBuilder: (context, index) {
                    int dayNum;
                    bool isOtherMonth = false;
                    bool isWeekend = (index % 7 == 0 || index % 7 == 6);

                    if (index < firstWeekday) {
                      dayNum = daysInPrevMonth - firstWeekday + 1 + index;
                      isOtherMonth = true;
                    } else if (index < firstWeekday + daysInMonth) {
                      dayNum = index - firstWeekday + 1;
                      isOtherMonth = false;
                    } else {
                      dayNum = index - (firstWeekday + daysInMonth) + 1;
                      isOtherMonth = true;
                    }

                    final now = DateTime.now();
                    final isToday = !isOtherMonth &&
                        dayNum == now.day &&
                        currentMonth == now.month &&
                        currentYear == now.year;
                    final isLeave = !isOtherMonth && dayNum == 11;
                    final isGovtHoliday = !isOtherMonth && (dayNum == 25 || dayNum == 2);
                    final isWFH = !isOtherMonth && dayNum == 18;
                    final isSelected = !isOtherMonth && dayNum == _selectedDayIndex;

                    Color textColor = isDark ? AppColors.textLight : const Color(0xFF1E293B);
                    Color bgColor = Colors.transparent;
                    Color? dotColor;

                    if (isOtherMonth) {
                      textColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
                    } else if (isSelected) {
                      bgColor = const Color(0xFF058A5E);
                      textColor = Colors.white;
                      dotColor = Colors.white;
                    } else if (isToday) {
                      bgColor = AppColors.vibrantEmerald.withValues(alpha: 0.3);
                      textColor = AppColors.primaryPine;
                      dotColor = AppColors.primaryPine;
                    } else if (isLeave) {
                      // Approved Leave (Employee / Office granted)
                      bgColor = const Color(0xFFFEF3C7);
                      textColor = const Color(0xFF92400E);
                      dotColor = const Color(0xFFF59E0B);
                    } else if (isGovtHoliday) {
                      // Government Holiday
                      bgColor = const Color(0xFFEDE9FE);
                      textColor = const Color(0xFF5B21B6);
                      dotColor = const Color(0xFF8B5CF6);
                    } else if (isWFH) {
                      bgColor = const Color(0xFFDBEAFE);
                      textColor = const Color(0xFF1E40AF);
                      dotColor = const Color(0xFF3B82F6);
                    } else if (isWeekend) {
                      // Saturdays & Sundays in bold black font
                      textColor = isDark ? Colors.white : const Color(0xFF0F172A);
                      dotColor = isDark ? Colors.white54 : const Color(0xFF475569);
                    } else {
                      dotColor = const Color(0xFF10B981);
                    }

                    return GestureDetector(
                      onTap: () {
                        if (!isOtherMonth) {
                          setState(() => _selectedDayIndex = dayNum);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSelected
                              ? Border.all(color: const Color(0xFF058A5E), width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: (isToday || isSelected || isLeave || isGovtHoliday || isWFH || isWeekend)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            if (dotColor != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Calendar Legend Row (Differentiating Leave & Govt Holiday & Weekend)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildLegendItem(const Color(0xFF10B981), 'Present'),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildLegendItem(const Color(0xFF3B82F6), 'WFH'),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildLegendItem(const Color(0xFFF59E0B), 'Approved Leave'),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildLegendItem(const Color(0xFF8B5CF6), 'Govt Holiday'),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildLegendItem(
                          isDark ? Colors.white : const Color(0xFF0F172A),
                          'Weekend',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Live Attendance Session Card (Hidden for Admin)
          if (widget.showLiveAttendanceCard && widget.userRole.toUpperCase() != 'ADMIN') ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF032E20),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF032E20).withValues(alpha: 0.3),
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
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Live Attendance Session',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.isClockedIn ? 'Shift Active' : 'Auto Clocked Out',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA7F3D0),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                widget.formattedClockTime.isNotEmpty
                                    ? widget.formattedClockTime
                                    : '05 : 50 : 57',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'AM',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFA7F3D0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            'Logged Today',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '7.8 hrs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Shift Target: ${widget.userRole.toUpperCase() == 'INTERN' ? '7.0' : '8.0'} hrs • ${widget.shiftCompletionPercent}% Reached',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: widget.shiftCompletionRatio,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF065F46),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFA7F3D0)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Innoveity Tech Park • 4th Floor',
                                style: TextStyle(fontSize: 11, color: Color(0xFFA7F3D0)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: widget.onClockToggle,
                        icon: Icon(
                          widget.isClockedIn ? Icons.logout : Icons.login,
                          size: 14,
                          color: const Color(0xFF032E20),
                        ),
                        label: Text(
                          widget.isClockedIn ? 'Clock Out' : 'Clock In',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF032E20),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. Month Summary Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentMonthName.toUpperCase()} $currentYear SUMMARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '88% Attendance',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF058A5E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4 Summary Stat Cards Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'TOTAL',
                  value: '$daysInMonth',
                  subtext: 'Work Days',
                  bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  textColor: isDark ? AppColors.textLight : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSummaryCard(
                  label: 'PRESENT',
                  value: '${(daysInMonth * 0.8).toInt()}',
                  subtext: 'Office',
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  textColor: const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSummaryCard(
                  label: 'WFH',
                  value: '2',
                  subtext: 'Approved',
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  textColor: const Color(0xFF1D4EDB),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSummaryCard(
                  label: 'LEAVES',
                  value: '1',
                  subtext: 'Casual',
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFEF3C7),
                  textColor: const Color(0xFFB45309),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 6. Daily Shift Logs Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY SHIFT LOGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                ),
              ),
              const Text(
                'Recent Entries',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF058A5E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Daily Shift Logs List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = widget.logs[index];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.date,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Check In: ${log.checkIn}  •  Check Out: ${log.checkOut}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${log.workingHours} hrs',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF058A5E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.status,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required String subtext,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtext,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
