import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import '../widgets/app_avatar.dart';
import '../widgets/geofence_verification_modal.dart';

class AttendancePortalScreen extends StatefulWidget {
  final AppState state;
  final bool isEmbedded;
  final VoidCallback? onClockToggle;

  const AttendancePortalScreen({
    super.key,
    required this.state,
    this.isEmbedded = false,
    this.onClockToggle,
  });

  @override
  State<AttendancePortalScreen> createState() => _AttendancePortalScreenState();
}

class _AttendancePortalScreenState extends State<AttendancePortalScreen> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // View Mode: 'table' or 'calendar'
  String _viewMode = 'table';

  // Filters
  String _selectedMonth = 'October';
  String _selectedYear = '2026';
  String _selectedStatus = 'All Statuses';
  String _selectedLocation = 'All Locations';
  String _selectedPerPage = '10 per page';

  final List<String> _months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _years = ['2027', '2026', '2025', '2024', '2023'];

  final List<String> _statuses = const [
    'All Statuses',
    'PRESENT',
    'WORK FROM HOME',
    'WFH',
    'LATE',
    'HALF DAY',
    'ABSENT',
    'HOLIDAY',
    'ON LEAVE',
  ];

  final List<String> _locations = const [
    'All Locations',
    'Office',
    'Home',
  ];

  final List<String> _perPageOptions = const [
    '10 per page',
    '25 per page',
    '50 per page',
  ];

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onAppStateChanged);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AttendancePortalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onAppStateChanged);
      widget.state.addListener(_onAppStateChanged);
    }
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onAppStateChanged);
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatLiveClock(DateTime dt) {
    return DateFormat('HH:mm:ss').format(dt);
  }

  String _formatLiveDate(DateTime dt) {
    return DateFormat('EEEE, MMMM d, y').format(dt);
  }

  // Calculate live shift countdown until cutoff hour (5:00 PM for Interns, 6:00 PM for Employees)
  String _calculateShiftCountdown(DateTime now) {
    final cutoffHour = widget.state.autoClockOutCutoffHour;
    final shiftEnd = DateTime(now.year, now.month, now.day, cutoffHour, 0, 0);
    if (now.isAfter(shiftEnd)) {
      return '00:00:00';
    }
    final diff = shiftEnd.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // Calculate live shift progress hours synchronized with AppState
  double _calculateShiftProgressHours(DateTime now, bool isClockedIn) {
    final targetShiftHours = widget.state.shiftTargetHours;
    if (!isClockedIn) {
      return (widget.state.clockedSeconds / 3600.0).clamp(0.0, targetShiftHours);
    }
    return (widget.state.clockedSeconds / 3600.0).clamp(0.0, targetShiftHours);
  }

  int _getMonthNumber(String monthName) {
    final idx = _months.indexOf(monthName);
    return idx != -1 ? idx + 1 : 10;
  }

  String _getMonthName(int monthNum) {
    if (monthNum >= 1 && monthNum <= 12) {
      return _months[monthNum - 1];
    }
    return 'October';
  }

  void _previousMonth() {
    int m = _getMonthNumber(_selectedMonth);
    int y = int.tryParse(_selectedYear) ?? 2026;
    m--;
    if (m < 1) {
      m = 12;
      y--;
    }
    setState(() {
      _selectedMonth = _getMonthName(m);
      _selectedYear = '$y';
      if (!_years.contains(_selectedYear)) {
        _years.add(_selectedYear);
        _years.sort((a, b) => b.compareTo(a));
      }
    });
  }

  void _nextMonth() {
    int m = _getMonthNumber(_selectedMonth);
    int y = int.tryParse(_selectedYear) ?? 2026;
    m++;
    if (m > 12) {
      m = 1;
      y++;
    }
    setState(() {
      _selectedMonth = _getMonthName(m);
      _selectedYear = '$y';
      if (!_years.contains(_selectedYear)) {
        _years.add(_selectedYear);
        _years.sort((a, b) => b.compareTo(a));
      }
    });
  }

  /// Obtains full attendance logs for the employee for any given month and year
  List<AttendanceLog> _getMonthlyAttendanceLogs(int year, int month) {
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final List<AttendanceLog> result = [];
    final now = DateTime.now();
    final bool isCurrentMonth = (year == now.year && month == now.month) || (year == 2026 && month == 10);
    final shortMonth = DateFormat('MMM').format(DateTime(year, month, 1));

    for (int day = daysInMonth; day >= 1; day--) {
      final dateObj = DateTime(year, month, day);
      final weekdayStr = DateFormat('EEE').format(dateObj);
      final dateFormatted = '$day $shortMonth $year ($weekdayStr)';
      final isWeekend = dateObj.weekday == DateTime.saturday || dateObj.weekday == DateTime.sunday;

      // 1. If today (live runtime date or October 26/27)
      final bool isToday = (year == now.year && month == now.month && day == now.day) ||
                           (year == 2026 && month == 10 && (day == 26 || day == 27));
      if (isToday) {
        final liveLog = widget.state.attendanceLogs.firstWhere(
          (l) => l.date.toLowerCase().contains('today') ||
                 l.date.toLowerCase().contains('$day $shortMonth'.toLowerCase()) ||
                 l.date.toLowerCase().contains('26 oct') ||
                 l.date.toLowerCase().contains('27 oct'),
          orElse: () => AttendanceLog(
            date: dateFormatted,
            checkIn: widget.state.clockInTimeDisplay != 'Not Clocked In' ? widget.state.clockInTimeDisplay : '10:00',
            checkOut: widget.state.isClockedIn
                ? 'Active Shift'
                : (widget.state.clockOutTimeDisplay != null && widget.state.clockOutTimeDisplay != '--'
                    ? widget.state.clockOutTimeDisplay!
                    : '17:00'),
            workingHours: widget.state.clockedSeconds > 0 ? (widget.state.clockedSeconds / 3600.0) : 7.0,
            status: widget.state.isClockedIn ? 'PRESENT' : 'OFFLINE',
            workLocation: widget.state.lastWorkLocation,
            totalWorkedStr: widget.state.formattedClockTime,
          ),
        );
        result.add(liveLog);
        continue;
      }

      // 2. Future days (after Oct 26, 2026)
      if (dateObj.isAfter(DateTime(2026, 10, 26))) {
        result.add(
          AttendanceLog(
            date: dateFormatted,
            checkIn: '—',
            checkOut: '—',
            workingHours: 0,
            status: isWeekend ? 'HOLIDAY' : 'UPCOMING',
            workLocation: '—',
            totalWorkedStr: '—',
          ),
        );
        continue;
      }

      // 3. Weekend days
      if (isWeekend) {
        result.add(
          AttendanceLog(
            date: dateFormatted,
            checkIn: '—',
            checkOut: '—',
            workingHours: 0,
            status: 'HOLIDAY',
            workLocation: '—',
            totalWorkedStr: '—',
          ),
        );
        continue;
      }

      // 4. Current month (October 2026) existing logs in state
      if (isCurrentMonth) {
        final existingMatch = widget.state.attendanceLogs.firstWhere(
          (l) => l.date.toLowerCase().contains('$day $shortMonth'.toLowerCase()) ||
                 l.date.toLowerCase().contains('$day oct'),
          orElse: () => AttendanceLog(date: '', checkIn: '', checkOut: '', workingHours: 0, status: '', workLocation: '', totalWorkedStr: ''),
        );
        if (existingMatch.date.isNotEmpty) {
          result.add(existingMatch);
          continue;
        }
      }

      // 5. Deterministic realistic employee attendance pattern for all historical months
      final seed = (day * 7 + month * 13 + year * 3);
      final pattern = seed % 20;

      String status;
      String checkIn;
      String checkOut;
      double hours;
      String location;
      String totalWorked;

      if (pattern == 3 || pattern == 11) {
        status = 'WORK FROM HOME';
        checkIn = '09:55';
        checkOut = '17:00';
        hours = 7.08;
        location = 'Home';
        totalWorked = '7h 5m';
      } else if (pattern == 7) {
        status = 'SICK OR CASUAL LEAVE';
        checkIn = '—';
        checkOut = '—';
        hours = 0.0;
        location = '—';
        totalWorked = '—';
      } else if (pattern == 15) {
        status = 'ABSENT';
        checkIn = '—';
        checkOut = '—';
        hours = 0.0;
        location = '—';
        totalWorked = '—';
      } else if (pattern == 4) {
        status = 'LATE';
        checkIn = '10:15';
        checkOut = '17:00';
        hours = 6.75;
        location = 'Office';
        totalWorked = '6h 45m';
      } else {
        status = 'PRESENT';
        final minOffset = (seed % 5);
        checkIn = '10:0$minOffset';
        checkOut = '17:00';
        hours = 6.95 - (minOffset * 0.02);
        location = 'Office';
        totalWorked = '6h ${58 - minOffset}m';
      }

      result.add(
        AttendanceLog(
          date: dateFormatted,
          checkIn: checkIn,
          checkOut: checkOut,
          workingHours: hours,
          status: status,
          workLocation: location,
          totalWorkedStr: totalWorked,
        ),
      );
    }

    return result;
  }

  List<AttendanceLog> _getFilteredLogs() {
    final int year = int.tryParse(_selectedYear) ?? 2026;
    final int month = _getMonthNumber(_selectedMonth);
    final monthLogs = _getMonthlyAttendanceLogs(year, month);

    final filtered = monthLogs.where((log) {
      // Status filter
      if (_selectedStatus != 'All Statuses') {
        final statusUpper = log.status.toUpperCase();
        final filterUpper = _selectedStatus.toUpperCase();
        if (filterUpper == 'ON LEAVE' || filterUpper == 'LEAVE') {
          if (!statusUpper.contains('LEAVE')) return false;
        } else if (filterUpper == 'PRESENT') {
          if (statusUpper != 'PRESENT') return false;
        } else if (filterUpper == 'WORK FROM HOME' || filterUpper == 'WFH') {
          if (!statusUpper.contains('WORK FROM HOME') && !statusUpper.contains('WFH')) return false;
        } else if (filterUpper == 'ABSENT') {
          if (statusUpper != 'ABSENT') return false;
        } else if (filterUpper == 'HOLIDAY') {
          if (statusUpper != 'HOLIDAY') return false;
        } else if (filterUpper == 'LATE') {
          if (statusUpper != 'LATE') return false;
        } else if (statusUpper != filterUpper) {
          return false;
        }
      }

      // Location filter
      if (_selectedLocation != 'All Locations') {
        if (!log.workLocation.toLowerCase().contains(_selectedLocation.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();

    int perPage = 10;
    if (_selectedPerPage.contains('25')) perPage = 25;
    if (_selectedPerPage.contains('50')) perPage = 50;

    return filtered.take(perPage).toList();
  }

  void _handleClockToggle() {
    if (widget.onClockToggle != null) {
      widget.onClockToggle!();
      return;
    }

    if (widget.state.isClockedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.access_time_rounded, color: Color(0xFFEA580C)),
              SizedBox(width: 10),
              Text('Clock Out Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Text('Are you sure you want to end your active shift and clock out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.state.clockOutShift();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully clocked out of your shift!'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                }
              },
              child: const Text('Clock Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (!widget.state.isAdmin && widget.state.hasCompletedShiftToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Shift completed for today. Employees and interns can only clock in and clock out once per day.',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => GeofenceVerificationModal(
          userRole: widget.state.userProfile.role,
          userName: widget.state.userProfile.name,
          isAdmin: widget.state.isAdmin,
          hasCompletedShiftToday: widget.state.hasCompletedShiftToday,
          onConfirmClockIn: (result, isRemoteExemption) async {
            if (isRemoteExemption) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Remote work approval requested. You have not been clocked in.',
                    ),
                  ),
                );
              }
              return;
            }

            if (!widget.state.isAdmin && widget.state.hasCompletedShiftToday) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Shift completed for today. Employees and interns can only clock in and clock out once per day.',
                    ),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
              return;
            }

            await widget.state.clockInWithGeofence(
              distanceMeters: result.distanceMeters,
              isRemoteExemption: false,
              userLat: result.userLat,
              userLng: result.userLng,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Clocked in: on-site verified (${result.distanceMeters.toInt()}m from HQ).',
                  ),
                  backgroundColor: AppColors.primaryPine,
                ),
              );
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLight : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textLightMuted : const Color(0xFF64748B);
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5);

    final isClockedIn = widget.state.isClockedIn;
    final liveHours = _calculateShiftProgressHours(_currentTime, isClockedIn);
    final targetShiftHours = widget.state.shiftTargetHours;
    final progressPercent = widget.state.shiftCompletionPercent;
    final countdownStr = _calculateShiftCountdown(_currentTime);
    final cutoffHour = widget.state.autoClockOutCutoffHour;
    final cutoffFormatted = '$cutoffHour:00';

    final filteredLogs = _getFilteredLogs();

    final bodyContent = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shift Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.access_time_rounded, color: Color(0xFFEA580C), size: 20),
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
                                'Shift: Innoveity shift 2',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'WORKING',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Scheduled Hours: 10:00 - $cutoffFormatted',
                            style: TextStyle(fontSize: 11.5, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Main Section: Clock-In Portal Card & Telemetry / Geofence Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 780;

                  final clockInCard = _buildClockInCard(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    isClockedIn: isClockedIn,
                    liveHours: liveHours,
                    targetShiftHours: targetShiftHours,
                    progressPercent: progressPercent,
                    countdownStr: countdownStr,
                    cutoffFormatted: cutoffFormatted,
                  );

                  final telemetryCards = Column(
                    children: [
                      _buildTelemetryCard(
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isClockedIn: isClockedIn,
                      ),
                      const SizedBox(height: 12),
                      _buildGeofenceCard(
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isClockedIn: isClockedIn,
                      ),
                    ],
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: clockInCard),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: telemetryCards),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      clockInCard,
                      const SizedBox(height: 16),
                      telemetryCards,
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Attendance History Section
              _buildAttendanceHistorySection(
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBg: cardBg,
                borderColor: borderColor,
                logs: filteredLogs,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      );

    if (widget.isEmbedded) {
      return Container(
        color: bgCanvas,
        child: bodyContent,
      );
    }

    return Scaffold(
      drawer: AppDrawer(state: widget.state, activeRoute: 'attendance'),
      backgroundColor: bgCanvas,
      appBar: AppBar(
        leading: AppDropdownMenu(state: widget.state),
        titleSpacing: 8,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFEA580C),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Attendance Portal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: widget.state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('9+', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: buildUserAvatar(
              avatar: widget.state.userProfile.avatar,
              name: widget.state.userProfile.name,
              size: 28,
              backgroundColor: const Color(0xFFEA580C),
              fontSize: 12,
            ),
          ),
        ],
      ),
      body: bodyContent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.headerDarkPine : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderCardDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 2,
          onTap: (index) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            widget.state.setTab(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
          selectedItemColor: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
          unselectedItemColor: isDark ? AppColors.textLightMuted : AppColors.textMuted,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_rounded),
              activeIcon: Icon(Icons.access_time_filled_rounded),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Leaves',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Clock In / Clock Out Central Panel
  Widget _buildClockInCard({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBg,
    required Color borderColor,
    required bool isClockedIn,
    required double liveHours,
    required double targetShiftHours,
    required int progressPercent,
    required String countdownStr,
    required String cutoffFormatted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Clock Badge Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFEDD5), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.access_time_rounded, color: Color(0xFFEA580C), size: 26),
            ),
          ),

          const SizedBox(height: 14),

          // Big Live Digital Clock
          Text(
            _formatLiveClock(_currentTime),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEA580C),
              letterSpacing: 1.2,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: 4),

          // Live Date
          Text(
            _formatLiveDate(_currentTime),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),

          const SizedBox(height: 14),

          // Status Pills Row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isClockedIn ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isClockedIn ? const Color(0xFFFFEDD5) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isClockedIn ? const Color(0xFFEA580C) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isClockedIn ? 'ON SHIFT • CLOCKED IN (PRESENT)' : 'OFFLINE • NOT CLOCKED IN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isClockedIn ? const Color(0xFFEA580C) : const Color(0xFFEF4444),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF059669)),
                    SizedBox(width: 5),
                    Text(
                      'Auto Clock-Out',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Live Check-in time & Active Working Time telemetry (when clocked in)
          if (isClockedIn) ...[
            Text.rich(
              TextSpan(
                text: 'Checked In: ',
                style: TextStyle(fontSize: 11.5, color: textMuted),
                children: [
                  TextSpan(
                    text: widget.state.clockInTimeDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' • Active Duration: ',
                    style: TextStyle(color: textMuted),
                  ),
                  TextSpan(
                    text: widget.state.formattedClockTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Shift Countdown
          Text.rich(
            TextSpan(
              text: 'Shift Countdown: ',
              style: TextStyle(fontSize: 11.5, color: textMuted),
              children: [
                TextSpan(
                  text: countdownStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                    fontFamily: 'monospace',
                  ),
                ),
                TextSpan(
                  text: ' • Ends: ',
                  style: TextStyle(color: textMuted),
                ),
                TextSpan(
                  text: cutoffFormatted,
                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Shift Progress Bar
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Shift Progress (${liveHours.toStringAsFixed(1)} hrs)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progressPercent% (${targetShiftHours.toStringAsFixed(1)}h Target)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (progressPercent / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Big Clock In / Clock Out Action Button
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleClockToggle,
                icon: Icon(
                  isClockedIn ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  isClockedIn ? 'Clock Out' : 'Clock In',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClockedIn ? const Color(0xFFEF4444) : const Color(0xFF058A5E),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Telemetry Card
  Widget _buildTelemetryCard({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBg,
    required Color borderColor,
    required bool isClockedIn,
  }) {
    final liveGpsStr = widget.state.lastClockInDistance != null
        ? '${widget.state.lastClockInDistance!.toInt()}m from HQ (Verified)'
        : (isClockedIn ? 'HQ Geofence (On-Site)' : 'Ready for GPS check');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.laptop_mac_outlined, size: 16, color: Color(0xFFEA580C)),
              const SizedBox(width: 8),
              Text(
                'SYSTEM & IP TELEMETRY',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTelemetryRow('Check-in Time:', widget.state.clockInTimeDisplay, textPrimary: textPrimary, textMuted: textMuted),
          Divider(height: 14, thickness: 0.8, color: borderColor),
          _buildTelemetryRow('Working Hours:', widget.state.formattedClockTime, isMonospace: true, highlightColor: isClockedIn ? const Color(0xFFEA580C) : null, textPrimary: textPrimary, textMuted: textMuted),
          Divider(height: 14, thickness: 0.8, color: borderColor),
          _buildTelemetryRow('Network IP:', '106.51.59.160', isMonospace: true, textPrimary: textPrimary, textMuted: textMuted),
          Divider(height: 14, thickness: 0.8, color: borderColor),
          _buildTelemetryRow('Device Type:', 'Desktop', textPrimary: textPrimary, textMuted: textMuted),
          Divider(height: 14, thickness: 0.8, color: borderColor),
          _buildTelemetryRow('Live GPS:', liveGpsStr, highlightColor: isClockedIn ? const Color(0xFF059669) : const Color(0xFFEA580C), textPrimary: textPrimary, textMuted: textMuted),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(
    String label,
    String value, {
    bool isMonospace = false,
    Color? highlightColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: TextStyle(fontSize: 11.5, color: textMuted))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              fontFamily: isMonospace ? 'monospace' : null,
              color: highlightColor ?? textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Geofence Policy Card
  Widget _buildGeofenceCard({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBg,
    required Color borderColor,
    required bool isClockedIn,
  }) {
    final statusColor = isClockedIn ? const Color(0xFF059669) : const Color(0xFFEA580C);
    final statusLabel = isClockedIn
        ? 'Location Verified (On-Site)'
        : 'Premise Geofence Active (100m)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Text(
                'GEOFENCE POLICY',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Clock-in requires active GPS coordinates within the office radius unless Work From Home is sanctioned.',
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isClockedIn ? Icons.check_circle_rounded : Icons.radar_rounded,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: statusColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Attendance History Section
  Widget _buildAttendanceHistorySection({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBg,
    required Color borderColor,
    required List<AttendanceLog> logs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Table / Calendar toggle
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 640;

            final headerText = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.calendar_month_outlined, size: 20, color: Color(0xFFEA580C)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance History',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Complete audit log of your daily attendance records, work locations, and shift durations.',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final viewToggle = Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleBtn(
                    label: 'Table View',
                    icon: Icons.table_chart_outlined,
                    isActive: _viewMode == 'table',
                    isDark: isDark,
                    onTap: () => setState(() => _viewMode = 'table'),
                  ),
                  _buildToggleBtn(
                    label: 'Calendar View',
                    icon: Icons.calendar_today_outlined,
                    isActive: _viewMode == 'calendar',
                    isDark: isDark,
                    onTap: () => setState(() => _viewMode = 'calendar'),
                  ),
                ],
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerText,
                  const SizedBox(height: 10),
                  viewToggle,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: headerText),
                const SizedBox(width: 16),
                viewToggle,
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        // 5 Dropdown Filters Bar (Image 2)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 620;

              final monthFilter = _buildFilterItem('MONTH', _selectedMonth, _months, (v) => setState(() => _selectedMonth = v!), isDark, textMuted, textPrimary, cardBg);
              final yearFilter = _buildFilterItem('YEAR', _selectedYear, _years, (v) => setState(() => _selectedYear = v!), isDark, textMuted, textPrimary, cardBg);
              final statusFilter = _buildFilterItem('STATUS', _selectedStatus, _statuses, (v) => setState(() => _selectedStatus = v!), isDark, textMuted, textPrimary, cardBg);
              final locFilter = _buildFilterItem('LOCATION', _selectedLocation, _locations, (v) => setState(() => _selectedLocation = v!), isDark, textMuted, textPrimary, cardBg);
              final perPageFilter = _buildFilterItem('PER PAGE', _selectedPerPage, _perPageOptions, (v) => setState(() => _selectedPerPage = v!), isDark, textMuted, textPrimary, cardBg);

              if (isMobile) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    SizedBox(width: (constraints.maxWidth - 24) / 2, child: monthFilter),
                    SizedBox(width: (constraints.maxWidth - 24) / 2, child: yearFilter),
                    SizedBox(width: (constraints.maxWidth - 24) / 2, child: statusFilter),
                    SizedBox(width: (constraints.maxWidth - 24) / 2, child: locFilter),
                    SizedBox(width: constraints.maxWidth - 16, child: perPageFilter),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: monthFilter),
                  const SizedBox(width: 8),
                  Expanded(child: yearFilter),
                  const SizedBox(width: 8),
                  Expanded(child: statusFilter),
                  const SizedBox(width: 8),
                  Expanded(child: locFilter),
                  const SizedBox(width: 8),
                  Expanded(child: perPageFilter),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Table View or Calendar View
        if (_viewMode == 'table')
          _buildTableView(logs: logs, cardBg: cardBg, borderColor: borderColor, textPrimary: textPrimary, textMuted: textMuted, isDark: isDark)
        else
          _buildCalendarView(cardBg: cardBg, borderColor: borderColor, textPrimary: textPrimary, textMuted: textMuted, isDark: isDark),
      ],
    );
  }

  Widget _buildToggleBtn({
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? const Color(0xFFEA580C) : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    bool isDark,
    Color textMuted,
    Color textPrimary,
    Color cardBg,
  ) {
    final uniqueItems = <String>[];
    final seen = <String>{};
    for (final i in items) {
      if (seen.add(i)) uniqueItems.add(i);
    }
    String effectiveValue = value;
    if (!uniqueItems.contains(effectiveValue)) {
      if (effectiveValue.toUpperCase() == 'WFH' && uniqueItems.contains('WORK FROM HOME')) {
        effectiveValue = 'WORK FROM HOME';
      } else if (effectiveValue.toUpperCase() == 'WORK FROM HOME' && uniqueItems.contains('WFH')) {
        effectiveValue = 'WFH';
      } else if (uniqueItems.isNotEmpty) {
        effectiveValue = uniqueItems.first;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              dropdownColor: cardBg,
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: textMuted),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary),
              items: uniqueItems.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Table View (Image 2)
  Widget _buildTableView({
    required List<AttendanceLog> logs,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 700),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                DataColumn(label: Text('CLOCK IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                DataColumn(label: Text('CLOCK OUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                DataColumn(label: Text('WORK LOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                DataColumn(label: Text('TOTAL WORKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
              ],
              rows: logs.map((log) {
                return DataRow(
                  cells: [
                    // DATE
                    DataCell(
                      Text(
                        log.date,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ),
                    // CLOCK IN
                    DataCell(
                      Text(
                        log.checkIn,
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                    ),
                    // CLOCK OUT
                    DataCell(
                      Text(
                        log.checkOut,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: log.checkOut == 'Shift Active' ? FontWeight.bold : FontWeight.normal,
                          color: log.checkOut == 'Shift Active' ? const Color(0xFFEA580C) : textPrimary,
                        ),
                      ),
                    ),
                    // WORK LOCATION
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (log.workLocation.toLowerCase() == 'office') ...[
                            const Icon(Icons.business_outlined, size: 14, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 6),
                            Text('Office', style: TextStyle(fontSize: 12, color: textPrimary)),
                          ] else if (log.workLocation.toLowerCase() == 'home') ...[
                            const Icon(Icons.home_outlined, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text('Home', style: TextStyle(fontSize: 12, color: textPrimary)),
                          ] else ...[
                            Text('—', style: TextStyle(fontSize: 12, color: textMuted)),
                          ],
                        ],
                      ),
                    ),
                    // TOTAL WORKED
                    DataCell(
                      Text(
                        log.displayTotalWorked,
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                    ),
                    // STATUS
                    DataCell(_buildStatusBadge(log.status)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData? icon;

    final s = status.toUpperCase();
    if (s == 'PRESENT') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      icon = Icons.check_circle_outline_rounded;
    } else if (s.contains('WORK FROM HOME') || s.contains('WFH')) {
      bg = const Color(0xFFCCFBF1);
      fg = const Color(0xFF0F766E);
      icon = Icons.home_work_outlined;
    } else if (s == 'HOLIDAY') {
      bg = const Color(0xFFEDE9FE);
      fg = const Color(0xFF6D28D9);
    } else if (s == 'ABSENT') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      icon = Icons.cancel_outlined;
    } else if (s.contains('SICK') || s.contains('CASUAL') || s.contains('LEAVE') || s == 'LATE') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      icon = Icons.event_busy_outlined;
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            s,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  // Calendar View
  Widget _buildCalendarView({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    final daysInWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Month navigation bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  _showMonthYearSelectionDialog(context, isDark, textPrimary, textMuted, cardBg, borderColor);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_selectedMonth $_selectedYear',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: textMuted),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Previous Month',
                    onPressed: _previousMonth,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Next Month',
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Day header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysInWeek
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 8),
          // Dynamic Days Grid for selected month and year
          Builder(
            builder: (ctx) {
              final int year = int.tryParse(_selectedYear) ?? 2026;
              final int month = _getMonthNumber(_selectedMonth);

              // Number of days in selected month
              final int daysInMonth = DateTime(year, month + 1, 0).day;

              // Weekday of 1st day of month: Mon=1..Sun=7 -> offset Mon=0..Sun=6
              final int firstDayOffset = DateTime(year, month, 1).weekday - 1;

              // Total cells required (multiple of 7)
              final int totalCells = ((firstDayOffset + daysInMonth + 6) ~/ 7) * 7;

              // Map logs by day number for fast status lookup
              final monthLogs = _getMonthlyAttendanceLogs(year, month);
              final Map<int, AttendanceLog> logByDay = {};
              for (final l in monthLogs) {
                final parts = l.date.trim().split(' ');
                if (parts.isNotEmpty) {
                  final dNum = int.tryParse(parts[0]);
                  if (dNum != null) {
                    logByDay[dNum] = l;
                  }
                }
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (ctx, i) {
                  final dayNumber = i - firstDayOffset + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final dateObj = DateTime(year, month, dayNumber);
                  final isWeekend = dateObj.weekday == DateTime.saturday || dateObj.weekday == DateTime.sunday;
                  final isToday = (year == 2026 && month == 10 && dayNumber == 26);
                  final isFuture = dateObj.isAfter(DateTime(2026, 10, 26));

                  // Determine status for this day
                  String? dayStatus;
                  if (logByDay.containsKey(dayNumber)) {
                    dayStatus = logByDay[dayNumber]!.status;
                  } else if (isWeekend) {
                    dayStatus = 'HOLIDAY';
                  } else if (!isFuture) {
                    dayStatus = 'PRESENT';
                  }

                  if (dayStatus == 'UPCOMING') {
                    dayStatus = null;
                  }

                  Color? statusColor;
                  final s = (dayStatus ?? '').toUpperCase();
                  if (s == 'PRESENT') statusColor = const Color(0xFF10B981);
                  if (s == 'ABSENT') statusColor = const Color(0xFFEF4444);
                  if (s.contains('WORK FROM HOME') || s.contains('WFH')) statusColor = const Color(0xFF0D9488);
                  if (s.contains('LEAVE') || s.contains('CASUAL') || s.contains('SICK') || s == 'LATE') {
                    statusColor = const Color(0xFFF59E0B);
                  }
                  if (s == 'HOLIDAY') statusColor = const Color(0xFF8B5CF6);

              final hasStatus = statusColor != null;

              Color cellBg;
              if (isToday) {
                cellBg = const Color(0xFFEA580C).withValues(alpha: 0.16);
              } else if (hasStatus) {
                cellBg = statusColor.withValues(alpha: isDark ? 0.22 : 0.10);
              } else {
                cellBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
              }

              Color cellBorderColor;
              if (isToday) {
                cellBorderColor = const Color(0xFFEA580C);
              } else if (hasStatus) {
                cellBorderColor = statusColor.withValues(alpha: isDark ? 0.60 : 0.40);
              } else {
                cellBorderColor = borderColor;
              }

              Color cellTextColor;
              if (isToday) {
                cellTextColor = const Color(0xFFEA580C);
              } else if (hasStatus) {
                cellTextColor = isDark
                    ? statusColor
                    : (statusColor == const Color(0xFF10B981)
                        ? const Color(0xFF047857)
                        : (statusColor == const Color(0xFFEF4444)
                            ? const Color(0xFFB91C1C)
                            : (statusColor == const Color(0xFF0D9488)
                                ? const Color(0xFF0F766E)
                                : (statusColor == const Color(0xFFF59E0B)
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF6D28D9)))));
              } else {
                cellTextColor = textMuted;
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cellBorderColor,
                    width: isToday ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: (isToday || hasStatus) ? FontWeight.bold : FontWeight.w500,
                        color: cellTextColor,
                      ),
                    ),
                    if (hasStatus) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          // Attendance Legend
          _buildAttendanceLegend(isDark: isDark, borderColor: borderColor),
        ],
      ),
    );
  }

  Widget _buildAttendanceLegend({
    required bool isDark,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildLegendChip(label: 'Present', color: const Color(0xFF10B981), isDark: isDark),
          _buildLegendChip(label: 'Absent', color: const Color(0xFFEF4444), isDark: isDark),
          _buildLegendChip(label: 'WFH', color: const Color(0xFF0D9488), isDark: isDark),
          _buildLegendChip(label: 'Sick or Casual Leave', color: const Color(0xFFF59E0B), isDark: isDark),
          _buildLegendChip(label: 'Holiday', color: const Color(0xFF8B5CF6), isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildLegendChip({
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.28 : 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.2),
          ),
          child: Center(
            child: Container(
              width: 4.5,
              height: 4.5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  void _showMonthYearSelectionDialog(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardBg,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month & Year',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Years selector row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _years.map((y) {
                        final isSelected = y == _selectedYear;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(y),
                            selected: isSelected,
                            selectedColor: const Color(0xFFEA580C),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setSheetState(() => _selectedYear = y);
                                setState(() => _selectedYear = y);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Months Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (ctx, idx) {
                      final mName = _months[idx];
                      final isSelected = mName == _selectedMonth;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedMonth = mName);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEA580C)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              mName.substring(0, 3),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
