import 'dart:math';
import 'package:flutter/material.dart';

/// Tactile Split-Flap Clock Card matching the retro airport / mechanical split-flap aesthetic.
/// Features animated 3D tactile flipping cards for Hours, Minutes, and Seconds (orange-accented),
/// orange colon separators, AM/PM pill indicator, and formatted date subtitle.
class SplitFlapClock extends StatelessWidget {
  final DateTime currentTime;
  final bool isDark;

  const SplitFlapClock({
    super.key,
    required this.currentTime,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rawHour = currentTime.hour;
    final hour12 = rawHour % 12 == 0 ? 12 : rawHour % 12;
    final hoursStr = hour12.toString().padLeft(2, '0');
    final minutesStr = currentTime.minute.toString().padLeft(2, '0');
    final secondsStr = currentTime.second.toString().padLeft(2, '0');
    final isAm = rawHour < 12;

    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdayStr = weekdays[currentTime.weekday - 1];
    final monthStr = months[currentTime.month - 1];
    final dateString = '$weekdayStr • ${currentTime.day} $monthStr';

    // Clock container background is pure white or black depending on the theme
    final clockBg = isDark ? Colors.black : Colors.white;
    final borderCol = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: clockBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Row of split-flap cards, colons, and AM/PM badge
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SplitFlapCard(
                  key: const ValueKey('hours_card'),
                  value: hoursStr,
                  isSeconds: false,
                  isDark: isDark,
                ),
                _buildColon(),
                SplitFlapCard(
                  key: const ValueKey('minutes_card'),
                  value: minutesStr,
                  isSeconds: false,
                  isDark: isDark,
                ),
                _buildColon(),
                SplitFlapCard(
                  key: const ValueKey('seconds_card'),
                  value: secondsStr,
                  isSeconds: true,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildAmPmBadge(isAm, isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Date display: Wednesday • 28 October
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dateString,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColonDot(),
          SizedBox(height: 10),
          _ColonDot(),
        ],
      ),
    );
  }

  Widget _buildAmPmBadge(bool isAm, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AM badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: isAm ? const Color(0xFFEA580C) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            'AM',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: isAm
                  ? Colors.white
                  : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            ),
          ),
        ),
        const SizedBox(height: 3),
        // PM badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: !isAm ? const Color(0xFFEA580C) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            'PM',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: !isAm
                  ? Colors.white
                  : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            ),
          ),
        ),
      ],
    );
  }
}

/// A tactile card widget that realistically flips down along its horizontal central crease
/// with 3D perspective transform and realistic shading whenever [value] changes.
class SplitFlapCard extends StatefulWidget {
  final String value;
  final bool isSeconds;
  final bool isDark;

  const SplitFlapCard({
    super.key,
    required this.value,
    required this.isSeconds,
    required this.isDark,
  });

  @override
  State<SplitFlapCard> createState() => _SplitFlapCardState();
}

class _SplitFlapCardState extends State<SplitFlapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late String _currentValue;
  late String _previousValue;

  static const double cardWidth = 52.0;
  static const double cardHeight = 58.0;
  static const double halfHeight = cardHeight / 2; // 29.0

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _previousValue = _currentValue;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SplitFlapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _currentValue = widget.value;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;
        final isAnimating = _controller.isAnimating;

        // Top base shows the incoming value; bottom base shows outgoing value during flip
        final baseTopValue = _currentValue;
        final baseBottomValue = isAnimating ? _previousValue : _currentValue;

        return Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Static base background cards
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopHalf(baseTopValue),
                  _buildBottomHalf(baseBottomValue),
                ],
              ),

              // 2. Dynamic 3D mechanical flip animation
              if (isAnimating) ...[
                if (progress < 0.5) ...[
                  // Phase 1 (0 -> 90 degrees): Upper flap folds forward & down towards viewer
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: halfHeight,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0025)
                        ..rotateX((progress / 0.5) * (pi / 2)),
                      child: Stack(
                        children: [
                          _buildTopHalf(_previousValue),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: ((progress / 0.5) * 0.45).clamp(0.0, 0.5),
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Subtle cast shadow on bottom half as upper flap drops
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: halfHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: ((progress / 0.5) * 0.2).clamp(0.0, 0.25),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(9),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Phase 2 (90 -> 0 degrees): Lower flap swings down into position
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: halfHeight,
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0025)
                        ..rotateX(-(1.0 - (progress - 0.5) / 0.5) * (pi / 2)),
                      child: Stack(
                        children: [
                          _buildBottomHalf(_currentValue),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: ((1.0 - (progress - 0.5) / 0.5) * 0.45).clamp(0.0, 0.5),
                              ),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],

          // 3. Central horizontal split crease
          Positioned(
            left: 0,
            right: 0,
            top: halfHeight - 0.75,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF0B0F17)
                    : const Color(0xFFCBD5E1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isDark ? 0.35 : 0.08,
                    ),
                    blurRadius: 1,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
            ),
          ),

          // 4. Left mechanical notch
          Positioned(
            left: -1,
            top: halfHeight - 1.75,
            child: Container(
              width: 2.5,
              height: 3.5,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(2),
                ),
              ),
            ),
          ),

          // 5. Right mechanical notch
          Positioned(
            right: -1,
            top: halfHeight - 1.75,
            child: Container(
              width: 2.5,
              height: 3.5,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
);
}

  Widget _buildTopHalf(String text) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
      child: SizedBox(
        width: cardWidth,
        height: halfHeight,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.5,
          child: _buildFullFace(text),
        ),
      ),
    );
  }

  Widget _buildBottomHalf(String text) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
      child: SizedBox(
        width: cardWidth,
        height: halfHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 0.5,
          child: _buildFullFace(text),
        ),
      ),
    );
  }

  Widget _buildFullFace(String text) {
    final cardBg = widget.isDark ? const Color(0xFF1B2333) : const Color(0xFFF1F5F9);
    final textColor = widget.isSeconds
        ? const Color(0xFFEA580C)
        : (widget.isDark ? Colors.white : const Color(0xFF0F172A));

    final borderColor = widget.isSeconds
        ? const Color(0xFFEA580C).withValues(alpha: widget.isDark ? 0.65 : 0.75)
        : (widget.isDark
            ? const Color(0xFF334155).withValues(alpha: 0.6)
            : const Color(0xFFCBD5E1));

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: borderColor,
          width: widget.isSeconds ? 1.4 : 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          color: textColor,
          letterSpacing: -0.5,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ColonDot extends StatelessWidget {
  const _ColonDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFFEA580C),
        shape: BoxShape.circle,
      ),
    );
  }
}
