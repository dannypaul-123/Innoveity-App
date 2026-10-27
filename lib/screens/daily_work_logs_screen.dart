import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_dropdown_menu.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_avatar.dart';
import 'announcements_screen.dart';
import 'main_navigation_screen.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.dash = 6.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dash < metric.length) ? dash : metric.length - distance;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dash != oldDelegate.dash ||
      gap != oldDelegate.gap ||
      radius != oldDelegate.radius;
}

class DailyWorkLogsScreen extends StatefulWidget {
  final List<WorkLogEntry> workLogs;
  final Function(WorkLogEntry) onAddWorkLog;
  final String formattedClockTime;
  final bool isClockedIn;
  final Future<void> Function()? onRefresh;
  final AppState? state;

  const DailyWorkLogsScreen({
    super.key,
    required this.workLogs,
    required this.onAddWorkLog,
    required this.formattedClockTime,
    required this.isClockedIn,
    this.onRefresh,
    this.state,
  });

  @override
  State<DailyWorkLogsScreen> createState() => _DailyWorkLogsScreenState();
}

class _DailyWorkLogsScreenState extends State<DailyWorkLogsScreen> {
  String _searchQuery = '';
  String _selectedDateFilter = 'All Time';
  String _selectedStatusFilter = 'All Statuses';
  bool _isSyncing = false;

  String _formatHoursMinutes(double hoursDecimal) {
    if (hoursDecimal <= 0) return '0 hrs';
    final hrs = hoursDecimal.toInt();
    final mins = ((hoursDecimal - hrs) * 60).round();
    if (hrs == 0 && mins == 0) return '0 hrs';
    if (mins == 0) return '$hrs hrs';
    if (hrs == 0) return '${mins}m';
    return '${hrs}h ${mins}m';
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      setState(() => _isSyncing = true);
      await widget.onRefresh!();
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced latest work logs from backend server!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {});
    }
  }

  void _showCreateWorkLogModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLight : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textLightMuted : const Color(0xFF64748B);
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Initial times: default 10:00 to 11:29 matching the reference photo
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 29);

    double calcHours(TimeOfDay s, TimeOfDay e) {
      final sMin = s.hour * 60 + s.minute;
      final eMin = e.hour * 60 + e.minute;
      int diff = eMin - sMin;
      if (diff < 0) diff += 24 * 60;
      return diff / 60.0;
    }

    String formatTimeOfDay(TimeOfDay t) {
      final hourStr = t.hour.toString().padLeft(2, '0');
      final minStr = t.minute.toString().padLeft(2, '0');
      return '$hourStr:$minStr';
    }

    String formatHoursBadge(double hrs) {
      final totalMin = (hrs * 60).round();
      final h = totalMin ~/ 60;
      final m = totalMin % 60;
      final dec = hrs.toStringAsFixed(2);
      return '${h}h ${m}m (${dec}h)';
    }

    // Projects list
    final availableProjects = <String>[
      '-- No Specific Project --',
      'Mobile Application Redesign',
      'Internal ERP Migration',
      'Customer Support Portal',
      'Backend API Optimization',
      'HR & Payroll Platform',
    ];
    if (widget.state?.tasks != null) {
      for (final t in widget.state!.tasks) {
        if (t.category.isNotEmpty && !availableProjects.contains(t.category)) {
          availableProjects.add(t.category);
        }
      }
    }

    // Tasks list
    final availableTasks = <String>[
      '-- No Specific Task --',
      'UI Design Implementation',
      'Bug Fixing & Regression Testing',
      'Database Schema Migration',
      'API Integration & Endpoints',
      'Code Review & Documentation',
    ];
    if (widget.state?.tasks != null) {
      for (final t in widget.state!.tasks) {
        if (!availableTasks.contains(t.title)) {
          availableTasks.add(t.title);
        }
      }
    }

    String selectedProject = '-- No Specific Project --';
    String selectedTask = '-- No Specific Task --';
    final descriptionController = TextEditingController();
    final List<String> attachedFiles = [];

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final hoursVal = calcHours(startTime, endTime);
          final hoursDisplay = formatHoursBadge(hoursVal);

          void submitLog({required bool isDraft}) {
            final desc = descriptionController.text.trim();
            if (!isDraft && desc.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please describe your achievements or completed tasks.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
              return;
            }

            final projTitle = selectedProject != '-- No Specific Project --'
                ? selectedProject
                : (selectedTask != '-- No Specific Task --' ? selectedTask : 'General Work');

            final finalDesc = desc.isNotEmpty ? desc : (isDraft ? 'Work in progress draft.' : 'Daily activities completed.');
            final statusStr = isDraft ? 'DRAFT' : 'PENDING';
            final attachmentStr = attachedFiles.isNotEmpty ? attachedFiles.join(', ') : 'None';

            final newEntry = WorkLogEntry(
              id: 'WL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              date: 'Today',
              projectTask: projTitle,
              description: finalDesc,
              hours: double.parse(hoursVal.toStringAsFixed(2)),
              status: statusStr,
              attachmentName: attachmentStr,
              submittedTime: 'Today, ${TimeOfDay.now().format(context)}',
              startTime: formatTimeOfDay(startTime),
              endTime: formatTimeOfDay(endTime),
              projectName: selectedProject != '-- No Specific Project --' ? selectedProject : null,
              taskTitle: selectedTask != '-- No Specific Task --' ? selectedTask : null,
              attachments: List.from(attachedFiles),
            );

            widget.onAddWorkLog(newEntry);
            Navigator.pop(ctx);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isDraft
                      ? "Work log draft saved successfully!"
                      : "Work log for '$projTitle' submitted successfully!",
                ),
                backgroundColor: isDraft ? const Color(0xFFD97706) : const Color(0xFF058A5E),
              ),
            );
          }

          return Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            elevation: 16,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(
                  builder: (ctxInner, dialogConstraints) {
                    final isCompact = dialogConstraints.maxWidth < 460;
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isCompact ? 16 : 24),
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF97316), width: 1.8),
                            ),
                            child: const Center(
                              child: Icon(Icons.access_time_rounded, color: Color(0xFFEA580C), size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Create Today's Work Log",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Submit today's completed work before ending your shift.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(ctx),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      const SizedBox(height: 18),

                      // Time and Hours Row (3 columns in a rounded container)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: LayoutBuilder(
                          builder: (ctxLayout, constraints) {
                            final isMobile = constraints.maxWidth < 420;
                            final timePickers = [
                              // START TIME
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'START TIME',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: startTime,
                                      );
                                      if (picked != null) {
                                        setModalState(() => startTime = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: inputBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formatTimeOfDay(startTime),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Icon(Icons.access_time, size: 16, color: textMuted),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // END TIME
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'END TIME',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: endTime,
                                      );
                                      if (picked != null) {
                                        setModalState(() => endTime = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: inputBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formatTimeOfDay(endTime),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Icon(Icons.access_time, size: 16, color: textMuted),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // HOURS WORKED
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HOURS WORKED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: inputBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            hoursDisplay,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFEA580C),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Live',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ];

                            if (isMobile) {
                              return Column(
                                children: [
                                  timePickers[0],
                                  const SizedBox(height: 10),
                                  timePickers[1],
                                  const SizedBox(height: 10),
                                  timePickers[2],
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: timePickers[0]),
                                const SizedBox(width: 10),
                                Expanded(child: timePickers[1]),
                                const SizedBox(width: 10),
                                Expanded(child: timePickers[2]),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Select Project and Select Task Row
                      LayoutBuilder(
                        builder: (ctxLayout, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
                          final projWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Project (Optional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedProject,
                                    isExpanded: true,
                                    dropdownColor: cardBg,
                                    icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textMuted),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: availableProjects.map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() => selectedProject = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );

                          final taskWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Task (Optional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedTask,
                                    isExpanded: true,
                                    dropdownColor: cardBg,
                                    icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textMuted),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: availableTasks.map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() => selectedTask = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                projWidget,
                                const SizedBox(height: 12),
                                taskWidget,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: projWidget),
                              const SizedBox(width: 12),
                              Expanded(child: taskWidget),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Work Summary (Tasks Completed) *
                      RichText(
                        text: TextSpan(
                          text: 'Work Summary (Tasks Completed) ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                          children: const [
                            TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        minLines: 3,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Describe your achievements, tasks completed, features built, or bugs solved today...',
                          hintStyle: TextStyle(fontSize: 12, color: textMuted),
                          fillColor: inputBg,
                          filled: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Attachments Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Transform.rotate(
                                angle: -0.7,
                                child: const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFFEA580C)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Attachments',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                            ],
                          ),
                          Flexible(
                            child: Text(
                              'PNG, JPG, WEBP, GIF, MP4, MOV, MP3, WAV, PDF, DOCX, XLSX, ZIP',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: textMuted),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dashed Upload Area
                      CustomPaint(
                        painter: DashedBorderPainter(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          radius: 12,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            try {
                              final result = await FilePicker.pickFiles(
                                allowMultiple: true,
                              );
                              if (result != null && result.files.isNotEmpty) {
                                setModalState(() {
                                  for (final f in result.files) {
                                    if (f.name.isNotEmpty && !attachedFiles.contains(f.name)) {
                                      attachedFiles.add(f.name);
                                    }
                                  }
                                });
                              }
                            } catch (_) {
                              // Fallback simulated file add if permission or platform issue
                              setModalState(() {
                                attachedFiles.add('daily_work_screenshot.png');
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFFEDD5)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.file_upload_outlined, color: Color(0xFFEA580C), size: 22),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Drag & Drop Files Here',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: 'Or click to upload • Press ',
                                    style: TextStyle(fontSize: 11, color: textMuted),
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          margin: const EdgeInsets.symmetric(horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                          ),
                                          child: Text(
                                            'Ctrl+V',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' anywhere to paste screenshots or copied files.',
                                        style: TextStyle(fontSize: 11, color: textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (attachedFiles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: attachedFiles.map((fileName) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined, size: 14, color: Color(0xFFEA580C)),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 160),
                                    child: Text(
                                      fileName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => setModalState(() => attachedFiles.remove(fileName)),
                                    child: Icon(Icons.close, size: 14, color: textMuted),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Footer Action Buttons: Cancel, Save Draft, Submit Work Log
                      LayoutBuilder(
                        builder: (ctxActions, actionConstraints) {
                          final isNarrow = actionConstraints.maxWidth < 430;

                          final cancelButton = OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textLight : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );

                          final draftButton = OutlinedButton.icon(
                            onPressed: () => submitLog(isDraft: true),
                            icon: const Icon(Icons.save_outlined, size: 16, color: Color(0xFFB45309)),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Save Draft',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFBEB),
                              side: const BorderSide(color: Color(0xFFFDE68A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          );

                          final submitButton = ElevatedButton.icon(
                            onPressed: () => submitLog(isDraft: false),
                            icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Submit Work Log',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF058A5E),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: cancelButton),
                                    const SizedBox(width: 8),
                                    Expanded(child: draftButton),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: submitButton,
                                ),
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              cancelButton,
                              const SizedBox(width: 8),
                              draftButton,
                              const SizedBox(width: 8),
                              submitButton,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
        },
      ),
    );
  }

  void _showWorkLogDetailsModal(BuildContext context, WorkLogEntry item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLight : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textLightMuted : const Color(0xFF64748B);
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    Color statusBg;
    Color statusFg;
    if (item.status == 'APPROVED') {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF15803D);
    } else if (item.status == 'REJECTED') {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFB91C1C);
    } else if (item.status == 'DRAFT') {
      statusBg = const Color(0xFFFEF3C7);
      statusFg = const Color(0xFFB45309);
    } else {
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        elevation: 16,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (ctxInner, dialogConstraints) {
                final isCompact = dialogConstraints.maxWidth < 460;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 16 : 24),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF97316), width: 1.8),
                        ),
                        child: const Center(
                          child: Icon(Icons.access_time_rounded, color: Color(0xFFEA580C), size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work Log Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: ${item.date} • Submitted: ${item.submittedTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(ctx),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, size: 20, color: textMuted),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  const SizedBox(height: 18),

                  // Overview Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STATUS',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HOURS WORKED',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.formattedHours,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PROJECT / TASK',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.projectTask,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            if (item.startTime != null && item.endTime != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SHIFT TIME',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.startTime} - ${item.endTime}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Work Summary',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      item.description,
                      style: TextStyle(fontSize: 13, height: 1.5, color: textPrimary),
                    ),
                  ),

                  if (item.attachmentName.isNotEmpty && item.attachmentName != 'None') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Attachment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFFEA580C)),
                          const SizedBox(width: 8),
                          Text(
                            item.attachmentName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textMuted;

    final filteredLogs = widget.workLogs.where((log) {
      final matchesSearch = _searchQuery.isEmpty ||
          log.projectTask.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'All Statuses' ||
          log.status.toUpperCase() == _selectedStatusFilter.toUpperCase();

      return matchesSearch && matchesStatus;
    }).toList();

    final totalHoursToday = widget.workLogs
        .where((l) => l.date.toLowerCase().contains('today'))
        .fold(0.0, (sum, item) => sum + item.hours);

    final hoursTodayDisplay = totalHoursToday > 0
        ? _formatHoursMinutes(totalHoursToday)
        : '0 hrs';

    final totalHoursWeek = widget.workLogs.fold(0.0, (sum, item) => sum + item.hours);
    final weekHoursDisplay = totalHoursWeek > 0 ? '${totalHoursWeek.toStringAsFixed(0)} hrs' : '0 hrs';
    final avgHours = widget.workLogs.isNotEmpty
        ? (totalHoursWeek / widget.workLogs.length)
        : 0.0;

    final userName = widget.state?.userProfile.name ?? 'Daniel Paul';
    final userEmployeeId = widget.state?.userProfile.employeeId ?? 'IN-1001';
    final userRole = widget.state?.userProfile.role ?? 'INTERN';
    final userAvatar = widget.state?.userProfile.avatar;

    return Scaffold(
      drawer: widget.state != null ? AppDrawer(state: widget.state!, activeRoute: 'worklogs') : null,
      appBar: AppBar(
        leading: widget.state != null
            ? AppDropdownMenu(state: widget.state!)
            : const BackButton(),
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
              if (widget.state != null) {
                showSearch(
                  context: context,
                  delegate: AppQuickSearchDelegate(
                    state: widget.state!,
                    isDark: isDark,
                  ),
                );
              }
            },
            tooltip: 'Quick Search',
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onPressed: () {
              if (widget.state != null) {
                widget.state!.toggleTheme();
              }
            },
            tooltip: 'Toggle Theme',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {
                  if (widget.state != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnouncementsScreen(state: widget.state!),
                      ),
                    );
                  }
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner matching Website UI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.access_time_filled, color: Colors.orange, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Work Logs',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track your daily completed tasks, auto-fill working hours, and review submitted work logs.',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateWorkLogModal(context),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    "Create Today's Work Log",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPine,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Metrics Cards Row (5 Stat Cards matching website reference image)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('HOURS TODAY', hoursTodayDisplay, Colors.orange[800]!, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('THIS WEEK', weekHoursDisplay, Colors.orange[700]!, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('THIS MONTH', '0 hrs', Colors.blue[700]!, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('TASKS LOGGED', '${widget.workLogs.length} Tasks', Colors.purple[700]!, isDark),
                  const SizedBox(width: 10),
                  _buildStatCard('AVG HOURS / DAY', '${avgHours.toStringAsFixed(1)} hrs', Colors.teal[700]!, isDark),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search project, task, or description...',
                      hintStyle: TextStyle(color: textMuted),
                      prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFilter(
                          value: _selectedDateFilter,
                          items: const ['All Time', 'Today', 'This Week', 'This Month'],
                          onChanged: (v) => setState(() => _selectedDateFilter = v!),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdownFilter(
                          value: _selectedStatusFilter,
                          items: const ['All Statuses', 'APPROVED', 'PENDING', 'REJECTED'],
                          onChanged: (v) => setState(() => _selectedStatusFilter = v!),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Work Log Items List View
            if (filteredLogs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.find_in_page_outlined, size: 48, color: textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No work logs found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try changing your filters or create today\'s work log.',
                      style: TextStyle(fontSize: 12, color: textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLogs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = filteredLogs[index];
                  return _buildWorkLogCard(context, item, isDark);
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: widget.state == null,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _handleRefresh,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPine),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sync', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateWorkLogModal(context),
                      icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Submit Work Log",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.state != null)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderLight, width: 1),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: 1,
                onTap: (index) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  widget.state!.setTab(index);
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
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : const Color(0xFF1E293B)),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(color: isDark ? AppColors.textLight : const Color(0xFF1E293B))))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildWorkLogCard(BuildContext context, WorkLogEntry item, bool isDark) {
    Color statusBg;
    Color statusFg;
    if (item.status == 'APPROVED') {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF15803D);
    } else if (item.status == 'REJECTED') {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFB91C1C);
    } else if (item.status == 'DRAFT') {
      statusBg = const Color(0xFFFEF3C7);
      statusFg = const Color(0xFFB45309);
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusFg = const Color(0xFFB45309);
    }

    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : const Color(0xFF64748B);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showWorkLogDetailsModal(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.date,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusFg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.projectTask,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : const Color(0xFF475569)),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.primaryPine),
                    const SizedBox(width: 4),
                    Text(
                      item.formattedHours,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPine),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.attachment, size: 14, color: textMuted),
                    const SizedBox(width: 4),
                    Text(
                      item.attachmentName,
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ],
                ),
                Text(
                  item.submittedTime,
                  style: TextStyle(fontSize: 10, color: textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
