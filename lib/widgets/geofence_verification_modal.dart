import 'package:flutter/material.dart';

import '../services/geofence_service.dart';
import '../theme/app_colors.dart';

class GeofenceVerificationModal extends StatefulWidget {
  final Function(GeofenceResult result, bool isRemoteExemption)
  onConfirmClockIn;
  final String? userRole;
  final String? userName;
  final bool? isAdmin;
  final DateTime? currentTime;
  final bool? hasCompletedShiftToday;

  const GeofenceVerificationModal({
    super.key,
    required this.onConfirmClockIn,
    this.userRole,
    this.userName,
    this.isAdmin,
    this.currentTime,
    this.hasCompletedShiftToday,
  });

  @override
  State<GeofenceVerificationModal> createState() =>
      _GeofenceVerificationModalState();
}

class _GeofenceVerificationModalState extends State<GeofenceVerificationModal> {
  late GeofenceResult _currentResult;
  bool _isCheckingGPS = false;

  @override
  void initState() {
    super.initState();
    _currentResult = GeofenceService.getInitialState();
    _fetchLiveGPS();
  }

  void _fetchLiveGPS() async {
    setState(() => _isCheckingGPS = true);
    final result = await GeofenceService.getCurrentLiveLocation();
    if (mounted) {
      setState(() {
        _isCheckingGPS = false;
        _currentResult = result;
      });
    }
  }

  void _refreshGPS() {
    _fetchLiveGPS();
  }

  bool get _isEmployeeOrIntern {
    if (widget.isAdmin == true) return false;
    final role = (widget.userRole ?? '').trim().toUpperCase();
    if (role == 'ADMIN' || role == 'SUPER_ADMIN' || role == 'SUPERADMIN') {
      return false;
    }
    return true;
  }

  bool get _isIntern {
    return (widget.userRole ?? '').trim().toUpperCase() == 'INTERN';
  }

  DateTime get _effectiveNow => widget.currentTime ?? DateTime.now();

  bool get _isLateArrival {
    if (!_isEmployeeOrIntern) return false;
    final now = _effectiveNow;
    final cutoff = DateTime(now.year, now.month, now.day, 10, 0, 0);
    return now.isAfter(cutoff) && now.difference(cutoff).inMinutes >= 1;
  }

  String get _lateDurationFormatted {
    final now = _effectiveNow;
    final cutoff = DateTime(now.year, now.month, now.day, 10, 0, 0);
    final diff = now.difference(cutoff);
    final totalMinutes = diff.inMinutes;
    if (totalMinutes < 1) return '0 mins';

    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    if (hours > 0 && mins > 0) {
      return '$hours ${hours == 1 ? "hr" : "hrs"} $mins ${mins == 1 ? "min" : "mins"}';
    } else if (hours > 0) {
      return '$hours ${hours == 1 ? "hr" : "hrs"}';
    } else {
      return '$mins ${mins == 1 ? "min" : "mins"}';
    }
  }

  String _formatTime12h(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVerified = _currentResult.isWithinRadius;
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: EdgeInsets.all(isCompact ? 14 : 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Modal Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.vibrantEmerald.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified ? Icons.my_location : Icons.location_off,
                      color: isVerified
                          ? AppColors.vibrantEmerald
                          : Colors.orange[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geofence Location Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Strict 200m Office Perimeter Verification',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 16,
                      color: AppColors.primaryPine,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live GPS verification is required. Test locations are disabled.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Late Clock-In Notice (Only for Employee Side & Interns when clocking in after 10:00 AM)
              if (_isLateArrival) ...[
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('late_clock_in_notice_card'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B1D1D) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time_filled,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isIntern ? 'Intern Late Arrival' : 'Late Clock-In Notice',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$_lateDurationFormatted Late',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shift cutoff was 10:00 AM. You are logging in $_lateDurationFormatted late at ${_formatTime12h(_effectiveNow)}.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Geofence Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isVerified
                        ? AppColors.vibrantEmerald.withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.business,
                                size: 16,
                                color: AppColors.primaryPine,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  GeofenceService.officeName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPine.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Radius: 200m',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPine,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildCoordColumn(
                            'HQ Center',
                            '${_currentResult.officeLat.toStringAsFixed(4)}°, ${_currentResult.officeLng.toStringAsFixed(4)}°',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildCoordColumn(
                            'Your GPS',
                            '${_currentResult.userLat.toStringAsFixed(4)}°, ${_currentResult.userLng.toStringAsFixed(4)}°',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Distance',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_currentResult.distanceMeters.toInt()} meters',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isVerified
                                        ? AppColors.vibrantEmerald
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Status Verification Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified
                        ? AppColors.borderEmerald
                        : Colors.orange[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVerified
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: isVerified
                          ? AppColors.vibrantEmerald
                          : Colors.orange[800],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentResult.message,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isVerified
                              ? AppColors.primaryPine
                              : Colors.orange[900],
                        ),
                      ),
                    ),
                    if (_isCheckingGPS)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _refreshGPS,
                        tooltip: 'Refresh Location',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons
              if (isVerified)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.isAdmin != true && widget.hasCompletedShiftToday == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Shift completed for today. Employees and interns can only clock in and clock out once per day.',
                            ),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                        return;
                      }
                      widget.onConfirmClockIn(_currentResult, false);
                    },
                    icon: const Icon(Icons.verified, size: 18),
                    label: Text(
                      'Confirm Clock In (${_currentResult.distanceMeters.toInt()}m Verified)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final wifiResult = GeofenceService.verifyWifiLocation();
                          setState(() {
                            _currentResult = wifiResult;
                          });
                        },
                        icon: const Icon(Icons.wifi, size: 18),
                        label: const Text('Verify via Office Wi-Fi / IP Gateway'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPine,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (widget.isAdmin != true && widget.hasCompletedShiftToday == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Shift completed for today. Employees and interns can only clock in and clock out once per day.',
                                ),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }
                          widget.onConfirmClockIn(_currentResult, true);
                        },
                        icon: const Icon(
                          Icons.home_work,
                          size: 18,
                          color: AppColors.primaryPine,
                        ),
                        label: const Text(
                          'Request Remote Work Approval',
                          style: TextStyle(
                            color: AppColors.primaryPine,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryPine),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Remote work requires manager approval.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
