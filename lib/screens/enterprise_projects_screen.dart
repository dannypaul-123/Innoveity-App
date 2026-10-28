import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_models.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';

/// Standalone screen for Employee / Intern side navigation via AppDrawer
class EnterpriseProjectsScreen extends StatelessWidget {
  final AppState state;

  const EnterpriseProjectsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDarkBody : AppColors.background,
      drawer: AppDrawer(state: state, activeRoute: 'projects'),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? AppColors.headerDarkPine : Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Workspaces / Projects',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
              size: 20,
            ),
            onPressed: state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: EnterpriseProjectsView(
          state: state,
          isDark: isDark,
        ),
      ),
    );
  }
}

/// Main Reusable Projects View (matching Image 1 exactly and embedded in Admin Portal tab 14)
class EnterpriseProjectsView extends StatefulWidget {
  final AppState state;
  final bool isDark;

  const EnterpriseProjectsView({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  State<EnterpriseProjectsView> createState() => _EnterpriseProjectsViewState();
}

class _EnterpriseProjectsViewState extends State<EnterpriseProjectsView> {
  String _selectedFilter = 'All Projects';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = [
    'All Projects',
    'Active',
    'Overdue',
    'Draft',
    'Scheduled',
    'On Hold',
    'Completed',
    'Archived',
  ];

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(EnterpriseProjectsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChanged);
      widget.state.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<EnterpriseProject> _getFilteredProjects() {
    final allProjects = widget.state.projects;
    List<EnterpriseProject> list;

    switch (_selectedFilter) {
      case 'Active':
        list = widget.state.activeProjects;
        break;
      case 'Overdue':
        list = widget.state.overdueProjects;
        break;
      case 'Draft':
        list = widget.state.draftProjects;
        break;
      case 'Scheduled':
        list = widget.state.scheduledProjects;
        break;
      case 'On Hold':
        list = widget.state.onHoldProjects;
        break;
      case 'Completed':
        list = widget.state.completedProjects;
        break;
      case 'Archived':
        list = widget.state.archivedProjects;
        break;
      case 'All Projects':
      default:
        list = allProjects;
        break;
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            p.code.toLowerCase().contains(_searchQuery) ||
            (p.projectLeaderName != null &&
                p.projectLeaderName!.toLowerCase().contains(_searchQuery)) ||
            p.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return list;
  }

  void _openCreateProjectWizard(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectWorkflowSetupWizardDialog(
        state: widget.state,
        isDark: widget.isDark,
      ),
    );
  }

  void _openStageReviewDialog(BuildContext context, EnterpriseProject project) {
    showDialog(
      context: context,
      builder: (_) => ProjectStageReviewDialog(
        project: project,
        state: widget.state,
        isDark: widget.isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final filteredProjects = _getFilteredProjects();

    // Metric counts
    final totalCount = widget.state.projects.length;
    final activeCount = widget.state.activeProjects.length;
    final overdueCount = widget.state.overdueProjects.length;
    final completedCount = widget.state.completedProjects.length;
    final onHoldCount = widget.state.onHoldProjects.length;
    final archivedCount = widget.state.archivedProjects.length;

    final primaryOrange = const Color(0xFFEA580C);
    final bgCard = isDark ? AppColors.statCardDarkPine : Colors.white;
    final borderColor = isDark
        ? AppColors.vibrantEmerald.withValues(alpha: 0.15)
        : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb matching Image 1
          _buildBreadcrumbs(isDark),
          const SizedBox(height: 12),

          // Header with Folder Icon, Title, Subtitle, Search, and Create Button
          _buildHeaderSection(isDark, primaryOrange),
          const SizedBox(height: 20),

          // 6 Metric Cards matching Image 1
          _buildMetricCardsRow(
            isDark: isDark,
            bgCard: bgCard,
            borderColor: borderColor,
            totalCount: totalCount,
            activeCount: activeCount,
            overdueCount: overdueCount,
            completedCount: completedCount,
            onHoldCount: onHoldCount,
            archivedCount: archivedCount,
          ),
          const SizedBox(height: 20),

          // Filter Tab Pills matching Image 1
          _buildFilterPills(isDark, primaryOrange),
          const SizedBox(height: 20),

          // Main Projects Content: Empty State or Projects List
          if (filteredProjects.isEmpty)
            _buildEmptyState(isDark, bgCard, borderColor)
          else
            _buildProjectsList(filteredProjects, isDark, primaryOrange),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(bool isDark) {
    final muted = isDark ? AppColors.textLightMuted : const Color(0xFF64748B);
    final activeText = isDark ? AppColors.textLight : const Color(0xFF0F172A);

    return Row(
      children: [
        Text(
          'Portal',
          style: TextStyle(
            fontSize: 13,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text('  /  ', style: TextStyle(fontSize: 13, color: muted)),
        Text(
          'Workspaces',
          style: TextStyle(
            fontSize: 13,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text('  /  ', style: TextStyle(fontSize: 13, color: muted)),
        Text(
          'Projects',
          style: TextStyle(
            fontSize: 13,
            color: activeText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(bool isDark, Color primaryOrange) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        final leftSide = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryOrange.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                color: primaryOrange,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise Projects',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage project lifecycles, 1:1 project chat groups, milestones, and Kanban workflows for Innoveity Tech.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final rightControls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isNarrow ? constraints.maxWidth * 0.55 : 240,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textLight : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Search by code, title, or lead...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _openCreateProjectWizard(context),
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Create New Project',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftSide,
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: rightControls,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: leftSide),
            const SizedBox(width: 16),
            rightControls,
          ],
        );
      },
    );
  }

  Widget _buildMetricCardsRow({
    required bool isDark,
    required Color bgCard,
    required Color borderColor,
    required int totalCount,
    required int activeCount,
    required int overdueCount,
    required int completedCount,
    required int onHoldCount,
    required int archivedCount,
  }) {
    final metrics = [
      {'label': 'TOTAL PROJECTS', 'value': totalCount, 'color': isDark ? Colors.white : const Color(0xFF0F172A)},
      {'label': 'ACTIVE', 'value': activeCount, 'color': const Color(0xFFEA580C)},
      {'label': 'OVERDUE', 'value': overdueCount, 'color': const Color(0xFFEA580C)},
      {'label': 'COMPLETED', 'value': completedCount, 'color': const Color(0xFF2563EB)},
      {'label': 'ON HOLD', 'value': onHoldCount, 'color': const Color(0xFFEA580C)},
      {'label': 'ARCHIVED', 'value': archivedCount, 'color': const Color(0xFF64748B)},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isMedium = constraints.maxWidth >= 550 && !isWide;

        if (isWide) {
          return Row(
            children: metrics.map((m) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildMetricCard(
                    label: m['label'] as String,
                    value: m['value'] as int,
                    valueColor: m['color'] as Color,
                    bgCard: bgCard,
                    borderColor: borderColor,
                    isDark: isDark,
                  ),
                ),
              );
            }).toList(),
          );
        } else if (isMedium) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metrics.map((m) {
              final w = (constraints.maxWidth - 16) / 3;
              return SizedBox(
                width: w,
                child: _buildMetricCard(
                  label: m['label'] as String,
                  value: m['value'] as int,
                  valueColor: m['color'] as Color,
                  bgCard: bgCard,
                  borderColor: borderColor,
                  isDark: isDark,
                ),
              );
            }).toList(),
          );
        }

        // Mobile: 2 columns
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics.map((m) {
            final w = (constraints.maxWidth - 8) / 2;
            return SizedBox(
              width: w,
              child: _buildMetricCard(
                label: m['label'] as String,
                value: m['value'] as int,
                valueColor: m['color'] as Color,
                bgCard: bgCard,
                borderColor: borderColor,
                isDark: isDark,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int value,
    required Color valueColor,
    required Color bgCard,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.0),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(bool isDark, Color primaryOrange) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryOrange
                      : (isDark ? const Color(0xFF1E293B) : Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? primaryOrange
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color bgCard, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_outlined,
              size: 38,
              color: isDark ? AppColors.textLightMuted : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No projects match the selected filter criteria. Click "Create New Project" to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openCreateProjectWizard(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: const Text('Create New Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(List<EnterpriseProject> projects, bool isDark, Color primaryOrange) {
    return Column(
      children: projects.map((project) {
        return _buildProjectCard(project, isDark, primaryOrange);
      }).toList(),
    );
  }

  Widget _buildProjectCard(EnterpriseProject project, bool isDark, Color primaryOrange) {
    final bgCard = isDark ? AppColors.statCardDarkPine : Colors.white;
    final borderColor = isDark
        ? AppColors.vibrantEmerald.withValues(alpha: 0.15)
        : const Color(0xFFE2E8F0);
    final curStage = project.currentStage;
    final isAwaiting = project.isAwaitingApproval;
    final isRejected = project.isStageRejected;

    // Priority color
    Color priorityColor = const Color(0xFF10B981);
    if (project.priority == 'Critical') priorityColor = const Color(0xFFEF4444);
    else if (project.priority == 'High') priorityColor = const Color(0xFFF97316);
    else if (project.priority == 'Medium') priorityColor = const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRejected
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : (isAwaiting ? primaryOrange.withValues(alpha: 0.4) : borderColor),
          width: isRejected || isAwaiting ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar of Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                // Project Code Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    project.code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Priority Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${project.priority} Priority',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Project Type Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.projectType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const Spacer(),
                // Status badge
                _buildProjectStatusBadge(project.status, isDark),
              ],
            ),
          ),

          // Project Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                  ),
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Timeline, Leader, Team info strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(
                      '${DateFormat('dd-MM-yyyy').format(project.startDate)} — ${DateFormat('dd-MM-yyyy').format(project.endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (project.projectLeaderName != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        'Leader: ${project.projectLeaderName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textLight : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                if (project.memberNames.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_outlined, size: 14, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        '${project.memberNames.length} Members',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Pipeline Workflow Visual (Horizontal stages matching Image 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Workflow Pipeline (${project.workflowStages.length} Stages)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${project.progressPercent}% Complete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHorizontalPipeline(project, isDark),
              ],
            ),
          ),

          // Rejection / Approval Alert Callout (If applicable)
          if (isRejected) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Text(
                        'Stage "${curStage.name}" Rejected by Admin — Redo Required',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  if (curStage.rejectionReason != null && curStage.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Admin Feedback: "${curStage.rejectionReason}"',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF7F1D1D),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Employee / Intern must redo this stage and resubmit until Admin accepts it.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isAwaiting) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stage "${curStage.name}" is Awaiting Admin Approval.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),

          // Actions Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Current Stage Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current Stage: ${curStage.name}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textLight : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Spacer(),

                // Admin Review Button
                if (widget.state.isAdmin) ...[
                  if (isAwaiting) ...[
                    ElevatedButton.icon(
                      onPressed: () => _openStageReviewDialog(context, project),
                      icon: const Icon(Icons.gavel_rounded, size: 16, color: Colors.white),
                      label: const Text('Review Stage Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ] else if (!project.isCompleted) ...[
                    OutlinedButton.icon(
                      onPressed: () => _openStageReviewDialog(context, project),
                      icon: Icon(Icons.tune_rounded, size: 15, color: primaryOrange),
                      label: Text('Manage Stage', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w700, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryOrange),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],

                // Employee / Intern Redo & Resubmit or Advance
                if (!widget.state.isAdmin) ...[
                  if (isRejected) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        await widget.state.resubmitProjectStage(
                          projectId: project.id,
                          resubmittedBy: widget.state.userProfile.name,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stage redone and resubmitted to Admin for approval!'),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                      label: const Text('Redo & Resubmit to Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ] else if (isAwaiting) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Text(
                        'Under Admin Review',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ] else if (!project.isCompleted) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        await widget.state.advanceProjectStage(
                          projectId: project.id,
                          userEmail: widget.state.userProfile.name,
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                      label: Text(
                        curStage.requiresApproval ? 'Submit for Admin Approval' : 'Advance Stage',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPipeline(EnterpriseProject project, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: project.workflowStages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          final isCurrent = index == project.currentStageIndex;
          final isPast = index < project.currentStageIndex;
          final isLast = index == project.workflowStages.length - 1;

          // Color calculation
          Color dotColor = const Color(0xFF64748B);
          if (stage.status == 'APPROVED' || isPast) dotColor = const Color(0xFF10B981);
          else if (stage.status == 'REJECTED_REDO') dotColor = const Color(0xFFEF4444);
          else if (stage.status == 'AWAITING_APPROVAL') dotColor = const Color(0xFF8B5CF6);
          else if (isCurrent) dotColor = const Color(0xFFF59E0B);

          String subtitle = 'Standard';
          if (stage.isFinalCompletedStage) subtitle = 'Completed';
          else if (stage.status == 'REJECTED_REDO') subtitle = 'Redo Required';
          else if (stage.requiresApproval) subtitle = 'Approval Req';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent
                        ? dotColor
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isCurrent ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          stage.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isDark ? AppColors.textLight : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: stage.status == 'REJECTED_REDO'
                            ? const Color(0xFFEF4444)
                            : (stage.requiresApproval
                                ? const Color(0xFF8B5CF6)
                                : (isDark ? AppColors.textLightMuted : const Color(0xFF64748B))),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectStatusBadge(String status, bool isDark) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF475569);

    if (status == 'Active') {
      bg = const Color(0xFFEA580C).withValues(alpha: 0.12);
      text = const Color(0xFFEA580C);
    } else if (status == 'Completed') {
      bg = const Color(0xFF2563EB).withValues(alpha: 0.12);
      text = const Color(0xFF2563EB);
    } else if (status == 'Overdue') {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
      text = const Color(0xFFEF4444);
    } else if (status == 'On Hold') {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      text = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}

/// 5-Step Project & Workflow Setup Wizard Dialog matching Images 2, 3, 4, 5
class ProjectWorkflowSetupWizardDialog extends StatefulWidget {
  final AppState state;
  final bool isDark;

  const ProjectWorkflowSetupWizardDialog({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  State<ProjectWorkflowSetupWizardDialog> createState() =>
      _ProjectWorkflowSetupWizardDialogState();
}

class _ProjectWorkflowSetupWizardDialogState
    extends State<ProjectWorkflowSetupWizardDialog> {
  int _currentStep = 1; // 1 to 5

  // Step 1: Basic Info
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _projectType = 'Client Project';
  String _priority = 'Medium';
  String _initialStatus = 'Active';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String? _selectedLeaderId;
  String? _selectedLeaderName;

  // Step 2: Team Members
  String _selectedTeam = '-- No Team --';
  final Set<String> _selectedMemberEmails = {};

  // Step 3: Workflow Stages
  List<ProjectWorkflowStage> _stages = [
    const ProjectWorkflowStage(id: 'stg-1', name: 'To Do', order: 1, colorHex: '#64748B'),
    const ProjectWorkflowStage(id: 'stg-2', name: 'In Progress', order: 2, colorHex: '#F59E0B'),
    const ProjectWorkflowStage(id: 'stg-3', name: 'In Review', order: 3, requiresApproval: true, colorHex: '#8B5CF6'),
    const ProjectWorkflowStage(id: 'stg-4', name: 'Done', order: 4, isFinalCompletedStage: true, colorHex: '#10B981'),
  ];

  // Step 4: Approval Rules
  bool _requireAdminApproval = true;
  bool _requireRedoOnRejection = true;
  bool _requireRejectionComments = true;
  bool _notifyTeamOnStatusChange = true;

  @override
  void initState() {
    super.initState();
    // Preselect current admin as leader if available
    _selectedLeaderName = widget.state.userProfile.name;
    _selectedLeaderId = widget.state.userProfile.email;
    _selectedMemberEmails.add(widget.state.userProfile.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a Project Name to continue'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    } else if (_currentStep == 3) {
      if (_stages.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('At least 2 stages are required'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _launchProject() async {
    final codeNum = 100 + widget.state.projects.length + 1;
    final projectCode = 'PRJ-$codeNum';
    final projectId = 'PRJ-${DateTime.now().millisecondsSinceEpoch % 100000}';

    // Member names
    final memberNames = <String>[];
    for (final email in _selectedMemberEmails) {
      final user = AppState.userDirectory[email];
      if (user != null) {
        memberNames.add(user.name);
      } else if (email == widget.state.userProfile.email) {
        memberNames.add(widget.state.userProfile.name);
      } else {
        memberNames.add(email);
      }
    }

    final newProject = EnterpriseProject(
      id: projectId,
      code: projectCode,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      projectType: _projectType,
      priority: _priority,
      status: _initialStatus,
      startDate: _startDate,
      endDate: _endDate,
      projectLeaderId: _selectedLeaderId,
      projectLeaderName: _selectedLeaderName,
      assignedTeam: _selectedTeam == '-- No Team --' ? null : _selectedTeam,
      memberIds: _selectedMemberEmails.toList(),
      memberNames: memberNames,
      workflowStages: _stages,
      currentStageIndex: 0,
      requiresAdminApproval: _requireAdminApproval,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await widget.state.addEnterpriseProject(newProject);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project "${newProject.name}" ($projectCode) launched successfully!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryOrange = const Color(0xFFEA580C);
    final primaryGreen = const Color(0xFF059669);
    final isStep1 = _currentStep == 1;
    final themeColor = isStep1 ? primaryOrange : primaryGreen;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDarkBody : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          children: [
            // Header matching Images 2-5
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project & Workflow Setup Wizard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStepSubtitle(),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Step Progress Pills Strip matching Images 2-5
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStepProgressPills(themeColor, isDark),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // Step Body Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: _buildCurrentStepContent(isDark, themeColor),
              ),
            ),

            const Divider(height: 1),

            // Dialog Footer Navigation matching Images 2-5
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  if (_currentStep == 1)
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? AppColors.textLight : const Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        '← Back',
                        style: TextStyle(
                          color: isDark ? AppColors.textLight : const Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (_currentStep < 5)
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Next Step', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _launchProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Launch Project & Workflow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
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

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 1:
        return 'Step 1 of 5 — Basic Info';
      case 2:
        return 'Step 2 of 5 — Team Members';
      case 3:
        return 'Step 3 of 5 — Workflow Stages';
      case 4:
        return 'Step 4 of 5 — Approval Rules';
      case 5:
        return 'Step 5 of 5 — Preview & Create';
      default:
        return '';
    }
  }

  Widget _buildStepProgressPills(Color themeColor, bool isDark) {
    final stepNames = [
      '1. Basic Info',
      '2. Team Members',
      '3. Workflow Stages',
      '4. Approval Rules',
      '5. Preview & Create',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stepNames.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final title = entry.value;
          final isCurrent = idx == _currentStep;
          final isPast = idx < _currentStep;

          Color pillBg = Colors.transparent;
          Color textCol = isDark ? AppColors.textLightMuted : const Color(0xFF64748B);

          if (isCurrent) {
            pillBg = themeColor;
            textCol = Colors.white;
          } else if (isPast) {
            pillBg = const Color(0xFF059669).withValues(alpha: 0.15);
            textCol = const Color(0xFF059669);
          }

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: textCol,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark, Color themeColor) {
    switch (_currentStep) {
      case 1:
        return _buildStep1BasicInfo(isDark);
      case 2:
        return _buildStep2TeamMembers(isDark);
      case 3:
        return _buildStep3WorkflowStages(isDark);
      case 4:
        return _buildStep4ApprovalRules(isDark);
      case 5:
        return _buildStep5PreviewCreate(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: Basic Info (matching Image 2) ---
  Widget _buildStep1BasicInfo(bool isDark) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      ),
    );

    // Leader options from directory
    final leaderOptions = <Map<String, String>>[
      {'id': '', 'name': '-- Unassigned --'},
    ];
    AppState.userDirectory.forEach((email, profile) {
      leaderOptions.add({'id': email, 'name': '${profile.name} (${profile.role})'});
    });
    if (!leaderOptions.any((o) => o['id'] == widget.state.userProfile.email)) {
      leaderOptions.add({
        'id': widget.state.userProfile.email,
        'name': '${widget.state.userProfile.name} (${widget.state.userProfile.role})',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project Name
        _buildFieldLabel('Project Name *', isDark),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          style: TextStyle(color: isDark ? AppColors.textLight : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'e.g. Enterprise Website Redesign',
            hintStyle: TextStyle(color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8)),
            border: border,
            enabledBorder: border,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),

        // Description
        _buildFieldLabel('Description', isDark),
        const SizedBox(height: 6),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          style: TextStyle(color: isDark ? AppColors.textLight : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Brief summary of goals, scope, and target deliverables...',
            hintStyle: TextStyle(color: isDark ? AppColors.textLightMuted : const Color(0xFF94A3B8)),
            border: border,
            enabledBorder: border,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),

        // Row of 3 dropdowns: Project Type, Priority, Initial Status
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            final itemWidth = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 20) / 3;

            return Wrap(
              spacing: 10,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Project Type', isDark),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _projectType,
                        decoration: InputDecoration(border: border, contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                        items: ['Client Project', 'Internal Project', 'Research & Development', 'Maintenance']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _projectType = val);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Priority', isDark),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _priority,
                        decoration: InputDecoration(border: border, contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                        items: [
                          const DropdownMenuItem(value: 'Low', child: Text('🟢 Low', style: TextStyle(fontSize: 13))),
                          const DropdownMenuItem(value: 'Medium', child: Text('🟡 Medium', style: TextStyle(fontSize: 13))),
                          const DropdownMenuItem(value: 'High', child: Text('🟠 High', style: TextStyle(fontSize: 13))),
                          const DropdownMenuItem(value: 'Critical', child: Text('🔴 Critical', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _priority = val);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Initial Status', isDark),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _initialStatus,
                        decoration: InputDecoration(border: border, contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                        items: ['Active', 'Draft', 'Scheduled', 'On Hold']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: s == 'Active' ? const Color(0xFFEA580C) : null,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _initialStatus = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Row of 2 Date pickers: Estimated Start Date & Estimated End Date
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Estimated Start Date *', isDark),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('dd-MM-yyyy').format(_startDate),
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textLight : const Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Estimated End Date *', isDark),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('dd-MM-yyyy').format(_endDate),
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textLight : const Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Project Leader dropdown
        _buildFieldLabel('Project Leader', isDark),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: leaderOptions.any((o) => o['id'] == _selectedLeaderId) ? _selectedLeaderId : '',
          decoration: InputDecoration(border: border, contentPadding: const EdgeInsets.symmetric(horizontal: 14)),
          items: leaderOptions.map((opt) {
            return DropdownMenuItem(
              value: opt['id'],
              child: Text(opt['name']!, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLeaderId = val;
              final opt = leaderOptions.firstWhere((o) => o['id'] == val, orElse: () => {'name': ''});
              _selectedLeaderName = opt['name']!.split('(').first.trim();
              if (val != null && val.isNotEmpty) {
                _selectedMemberEmails.add(val);
              }
            });
          },
        ),
      ],
    );
  }

  // --- STEP 2: Team Members (matching Image 3) ---
  Widget _buildStep2TeamMembers(bool isDark) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      ),
    );

    // Build selectable directory members
    final members = <UserProfile>[];
    AppState.userDirectory.forEach((_, p) {
      members.add(p);
    });
    if (!members.any((m) => m.email == widget.state.userProfile.email)) {
      members.add(widget.state.userProfile);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Assigned Team (Optional)', isDark),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedTeam,
          decoration: InputDecoration(border: border, contentPadding: const EdgeInsets.symmetric(horizontal: 14)),
          items: [
            '-- No Team --',
            'Core Development Team',
            'Mobile App Engineering',
            'Frontend & Design Team',
            'QA & Automation Testing',
            'DevOps & Infrastructure',
          ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedTeam = val);
          },
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Select Project Members (${_selectedMemberEmails.length} selected)', isDark),
        const SizedBox(height: 10),

        ...members.map((member) {
          final isSelected = _selectedMemberEmails.contains(member.email);
          final isLeader = member.email == _selectedLeaderId ||
              member.name.toLowerCase() == (_selectedLeaderName ?? '').toLowerCase();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF059669).withValues(alpha: 0.5)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                value: isSelected,
                activeColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                    ),
                  ),
                  if (isLeader) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Project Leader',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${member.role} • ${(member.department != null && member.department!.isNotEmpty) ? member.department! : "Engineering"}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                ),
              ),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedMemberEmails.add(member.email);
                  } else {
                    _selectedMemberEmails.remove(member.email);
                  }
                });
              },
            ),
          ),
        );
        }),
      ],
    );
  }

  // --- STEP 3: Workflow Stages (matching Image 4) ---
  Widget _buildStep3WorkflowStages(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure Project Workflow Stages',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Min 2, Max 10 stages. Check "Approval" for review stages, and select exactly 1 Completed stage.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _stages.length < 10
                  ? () {
                      setState(() {
                        final newOrder = _stages.length + 1;
                        _stages.insert(
                          _stages.length - 1,
                          ProjectWorkflowStage(
                            id: 'stg-${DateTime.now().millisecondsSinceEpoch % 1000}',
                            name: 'Stage $newOrder',
                            order: newOrder,
                            colorHex: '#3B82F6',
                          ),
                        );
                      });
                    }
                  : null,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Add Stage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _stages.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _stages.removeAt(oldIndex);
              _stages.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final stage = _stages[index];
            final isLast = index == _stages.length - 1;

            return Container(
              key: ValueKey(stage.id),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator_rounded, size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    '#${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: stage.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        _stages[index] = stage.copyWith(name: val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Approval checkbox or Final Completed Stage Badge
                  if (isLast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FINAL APPROVAL STAGE — AUTO COMPLETED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: stage.requiresApproval,
                          activeColor: const Color(0xFF059669),
                          onChanged: (checked) {
                            setState(() {
                              _stages[index] = stage.copyWith(requiresApproval: checked ?? false);
                            });
                          },
                        ),
                        Text(
                          stage.requiresApproval ? '✓ Approval' : 'Approval',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: stage.requiresApproval ? const Color(0xFF059669) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(width: 8),
                  // Delete Stage Button
                  if (_stages.length > 2)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      onPressed: () {
                        setState(() {
                          _stages.removeAt(index);
                        });
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 4: Approval Rules (Enforces Admin approval & Redo on Rejection) ---
  Widget _buildStep4ApprovalRules(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workflow Stage Gate & Admin Approval Rules',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enforce strict administrative governance before projects can advance to the next stage.',
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        // Core Rule 1: Admin Approval Gate
        _buildRuleCard(
          title: 'Mandatory Admin Approval Gate',
          description:
              'Stages flagged with "Approval" will automatically halt progression and submit a review request to the Admin. Only Admin can sanction the transition.',
          icon: Icons.security_rounded,
          iconColor: const Color(0xFF059669),
          value: _requireAdminApproval,
          isDark: isDark,
          onChanged: (v) => setState(() => _requireAdminApproval = v),
        ),
        const SizedBox(height: 12),

        // Core Rule 2: Rejection Redo Requirement (Requested feature)
        _buildRuleCard(
          title: 'Strict Redo on Stage Rejection',
          description:
              'When Admin rejects the particular stage, the assigned employee or intern MUST redo the stage deliverable and resubmit until Admin accepts it.',
          icon: Icons.replay_rounded,
          iconColor: const Color(0xFFEA580C),
          value: _requireRedoOnRejection,
          isDark: isDark,
          onChanged: (v) => setState(() => _requireRedoOnRejection = v),
        ),
        const SizedBox(height: 12),

        // Core Rule 3: Mandatory Rejection Reason
        _buildRuleCard(
          title: 'Mandatory Feedback Notes on Rejection',
          description:
              'Admin must specify actionable corrective feedback explaining why the stage was rejected so team members know what to fix.',
          icon: Icons.comment_rounded,
          iconColor: const Color(0xFF2563EB),
          value: _requireRejectionComments,
          isDark: isDark,
          onChanged: (v) => setState(() => _requireRejectionComments = v),
        ),
        const SizedBox(height: 12),

        // Core Rule 4: Team Notification
        _buildRuleCard(
          title: 'Realtime Alerts for Team Members',
          description:
              'Notify all project members instantly when a stage is approved, rejected for redo, or completed.',
          icon: Icons.notifications_active_rounded,
          iconColor: const Color(0xFF8B5CF6),
          value: _notifyTeamOnStatusChange,
          isDark: isDark,
          onChanged: (v) => setState(() => _notifyTeamOnStatusChange = v),
        ),
      ],
    );
  }

  Widget _buildRuleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- STEP 5: Preview & Create (matching Image 5) ---
  Widget _buildStep5PreviewCreate(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary green callout banner matching Image 5
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project Configuration Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review your project settings before launching the workflow.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textLightMuted : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Row of 2 Summary Cards matching Image 5
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Name & Code',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Untitled Project',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_projectType.toUpperCase()} • ${_priority.toUpperCase()} PRIORITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline & Leader',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('yyyy-MM-dd').format(_startDate)} — ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Leader: ${_selectedLeaderName ?? "Unassigned"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Configured Workflow Pipeline (N Stages) matching Image 5
        Text(
          'Configured Workflow Pipeline (${_stages.length} Stages)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _stages.asMap().entries.map((entry) {
              final idx = entry.key;
              final stage = entry.value;
              final isLast = idx == _stages.length - 1;

              Color dotColor = const Color(0xFF64748B);
              if (idx == 0) dotColor = const Color(0xFF64748B);
              else if (idx == 1) dotColor = const Color(0xFFF59E0B);
              else if (stage.requiresApproval) dotColor = const Color(0xFF8B5CF6);
              else if (isLast) dotColor = const Color(0xFF10B981);

              String subtitle = 'Standard';
              if (stage.requiresApproval) subtitle = 'Approval Req';
              if (isLast) subtitle = 'Completed';

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              stage.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: stage.requiresApproval
                                ? const Color(0xFF8B5CF6)
                                : (isLast ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textLight : const Color(0xFF334155),
      ),
    );
  }
}

/// Admin Stage Review & Approval / Rejection Modal
class ProjectStageReviewDialog extends StatefulWidget {
  final EnterpriseProject project;
  final AppState state;
  final bool isDark;

  const ProjectStageReviewDialog({
    super.key,
    required this.project,
    required this.state,
    required this.isDark,
  });

  @override
  State<ProjectStageReviewDialog> createState() =>
      _ProjectStageReviewDialogState();
}

class _ProjectStageReviewDialogState extends State<ProjectStageReviewDialog> {
  final TextEditingController _rejectionCtrl = TextEditingController();
  bool _isRejecting = false;

  @override
  void dispose() {
    _rejectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    await widget.state.approveProjectStage(
      projectId: widget.project.id,
      approvedBy: widget.state.userProfile.name,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stage "${widget.project.currentStage.name}" Approved! Project progressed.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _reject() async {
    final reason = _rejectionCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide rejection feedback explaining what the employee must redo.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    await widget.state.rejectProjectStage(
      projectId: widget.project.id,
      rejectedBy: widget.state.userProfile.name,
      rejectionReason: reason,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stage "${widget.project.currentStage.name}" Rejected. Employee must redo the stage.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final curStage = widget.project.currentStage;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDarkBody : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(22),
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Color(0xFF8B5CF6), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Stage Approval Gate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Review stage deliverables and sanction progression or demand redo.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Project Details Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.project.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        widget.project.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stage: ${curStage.name} (Stage #${widget.project.currentStageIndex + 1})',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textLight : const Color(0xFF334155),
                    ),
                  ),
                  if (curStage.submittedBy != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Submitted By: ${curStage.submittedBy}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // If in Reject Mode, show feedback textfield
            if (_isRejecting) ...[
              Text(
                'Rejection Feedback / Required Redo Instructions *',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textLight : const Color(0xFF991B1B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _rejectionCtrl,
                maxLines: 3,
                style: TextStyle(color: isDark ? AppColors.textLight : const Color(0xFF0F172A), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Describe what deliverables are missing or what needs to be redone before approval...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Notice: The employee/intern must complete and redo this stage until you accept it.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            Row(
              children: [
                if (!_isRejecting) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isRejecting = true),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 16),
                      label: const Text('Reject Stage (Demand Redo)', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approve,
                      icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                      label: const Text('Approve & Advance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: () => setState(() => _isRejecting = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 16),
                    label: const Text('Confirm Rejection & Require Redo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
