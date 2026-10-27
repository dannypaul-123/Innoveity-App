import 'package:flutter/material.dart';

import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'leaves_screen.dart';
import 'profile_screen.dart';
import 'ticket_desk_screen.dart';
import 'daily_work_logs_screen.dart';
import 'active_board_screen.dart';
import 'roadmap_screen.dart';
import 'announcements_screen.dart';
import 'attendance_portal_screen.dart';
import '../widgets/geofence_verification_modal.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import '../widgets/app_avatar.dart';

class MainNavigationScreen extends StatelessWidget {
  final AppState state;

  const MainNavigationScreen({super.key, required this.state});

  void _handleClockToggleWithGeofence(BuildContext context) {
    if (state.isClockedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.access_time_rounded, color: Color(0xFFEA580C)),
              SizedBox(width: 10),
              Text(
                'Clock Out Confirmation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to end your active shift and clock out?',
          ),
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
                await state.clockOutShift();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully clocked out of your shift!'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                }
              },
              child: const Text(
                'Clock Out',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else if (!state.isAdmin && state.hasCompletedShiftToday) {
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
          userRole: state.userProfile.role,
          userName: state.userProfile.name,
          isAdmin: state.isAdmin,
          hasCompletedShiftToday: state.hasCompletedShiftToday,
          onConfirmClockIn: (result, isRemoteExemption) async {
            if (isRemoteExemption) {
              if (context.mounted) {
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

            if (!state.isAdmin && state.hasCompletedShiftToday) {
              if (context.mounted) {
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

            await state.clockInWithGeofence(
              distanceMeters: result.distanceMeters,
              isRemoteExemption: false,
              userLat: result.userLat,
              userLng: result.userLng,
            );
            if (context.mounted) {
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

  void _showQuickSearchModal(BuildContext context) {
    final isDark = state.isDarkMode;
    showSearch(
      context: context,
      delegate: AppQuickSearchDelegate(state: state, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final Widget homeScreenView = DashboardScreen(
      tasks: state.tasks,
      onClockToggle: () => _handleClockToggleWithGeofence(context),
      isClockedIn: state.isClockedIn,
      formattedClockTime: state.formattedClockTime,
      clockInTime: state.clockInTimeDisplay,
      shiftCompletionPercent: state.shiftCompletionPercent,
      shiftCompletionRatio: state.shiftCompletionRatio,
      onNavigateTab: state.setTab,
      onOpenDesk: () => _openTicketDesk(context),
      userRole: state.userProfile.role,
      autoClockOutNotice: state.autoClockOutNotice,
      userId: state.userProfile.id,
      userEmployeeId: state.userProfile.employeeId,
      userEmail: state.userProfile.email,
      userName: state.userProfile.name,
      userAvatar: state.userProfile.avatar,
      userDepartment: state.userProfile.department,
      attendanceLogs: state.attendanceLogs,
      latestApprovedLeave: state.currentApprovedLeave,
      showLeaveApprovalNotice: state.showLeaveApprovalNotice,
      onDismissLeaveNotice: state.dismissLeaveApprovalNotice,
      onOpenAnnouncements: () => _openAnnouncements(context),
    );

    final List<Widget> screens = [
      homeScreenView,
      TasksScreen(
        tasks: state.tasks,
        onAddTask: state.addTask,
        onUpdateTaskProgress: state.updateTaskProgress,
        userRole: state.userProfile.role,
      ),
      AttendancePortalScreen(
        state: state,
        isEmbedded: true,
        onClockToggle: () => _handleClockToggleWithGeofence(context),
      ),
      LeavesScreen(
        balances: state.leaveBalances,
        requests: state.leaveRequests,
        onApplyLeave: state.addLeaveRequest,
        userName: state.userProfile.name,
        userRole: state.userProfile.role,
        latestApprovedLeave: state.currentApprovedLeave,
        showLeaveApprovalNotice: state.showLeaveApprovalNotice,
        onDismissLeaveNotice: state.dismissLeaveApprovalNotice,
        allEmployees: state.allEmployees,
      ),
      ProfileScreen(
        userProfile: state.userProfile,
        payslips: state.rawPayslips,
        onLogout: state.logout,
        onToggleTheme: state.toggleTheme,
        isDarkMode: state.isDarkMode,
        onUpdateProfile: state.updateProfileDetails,
        onUpdateAvatar: state.updateAvatar,
      ),
    ];

    final activeRouteNames = ['dashboard', 'tasks', 'attendance', 'leaves', 'profile'];
    final currentRoute = activeRouteNames[state.currentTab.clamp(0, 4)];

    return Scaffold(
      drawer: AppDrawer(state: state, activeRoute: currentRoute),
      appBar: AppBar(
        leading: AppDropdownMenu(state: state),
        titleSpacing: 8,
        title: Row(
          children: [
            buildUserAvatar(
              avatar: state.userProfile.avatar,
              name: state.userProfile.name,
              size: 36,
              border: Border.all(color: AppColors.vibrantEmerald, width: 1.5),
              backgroundColor: AppColors.primaryPine,
              fontSize: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.userProfile.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${state.userProfile.employeeId} • ${state.userProfile.role.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: state.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () => _showQuickSearchModal(context),
            tooltip: 'Quick Search (proj, chat, pay, leave...)',
          ),
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onPressed: state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () => _openAnnouncements(context),
                tooltip: 'Announcements & Alerts',
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.vibrantEmerald,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: state.currentTab, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: state.isDarkMode ? AppColors.headerDarkPine : Colors.white,
          border: Border(
            top: BorderSide(
              color: state.isDarkMode ? AppColors.borderCardDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: state.currentTab,
          onTap: state.setTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: state.isDarkMode ? AppColors.headerDarkPine : Colors.white,
          selectedItemColor: state.isDarkMode ? AppColors.vibrantEmerald : AppColors.primaryPine,
          unselectedItemColor: state.isDarkMode ? AppColors.textLightMuted : AppColors.textMuted,
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
  },
);
}

  void _openAnnouncements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementsScreen(state: state),
      ),
    );
  }

  void _openTicketDesk(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDeskScreen(
          tickets: state.tickets,
          assets: state.assets,
          onAddTicket: state.addTicket,
          state: state,
        ),
      ),
    );
  }
}

class AppQuickSearchDelegate extends SearchDelegate<String> {
  final AppState state;
  final bool isDark;

  AppQuickSearchDelegate({required this.state, required this.isDark});

  @override
  String get searchFieldLabel => "Quick Search: type 'atten', 'proj', 'chat', 'pay', 'leave'...";

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.textDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          color: isDark ? Colors.white : AppColors.textDark,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim().toLowerCase();
    final items = [
      {'title': 'Active Board', 'desc': 'Scrum project board & task filters', 'type': 'proj', 'route': 'active_board'},
      {'title': 'Roadmap', 'desc': 'Gantt timeline & sprint releases', 'type': 'proj', 'route': 'roadmap'},
      {'title': 'My Work Logs', 'desc': 'Daily work log hours & submitted entries', 'type': 'log', 'route': 'worklogs'},
      {'title': 'Attendance Portal', 'desc': 'Clock-in history & working hours', 'type': 'atten', 'route': 'attendance'},
      {'title': 'Leave Management', 'desc': 'Leave balances & requests', 'type': 'leave', 'route': 'leaves'},
      {'title': 'Announcements', 'desc': 'Company notices & HR alerts', 'type': 'chat', 'route': 'announcements'},
      {'title': 'Salary & Payslips', 'desc': 'Monthly payroll breakdown & PDF', 'type': 'pay', 'route': 'profile'},
      {'title': 'IT Support Desk', 'desc': 'Submit & track support tickets and assigned assets', 'type': 'desk', 'route': 'desk'},
    ];

    final filtered = items.where((i) {
      if (q.isEmpty) return true;
      return (i['title'] as String).toLowerCase().contains(q) ||
          (i['desc'] as String).toLowerCase().contains(q) ||
          (i['type'] as String).toLowerCase().contains(q);
    }).toList();

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5),
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final item = filtered[i];
          return ListTile(
            leading: const Icon(Icons.search, color: Color(0xFFEA580C)),
            title: Text(
              item['title'] as String,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              item['desc'] as String,
              style: TextStyle(color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
            ),
            onTap: () {
              close(context, item['route'] as String);
              final r = item['route'] as String;
              if (r == 'active_board') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveBoardScreen(state: state)));
              } else if (r == 'roadmap') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RoadmapScreen(state: state)));
              } else if (r == 'worklogs') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DailyWorkLogsScreen(workLogs: state.workLogs, onAddWorkLog: state.addWorkLog, formattedClockTime: state.formattedClockTime, isClockedIn: state.isClockedIn, onRefresh: state.refreshApiData, state: state)));
              } else if (r == 'announcements') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementsScreen(state: state)));
              } else if (r == 'desk') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDeskScreen(tickets: state.tickets, assets: state.assets, onAddTicket: state.addTicket, state: state)));
              } else if (r == 'attendance') {
                state.setTab(2);
              } else if (r == 'leaves') {
                state.setTab(3);
              } else if (r == 'profile') {
                state.setTab(4);
              }
            },
          );
        },
      ),
    );
  }
}
