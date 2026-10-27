import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';

class TasksScreen extends StatefulWidget {
  final List<TaskItem> tasks;
  final Function(TaskItem)? onAddTask;
  final Function(String taskId, String status, double progress)? onUpdateTaskProgress;
  final String userRole;

  const TasksScreen({
    super.key,
    required this.tasks,
    this.onAddTask,
    this.onUpdateTaskProgress,
    this.userRole = 'EMPLOYEE',
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  bool get isAdmin =>
      widget.userRole.toUpperCase() == 'ADMIN' ||
      widget.userRole.toUpperCase() == 'SUPER_ADMIN';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filtering logic
    final filteredTasks = widget.tasks.where((task) {
      final matchesFilter = _selectedFilter == 'All' || task.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    final counts = {
      'All': widget.tasks.length,
      'In Progress': widget.tasks.where((t) => t.status == 'In Progress').length,
      'Pending': widget.tasks.where((t) => t.status == 'Pending').length,
      'In Review': widget.tasks.where((t) => t.status == 'In Review').length,
      'Completed': widget.tasks.where((t) => t.status == 'Completed').length,
    };

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTaskDialog(context),
              backgroundColor: AppColors.primaryPine,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar & Filter Buttons
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search deliverables, bugs...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Workspace Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildWorkspaceChip('All Workspaces', isSelected: true),
                  const SizedBox(width: 8),
                  _buildWorkspaceChip('Mobile App Redesign', isSelected: false),
                  const SizedBox(width: 8),
                  _buildWorkspaceChip('Internal ERP v2', isSelected: false),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Filter Pills Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('All', counts['All'] ?? 0),
                  const SizedBox(width: 6),
                  _buildFilterPill('In Progress', counts['In Progress'] ?? 0),
                  const SizedBox(width: 6),
                  _buildFilterPill('Pending', counts['Pending'] ?? 0),
                  const SizedBox(width: 6),
                  _buildFilterPill('In Review', counts['In Review'] ?? 0),
                  const SizedBox(width: 6),
                  _buildFilterPill('Completed', counts['Completed'] ?? 0),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sprint Metric Summary Banner
            Card(
              color: isDark ? const Color(0xFF064E3B).withOpacity(0.4) : AppColors.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt, color: AppColors.primaryPine, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sprint 38 Execution',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '4 of 6 deliverables targeted for week',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '66%',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.vibrantEmerald),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Task List
            Text(
              'Deliverables (${filteredTasks.length})',
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            filteredTasks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No tasks found matching filter criteria.'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskCard(task);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceChip(String title, {required bool isSelected}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryPineDark : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primaryPineDark : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : (isDark ? AppColors.textLight : AppColors.textDark),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String status, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == status;
    Color bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color text = isDark ? AppColors.textLight : AppColors.textDark;
    Color border = isDark ? const Color(0xFF334155) : AppColors.borderLight;

    if (isSelected) {
      bg = isDark ? AppColors.primaryPine.withOpacity(0.25) : AppColors.surfaceContainerLow;
      text = isDark ? AppColors.vibrantEmerald : AppColors.primaryPine;
      border = isDark ? AppColors.vibrantEmerald : AppColors.primaryPine;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          '$status ($count)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: text,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusBg;
    Color statusText;
    Color statusBorder;

    switch (task.status) {
      case 'In Progress':
        statusBg = AppColors.inProgressBg;
        statusText = AppColors.inProgressText;
        statusBorder = AppColors.inProgressBorder;
        break;
      case 'Pending':
        statusBg = AppColors.pendingBg;
        statusText = AppColors.pendingText;
        statusBorder = AppColors.pendingBorder;
        break;
      case 'In Review':
        statusBg = AppColors.inReviewBg;
        statusText = AppColors.inReviewText;
        statusBorder = AppColors.inReviewBorder;
        break;
      case 'Completed':
        statusBg = AppColors.completedBg;
        statusText = AppColors.completedText;
        statusBorder = AppColors.completedBorder;
        break;
      default:
        statusBg = AppColors.inProgressBg;
        statusText = AppColors.inProgressText;
        statusBorder = AppColors.inProgressBorder;
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetailsAndUpdateDialog(context, task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.category,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                task.description,
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        task.dueDate,
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${(task.progress * 100).toInt()}% Done',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPine),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_note, size: 16, color: AppColors.primaryPine),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    task.status == 'Completed' ? AppColors.vibrantEmerald : AppColors.primaryPine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetailsAndUpdateDialog(BuildContext context, TaskItem task) {
    String currentStatus = task.status;
    double currentProgress = task.progress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final percent = (currentProgress * 100).toInt();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.category,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPine),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.completedBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.completedBorder),
                        ),
                        child: Text(
                          'Priority: ${task.priority}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.completedText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.description.isNotEmpty ? task.description : 'No additional description provided.',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${task.dueDate}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  const Text(
                    'Update Deliverable Progress & Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Status Dropdown
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.borderLight),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentStatus,
                              isExpanded: true,
                              items: ['Pending', 'In Progress', 'In Review', 'Completed']
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    currentStatus = val;
                                    if (val == 'Completed') {
                                      currentProgress = 1.0;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress Completion:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        '$percent%',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryPine),
                      ),
                    ],
                  ),
                  Slider(
                    value: currentProgress,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    activeColor: AppColors.primaryPine,
                    inactiveColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    label: '$percent%',
                    onChanged: (val) {
                      setModalState(() {
                        currentProgress = val;
                        if (val == 1.0) {
                          currentStatus = 'Completed';
                        } else if (val > 0.0 && currentStatus == 'Pending') {
                          currentStatus = 'In Progress';
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onUpdateTaskProgress != null) {
                          widget.onUpdateTaskProgress!(task.id, currentStatus, currentProgress);
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task "${task.title}" updated to $currentStatus ($percent%).'),
                            backgroundColor: AppColors.primaryPine,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                      label: const Text('Save & Update Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPine,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Mobile App Redesign';
    String priority = 'High';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && widget.onAddTask != null) {
                widget.onAddTask!(
                  TaskItem(
                    id: 'TSK-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    title: titleController.text,
                    description: descController.text,
                    category: category,
                    status: 'In Progress',
                    priority: priority,
                    progress: 0.1,
                    dueDate: 'Due Tomorrow',
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPine),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
