import 'package:flutter/material.dart';

/// Tactile Split-Flap Clock Card matching the retro airport / mechanical split-flap aesthetic.
/// Features tactile cards for Hours, Minutes, and Seconds (orange-accented),
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

    // The background of the clock is white or black depending on the theme
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
                _buildFlapCard(
                  value: hoursStr,
                  isSeconds: false,
                  isDark: isDark,
                ),
                _buildColon(),
                _buildFlapCard(
                  value: minutesStr,
                  isSeconds: false,
                  isDark: isDark,
                ),
                _buildColon(),
                _buildFlapCard(
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

  Widget _buildFlapCard({
    required String value,
    required bool isSeconds,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF1B2333) : const Color(0xFFF1F5F9);
    final textColor = isSeconds
        ? const Color(0xFFEA580C)
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    final borderColor = isSeconds
        ? const Color(0xFFEA580C).withValues(alpha: isDark ? 0.65 : 0.75)
        : (isDark
            ? const Color(0xFF334155).withValues(alpha: 0.6)
            : const Color(0xFFCBD5E1));

    const cardWidth = 52.0;
    const cardHeight = 56.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor, width: isSeconds ? 1.4 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Digit text
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: textColor,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ),

          // Horizontal split hinge crease
          Positioned(
            left: 0,
            right: 0,
            top: (cardHeight / 2) - 0.75,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0B0F17)
                    : const Color(0xFFCBD5E1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 1,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
            ),
          ),

          // Left notch indent
          Positioned(
            left: -1,
            top: (cardHeight / 2) - 1.75,
            child: Container(
              width: 2.5,
              height: 3.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
              ),
            ),
          ),

          // Right notch indent
          Positioned(
            right: -1,
            top: (cardHeight / 2) - 1.75,
            child: Container(
              width: 2.5,
              height: 3.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
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
