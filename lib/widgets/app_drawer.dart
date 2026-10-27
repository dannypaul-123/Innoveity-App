import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../screens/active_board_screen.dart';
import '../screens/roadmap_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/daily_work_logs_screen.dart';
import '../screens/ticket_desk_screen.dart';
import '../screens/asset_management_screen.dart';
import 'app_avatar.dart';

class AppDrawer extends StatelessWidget {
  final AppState state;
  final String activeRoute;

  const AppDrawer({
    super.key,
    required this.state,
    this.activeRoute = 'dashboard',
  });

  static const Color activePink = AppColors.primaryPine;

  void _navigate(BuildContext context, VoidCallback action) {
    Navigator.pop(context); // Close drawer
    Navigator.of(context).popUntil((route) => route.isFirst);
    action();
  }

  void _goToRootTab(BuildContext context, int tabIndex) {
    Navigator.pop(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    state.setTab(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
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
            // --- TOP HEADER (User Avatar + Name + "View my Profile") ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  _buildAvatar(isDark, brandAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.userProfile.name.isNotEmpty
                              ? state.userProfile.name
                              : 'Innovety User',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        InkWell(
                          onTap: () => _goToRootTab(context, 4),
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            'View my Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.emeraldMintText
                                  : AppColors.primaryPine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: 20,
                      color: brandAccent,
                    ),
                    onPressed: state.toggleTheme,
                    tooltip: 'Toggle Theme',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // --- SCROLLABLE NAVIGATION LIST ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  if (state.isAdmin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          state.togglePreviewMode();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: brandAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: brandAccent, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_rounded, color: brandAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Switch to Admin Portal 🛡️',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: brandAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // 1. Dashboard / Home
                  _buildNavItem(
                    context: context,
                    icon: Icons.home_outlined,
                    label: 'Dashboard',
                    isActive: activeRoute == 'dashboard',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () => _goToRootTab(context, 0),
                  ),

                  // 2. Active Board
                  _buildNavItem(
                    context: context,
                    icon: Icons.grid_view_outlined,
                    label: 'Active Board',
                    isActive: activeRoute == 'active_board',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () {
                      _navigate(context, () {
                        if (activeRoute != 'active_board') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveBoardScreen(state: state),
                            ),
                          );
                        }
                      });
                    },
                  ),

                  // 3. My Work Logs
                  _buildNavItem(
                    context: context,
                    icon: Icons.history_rounded,
                    label: 'My Work Logs',
                    isActive: activeRoute == 'worklogs',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () {
                      _navigate(context, () {
                        if (activeRoute != 'worklogs') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyWorkLogsScreen(
                                workLogs: state.workLogs,
                                onAddWorkLog: state.addWorkLog,
                                formattedClockTime: state.formattedClockTime,
                                isClockedIn: state.isClockedIn,
                                onRefresh: state.refreshApiData,
                                state: state,
                              ),
                            ),
                          );
                        }
                      });
                    },
                  ),

                  // Attendance Portal
                  _buildNavItem(
                    context: context,
                    icon: Icons.access_time_rounded,
                    label: 'Attendance Portal',
                    isActive: activeRoute == 'attendance',
                    isDark: isDark,
                    brandAccent: const Color(0xFFEA580C),
                    solidActive: true,
                    onTap: () => _goToRootTab(context, 2),
                  ),

                  // 4. Roadmap
                  _buildNavItem(
                    context: context,
                    icon: Icons.alt_route_outlined,
                    label: 'Roadmap',
                    isActive: activeRoute == 'roadmap',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () {
                      _navigate(context, () {
                        if (activeRoute != 'roadmap') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoadmapScreen(state: state),
                            ),
                          );
                        }
                      });
                    },
                  ),

                  // 5. Leave Management
                  _buildNavItem(
                    context: context,
                    icon: Icons.hourglass_empty_rounded,
                    label: 'Leave Management',
                    isActive: activeRoute == 'leaves',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () => _goToRootTab(context, 3),
                  ),

                  // 6. Announcements
                  _buildNavItem(
                    context: context,
                    icon: Icons.campaign_outlined,
                    label: 'Announcements',
                    isActive: activeRoute == 'announcements',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    badge: state.announcements.where((a) => !a.isRead).isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.announcements.where((a) => !a.isRead).length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      _navigate(context, () {
                        if (activeRoute != 'announcements') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnnouncementsScreen(state: state),
                            ),
                          );
                        }
                      });
                    },
                  ),

                  // 7. My Profile
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    isActive: activeRoute == 'profile',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () => _goToRootTab(context, 4),
                  ),

                  // 8. IT Support Desk
                  _buildNavItem(
                    context: context,
                    icon: Icons.confirmation_number_outlined,
                    label: 'IT Support Desk',
                    isActive: activeRoute == 'desk',
                    isDark: isDark,
                    brandAccent: brandAccent,
                    onTap: () {
                      _navigate(context, () {
                        if (activeRoute != 'desk') {
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
                      });
                    },
                  ),

                  // 9. Asset Management
                  _buildNavItem(
                    context: context,
                    icon: Icons.laptop_mac_outlined,
                    label: 'Asset Management',
                    isActive: activeRoute == 'assets',
                    isDark: isDark,
                    brandAccent: const Color(0xFFEA580C),
                    onTap: () {
                      _navigate(context, () {
                        if (activeRoute != 'assets') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssetManagementScreen(state: state),
                            ),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- SECONDARY FOOTER LINKS ---
                  _buildSecondaryLink(
                    context,
                    "FAQ's",
                    isDark,
                    () => _showInfoDialog(
                      context,
                      "FAQ's",
                      "Find answers to common questions about leave policies, shifts, and HR operations.",
                      brandAccent,
                    ),
                  ),
                  _buildSecondaryLink(
                    context,
                    'Contact Us',
                    isDark,
                    () => _showInfoDialog(
                      context,
                      'Contact Support',
                      'Need help? Email support@innovety.com or submit a ticket in the IT Support Desk.',
                      brandAccent,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // --- BOTTOM SECTION: LOGOUT (HIGHLIGHTED IN RED) & APP VERSION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: isDark ? AppColors.borderCardDark : AppColors.borderLight,
              ),
            ),
            const SizedBox(height: 8),
            _buildLogoutButton(context, isDark),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'Version 2.0.1',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    const alertRed = Color(0xFFEF4444);
    const alertRedDark = Color(0xFFDC2626);
    const alertRedLight = Color(0xFFF87171);

    final bgTint = isDark
        ? alertRed.withValues(alpha: 0.16)
        : const Color(0xFFFEF2F2);
    final borderColor = isDark
        ? alertRed.withValues(alpha: 0.35)
        : const Color(0xFFFCA5A5);
    final contentColor = isDark ? alertRedLight : alertRedDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _confirmLogout(context),
            borderRadius: BorderRadius.circular(12),
            splashColor: alertRed.withValues(alpha: 0.2),
            highlightColor: alertRed.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 21,
                    color: contentColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: contentColor,
                        letterSpacing: -0.1,
                      ),
                    ),
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
    final isDark = state.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertText,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
              state.logout();
            },
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark, Color brandAccent) {
    return buildUserAvatar(
      avatar: state.userProfile.avatar,
      name: state.userProfile.name,
      size: 44,
      border: Border.all(
        color: brandAccent.withValues(alpha: 0.5),
        width: 1.5,
      ),
      backgroundColor: isDark ? AppColors.statCardDarkPine : AppColors.surfaceContainerLow,
      textColor: brandAccent,
      fontSize: 16,
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required Color brandAccent,
    required VoidCallback onTap,
    Widget? badge,
    bool solidActive = false,
  }) {
    final inactiveIconColor =
        isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final textColor = isActive
        ? (solidActive ? Colors.white : (isDark ? AppColors.emeraldMintText : AppColors.primaryPine))
        : (isDark ? AppColors.textLight : AppColors.textDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: isActive
            ? (solidActive ? brandAccent : brandAccent.withValues(alpha: isDark ? 0.16 : 0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: brandAccent.withValues(alpha: 0.15),
          highlightColor: brandAccent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: isActive ? (solidActive ? Colors.white : brandAccent) : inactiveIconColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isActive && solidActive)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                else
                  ?badge,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryLink(
    BuildContext context,
    String text,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String message,
    Color brandAccent,
  ) {
    final isDark = state.isDarkMode;
    Navigator.pop(context); // close drawer first
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(color: brandAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
