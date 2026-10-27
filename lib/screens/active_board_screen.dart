import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../models/app_models.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import 'announcements_screen.dart';
import 'main_navigation_screen.dart';

class ActiveBoardScreen extends StatefulWidget {
  final AppState state;

  const ActiveBoardScreen({super.key, required this.state});

  @override
  State<ActiveBoardScreen> createState() => _ActiveBoardScreenState();
}

class _ActiveBoardScreenState extends State<ActiveBoardScreen> {
  String _selectedProjectFilter = 'All Projects';
  String _selectedSprintFilter = 'ALL';
  String _selectedTypeFilter = 'All Types';
  String _selectedPriorityFilter = 'All Priorities';
  String _searchQuery = '';
  int _activeTab = 1; // 0: Summary, 1: Board, 2: Docs, 3: Forms

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
    'Feature',
  ];

  final List<String> _priorityOptions = [
    'All Priorities',
    'Urgent',
    'High',
    'Medium',
    'Normal',
  ];

  List<TaskItem> get _filteredTasks {
    return widget.state.tasks.where((task) {
      if (_selectedProjectFilter != 'All Projects' &&
          !task.category.toLowerCase().contains(_selectedProjectFilter.toLowerCase())) {
        return false;
      }
      if (_selectedPriorityFilter != 'All Priorities' &&
          task.priority.toLowerCase() != _selectedPriorityFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(query);
        final matchDesc = task.description.toLowerCase().contains(query);
        final matchCat = task.category.toLowerCase().contains(query);
        if (!matchTitle && !matchDesc && !matchCat) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5);
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final filteredList = _filteredTasks;
    final bool isEmptyFilteredState = filteredList.isEmpty || _selectedProjectFilter == 'All Projects (0)';

    final userName = widget.state.userProfile.name.isNotEmpty ? widget.state.userProfile.name : 'Daniel Paul';
    final userEmployeeId = widget.state.userProfile.employeeId.isNotEmpty ? widget.state.userProfile.employeeId : 'IN-1001';
    final userRole = widget.state.userProfile.role.isNotEmpty ? widget.state.userProfile.role : 'INTERN';
    final userAvatar = widget.state.userProfile.avatar;

    return Scaffold(
      drawer: AppDrawer(state: widget.state, activeRoute: 'active_board'),
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
              // Sub-header Banner (Spaces / My Software Team / Scrum + Avatars)
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
                    // Search bar
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

                    // Dropdowns: PROJECT, SPRINT, TYPE, PRIORITY
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

              // Board Content or Empty State
              if (isEmptyFilteredState && _selectedProjectFilter.contains('(0)'))
                _buildEmptyState(bgCard, textPrimary, textMuted, borderCol)
              else if (filteredList.isEmpty)
                _buildEmptyState(bgCard, textPrimary, textMuted, borderCol)
              else
                _buildKanbanBoardView(filteredList, bgCard, textPrimary, textMuted, borderCol, isDark),
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
              Icons.folder_open_outlined,
              size: 54,
              color: Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Projects Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no active projects matching your selected filter parameters.\nCreate a new project to start managing tasks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedProjectFilter = 'All Projects';
                _selectedPriorityFilter = 'All Priorities';
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Board Filters'),
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

  Widget _buildKanbanBoardView(
    List<TaskItem> tasks,
    Color bgCard,
    Color textPrimary,
    Color textMuted,
    Color borderCol,
    bool isDark,
  ) {
    final columns = ['In Progress', 'Pending', 'In Review', 'Completed'];

    return SizedBox(
      height: 600,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: columns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, idx) {
          final colName = columns[idx];
          final colTasks = tasks.where((t) => t.status == colName).toList();

          return Container(
            width: 280,
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderCol)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        colName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${colTasks.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards list
                Expanded(
                  child: colTasks.isEmpty
                      ? Center(
                          child: Text(
                            'No items',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: colTasks.length,
                          itemBuilder: (ctx, i) {
                            final task = colTasks[i];
                            return _buildTaskCard(task, isDark, textPrimary, textMuted);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task, bool isDark, Color textPrimary, Color textMuted) {
    Color priorityColor = Colors.blue;
    if (task.priority == 'Urgent') priorityColor = Colors.red;
    if (task.priority == 'High') priorityColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              Text(
                task.id,
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: task.progress,
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            color: const Color(0xFFEA580C),
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task.category,
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
              Text(
                '${(task.progress * 100).toInt()}%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
