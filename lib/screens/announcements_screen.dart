import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import 'main_navigation_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  final AppState state;

  const AnnouncementsScreen({super.key, required this.state});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _filter = 'ALL'; // 'ALL', 'UNREAD', 'STORED'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAnnouncementDetailModal(BuildContext context, AnnouncementItem ann, bool isDark) {
    // Automatically mark as read and stored in the tab
    if (!ann.isRead) {
      widget.state.markAnnouncementAsRead(ann.id);
    }

    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final isUrgent = ann.priority.toLowerCase() == 'urgent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFEA580C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUrgent ? const Color(0xFFEF4444) : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          ann.priority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ann.targetAudience.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ann.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${ann.formattedDate} • Published by ${ann.author}',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                ann.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF058A5E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF058A5E).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF058A5E)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Stored in Announcements: This bulletin is saved in your archive tab and can be reviewed anytime.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (ann.isRead) {
                          widget.state.markAnnouncementAsUnread(ann.id);
                        } else {
                          widget.state.markAnnouncementAsRead(ann.id);
                        }
                        Navigator.pop(ctx);
                      },
                      icon: Icon(
                        ann.isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                        size: 16,
                      ),
                      label: Text(
                        ann.isRead ? 'Mark as Unread' : 'Keep as Read & Stored',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final isDark = state.isDarkMode;
        final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5);
        final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
        final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;
        final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

        // All published announcements from AppState
        final allAnnouncements = List<AnnouncementItem>.from(state.announcements);
        allAnnouncements.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.timestamp.compareTo(a.timestamp);
        });

        final totalCount = allAnnouncements.length;
        final unreadCount = allAnnouncements.where((a) => !a.isRead).length;
        final storedReadCount = allAnnouncements.where((a) => a.isRead).length;

        // Apply search and filter
        final query = _searchCtrl.text.trim().toLowerCase();
        final filteredList = allAnnouncements.where((a) {
          if (_filter == 'UNREAD' && a.isRead) return false;
          if (_filter == 'STORED' && !a.isRead) return false;
          if (query.isNotEmpty) {
            final matchTitle = a.title.toLowerCase().contains(query);
            final matchMsg = a.message.toLowerCase().contains(query);
            final matchAuthor = a.author.toLowerCase().contains(query);
            final matchAudience = a.targetAudience.toLowerCase().contains(query);
            if (!matchTitle && !matchMsg && !matchAuthor && !matchAudience) return false;
          }
          return true;
        }).toList();

        return Scaffold(
          drawer: AppDrawer(state: state, activeRoute: 'announcements'),
          backgroundColor: bgCanvas,
          appBar: AppBar(
            leading: AppDropdownMenu(state: state),
            titleSpacing: 8,
            title: Row(
              children: [
                buildUserAvatar(
                  avatar: state.userProfile.avatar,
                  name: state.userProfile.name,
                  size: 36,
                  border: Border.all(color: AppColors.primaryPine, width: 1.5),
                  backgroundColor: const Color(0xFFEA580C),
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
                          color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
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
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: AppQuickSearchDelegate(state: state, isDark: isDark),
                  );
                },
                tooltip: 'Quick Search',
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
                    onPressed: () {},
                    tooltip: 'Announcements & Alerts',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA580C),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Title + Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Announcements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Official broadcasts & team notifications',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          state.markAllAnnouncementsAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All announcements marked as read & preserved in tab!'),
                              backgroundColor: Color(0xFF058A5E),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFFEA580C)),
                        label: const Text(
                          'Mark All Read',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Info Banner Explaining Persistent Storage
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.archive_outlined, size: 18, color: Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Read announcements remain stored in this tab. $storedReadCount stored in archive • $unreadCount new notice${unreadCount == 1 ? '' : 's'}.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search announcements by title, keyword, or author...',
                    hintStyle: TextStyle(fontSize: 12, color: textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

                const SizedBox(height: 12),

                // Filter Tabs: ALL, UNREAD, STORED & READ
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All ($totalCount)', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('UNREAD', 'Unread ($unreadCount)', isDark, isHighlight: unreadCount > 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('STORED', 'Stored & Read ($storedReadCount)', isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Content List
                if (filteredList.isEmpty)
                  _buildEmptyState(isDark, textPrimary, textMuted, totalCount)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final item = filteredList[idx];
                      return _buildAnnouncementCard(context, item, isDark, textPrimary, textMuted, bgCard, borderCol);
                    },
                  ),
              ],
            ),
          ),
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
              currentIndex: state.currentTab,
              onTap: (index) {
                state.setTab(index);
                Navigator.of(context).popUntil((route) => route.isFirst);
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
      },
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark, {bool isHighlight = false}) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEA580C)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA580C)
                : (isHighlight
                    ? const Color(0xFFEA580C).withValues(alpha: 0.5)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AnnouncementItem item,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color bgCard,
    Color borderCol,
  ) {
    final isUrgent = item.priority.toLowerCase() == 'urgent';
    final isCelebration = item.priority.toLowerCase() == 'celebration';
    final isPinned = item.isPinned;
    final isRead = item.isRead;

    // Distinct border and accent for unread vs read
    final cardBorderColor = isPinned
        ? const Color(0xFFEA580C)
        : (isUrgent
            ? const Color(0xFFEF4444).withValues(alpha: 0.6)
            : (!isRead
                ? const Color(0xFFEA580C).withValues(alpha: 0.45)
                : borderCol));

    return InkWell(
      onTap: () => _showAnnouncementDetailModal(context, item, isDark),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor, width: (isPinned || !isRead || isUrgent) ? 1.4 : 1.0),
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
            // Top Meta Row: Pinned, Priority, Audience, Read Status Badge & Date
            Row(
              children: [
                if (isPinned)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PINNED',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Priority Badge
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? const Color(0xFFFEF2F2)
                        : (isCelebration
                            ? const Color(0xFFF0FDF4)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isUrgent
                          ? const Color(0xFFEF4444)
                          : (isCelebration ? const Color(0xFF22C55E) : Colors.transparent),
                    ),
                  ),
                  child: Text(
                    item.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: isUrgent
                          ? const Color(0xFFDC2626)
                          : (isCelebration ? const Color(0xFF15803D) : textMuted),
                    ),
                  ),
                ),

                // Audience Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.targetAudience.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),

                const Spacer(),

                // Status Badge: "● NEW" vs "✓ Read & Stored"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: !isRead
                        ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                        : (isDark ? Colors.white10 : const Color(0xFFF0FDF4)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: !isRead
                          ? const Color(0xFFEA580C).withValues(alpha: 0.35)
                          : const Color(0xFF16A34A).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        !isRead ? Icons.fiber_manual_record : Icons.check_circle_outline_rounded,
                        size: !isRead ? 8 : 10,
                        color: !isRead ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        !isRead ? 'NEW' : 'Read & Stored',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: !isRead ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Announcement Title
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: !isRead ? FontWeight.w800 : FontWeight.w600,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            // Announcement Message (Preview)
            Text(
              item.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: isRead ? textMuted : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Footer Row: Author + Date + Quick Read/Unread Action
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 13,
                  color: isDark ? AppColors.vibrantEmerald : const Color(0xFF058A5E),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.author} • ${item.formattedDate}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Quick Toggle Action
                InkWell(
                  onTap: () {
                    if (item.isRead) {
                      widget.state.markAnnouncementAsUnread(item.id);
                    } else {
                      widget.state.markAnnouncementAsRead(item.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isRead ? Icons.mark_email_unread_outlined : Icons.check_circle_outline_rounded,
                          size: 13,
                          color: item.isRead ? textMuted : const Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.isRead ? 'Mark Unread' : 'Mark Read',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.isRead ? textMuted : const Color(0xFFEA580C),
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState(bool isDark, Color textPrimary, Color textMuted, int totalCount) {
    String title = 'No Broadcasts Published';
    String message = 'Company broadcasts, HR updates, and announcements will appear here once published from the Admin side.';

    if (_filter == 'UNREAD') {
      title = 'All Caught Up! 🎉';
      message = 'You have read all broadcasts. All $totalCount announcements are safely stored in the "Stored & Read" tab for your reference.';
    } else if (_filter == 'STORED') {
      title = 'No Stored Read Announcements';
      message = 'When you read company announcements, they will remain stored here permanently for future reference.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _filter == 'STORED' ? Icons.inventory_2_outlined : Icons.campaign_outlined,
                size: 42,
                color: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
            ),
            if (_filter != 'ALL') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() => _filter = 'ALL'),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('View All Announcements', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
