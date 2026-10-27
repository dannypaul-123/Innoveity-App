import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';

class TaskVelocityChartCard extends StatelessWidget {
  final List<TaskItem> tasks;
  final bool isDark;

  const TaskVelocityChartCard({
    super.key,
    required this.tasks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalTasks = tasks.length;

    final pendingCount = tasks.where((t) {
      final s = t.status.toLowerCase().trim();
      return s == 'pending';
    }).length;

    final inProgressCount = tasks.where((t) {
      final s = t.status.toLowerCase().trim();
      return s == 'in progress' || s == 'inprogress';
    }).length;

    final reviewCount = tasks.where((t) {
      final s = t.status.toLowerCase().trim();
      return s.contains('review') || s.contains('waiting');
    }).length;

    final approvedCount = tasks.where((t) {
      final s = t.status.toLowerCase().trim();
      return s == 'approved' || s == 'completed';
    }).length;

    final rejectedCount = tasks.where((t) {
      final s = t.status.toLowerCase().trim();
      return s == 'rejected';
    }).length;

    final completionPercentage = totalTasks > 0
        ? ((approvedCount / totalTasks) * 100).round()
        : 0;

    final badgeText = '$approvedCount completed ($completionPercentage%)';

    final categories = [
      _TaskVelocityCategory('Pending', pendingCount),
      _TaskVelocityCategory('In Progress', inProgressCount),
      _TaskVelocityCategory('Review', reviewCount),
      _TaskVelocityCategory('Approved', approvedCount),
      _TaskVelocityCategory('Rejected', rejectedCount),
    ];

    int maxCount = 0;
    for (final c in categories) {
      if (c.count > maxCount) maxCount = c.count;
    }

    // Default to at least 4 ticks matching the web dashboard layout
    final int maxY = maxCount <= 4 ? 4 : ((maxCount + 3) ~/ 4) * 4;
    final yTicks = [
      maxY,
      (maxY * 0.75).round(),
      (maxY * 0.50).round(),
      (maxY * 0.25).round(),
      0,
    ];

    const chartHeight = 170.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderCardDark : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title with Trending Icon
          Row(
            children: [
              Text(
                'Task Velocity & Deliverables',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.trending_up_rounded,
                size: 19,
                color: Color(0xFFEA580C),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Tasks Count + Completed Percentage Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalTasks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textLightMuted : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF431407).withValues(alpha: 0.45)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFEA580C).withValues(alpha: 0.45)
                        : const Color(0xFFFED7AA),
                    width: 1,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Bar Chart with Y-Axis and Dotted Gridlines
          SizedBox(
            height: chartHeight + 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Y-Axis Labels
                SizedBox(
                  width: 20,
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: yTicks.map((tick) {
                      return Text(
                        '$tick',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),

                // Chart Canvas Area
                Expanded(
                  child: Column(
                    children: [
                      // Gridlines & Bars Stack
                      SizedBox(
                        height: chartHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 5 Dotted Gridlines (Matching each Y tick)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(yTicks.length, (idx) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 1,
                                  child: CustomPaint(
                                    painter: _ChartDashedLinePainter(
                                      isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            // 5 Category Bars Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: categories.map((cat) {
                                final barHeightFraction = maxY > 0
                                    ? (cat.count / maxY).clamp(0.0, 1.0)
                                    : 0.0;
                                final targetBarHeight =
                                    barHeightFraction * (chartHeight - 14);

                                return Expanded(
                                  child: Tooltip(
                                    message: '${cat.status}: ${cat.count} Tasks',
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (cat.count > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                '${cat.count}',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFFEA580C),
                                                ),
                                              ),
                                            ),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(
                                              begin: 0.0,
                                              end: targetBarHeight,
                                            ),
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, animatedHeight, child) {
                                              return Container(
                                                width: 38,
                                                height: animatedHeight > 0
                                                    ? animatedHeight
                                                    : 0,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFEA580C),
                                                  borderRadius: BorderRadius.vertical(
                                                    top: Radius.circular(6),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // X-Axis Category Status Labels
                      Row(
                        children: categories.map((cat) {
                          return Expanded(
                            child: Text(
                              cat.status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textLightMuted
                                    : const Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskVelocityCategory {
  final String status;
  final int count;
  const _TaskVelocityCategory(this.status, this.count);
}

class _ChartDashedLinePainter extends CustomPainter {
  final Color color;
  const _ChartDashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ChartDashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
