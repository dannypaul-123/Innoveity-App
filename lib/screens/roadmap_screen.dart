import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import 'announcements_screen.dart';
import 'main_navigation_screen.dart';

class RoadmapScreen extends StatefulWidget {
  final AppState state;

  const RoadmapScreen({super.key, required this.state});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  String _selectedProjectFilter = 'All Projects';
  String _selectedSprintFilter = 'ALL';
  String _selectedTypeFilter = 'All Types';
  String _selectedPriorityFilter = 'All Priorities';
  String _searchQuery = '';
  int _activeTab = 1;

  final List<String> _projectOptions = [
    'All Projects',
    'Innoveity CRM Mobile',
    'AMACE Website',
    'IQAC Repository',
    'Internal ERP v2',
  ];

  final List<String> _sprintOptions = [
    'ALL',
    'Sprint 1 (Active)',
    'Sprint 2 (Q4)',
    'Backlog',
  ];

  final List<String> _typeOptions = [
    'All Types',
    'Task',
    'Bug',
    'Story',
  ];

  final List<String> _priorityOptions = [
    'All Priorities',
    'Urgent',
    'High',
    'Medium',
    'Normal',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5);
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final bool isEmptyState = _selectedProjectFilter == 'All Projects (0)' || widget.state.tasks.isEmpty;

    final userName = widget.state.userProfile.name.isNotEmpty ? widget.state.userProfile.name : 'Daniel Paul';
    final userEmployeeId = widget.state.userProfile.employeeId.isNotEmpty ? widget.state.userProfile.employeeId : 'IN-1001';
    final userRole = widget.state.userProfile.role.isNotEmpty ? widget.state.userProfile.role : 'INTERN';
    final userAvatar = widget.state.userProfile.avatar;

    return Scaffold(
      drawer: AppDrawer(state: widget.state, activeRoute: 'roadmap'),
      backgroundColor: bgCanvas,
      appBar: AppBar(
        leading: AppDropdownMenu(state: widget.state),
        titleSpacing: 8,
        title: Row(
          children: [
            buildUserAvatar(
              avatar: userAvatar,
              name: userName,
              size: 36,
              border: Border.all(color: AppColors.primaryPine, width: 1.5),
              backgroundColor: const Color(0xFFF97316),
              fontSize: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$userEmployeeId • ${userRole.toUpperCase()}',
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
                delegate: AppQuickSearchDelegate(
                  state: widget.state,
                  isDark: isDark,
                ),
              );
            },
            tooltip: 'Quick Search',
          ),
          IconButton(
            icon: Icon(
              widget.state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onPressed: widget.state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnnouncementsScreen(state: widget.state),
                    ),
                  );
                },
                tooltip: 'Announcements & Alerts',
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA580C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sub-header Banner (Spaces / My Software Team / Scrum)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFEA580C),
                          child: const Text(
                            'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spaces',
                                style: TextStyle(fontSize: 11, color: textMuted),
                              ),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'My Software Team',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Scrum',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEA580C),
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

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Sub-Tabs: Summary, Board, Docs, Forms
                    Row(
                      children: [
                        _buildSubTab(0, 'Summary'),
                        _buildSubTab(1, 'Board'),
                        _buildSubTab(2, 'Docs'),
                        _buildSubTab(3, 'Forms'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filter Controls Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 38,
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search board...',
                          hintStyle: TextStyle(fontSize: 12, color: textMuted),
                          prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    _buildFilterDropdown(
                      label: 'PROJECT:',
                      value: _selectedProjectFilter,
                      items: _projectOptions,
                      onChanged: (val) => setState(() => _selectedProjectFilter = val!),
                      isDark: isDark,
                    ),
                    _buildFilterDropdown(
                      label: 'SPRINT:',
                      value: _selectedSprintFilter,
                      items: _sprintOptions,
                      onChanged: (val) => setState(() => _selectedSprintFilter = val!),
                      isDark: isDark,
                    ),
                    _buildFilterDropdown(
                      label: 'TYPE:',
                      value: _selectedTypeFilter,
                      items: _typeOptions,
                      onChanged: (val) => setState(() => _selectedTypeFilter = val!),
                      isDark: isDark,
                    ),
                    _buildFilterDropdown(
                      label: 'PRIORITY:',
                      value: _selectedPriorityFilter,
                      items: _priorityOptions,
                      onChanged: (val) => setState(() => _selectedPriorityFilter = val!),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content View (Empty State vs Roadmap Gantt Timeline)
              if (isEmptyState)
                _buildEmptyState(bgCard, textPrimary, textMuted, borderCol)
              else
                _buildTimelineGanttView(bgCard, textPrimary, textMuted, borderCol, isDark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            widget.state.setTab(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryPine,
          unselectedItemColor: AppColors.textMuted,
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


  Widget _buildSubTab(int index, String label) {
    final isActive = _activeTab == index;
    final activeColor = const Color(0xFFEA580C);

    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2.5,
              width: 32,
              color: isActive ? activeColor : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textMuted,
            ),
          ),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isDense: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, size: 18, color: textPrimary),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
            items: items.map((e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color bgCard, Color textPrimary, Color textMuted, Color borderCol) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 54,
              color: Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No projects assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have access to any projects yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedProjectFilter = 'All Projects';
              });
            },
            icon: const Icon(Icons.folder_shared_rounded, size: 16),
            label: const Text('View Active Sprints'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGanttView(
    Color bgCard,
    Color textPrimary,
    Color textMuted,
    Color borderCol,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPRINT TIMELINE ROADMAP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Q4 Oct - Dec 2026',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ...widget.state.tasks.where((task) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return task.title.toLowerCase().contains(q) ||
                task.category.toLowerCase().contains(q);
          }).map((task) {
            Color statusColor;
            switch (task.status.toUpperCase()) {
              case 'COMPLETED':
                statusColor = Colors.green;
                break;
              case 'IN PROGRESS':
                statusColor = const Color(0xFFEA580C);
                break;
              default:
                statusColor = Colors.blue;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMilestoneRow(
                title: '${task.category}: ${task.title}',
                dateRange: task.dueDate,
                progress: task.progress,
                statusLabel: task.status.toUpperCase(),
                statusColor: statusColor,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow({
    required String title,
    required String dateRange,
    required double progress,
    required String statusLabel,
    required Color statusColor,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dateRange,
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
