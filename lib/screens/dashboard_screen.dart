import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/split_flap_clock.dart';

class DashboardScreen extends StatefulWidget {
  final List<TaskItem> tasks;
  final VoidCallback onClockToggle;
  final bool isClockedIn;
  final String formattedClockTime;
  final Function(int) onNavigateTab;
  final VoidCallback onOpenDesk;
  final String userRole;
  final String? autoClockOutNotice;
  final String clockInTime;
  final String userId;
  final String userEmployeeId;
  final String userEmail;
  final String userName;
  final String? userAvatar;
  final String? userDepartment;
  final List<AttendanceLog> attendanceLogs;
  final int shiftCompletionPercent;
  final double shiftCompletionRatio;
  final LeaveRequest? latestApprovedLeave;
  final bool showLeaveApprovalNotice;
  final VoidCallback? onDismissLeaveNotice;
  final VoidCallback? onOpenAnnouncements;

  const DashboardScreen({
    super.key,
    required this.tasks,
    required this.onClockToggle,
    required this.isClockedIn,
    required this.formattedClockTime,
    required this.onNavigateTab,
    required this.onOpenDesk,
    this.onOpenAnnouncements,
    this.userRole = 'EMPLOYEE',
    this.autoClockOutNotice,
    this.clockInTime = 'Not Clocked In',
    this.userId = '',
    this.userEmployeeId = '',
    this.userEmail = '',
    this.userName = '',
    this.userAvatar,
    this.userDepartment,
    this.attendanceLogs = const [],
    this.shiftCompletionPercent = 0,
    this.shiftCompletionRatio = 0.0,
    this.latestApprovedLeave,
    this.showLeaveApprovalNotice = false,
    this.onDismissLeaveNotice,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _currentTime;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  List<TaskItem> get tasks => widget.tasks;
  VoidCallback get onClockToggle => widget.onClockToggle;
  bool get isClockedIn => widget.isClockedIn;
  String get formattedClockTime => widget.formattedClockTime;
  Function(int) get onNavigateTab => widget.onNavigateTab;
  VoidCallback get onOpenDesk => widget.onOpenDesk;
  String get userRole => widget.userRole;
  String? get autoClockOutNotice => widget.autoClockOutNotice;
  String get clockInTime => widget.clockInTime;
  String get userId => widget.userId;
  String get userEmployeeId => widget.userEmployeeId;
  String get userEmail => widget.userEmail;
  String get userName => widget.userName;
  String? get userAvatar => widget.userAvatar;
  String? get userDepartment => widget.userDepartment;
  List<AttendanceLog> get attendanceLogs => widget.attendanceLogs;
  int get shiftCompletionPercent => widget.shiftCompletionPercent;
  double get shiftCompletionRatio => widget.shiftCompletionRatio;
  LeaveRequest? get latestApprovedLeave => widget.latestApprovedLeave;
  bool get showLeaveApprovalNotice => widget.showLeaveApprovalNotice;
  VoidCallback? get onDismissLeaveNotice => widget.onDismissLeaveNotice;

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatLiveClockTime() {
    final rawHour = _currentTime.hour;
    final hour = rawHour % 12 == 0 ? 12 : rawHour % 12;
    final h = hour.toString().padLeft(2, '0');
    final m = _currentTime.minute.toString().padLeft(2, '0');
    final s = _currentTime.second.toString().padLeft(2, '0');
    final period = rawHour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $period';
  }

  String _formatLiveClockDate() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdayStr = weekdays[_currentTime.weekday - 1];
    final monthStr = months[_currentTime.month - 1];
    return '$weekdayStr, $monthStr ${_currentTime.day}, ${_currentTime.year}';
  }

  bool _isLateArrival(String timeStr) {
    if (timeStr == 'Not Clocked In') return false;
    try {
      final clean = timeStr.trim().toUpperCase();
      if (clean.contains('AM')) {
        final timeOnly = clean.replaceAll('AM', '').trim();
        final parts = timeOnly.split(':');
        if (parts.isNotEmpty) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          if (hour == 12) return false;
          if (hour > 10 || (hour == 10 && minute > 0)) return true;
        }
      } else if (clean.contains('PM')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Widget _buildWelcomeDialogueBox(BuildContext context, bool isDark) {
    final isCompact = MediaQuery.sizeOf(context).width < 520;
    final roleStr = widget.userRole.toUpperCase();
    final idLabel = roleStr == 'INTERN'
        ? 'Intern ID'
        : (['ADMIN', 'SUPER_ADMIN'].contains(roleStr) ? 'Admin ID' : 'Employee ID');
    final idVal = widget.userEmployeeId.isNotEmpty ? widget.userEmployeeId : 'IN-1001';
    final deptVal = (widget.userDepartment != null && widget.userDepartment!.isNotEmpty)
        ? widget.userDepartment!
        : 'Mobile Application Development';
    final displayName = widget.userName.isNotEmpty ? widget.userName : 'Daniel Paul';

    final userInfoSection = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with status indicator
        Stack(
          children: [
            buildUserAvatar(
              avatar: widget.userAvatar,
              name: displayName,
              size: 52,
              backgroundColor: const Color(0xFFFF6433),
              fontSize: 24,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    width: 2.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // User Name, Role Pill, and Metadata Line
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_getGreeting()}, $displayName 👋',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Role Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF431407).withValues(alpha: 0.6)
                      : const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF9A3412) : const Color(0xFFFFD4C4),
                    width: 1,
                  ),
                ),
                child: Text(
                  roleStr,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle metadata details
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 2,
                children: [
                  Text(
                    '$idLabel: ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    idVal,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'Dept: ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    deptVal,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'Team: ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'No Team Assigned',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final clockSection = SizedBox(
      width: isCompact ? double.infinity : null,
      child: SplitFlapClock(
        currentTime: _currentTime,
        isDark: isDark,
      ),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userInfoSection,
                const SizedBox(height: 12),
                clockSection,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: userInfoSection),
                const SizedBox(width: 14),
                clockSection,
              ],
            ),
    );
  }

  Widget _buildLeaveApprovedNotification(BuildContext context, bool isDark) {
    if (latestApprovedLeave == null) return const SizedBox.shrink();
    final leave = latestApprovedLeave!;
    final isIntern = userRole.toUpperCase() == 'INTERN';

    void handleMarkAsRead() {
      onDismissLeaveNotice?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave approval message marked as read.'),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF059669) : const Color(0xFF10B981),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: handleMarkAsRead,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isIntern ? 'Intern Leave Sanctioned! 🎉' : 'Leave Request Approved! 🎉',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF065F46),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'APPROVED',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your ${leave.leaveType} (${leave.daysCount} Day) from ${leave.startDate} to ${leave.endDate} has been approved by Admin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: handleMarkAsRead,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 12, color: isDark ? Colors.white : const Color(0xFF047857)),
                              const SizedBox(width: 4),
                              Text(
                                'Mark as Read',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismissLeaveNotice != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF047857),
                    ),
                    onPressed: handleMarkAsRead,
                    tooltip: 'Mark as Read & Dismiss',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    final completedCount = tasks.where((t) => t.status == 'Completed').length;
    final pendingCount = tasks.where((t) => t.status == 'Pending').length;
    final isLate = isClockedIn && _isLateArrival(clockInTime);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Dialogue Box with Standard Live Clock (Replacing Countdown Clock Box)
          _buildWelcomeDialogueBox(context, isDark),

          // Leave Approved Notification Banner (Only for employee/intern; never shown on admin side)
          if (showLeaveApprovalNotice &&
              latestApprovedLeave != null &&
              userRole.toUpperCase() != 'ADMIN')
            _buildLeaveApprovedNotification(context, isDark),

          // Shift Attendance Summary Card
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 10 : 12),
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.access_time_filled,
                                color: AppColors.primaryPine,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Today's Shift Attendance",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Shift status & daily progress",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isClockedIn
                                  ? AppColors.completedBg
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isClockedIn
                                    ? AppColors.completedBorder
                                    : Colors.orange[300]!,
                              ),
                            ),
                            child: Text(
                              isClockedIn
                                  ? 'Shift Active (Geofence Verified)'
                                  : 'Clocked Out (Off Duty)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isClockedIn
                                    ? AppColors.completedText
                                    : Colors.orange[900],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 4-Grid Time Metrics (Replacing CHECK OUT with LATE WARNINGS)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isCompact ? 1.85 : 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildMetricTile(
                        context,
                        label: 'CHECK IN',
                        value: isClockedIn
                            ? clockInTime
                            : (clockInTime != '--' && clockInTime != 'Not Clocked In' && clockInTime.isNotEmpty
                                ? clockInTime
                                : 'Not Clocked In'),
                        subtitle: isClockedIn
                            ? 'HQ Geofence Verified'
                            : (clockInTime != '--' && clockInTime != 'Not Clocked In' && clockInTime.isNotEmpty
                                ? 'Shift Completed'
                                : null),
                      ),
                      _buildMetricTile(
                        context,
                        label: 'LATE WARNINGS',
                        value: isLate ? '1 / 3 Warning Used' : (isClockedIn ? 'On Time (0/3)' : '0 / 3 Warnings Used'),
                        subtitle: isLate
                            ? 'Checked in after 10:00 AM'
                            : '10:00 AM Cutoff (3 Max)',
                        valueColor: isLate
                            ? const Color(0xFFDC2626)
                            : (isDark ? AppColors.vibrantEmerald : AppColors.primaryPine),
                      ),
                      _buildMetricTile(
                        context,
                        label: 'WORKING HOURS',
                        value: formattedClockTime,
                        valueColor: isClockedIn
                            ? AppColors.primaryPine
                            : (formattedClockTime != '00:00:00'
                                ? (isDark ? AppColors.vibrantEmerald : AppColors.primaryPine)
                                : AppColors.textMuted),
                      ),
                      _buildMetricTile(
                        context,
                        label: 'WORKING HOUR TARGET',
                        value: userRole.toUpperCase() == 'INTERN'
                            ? '7.0 Hours'
                            : '8.0 Hours',
                        subtitle: userRole.toUpperCase() == 'INTERN'
                            ? 'Intern Shift Target'
                            : 'Staff Daily Target',
                        valueColor: isDark
                            ? AppColors.vibrantEmerald
                            : AppColors.primaryPine,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Main Shift Action Button inside Card
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: onClockToggle,
                      icon: Icon(
                        isClockedIn ? Icons.timer_off : Icons.my_location,
                        size: 16,
                      ),
                      label: Text(
                        isClockedIn ? 'Clock Out' : 'Clock In',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isClockedIn
                            ? Colors.amber[800]
                            : AppColors.primaryPine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userRole.toUpperCase() == 'INTERN'
                            ? 'Shift Completion Target (7.0 Hours)'
                            : 'Shift Completion Target (8.0 Hours)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '$shiftCompletionPercent%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isClockedIn
                              ? AppColors.primaryPine
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: shiftCompletionRatio,
                      minHeight: 6,
                      backgroundColor: AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.vibrantEmerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Action Pills Horizontal Bar (End of initial above-the-fold screen view)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.onOpenAnnouncements != null) ...[
                  _buildActionPill(
                    icon: Icons.campaign_outlined,
                    label: 'Announcements',
                    onTap: widget.onOpenAnnouncements!,
                    color: const Color(0xFFEA580C),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildActionPill(
                  icon: Icons.confirmation_number_outlined,
                  label: 'IT Support Ticket',
                  onTap: onOpenDesk,
                  color: AppColors.primaryPine,
                ),
                const SizedBox(width: 8),
                _buildActionPill(
                  icon: Icons.assignment_ind_outlined,
                  label: 'View Payslip',
                  onTap: () => onNavigateTab(4), // Profile / Payslip
                  color: AppColors.primaryPine,
                ),
                const SizedBox(width: 8),
                _buildActionPill(
                  icon: Icons.notifications_active_outlined,
                  label: '🔔 Test Push Alert',
                  onTap: () => PushNotificationService().showNotification(
                    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    title: 'Stitch Enterprise Notification',
                    body: 'Your shift report has been processed successfully.',
                  ),
                  color: AppColors.vibrantEmerald,
                ),
                const SizedBox(width: 8),
                _buildActionPill(
                  icon: Icons.event_available,
                  label: '+ Apply Leave',
                  onTap: () => onNavigateTab(3), // Leaves tab
                  color: AppColors.primaryPine,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick KPI Metrics Grid (Below the fold)

          // Quick KPI Metrics Grid
          Text(
            'Overview Metrics',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildKpiCard(
                context,
                title: 'TOTAL TASKS',
                value: '${tasks.length}',
                subtitle: 'Assigned to you',
                icon: Icons.assignment_outlined,
                iconColor: AppColors.primaryPine,
                onTap: () => onNavigateTab(1),
              ),
              _buildKpiCard(
                context,
                title: 'COMPLETED',
                value: '$completedCount',
                subtitle: 'Approved deliverables',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.vibrantEmerald,
                onTap: () => onNavigateTab(1),
              ),
              _buildKpiCard(
                context,
                title: 'ATTENDANCE %',
                value: '88%',
                subtitle: 'This month',
                icon: Icons.pie_chart_outline,
                iconColor: AppColors.primaryPine,
                onTap: () => onNavigateTab(2),
              ),
              _buildKpiCard(
                context,
                title: 'PENDING',
                value: '$pendingCount',
                subtitle: 'Action items',
                icon: Icons.pending_actions,
                iconColor: AppColors.pendingText,
                onTap: () => onNavigateTab(1),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // User-Specific Performance Analytics & Productivity Section
          PerformanceAnalyticsCard(
            userId: userId,
            userEmail: userEmail,
            userName: userName,
            attendanceLogs: attendanceLogs,
          ),        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    String? subtitle,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? (isDark ? AppColors.textLight : AppColors.textDark),
              ),
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                  ),
                  Icon(icon, size: 18, color: iconColor),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
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
}

class PerformanceAnalyticsCard extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final List<AttendanceLog> attendanceLogs;

  const PerformanceAnalyticsCard({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.attendanceLogs,
  });

  @override
  State<PerformanceAnalyticsCard> createState() => _PerformanceAnalyticsCardState();
}

class _PerformanceAnalyticsCardState extends State<PerformanceAnalyticsCard> {
  String _selectedPeriod = '1W';
  int? _hoveredIndex;

  List<double> _getUserWeeklyHours() {
    final email = widget.userEmail.toLowerCase();
    if (email.contains('anto')) {
      return [6.8, 0.0, 0.0, 0.0, 6.7, 8.0, 0.5];
    } else if (email.contains('paul')) {
      return [7.5, 8.0, 0.0, 0.0, 8.2, 7.8, 4.2];
    } else if (email.contains('suraj')) {
      return [8.0, 7.8, 0.0, 0.0, 8.1, 8.2, 5.0];
    } else if (email.contains('employee')) {
      return [7.2, 7.5, 0.0, 0.0, 7.8, 8.0, 3.5];
    } else if (email.contains('yeshwanth')) {
      return [6.5, 7.0, 0.0, 0.0, 7.2, 7.5, 2.0];
    } else if (email.contains('prasath') || email.contains('raghul')) {
      return [7.0, 6.8, 0.0, 0.0, 7.0, 7.4, 1.5];
    } else if (email.contains('praveen')) {
      return [7.1, 7.3, 0.0, 0.0, 7.5, 7.8, 2.5];
    }

    final seed = email.hashCode.abs();
    return [
      ((seed % 25 + 60) / 10.0).clamp(0.0, 8.0),
      ((seed % 15 + 65) / 10.0).clamp(0.0, 8.0),
      0.0,
      0.0,
      ((seed % 20 + 60) / 10.0).clamp(0.0, 8.0),
      ((seed % 10 + 72) / 10.0).clamp(0.0, 8.0),
      ((seed % 30 + 10) / 10.0).clamp(0.0, 8.0),
    ];
  }

  List<double> _getUserMonthlyHours() {
    final weekly = _getUserWeeklyHours();
    final sum = weekly.fold(0.0, (a, b) => a + b);
    final base = sum > 0 ? sum : 25.0;
    return [
      (base * 1.3).clamp(20.0, 42.0),
      (base * 1.4).clamp(22.0, 43.0),
      (base * 1.35).clamp(21.0, 42.5),
      (base * 0.85).clamp(15.0, 30.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? AppColors.cardDark : Colors.white;

    final isWeekly = _selectedPeriod == '1W';
    final dataValues = isWeekly ? _getUserWeeklyHours() : _getUserMonthlyHours();
    final labels = isWeekly
        ? ['Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed']
        : ['W1', 'W2', 'W3', 'W4'];
    final yMax = isWeekly ? 8.0 : 45.0;
    final yTicks = isWeekly ? [8, 6, 4, 2, 0] : [45, 30, 20, 10, 0];

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderCol, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Toggle Pill Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance Analytics & Productivity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Weekly productivity hours and task velocity breakdown.',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Toggle Pill 1W | 1M
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = '1W'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == '1W'
                                ? (isDark ? AppColors.vibrantEmerald : AppColors.primaryPine)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '1W',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedPeriod == '1W'
                                  ? (isDark ? AppColors.headerDarkPine : Colors.white)
                                  : textMuted,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = '1M'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == '1M'
                                ? (isDark ? AppColors.vibrantEmerald : AppColors.primaryPine)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '1M',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedPeriod == '1M'
                                  ? (isDark ? AppColors.headerDarkPine : Colors.white)
                                  : textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bar Chart Grid Area with Y-Axis & X-Axis
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Y-Axis Labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: yTicks.map((val) {
                      return Text(
                        '$val',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textMuted,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 12),

                  // Chart Canvas with Gridlines and Bar Columns
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chartHeight = constraints.maxHeight - 24;
                        return Column(
                          children: [
                            SizedBox(
                              height: chartHeight,
                              child: Stack(
                                children: [
                                  // Horizontal Dotted / Dashed Gridlines
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(5, (idx) {
                                      return Container(
                                        height: 1,
                                        color: isDark
                                            ? AppColors.borderCardDark
                                            : const Color(0xFFF1F5F9),
                                      );
                                    }),
                                  ),

                                  // Bar Columns Container
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: List.generate(dataValues.length, (idx) {
                                      final hrs = dataValues[idx];
                                      final pct = (hrs / yMax).clamp(0.0, 1.0);
                                      final barH = pct * (chartHeight - 10);
                                      final isHovered = _hoveredIndex == idx;

                                      return GestureDetector(
                                        onTapDown: (_) => setState(() => _hoveredIndex = idx),
                                        child: MouseRegion(
                                          onEnter: (_) => setState(() => _hoveredIndex = idx),
                                          onExit: (_) => setState(() => _hoveredIndex = null),
                                          child: Tooltip(
                                            message: '${labels[idx]}: ${hrs.toStringAsFixed(1)} hrs',
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.headerDarkPine,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                if (isHovered && hrs > 0)
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.vibrantEmerald,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${hrs.toStringAsFixed(1)}h',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        color: AppColors.headerDarkPine,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  width: isWeekly ? (constraints.maxWidth < 350 ? 24 : 36) : 46,
                                                  height: barH > 4 ? barH : (hrs > 0 ? 4 : 0),
                                                  decoration: BoxDecoration(
                                                    color: isHovered
                                                        ? AppColors.vibrantEmerald
                                                        : AppColors.primaryPine,
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(8),
                                                    ),
                                                    boxShadow: isHovered
                                                        ? [
                                                            BoxShadow(
                                                              color: AppColors.vibrantEmerald.withValues(alpha: 0.4),
                                                              blurRadius: 8,
                                                              offset: const Offset(0, 2),
                                                            )
                                                          ]
                                                        : [],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // X-Axis Labels Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: labels.map((lbl) {
                                return Text(
                                  lbl,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textMuted,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
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
}
