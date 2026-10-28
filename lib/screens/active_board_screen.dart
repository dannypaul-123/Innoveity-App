import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../models/project_models.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_dropdown_menu.dart';
import 'announcements_screen.dart';
import 'main_navigation_screen.dart';
import 'enterprise_projects_screen.dart';

class ActiveBoardScreen extends StatefulWidget {
  final AppState state;

  const ActiveBoardScreen({super.key, required this.state});

  @override
  State<ActiveBoardScreen> createState() => _ActiveBoardScreenState();
}

class _ActiveBoardScreenState extends State<ActiveBoardScreen> {
  String _selectedProjectFilter = 'All Projects';
  String _selectedPriorityFilter = 'All Priorities';
  String _selectedTypeFilter = 'All Types';
  String _selectedStageFilter = 'All Stages';
  String _searchQuery = '';
  int _activeTab = 1; // 0: Summary, 1: Board, 2: Docs, 3: Forms

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(ActiveBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChanged);
      widget.state.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  List<String> get _projectOptions {
    final assigned = widget.state.assignedProjectsForCurrentUser;
    if (assigned.isEmpty) {
      return ['All Projects (0)'];
    }
    final list = ['All Projects'];
    for (final p in assigned) {
      if (!list.contains(p.name)) {
        list.add(p.name);
      }
    }
    return list;
  }

  final List<String> _priorityOptions = [
    'All Priorities',
    'Critical',
    'High',
    'Medium',
    'Low',
  ];

  final List<String> _typeOptions = [
    'All Types',
    'Client Project',
    'Internal Project',
    'Research & Development',
    'Maintenance',
  ];

  final List<String> _stageOptions = [
    'All Stages',
    'To Do',
    'In Progress',
    'In Review',
    'Done',
  ];

  List<EnterpriseProject> get _filteredProjects {
    return widget.state.assignedProjectsForCurrentUser.where((project) {
      if (_selectedProjectFilter != 'All Projects' &&
          _selectedProjectFilter != 'All Projects (0)' &&
          project.name != _selectedProjectFilter) {
        return false;
      }
      if (_selectedPriorityFilter != 'All Priorities' &&
          project.priority.toLowerCase() != _selectedPriorityFilter.toLowerCase()) {
        return false;
      }
      if (_selectedTypeFilter != 'All Types' &&
          project.projectType.toLowerCase() != _selectedTypeFilter.toLowerCase()) {
        return false;
      }
      if (_selectedStageFilter != 'All Stages') {
        final curStageName = project.currentStage.name.toLowerCase();
        final filterStage = _selectedStageFilter.toLowerCase();
        if (filterStage == 'done' && (project.isCompleted || curStageName == 'done')) {
          // match
        } else if (curStageName != filterStage) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = project.name.toLowerCase().contains(query);
        final matchCode = project.code.toLowerCase().contains(query);
        final matchDesc = project.description.toLowerCase().contains(query);
        final matchLeader = (project.projectLeaderName ?? '').toLowerCase().contains(query);
        if (!matchName && !matchCode && !matchDesc && !matchLeader) return false;
      }
      return true;
    }).toList();
  }

  bool _projectMatchesColumn(EnterpriseProject project, String colName) {
    final curStageName = project.currentStage.name.toLowerCase().trim();
    final colLower = colName.toLowerCase().trim();

    if (colLower == curStageName) return true;

    if (colLower == 'to do' || colLower == 'pending') {
      return curStageName == 'to do' || curStageName == 'pending' || project.currentStageIndex == 0;
    }
    if (colLower == 'in progress') {
      return curStageName == 'in progress' ||
          (project.currentStageIndex > 0 &&
              !project.currentStage.requiresApproval &&
              !project.isCompleted &&
              curStageName != 'done' &&
              curStageName != 'in review');
    }
    if (colLower == 'in review') {
      return curStageName == 'in review' ||
          project.isAwaitingApproval ||
          project.isStageRejected ||
          (project.currentStage.requiresApproval && !project.isCompleted);
    }
    if (colLower == 'done' || colLower == 'completed') {
      return curStageName == 'done' ||
          curStageName == 'completed' ||
          project.isCompleted ||
          project.currentStage.isFinalCompletedStage;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final bgCanvas = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5);
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final assignedProjects = widget.state.assignedProjectsForCurrentUser;
    final filteredProjects = _filteredProjects;

    final userName = widget.state.userProfile.name.isNotEmpty
        ? widget.state.userProfile.name
        : 'Daniel Paul';
    final userEmployeeId = widget.state.userProfile.employeeId.isNotEmpty
        ? widget.state.userProfile.employeeId
        : 'IN-1001';
    final userRole = widget.state.userProfile.role.isNotEmpty
        ? widget.state.userProfile.role
        : 'EMPLOYEE';
    final userAvatar = widget.state.userProfile.avatar;

    // Check currently selected project if single
    EnterpriseProject? activeProject;
    if (_selectedProjectFilter != 'All Projects' &&
        _selectedProjectFilter != 'All Projects (0)') {
      final matches = assignedProjects.where((p) => p.name == _selectedProjectFilter);
      activeProject = matches.isNotEmpty ? matches.first : (assignedProjects.isNotEmpty ? assignedProjects.first : null);
    } else if (assignedProjects.isNotEmpty) {
      activeProject = assignedProjects.first;
    }

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
              // Dynamic Sub-header Banner (Project Overview + Scrum Badge)
              _buildProjectBanner(
                activeProject: activeProject,
                totalAssigned: assignedProjects.length,
                bgCard: bgCard,
                borderCol: borderCol,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Filter Controls Bar
              _buildFilterControlsBar(
                bgCard: bgCard,
                borderCol: borderCol,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Tab-dependent Content
              if (assignedProjects.isEmpty)
                _buildEmptyState(bgCard, textPrimary, textMuted, borderCol)
              else if (_activeTab == 0)
                _buildSummaryTab(filteredProjects, bgCard, textPrimary, textMuted, borderCol, isDark)
              else if (_activeTab == 2)
                _buildDocsTab(activeProject, bgCard, textPrimary, textMuted, borderCol, isDark)
              else if (_activeTab == 3)
                _buildFormsTab(activeProject, bgCard, textPrimary, textMuted, borderCol, isDark)
              else
                _buildKanbanBoardView(
                  projects: filteredProjects,
                  selectedProject: (_selectedProjectFilter != 'All Projects' && _selectedProjectFilter != 'All Projects (0)')
                      ? activeProject
                      : null,
                  bgCard: bgCard,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  borderCol: borderCol,
                  isDark: isDark,
                ),
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

  Widget _buildProjectBanner({
    required EnterpriseProject? activeProject,
    required int totalAssigned,
    required Color bgCard,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    final title = activeProject != null
        ? activeProject.name
        : (totalAssigned > 0 ? 'Assigned Projects ($totalAssigned)' : 'No Projects Assigned');
    final teamName = activeProject?.assignedTeam ?? 'Mobile Application Development';
    final code = activeProject?.code ?? 'PRJ-101';
    final priority = activeProject?.priority ?? 'Medium';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  color: Color(0xFFEA580C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spaces  /  Workspaces  /  Active Board',
                      style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Scrum • $priority',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Team: $teamName • Assigned by Admin',
                      style: TextStyle(fontSize: 12, color: textMuted),
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
    );
  }

  Widget _buildFilterControlsBar({
    required Color bgCard,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    final projectOpts = _projectOptions;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search bar
          SizedBox(
            width: 200,
            height: 38,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 12.5, color: textPrimary),
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

          // PROJECT Dropdown
          _buildFilterDropdown(
            label: 'PROJECT:',
            value: projectOpts.contains(_selectedProjectFilter)
                ? _selectedProjectFilter
                : projectOpts.first,
            items: projectOpts,
            onChanged: (val) {
              if (val != null) setState(() => _selectedProjectFilter = val);
            },
            isDark: isDark,
          ),

          // PRIORITY Dropdown
          _buildFilterDropdown(
            label: 'PRIORITY:',
            value: _selectedPriorityFilter,
            items: _priorityOptions,
            onChanged: (val) {
              if (val != null) setState(() => _selectedPriorityFilter = val);
            },
            isDark: isDark,
          ),

          // TYPE Dropdown
          _buildFilterDropdown(
            label: 'TYPE:',
            value: _selectedTypeFilter,
            items: _typeOptions,
            onChanged: (val) {
              if (val != null) setState(() => _selectedTypeFilter = val);
            },
            isDark: isDark,
          ),

          // STAGE Dropdown
          _buildFilterDropdown(
            label: 'STAGE:',
            value: _selectedStageFilter,
            items: _stageOptions,
            onChanged: (val) {
              if (val != null) setState(() => _selectedStageFilter = val);
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(int index, String label) {
    final isActive = _activeTab == index;
    const activeColor = Color(0xFFEA580C);

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
                child: Text(e, overflow: TextOverflow.ellipsis),
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
            'No Projects Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no active projects assigned to you by the Admin yet.\nOnce an Admin assigns a project to you, it will appear here on your Active Board.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
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
                _selectedTypeFilter = 'All Types';
                _selectedStageFilter = 'All Stages';
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

  Widget _buildKanbanBoardView({
    required List<EnterpriseProject> projects,
    required EnterpriseProject? selectedProject,
    required Color bgCard,
    required Color textPrimary,
    required Color textMuted,
    required Color borderCol,
    required bool isDark,
  }) {
    // If a specific project is selected, show columns matching its stages
    final List<String> columns = (selectedProject != null && selectedProject.workflowStages.isNotEmpty)
        ? selectedProject.workflowStages.map((s) => s.name).toList()
        : ['To Do', 'In Progress', 'In Review', 'Done'];

    return SizedBox(
      height: 640,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: columns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, idx) {
          final colName = columns[idx];

          // Collect projects for this column
          List<EnterpriseProject> colProjects;
          if (selectedProject != null) {
            // For a single selected project, display it in its active stage column
            final isCurrentStage = selectedProject.currentStage.name.toLowerCase().trim() ==
                colName.toLowerCase().trim();
            colProjects = isCurrentStage ? [selectedProject] : [];
          } else {
            colProjects = projects.where((p) => _projectMatchesColumn(p, colName)).toList();
          }

          return Container(
            width: 320,
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
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getColumnColor(colName),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            colName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${colProjects.length}',
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
                  child: colProjects.isEmpty
                      ? Center(
                          child: Text(
                            'No active items in $colName',
                            style: TextStyle(fontSize: 11.5, color: textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: colProjects.length,
                          itemBuilder: (ctx, i) {
                            final project = colProjects[i];
                            return _buildProjectBoardCard(
                              project,
                              isDark,
                              textPrimary,
                              textMuted,
                              borderCol,
                            );
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

  Color _getColumnColor(String colName) {
    final lower = colName.toLowerCase();
    if (lower.contains('to do') || lower.contains('pending')) return const Color(0xFF64748B);
    if (lower.contains('progress')) return const Color(0xFFEA580C);
    if (lower.contains('review')) return const Color(0xFF8B5CF6);
    if (lower.contains('done') || lower.contains('completed')) return const Color(0xFF10B981);
    return const Color(0xFF3B82F6);
  }

  Widget _buildProjectBoardCard(
    EnterpriseProject project,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderCol,
  ) {
    const primaryOrange = Color(0xFFEA580C);
    final curStage = project.currentStage;
    final isAwaiting = project.isAwaitingApproval;
    final isRejected = project.isStageRejected;

    // Priority color
    Color priorityColor = const Color(0xFF10B981);
    if (project.priority == 'Critical') {
      priorityColor = const Color(0xFFEF4444);
    } else if (project.priority == 'High') {
      priorityColor = const Color(0xFFF97316);
    } else if (project.priority == 'Medium') {
      priorityColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRejected
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : (isAwaiting ? primaryOrange.withValues(alpha: 0.5) : borderCol),
          width: isRejected || isAwaiting ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Chips (Code, Priority, Type)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  project.code,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: primaryOrange,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${project.priority} Priority',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: priorityColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.projectType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Project Title & Description
          Text(
            project.name,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.3),
            ),
          ],

          const SizedBox(height: 10),

          // Timeline & Leader info strip
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd/MM/yy').format(project.startDate)} — ${DateFormat('dd/MM/yy').format(project.endDate)}',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
              if (project.projectLeaderName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Leader: ${project.projectLeaderName}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Pipeline Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Stage: ${curStage.name}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${project.progressPercent}% Complete',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryOrange),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progressRatio,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              color: primaryOrange,
              minHeight: 5,
            ),
          ),

          // Rejection / Approval Alert Callout
          if (isRejected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Stage Rejected by Admin — Redo Required',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                  if (curStage.rejectionReason != null && curStage.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Admin: "${curStage.rejectionReason}"',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await widget.state.resubmitProjectStage(
                          projectId: project.id,
                          resubmittedBy: widget.state.userProfile.name,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stage redone and resubmitted to Admin for review!'),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                      label: const Text('Redo & Resubmit to Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isAwaiting) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Under Admin Review (Awaiting Approval)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!project.isCompleted) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.state.advanceProjectStage(
                    projectId: project.id,
                    userEmail: widget.state.userProfile.name,
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                label: Text(
                  curStage.requiresApproval ? 'Submit for Admin Approval' : 'Advance Stage',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Summary Tab
  Widget _buildSummaryTab(
    List<EnterpriseProject> projects,
    Color bgCard,
    Color textPrimary,
    Color textMuted,
    Color borderCol,
    bool isDark,
  ) {
    final total = projects.length;
    final active = projects.where((p) => p.status == 'Active').length;
    final inReview = projects.where((p) => p.isAwaitingApproval).length;
    final completed = projects.where((p) => p.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric Strip
        Row(
          children: [
            Expanded(child: _buildMetricTile('TOTAL ASSIGNED', '$total', textPrimary, bgCard, borderCol, isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile('ACTIVE', '$active', const Color(0xFFEA580C), bgCard, borderCol, isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile('IN REVIEW', '$inReview', const Color(0xFF8B5CF6), bgCard, borderCol, isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile('COMPLETED', '$completed', const Color(0xFF10B981), bgCard, borderCol, isDark)),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Assigned Project Overview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 12),

        ...projects.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Text(
                      '${p.progressPercent}% Complete',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p.description,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: p.progressRatio,
                  color: const Color(0xFFEA580C),
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  minHeight: 5,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    Color valColor,
    Color bgCard,
    Color borderCol,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valColor),
          ),
        ],
      ),
    );
  }

  // Docs Tab
  Widget _buildDocsTab(
    EnterpriseProject? project,
    Color bgCard,
    Color textPrimary,
    Color textMuted,
    Color borderCol,
    bool isDark,
  ) {
    if (project == null) {
      return _buildEmptyState(bgCard, textPrimary, textMuted, borderCol);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFFEA580C), size: 24),
              const SizedBox(width: 10),
              Text(
                '${project.name} — Technical Specs & Guidelines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Project Code: ${project.code}\n'
            'Assigned Team: ${project.assignedTeam ?? "Development"}\n'
            'Project Leader: ${project.projectLeaderName ?? "Admin"}\n\n'
            'Workflow Stages & Required Deliverables:',
            style: TextStyle(fontSize: 13, height: 1.4, color: textPrimary),
          ),
          const SizedBox(height: 10),
          ...project.workflowStages.map((stage) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    stage.status == 'APPROVED' ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: stage.status == 'APPROVED' ? const Color(0xFF10B981) : textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stage ${stage.order}: ${stage.name}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: stage.status == 'APPROVED' ? const Color(0xFF10B981) : textPrimary,
                    ),
                  ),
                  if (stage.requiresApproval) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Approval Gate',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Forms Tab
  Widget _buildFormsTab(
    EnterpriseProject? project,
    Color bgCard,
    Color textPrimary,
    Color textMuted,
    Color borderCol,
    bool isDark,
  ) {
    if (project == null) {
      return _buildEmptyState(bgCard, textPrimary, textMuted, borderCol);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: Color(0xFFEA580C), size: 24),
              const SizedBox(width: 10),
              Text(
                'Deliverable Submission & Stage Sign-off Form',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submit stage deliverables to Admin for review. If rejected, you will be notified to redo and resubmit.',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'Current Stage: ${project.currentStage.name}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe deliverables completed, GitHub PR link, or Figma prototype...',
              hintStyle: TextStyle(fontSize: 12, color: textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deliverables submitted successfully for Admin review!'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
            label: const Text('Submit Deliverable Form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
