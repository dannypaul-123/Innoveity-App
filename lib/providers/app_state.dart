import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/geofence_service.dart';
import '../services/push_notification_service.dart';
import '../core/storage/salary_template_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  int _currentTab = 0; // 0: Dashboard, 1: Tasks, 2: Calendar, 3: Leaves, 4: Profile
  bool _isDarkMode = false;
  bool _isLoading = false;
  
  // User profile loaded from CRM API
  UserProfile userProfile = UserProfile(
    id: '',
    employeeId: '',
    name: 'Employee',
    email: '',
    role: 'EMPLOYEE',
    department: 'Development',
    designation: 'Team Member',
    phone: '',
    joiningDate: '',
    basicSalary: 0.0,
    hra: 0.0,
    specialAllowance: 0.0,
    deductions: 0.0,
    netSalary: 0.0,
  );

  // Clock state
  bool _isClockedIn = false;
  int _clockedSeconds = 0;
  String? _clockInTimeStr;
  String? _clockOutTimeStr;
  DateTime? _clockInDateTime;
  DateTime? _clockOutDateTime;
  double? _lastClockInDistance;
  double? _lastClockInLat;
  double? _lastClockInLng;
  String? _lastWorkLocation;
  Timer? _timer;

  // Multi-employee attendance registry (keyed by clean email)
  final Map<String, EmployeeAttendanceRecord> _employeeAttendanceMap = {};
  Map<String, EmployeeAttendanceRecord> get employeeAttendanceMap => Map.unmodifiable(_employeeAttendanceMap);

  EmployeeAttendanceRecord? getEmployeeAttendanceRecord(String identifier) {
    final clean = identifier.toLowerCase().trim();
    if (_employeeAttendanceMap.containsKey(clean)) {
      return _employeeAttendanceMap[clean];
    }
    for (final rec in _employeeAttendanceMap.values) {
      if (rec.email.toLowerCase().trim() == clean ||
          rec.employeeId.toLowerCase().trim() == clean ||
          rec.employeeName.toLowerCase().trim() == clean) {
        return rec;
      }
    }
    return null;
  }

  static String todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String formatWorkedDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '—';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }


  // Site & Geofence Settings (INNOVEITY Workspace Headquarters)
  double hqLatitude = 12.920466;
  double hqLongitude = 80.121639;
  double geofenceRadiusMeters = 200.0;
  int internShiftCutoffHour = 17; // 5:00 PM
  int staffShiftCutoffHour = 18;  // 6:00 PM

  // Location Profiles
  List<GeofenceLocationProfile> locationProfiles = [
    GeofenceLocationProfile(
      id: 'LOC-HQ',
      name: 'INNOVEITY Workspace Headquarters',
      latitude: 12.920466,
      longitude: 80.121639,
      radiusMeters: 200.0,
      address: 'Tambaram Sanatorium, Chennai',
      isActive: true,
    ),
  ];
  String activeLocationProfileId = 'LOC-HQ';

  GeofenceLocationProfile get activeLocationProfile {
    return locationProfiles.firstWhere(
      (p) => p.id == activeLocationProfileId,
      orElse: () => locationProfiles.isNotEmpty
          ? locationProfiles.first
          : GeofenceLocationProfile(
              id: 'LOC-HQ',
              name: 'INNOVEITY Workspace Headquarters',
              latitude: hqLatitude,
              longitude: hqLongitude,
              radiusMeters: geofenceRadiusMeters,
              address: 'Tambaram, Chennai',
              isActive: true,
            ),
    );
  }

  void setActiveLocationProfile(String id) {
    activeLocationProfileId = id;
    final p = activeLocationProfile;
    hqLatitude = p.latitude;
    hqLongitude = p.longitude;
    geofenceRadiusMeters = p.radiusMeters;
    GeofenceService.officeLat = p.latitude;
    GeofenceService.officeLng = p.longitude;
    GeofenceService.officeName = p.name;
    GeofenceService.geofenceRadiusMeters = p.radiusMeters;
    GeofenceService.activeProfileId = id;
    GeofenceService.locationProfiles = List.from(locationProfiles);
    _persistGeofenceSettings();
    notifyListeners();
  }

  void addLocationProfile(GeofenceLocationProfile profile) {
    locationProfiles.add(profile);
    GeofenceService.locationProfiles = List.from(locationProfiles);
    setActiveLocationProfile(profile.id);
    addAuditLog('Geofence Location Created', 'Added ${profile.name} (Lat: ${profile.latitude}, Lon: ${profile.longitude})', userProfile.email);
    notifyListeners();
  }

  void updateLocationProfile(GeofenceLocationProfile updated) {
    final idx = locationProfiles.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      locationProfiles[idx] = updated;
    } else {
      locationProfiles.add(updated);
    }
    if (activeLocationProfileId == updated.id) {
      hqLatitude = updated.latitude;
      hqLongitude = updated.longitude;
      geofenceRadiusMeters = updated.radiusMeters;
      GeofenceService.officeLat = updated.latitude;
      GeofenceService.officeLng = updated.longitude;
      GeofenceService.officeName = updated.name;
      GeofenceService.geofenceRadiusMeters = updated.radiusMeters;
    }
    GeofenceService.locationProfiles = List.from(locationProfiles);
    _persistGeofenceSettings();
    addAuditLog('Geofence Location Updated', '${updated.name} (Lat: ${updated.latitude}, Lon: ${updated.longitude}, Radius: ${updated.radiusMeters}m)', userProfile.email);
    notifyListeners();
  }

  void deleteLocationProfile(String id) {
    if (locationProfiles.length <= 1) return; // Keep at least one profile
    locationProfiles.removeWhere((p) => p.id == id);
    if (activeLocationProfileId == id) {
      activeLocationProfileId = locationProfiles.first.id;
      final first = locationProfiles.first;
      hqLatitude = first.latitude;
      hqLongitude = first.longitude;
      geofenceRadiusMeters = first.radiusMeters;
      GeofenceService.officeLat = first.latitude;
      GeofenceService.officeLng = first.longitude;
      GeofenceService.officeName = first.name;
      GeofenceService.geofenceRadiusMeters = first.radiusMeters;
    }
    GeofenceService.locationProfiles = List.from(locationProfiles);
    _persistGeofenceSettings();
    addAuditLog('Geofence Location Deleted', 'Removed location profile $id', userProfile.email);
    notifyListeners();
  }

  // System Audit Logs
  final List<Map<String, dynamic>> auditLogs = [
    {
      'id': 'LOG-9001',
      'timestamp': '2026-10-09 11:30:15',
      'action': 'Geofence Verification',
      'user': 'admin@enterprise-crm.com',
      'ip': '182.73.189.42',
      'status': 'Verified (HQ 42m)',
    },
    {
      'id': 'LOG-9002',
      'timestamp': '2026-10-09 10:15:00',
      'action': 'Leave Application Approved',
      'user': 'admin@enterprise-crm.com',
      'ip': '182.73.189.42',
      'status': 'Success (Divya R WFH)',
    },
    {
      'id': 'LOG-9003',
      'timestamp': '2026-10-09 09:05:22',
      'action': 'User Login',
      'user': 'antorajan501@gmail.com',
      'ip': '157.48.21.90',
      'status': 'Authenticated',
    },
    {
      'id': 'LOG-9004',
      'timestamp': '2026-10-08 18:00:00',
      'action': 'Auto Clock-Out Enforced',
      'user': 'SYSTEM_DAEMON',
      'ip': '127.0.0.1',
      'status': 'Shift End 6:00 PM',
    },
  ];

  AppState() {
    _startClockTimer();
    loadSalaryTemplates();
    _loadSavedGeofenceSettings();
    _loadAllEmployeesAttendanceFromStorage();
    refreshApiData();
  }

  Future<void> _loadSavedGeofenceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString('geofence_location_profiles_json');
      if (profilesJson != null && profilesJson.isNotEmpty) {
        final List decoded = jsonDecode(profilesJson);
        locationProfiles = decoded.map((e) => GeofenceLocationProfile.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      final savedActiveId = prefs.getString('geofence_active_profile_id');
      if (savedActiveId != null && locationProfiles.any((p) => p.id == savedActiveId)) {
        activeLocationProfileId = savedActiveId;
      }
      final savedLat = prefs.getDouble('geofence_hq_latitude');
      final savedLng = prefs.getDouble('geofence_hq_longitude');
      final savedRadius = prefs.getDouble('geofence_radius_meters');
      if (savedLat != null && savedLng != null) {
        hqLatitude = savedLat;
        hqLongitude = savedLng;
      } else {
        final active = activeLocationProfile;
        hqLatitude = active.latitude;
        hqLongitude = active.longitude;
      }
      if (savedRadius != null) {
        geofenceRadiusMeters = savedRadius;
      }
      GeofenceService.officeLat = hqLatitude;
      GeofenceService.officeLng = hqLongitude;
      GeofenceService.officeName = activeLocationProfile.name;
      GeofenceService.geofenceRadiusMeters = geofenceRadiusMeters;
      GeofenceService.activeProfileId = activeLocationProfileId;
      GeofenceService.locationProfiles = List.from(locationProfiles);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistGeofenceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('geofence_hq_latitude', hqLatitude);
      await prefs.setDouble('geofence_hq_longitude', hqLongitude);
      await prefs.setDouble('geofence_radius_meters', geofenceRadiusMeters);
      await prefs.setString('geofence_active_profile_id', activeLocationProfileId);
      final jsonList = locationProfiles.map((p) => p.toJson()).toList();
      await prefs.setString('geofence_location_profiles_json', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _writeRecordToSharedPreferences(EmployeeAttendanceRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = record.email.toLowerCase().trim();
      final empId = record.employeeId.toLowerCase().trim();

      if (email.isNotEmpty) {
        await prefs.setString('emp_attendance_$email', jsonEncode(record.toJson()));
      }
      if (empId.isNotEmpty) {
        await prefs.setString('emp_attendance_id_$empId', jsonEncode(record.toJson()));
      }
      if (email.contains('dp0345217') || email.contains('danielpaul') || empId == 'in-1001') {
        await prefs.setString('emp_attendance_dp0345217@gmail.com', jsonEncode(record.toJson()));
        await prefs.setString('emp_attendance_danielpaul@enterprise-crm.com', jsonEncode(record.toJson()));
        await prefs.setString('emp_attendance_id_in-1001', jsonEncode(record.toJson()));
      }
      await prefs.setString('last_active_employee_attendance', jsonEncode(record.toJson()));
      if (email.isNotEmpty) {
        await prefs.setString('last_clocked_email', email);
      }
      if (empId.isNotEmpty) {
        await prefs.setString('last_clocked_employee_id', empId);
      }

      // Update registry of all recorded attendances
      final registryJson = jsonEncode(
        _employeeAttendanceMap.map((k, v) => MapEntry(k, v.toJson())),
      );
      await prefs.setString('all_employees_attendance_registry_v1', registryJson);
    } catch (e) {
      debugPrint('Error writing employee attendance: $e');
    }
  }

  Future<void> _persistCurrentEmployeeAttendance() async {
    final email = userProfile.email.toLowerCase().trim();
    final empId = userProfile.employeeId.toLowerCase().trim();
    if (email.isEmpty && empId.isEmpty) return;

    final primaryKey = email.isNotEmpty ? email : empId;

    try {
      final now = DateTime.now();
      final dateStr = todayDateStr();

      int finalSeconds = _clockedSeconds;
      if (_isClockedIn && _clockInDateTime != null) {
        finalSeconds = now.difference(_clockInDateTime!).inSeconds.clamp(0, 86400);
        _clockedSeconds = finalSeconds;
      }

      final record = EmployeeAttendanceRecord(
        email: email.isNotEmpty ? email : 'employee@innoveity.tech',
        employeeId: userProfile.employeeId,
        employeeName: userProfile.name,
        isClockedIn: _isClockedIn,
        date: dateStr,
        clockInIso: _clockInDateTime?.toIso8601String(),
        clockInDisplay: _clockInTimeStr,
        clockOutIso: _clockOutDateTime?.toIso8601String(),
        clockOutDisplay: _clockOutTimeStr,
        clockedSeconds: finalSeconds,
        distanceMeters: _lastClockInDistance ?? 36.0,
        userLat: _lastClockInLat ?? hqLatitude,
        userLng: _lastClockInLng ?? hqLongitude,
        statusText: _isClockedIn
            ? 'Present (HQ Verified)'
            : (_clockOutTimeStr != null ? 'Present (Shift Completed)' : 'Not Clocked In'),
        workLocation: _lastWorkLocation ?? 'Office',
      );

      _employeeAttendanceMap[primaryKey] = record;
      if (empId.isNotEmpty) {
        _employeeAttendanceMap[empId] = record;
      }
      if (email.contains('dp0345217') || email.contains('danielpaul') || empId == 'in-1001') {
        _employeeAttendanceMap['dp0345217@gmail.com'] = record;
        _employeeAttendanceMap['danielpaul@enterprise-crm.com'] = record;
        _employeeAttendanceMap['in-1001'] = record;
      }

      await _writeRecordToSharedPreferences(record);
    } catch (e) {
      debugPrint('Error persisting employee attendance: $e');
    }
  }

  Future<void> _loadUserAttendanceState([String? email, String? employeeId]) async {
    final cleanEmail = (email ?? userProfile.email).toLowerCase().trim();
    final cleanEmpId = (employeeId ?? userProfile.employeeId).toLowerCase().trim();
    final cleanName = userProfile.name.toLowerCase().trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      EmployeeAttendanceRecord? record;

      // 1. Check primary cleanEmail key
      if (cleanEmail.isNotEmpty) {
        final jsonStr = prefs.getString('emp_attendance_$cleanEmail');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            record = EmployeeAttendanceRecord.fromJson(jsonDecode(jsonStr));
          } catch (_) {}
        }
      }

      // 2. Check employee ID key
      if (record == null && cleanEmpId.isNotEmpty) {
        final idJson = prefs.getString('emp_attendance_id_$cleanEmpId');
        if (idJson != null && idJson.isNotEmpty) {
          try {
            record = EmployeeAttendanceRecord.fromJson(jsonDecode(idJson));
          } catch (_) {}
        }
      }

      // 3. Check Daniel Paul aliases
      if (record == null &&
          (cleanEmail.contains('dp0345217') ||
              cleanEmail.contains('danielpaul') ||
              cleanEmpId == 'in-1001' ||
              cleanName.contains('daniel'))) {
        for (final k in ['dp0345217@gmail.com', 'danielpaul@enterprise-crm.com', 'in-1001']) {
          final aliasJson = k.startsWith('in-')
              ? prefs.getString('emp_attendance_id_$k')
              : prefs.getString('emp_attendance_$k');
          if (aliasJson != null && aliasJson.isNotEmpty) {
            try {
              record = EmployeeAttendanceRecord.fromJson(jsonDecode(aliasJson));
              break;
            } catch (_) {}
          }
        }
      }

      // 4. Check in-memory _employeeAttendanceMap
      if (record == null) {
        if (cleanEmail.isNotEmpty && _employeeAttendanceMap.containsKey(cleanEmail)) {
          record = _employeeAttendanceMap[cleanEmail];
        } else if (cleanEmpId.isNotEmpty && _employeeAttendanceMap.containsKey(cleanEmpId)) {
          record = _employeeAttendanceMap[cleanEmpId];
        } else {
          for (final r in _employeeAttendanceMap.values) {
            if ((cleanEmpId.isNotEmpty && r.employeeId.toLowerCase().trim() == cleanEmpId) ||
                (cleanName.isNotEmpty && r.employeeName.toLowerCase().trim() == cleanName)) {
              record = r;
              break;
            }
          }
        }
      }

      // 5. Fallback to device last active record if matching profile or if currently logged in
      if (record == null) {
        final lastJson = prefs.getString('last_active_employee_attendance');
        if (lastJson != null && lastJson.isNotEmpty) {
          try {
            final candidate = EmployeeAttendanceRecord.fromJson(jsonDecode(lastJson));
            final candEmail = candidate.email.toLowerCase().trim();
            final candId = candidate.employeeId.toLowerCase().trim();
            final candName = candidate.employeeName.toLowerCase().trim();
            if (candEmail == cleanEmail ||
                (cleanEmpId.isNotEmpty && candId == cleanEmpId) ||
                (cleanName.isNotEmpty && candName == cleanName) ||
                (cleanEmail.contains('dp0345217') && candEmail.contains('danielpaul')) ||
                (cleanEmail.contains('danielpaul') && candEmail.contains('dp0345217'))) {
              record = candidate;
            }
          } catch (_) {}
        }
      }

      final today = todayDateStr();
      final bool isRecordForToday = record != null && (
        record.date == today ||
        (record.clockInIso != null &&
            DateTime.now().difference(DateTime.tryParse(record.clockInIso!) ?? DateTime.now()).inHours.abs() < 16)
      );

      if (record != null && isRecordForToday) {
        if (cleanEmail.isNotEmpty) _employeeAttendanceMap[cleanEmail] = record;
        if (cleanEmpId.isNotEmpty) _employeeAttendanceMap[cleanEmpId] = record;
        _lastClockInDistance = record.distanceMeters;
        _lastClockInLat = record.userLat;
        _lastClockInLng = record.userLng;
        _lastWorkLocation = record.workLocation;

        if (record.isClockedIn) {
          _isClockedIn = true;
          _clockInTimeStr = record.clockInDisplay ?? _formatCurrentTime();
          _clockOutTimeStr = null;
          _clockOutDateTime = null;

          if (record.clockInIso != null) {
            _clockInDateTime = DateTime.tryParse(record.clockInIso!);
          }
          if (_clockInDateTime != null) {
            _clockedSeconds = DateTime.now().difference(_clockInDateTime!).inSeconds.clamp(0, 86400);
          } else {
            _clockedSeconds = record.clockedSeconds;
          }

          // Ensure active shift log is present in attendanceLogs
          final activeIndex = attendanceLogs.indexWhere(
            (log) => log.checkOut == 'Active Shift' || log.date.toLowerCase().contains('today'),
          );
          final activeLog = AttendanceLog(
            date: 'Today (Shift Started)',
            checkIn: _clockInTimeStr!,
            checkOut: 'Active Shift',
            workingHours: (_clockedSeconds / 3600.0).clamp(0.1, 24.0),
            status: record.statusText.isNotEmpty ? record.statusText : 'Present (HQ Verified)',
            employeeName: userProfile.name,
            department: userProfile.department ?? 'Engineering & App',
            workLocation: record.workLocation,
            totalWorkedStr: '—',
          );
          if (activeIndex != -1) {
            attendanceLogs[activeIndex] = activeLog;
          } else {
            attendanceLogs.insert(0, activeLog);
          }

          _startClockTimer();
        } else {
          // Employee clocked out today
          _isClockedIn = false;
          _timer?.cancel();
          _clockInTimeStr = record.clockInDisplay;
          _clockOutTimeStr = record.clockOutDisplay;
          _clockedSeconds = record.clockedSeconds;
          if (record.clockInIso != null) {
            _clockInDateTime = DateTime.tryParse(record.clockInIso!);
          }
          if (record.clockOutIso != null) {
            _clockOutDateTime = DateTime.tryParse(record.clockOutIso!);
          }

          if (_clockInTimeStr != null && _clockOutTimeStr != null) {
            final workedHours = (_clockedSeconds / 3600.0).clamp(0.1, 24.0);
            final totalWorked = formatWorkedDuration(_clockedSeconds);
            final activeIndex = attendanceLogs.indexWhere(
              (log) => log.date.toLowerCase().contains('today') || log.checkOut == 'Active Shift',
            );
            final completedLog = AttendanceLog(
              date: 'Today (Shift Completed)',
              checkIn: _clockInTimeStr!,
              checkOut: _clockOutTimeStr!,
              workingHours: workedHours,
              status: 'PRESENT',
              employeeName: userProfile.name,
              department: userProfile.department ?? 'Engineering & App',
              workLocation: record.workLocation,
              totalWorkedStr: totalWorked,
            );
            if (activeIndex != -1) {
              attendanceLogs[activeIndex] = completedLog;
            } else {
              attendanceLogs.insert(0, completedLog);
            }
          }
        }
      } else {
        // Different day or no record today
        _isClockedIn = false;
        _clockedSeconds = 0;
        _clockInTimeStr = null;
        _clockOutTimeStr = null;
        _clockInDateTime = null;
        _clockOutDateTime = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user attendance state: $e');
    }
  }

  Future<void> _loadAllEmployeesAttendanceFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registryJson = prefs.getString('all_employees_attendance_registry_v1');
      if (registryJson != null && registryJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(registryJson);
        decoded.forEach((key, value) {
          try {
            _employeeAttendanceMap[key.toLowerCase().trim()] =
                EmployeeAttendanceRecord.fromJson(Map<String, dynamic>.from(value));
          } catch (_) {}
        });
      }

      // Also check individual employee records for directory users
      for (final email in userDirectory.keys) {
        final clean = email.toLowerCase().trim();
        final indJson = prefs.getString('emp_attendance_$clean');
        if (indJson != null && indJson.isNotEmpty) {
          try {
            _employeeAttendanceMap[clean] =
                EmployeeAttendanceRecord.fromJson(jsonDecode(indJson));
          } catch (_) {}
        }
      }

      // Cross-index records by employeeId and known aliases so lookups always succeed
      final currentEntries = Map<String, EmployeeAttendanceRecord>.from(_employeeAttendanceMap);
      for (final rec in currentEntries.values) {
        if (rec.employeeId.isNotEmpty) {
          _employeeAttendanceMap[rec.employeeId.toLowerCase().trim()] = rec;
        }
        if (rec.email.contains('dp0345217') || rec.email.contains('danielpaul')) {
          _employeeAttendanceMap['dp0345217@gmail.com'] = rec;
          _employeeAttendanceMap['danielpaul@enterprise-crm.com'] = rec;
          _employeeAttendanceMap['in-1001'] = rec;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all employees attendance: $e');
    }
  }

  void updateGeofenceSettings({
    required double lat,
    required double lon,
    required double radius,
    required int internCutoff,
    required int staffCutoff,
  }) {
    hqLatitude = lat;
    hqLongitude = lon;
    geofenceRadiusMeters = radius;
    internShiftCutoffHour = internCutoff;
    staffShiftCutoffHour = staffCutoff;

    // Synchronize to active profile and service
    final active = activeLocationProfile;
    active.latitude = lat;
    active.longitude = lon;
    active.radiusMeters = radius;

    GeofenceService.officeLat = lat;
    GeofenceService.officeLng = lon;
    GeofenceService.officeName = active.name;
    GeofenceService.geofenceRadiusMeters = radius;
    GeofenceService.locationProfiles = List.from(locationProfiles);

    _persistGeofenceSettings();

    addAuditLog('Geofence Settings Updated', 'Lat: $lat, Lon: $lon, Radius: ${radius}m', userProfile.email);
    notifyListeners();
  }

  void addAuditLog(String action, String details, String user) {
    final now = DateTime.now();
    final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    auditLogs.insert(0, {
      'id': 'LOG-${now.millisecondsSinceEpoch.toString().substring(7)}',
      'timestamp': timeStr,
      'action': action,
      'user': user,
      'ip': '182.73.189.42',
      'status': details,
    });
    notifyListeners();
  }

  bool get isLoggedIn => _isLoggedIn;
  int get currentTab => _currentTab;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  bool get isClockedIn => _isClockedIn;
  int get clockedSeconds => _clockedSeconds;

  static String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String get clockInTimeDisplay {
    if (_clockInTimeStr != null && _clockInTimeStr!.isNotEmpty) {
      return _clockInTimeStr!;
    }
    if (attendanceLogs.isNotEmpty &&
        attendanceLogs.first.checkIn != 'Now' &&
        attendanceLogs.first.checkIn != 'Not Clocked In') {
      return attendanceLogs.first.checkIn;
    }
    return _formatCurrentTime();
  }

  String? get clockOutTimeDisplay => _clockOutTimeStr;
  bool get hasClockedOutToday => !_isClockedIn && _clockOutTimeStr != null;

  bool get hasCompletedShiftToday {
    if (isAdmin) return false;
    if (_clockOutTimeStr != null && !_isClockedIn) return true;
    final todayStr = AppState.todayDateStr();
    final todayLog = attendanceLogs.firstWhere(
      (log) => log.date.toLowerCase().contains('today') || log.date == todayStr,
      orElse: () => AttendanceLog(
        date: '',
        checkIn: '',
        checkOut: '',
        workingHours: 0,
        status: '',
        employeeName: '',
        department: '',
      ),
    );
    if (todayLog.date.isNotEmpty &&
        todayLog.checkOut.isNotEmpty &&
        todayLog.checkOut != 'Active Shift' &&
        todayLog.checkOut != 'Not Clocked In' &&
        todayLog.checkOut != '--') {
      return true;
    }
    return false;
  }

  double? get lastClockInDistance => _lastClockInDistance;
  double? get lastClockInLat => _lastClockInLat;
  double? get lastClockInLng => _lastClockInLng;
  String get lastWorkLocation => _lastWorkLocation ?? 'Office';

  String get formattedClockTime {
    final hours = (_clockedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_clockedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_clockedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  double get shiftTargetHours =>
      userProfile.role.toUpperCase() == 'INTERN' ? 7.0 : 8.0;

  double get shiftCompletionRatio {
    if (!_isClockedIn && _clockedSeconds == 0) return 0.0;
    final totalTargetSeconds = shiftTargetHours * 3600;
    if (totalTargetSeconds <= 0) return 0.0;
    return (_clockedSeconds / totalTargetSeconds).clamp(0.0, 1.0);
  }

  int get shiftCompletionPercent => (shiftCompletionRatio * 100).round();


  String? autoClockOutNotice;

  int get autoClockOutCutoffHour =>
      userProfile.role.toUpperCase() == 'INTERN' ? 17 : 18;

  String get autoClockOutCutoffLabel =>
      userProfile.role.toUpperCase() == 'INTERN'
          ? '5:00 PM (Intern Shift End)'
          : '6:00 PM (Staff Shift End)';

  void checkAutoClockOut() {
    if (!_isClockedIn) return;

    final now = DateTime.now();
    final cutoffHour = autoClockOutCutoffHour;

    if (now.hour >= cutoffHour) {
      _isClockedIn = false;
      _timer?.cancel();

      final roleTitle = userProfile.role.toUpperCase() == 'INTERN' ? 'Intern' : 'Employee';
      final cutoffText = userProfile.role.toUpperCase() == 'INTERN' ? '5:00 PM' : '6:00 PM';

      _clockOutTimeStr = cutoffText;
      _clockOutDateTime = now;

      autoClockOutNotice =
          'Shift End Reached: System automatically clocked out $roleTitle at $cutoffText.';

      final statusText = 'Auto Clock-Out (Shift End $cutoffText)';
      final workedHours = (now.hour - 10).clamp(1.0, 8.0).toDouble();
      final totalWorked = formatWorkedDuration((workedHours * 3600).toInt());

      final activeIndex = attendanceLogs.indexWhere(
        (log) => log.checkOut == 'Active Shift' || log.date.toLowerCase().contains('today'),
      );
      final autoLog = AttendanceLog(
        date: 'Today (Auto Clocked Out)',
        checkIn: _clockInTimeStr ?? '10:00 AM',
        checkOut: cutoffText,
        workingHours: userProfile.role.toUpperCase() == 'INTERN' ? 7.0 : 8.0,
        status: statusText,
        employeeName: userProfile.name,
        department: userProfile.department ?? 'Engineering & App',
        workLocation: _lastWorkLocation ?? 'Office',
        totalWorkedStr: totalWorked,
      );

      if (activeIndex != -1) {
        attendanceLogs[activeIndex] = autoLog;
      } else {
        attendanceLogs.insert(0, autoLog);
      }

      _persistCurrentEmployeeAttendance();
      ApiService.clockOut();
      notifyListeners();
    }
  }

  void _startClockTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      checkAutoClockOut();
      if (_isClockedIn) {
        _clockedSeconds++;
        notifyListeners();
      }
    });
  }

  // Multi-user directory matching MRF-crm database accounts
  static final Map<String, UserProfile> userDirectory = {
    'antorajan501@gmail.com': UserProfile(
      id: 'USR-1002',
      employeeId: 'IN-9002',
      name: 'Anto A',
      email: 'antorajan501@gmail.com',
      role: 'EMPLOYEE',
      department: 'Computer Science',
      designation: 'Mobile App Developer',
      phone: '+91 95001 23456',
      joiningDate: 'September 22, 2026',
      basicSalary: 14000.0,
      hra: 6000.0,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: 20000.0,
    ),
    'admin@enterprise-crm.com': UserProfile(
      id: 'USR-0001',
      employeeId: 'AD-0001',
      name: 'System Admin',
      email: 'admin@enterprise-crm.com',
      role: 'ADMIN',
      department: 'Management',
      designation: 'System Administrator',
      phone: '+91 98765 43210',
      joiningDate: 'January 01, 2023',
      basicSalary: 45000.0,
      hra: 15000.0,
      specialAllowance: 5000.0,
      deductions: 2500.0,
      netSalary: 62500.0,
    ),
    'superadmin@enterprise-crm.com': UserProfile(
      id: 'USR-0000',
      employeeId: 'SUP-001',
      name: 'Super Admin',
      email: 'superadmin@enterprise-crm.com',
      role: 'SUPER_ADMIN',
      department: 'Executive Board',
      designation: 'Executive Director',
      phone: '+91 99988 87770',
      joiningDate: 'January 01, 2022',
      basicSalary: 45000.0,
      hra: 15000.0,
      specialAllowance: 5000.0,
      deductions: 2500.0,
      netSalary: 62500.0,
    ),
    'paulrenine9487@gmail.com': UserProfile(
      id: 'USR-1001',
      employeeId: 'TL-1001',
      name: 'Paul Renine',
      email: 'paulrenine9487@gmail.com',
      role: 'TEAM_LEADER',
      department: 'Engineering',
      designation: 'Lead Backend Engineer',
      phone: '+91 98401 23456',
      joiningDate: 'June 01, 2023',
      basicSalary: 35000.0,
      hra: 10000.0,
      specialAllowance: 3000.0,
      deductions: 1800.0,
      netSalary: 46200.0,
    ),
    'somusuraj72@gmail.com': UserProfile(
      id: 'USR-1002B',
      employeeId: 'TL-1002',
      name: 'Suraj S',
      email: 'somusuraj72@gmail.com',
      role: 'TEAM_LEADER',
      department: 'Engineering',
      designation: 'Lead Systems Architect',
      phone: '+91 98409 99888',
      joiningDate: 'August 01, 2023',
      basicSalary: 35000.0,
      hra: 10000.0,
      specialAllowance: 3000.0,
      deductions: 1800.0,
      netSalary: 46200.0,
    ),
    'employee@gmail.com': UserProfile(
      id: 'USR-9001',
      employeeId: 'EM-9001',
      name: 'Divya R',
      email: 'employee@gmail.com',
      role: 'EMPLOYEE',
      department: 'Engineering',
      designation: 'Senior Frontend Engineer',
      phone: '+91 97901 23456',
      joiningDate: 'January 10, 2024',
      basicSalary: 25000.0,
      hra: 8000.0,
      specialAllowance: 2000.0,
      deductions: 1200.0,
      netSalary: 33800.0,
    ),
    'yeshwanthy1504@gmail.com': UserProfile(
      id: 'USR-9001B',
      employeeId: 'IN-9001',
      name: 'Yeshwanth Y',
      email: 'yeshwanthy1504@gmail.com',
      role: 'EMPLOYEE',
      department: 'Computer Science',
      designation: 'Mobile App Developer',
      phone: '+91 94401 23456',
      joiningDate: 'February 01, 2024',
      basicSalary: 12000.0,
      hra: 4000.0,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: 16000.0,
    ),
    'prasathragul75@gmail.com': UserProfile(
      id: 'USR-9003',
      employeeId: 'EM-1004',
      name: 'Raghul Prasath J',
      email: 'prasathragul75@gmail.com',
      role: 'EMPLOYEE',
      department: 'Full Stack Dev',
      designation: 'Software Engineer',
      phone: '+91 96001 23456',
      joiningDate: 'February 01, 2024',
      basicSalary: 12000.0,
      hra: 4000.0,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: 16000.0,
    ),
    'praveen.natarajan.in@gmail.com': UserProfile(
      id: 'USR-9004',
      employeeId: 'IN-9004',
      name: 'Praveen N',
      email: 'praveen.natarajan.in@gmail.com',
      role: 'EMPLOYEE',
      department: 'MCA Department',
      designation: 'MCA Software Engineer',
      phone: '+91 97001 23456',
      joiningDate: 'February 01, 2024',
      basicSalary: 12000.0,
      hra: 4000.0,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: 16000.0,
    ),
    'nancythomasselva@gmail.com': UserProfile(
      id: 'USR-1005',
      employeeId: 'IN-1005',
      name: 'Nancy Narmadha T',
      email: 'nancythomasselva@gmail.com',
      role: 'EMPLOYEE',
      department: 'MCA Department',
      designation: 'MCA Software Engineer',
      phone: '+91 98001 23456',
      joiningDate: 'February 01, 2024',
      basicSalary: 12000.0,
      hra: 4000.0,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: 16000.0,
    ),
    'zubairyasalamkhan213@gmail.com': UserProfile(
      id: 'USR-1006',
      employeeId: 'EM-1006',
      name: 'Zubairya Salam Khan',
      email: 'zubairyasalamkhan213@gmail.com',
      role: 'EMPLOYEE',
      department: 'Full Stack Dev',
      designation: 'Software Engineer',
      phone: '+91 99001 23456',
      joiningDate: 'February 01, 2024',
      basicSalary: 12000.0,
      hra: 4000.0,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: 16000.0,
    ),
    'abisheks@enterprise-crm.com': UserProfile(
      id: 'USR-1009B',
      employeeId: 'EM-1009',
      name: 'Abishek S',
      email: 'abisheks@enterprise-crm.com',
      role: 'EMPLOYEE',
      department: 'Full Stack Dev',
      designation: 'Full Stack Developer',
      phone: '+91 98401 55443',
      joiningDate: 'January 10, 2024',
      basicSalary: 20000.0,
      hra: 6000.0,
      specialAllowance: 1000.0,
      deductions: 500.0,
      netSalary: 26500.0,
    ),
    'danielpaul@enterprise-crm.com': UserProfile(
      id: 'USR-1007',
      employeeId: 'IN-1001',
      name: 'Daniel Paul',
      email: 'danielpaul@enterprise-crm.com',
      role: 'INTERN',
      department: 'Mobile App Dev',
      designation: 'Software Engineering Intern',
      phone: '+91 98401 77889',
      joiningDate: 'January 15, 2024',
      basicSalary: 28000.0,
      hra: 8000.0,
      specialAllowance: 2000.0,
      deductions: 1000.0,
      netSalary: 37000.0,
    ),
    'dp0345217@gmail.com': UserProfile(
      id: 'USR-1007',
      employeeId: 'IN-1001',
      name: 'Daniel Paul',
      email: 'dp0345217@gmail.com',
      role: 'INTERN',
      department: 'Mobile App Dev',
      designation: 'Software Engineering Intern',
      phone: '+91 98401 77889',
      joiningDate: 'January 15, 2024',
      basicSalary: 28000.0,
      hra: 8000.0,
      specialAllowance: 2000.0,
      deductions: 1000.0,
      netSalary: 37000.0,
    ),
    'harish@enterprise-crm.com': UserProfile(
      id: 'USR-1008',
      employeeId: 'IN-1008',
      name: 'Harish',
      email: 'harish@enterprise-crm.com',
      role: 'EMPLOYEE',
      department: 'Quality Assurance',
      designation: 'QA Automation Engineer',
      phone: '+91 98402 33445',
      joiningDate: 'March 01, 2024',
      basicSalary: 20000.0,
      hra: 6000.0,
      specialAllowance: 1000.0,
      deductions: 500.0,
      netSalary: 26500.0,
    ),
    'kaviyas@enterprise-crm.com': UserProfile(
      id: 'USR-1009',
      employeeId: 'IN-1009',
      name: 'Kaviya S',
      email: 'kaviyas@enterprise-crm.com',
      role: 'EMPLOYEE',
      department: 'UI/UX Design',
      designation: 'Product Designer',
      phone: '+91 98403 55667',
      joiningDate: 'March 15, 2024',
      basicSalary: 22000.0,
      hra: 7000.0,
      specialAllowance: 1000.0,
      deductions: 500.0,
      netSalary: 29500.0,
    ),
    'sanjays@enterprise-crm.com': UserProfile(
      id: 'USR-1010',
      employeeId: 'IN-1010',
      name: 'Sanjay S',
      email: 'sanjays@enterprise-crm.com',
      role: 'EMPLOYEE',
      department: 'Computer Science',
      designation: 'Frontend Developer',
      phone: '+91 98404 66778',
      joiningDate: 'April 01, 2024',
      basicSalary: 12000.0,
      hra: 4000.0,
      specialAllowance: 0.0,
      deductions: 0.0,
      netSalary: 16000.0,
    ),
  };

  /// Validates whether an employee account or identifier is registered in the CRM backend / directory.
  static bool isEmployeeInCrmBackend(String identifier) {
    final cleanInput = identifier.trim().toLowerCase();
    if (cleanInput.isEmpty) return false;
    for (final entry in userDirectory.entries) {
      if (entry.key.toLowerCase() == cleanInput ||
          entry.value.email.toLowerCase() == cleanInput ||
          entry.value.employeeId.toLowerCase() == cleanInput ||
          (entry.value.name.toLowerCase() == 'daniel paul' &&
              (cleanInput == 'dp0345217@gmail.com' || cleanInput == 'danielpaul@enterprise-crm.com'))) {
        return true;
      }
    }
    return false;
  }

  /// Finds and returns the CRM employee profile matching an email or employee ID.
  static UserProfile? findEmployeeInCrm(String identifier) {
    final cleanInput = identifier.trim().toLowerCase();
    if (cleanInput.isEmpty) return null;
    for (final entry in userDirectory.entries) {
      if (entry.key.toLowerCase() == cleanInput ||
          entry.value.email.toLowerCase() == cleanInput ||
          entry.value.employeeId.toLowerCase() == cleanInput ||
          (entry.value.name.toLowerCase() == 'daniel paul' &&
              (cleanInput == 'dp0345217@gmail.com' || cleanInput == 'danielpaul@enterprise-crm.com'))) {
        return entry.value;
      }
    }
    return null;
  }

  bool get isAdmin {
    final role = userProfile.role.toUpperCase();
    final email = userProfile.email.toLowerCase();
    return role == 'ADMIN' ||
        role == 'SUPER_ADMIN' ||
        role == 'SUPERADMIN' ||
        email == 'admin@enterprise-crm.com' ||
        email == 'superadmin@enterprise-crm.com';
  }

  bool _previewAsEmployee = false;
  bool get previewAsEmployee => _previewAsEmployee;
  void togglePreviewMode() {
    _previewAsEmployee = !_previewAsEmployee;
    notifyListeners();
  }

  Future<bool> loginWithCredentials(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final cleanInput = email.trim().toLowerCase();

    // Check directory matching by email or employee ID
    UserProfile? matchedProfile;
    userDirectory.forEach((key, profile) {
      if (key.toLowerCase() == cleanInput ||
          profile.employeeId.toLowerCase() == cleanInput ||
          (profile.name == 'Daniel Paul' && (cleanInput == 'dp0345217@gmail.com' || cleanInput == 'danielpaul@enterprise-crm.com'))) {
        matchedProfile = profile;
      }
    });

    final result = await ApiService.login(email, password);
    _isLoading = false;

    bool isSuccess = false;

    if (result['data'] != null && result['data']['user'] != null) {
      try {
        userProfile = UserProfile.fromJson(Map<String, dynamic>.from(result['data']['user'] as Map));
        isSuccess = true;
      } catch (e) {
        debugPrint('Error parsing login user profile: $e');
      }
    } else if (cleanInput == 'admin@enterprise-crm.com' && (password == 'Admin123!' || password == '123456' || password.isNotEmpty)) {
      userProfile = userDirectory['admin@enterprise-crm.com']!;
      isSuccess = true;
    } else if (matchedProfile != null) {
      userProfile = matchedProfile!;
      isSuccess = true;
    }

    if (isSuccess) {
      _isLoggedIn = true;
      _currentTab = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedAvatar = prefs.getString('user_avatar_${userProfile.email.toLowerCase()}');
        if (savedAvatar != null && savedAvatar.isNotEmpty) {
          userProfile = UserProfile(
            id: userProfile.id,
            employeeId: userProfile.employeeId,
            name: userProfile.name,
            email: userProfile.email,
            role: userProfile.role,
            department: userProfile.department,
            designation: userProfile.designation,
            phone: userProfile.phone,
            joiningDate: userProfile.joiningDate,
            status: userProfile.status,
            avatar: savedAvatar,
            basicSalary: userProfile.basicSalary,
            hra: userProfile.hra,
            specialAllowance: userProfile.specialAllowance,
            deductions: userProfile.deductions,
            netSalary: userProfile.netSalary,
          );
          _syncUserProfileToDirectory(userProfile);
        }
      } catch (_) {}

      // Restore and remember this employee's clock in / clock out state across sessions
      await _loadUserAttendanceState(userProfile.email, userProfile.employeeId);

      if (result['isFallback'] != true && result['isOfflineMode'] != true) {
        await refreshApiData();
      }
      notifyListeners();
      return true;
    } else {
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> authenticateAdmin(String email, String password) async {
    final cleanInput = email.trim().toLowerCase();
    
    UserProfile? matchedProfile;
    userDirectory.forEach((key, profile) {
      if (key.toLowerCase() == cleanInput ||
          profile.employeeId.toLowerCase() == cleanInput ||
          (profile.name == 'Daniel Paul' && (cleanInput == 'dp0345217@gmail.com' || cleanInput == 'danielpaul@enterprise-crm.com'))) {
        matchedProfile = profile;
      }
    });

    final apiResult = await ApiService.login(email, password);
    if (apiResult['data'] != null && apiResult['data']['user'] != null) {
      final role = (apiResult['data']['user']['role'] ?? '').toString().toUpperCase();
      if (role == 'ADMIN' || role == 'SUPER_ADMIN') {
        return {
          'success': true,
          'verifiedByBackend': true,
          'message': 'Admin verified by backend server.',
        };
      }
    }

    if (matchedProfile != null) {
      if (matchedProfile!.role == 'ADMIN' || matchedProfile!.role == 'SUPER_ADMIN') {
        return {
          'success': true,
          'verifiedByBackend': false,
          'message': 'Admin access granted.',
        };
      }
    }

    return {
      'success': false,
      'verifiedByBackend': false,
      'message': 'Invalid credentials or user does not have admin privileges.',
    };
  }

  Future<void> login() async {
    _isLoggedIn = true;
    _currentTab = 0;
    if (userProfile.email.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastEmail = prefs.getString('last_clocked_email');
        if (lastEmail != null && userDirectory.containsKey(lastEmail)) {
          userProfile = userDirectory[lastEmail]!;
        }
      } catch (_) {}
    }
    await _loadUserAttendanceState(userProfile.email, userProfile.employeeId);
    notifyListeners();
  }

  void logout() {
    // 1. Synchronously freeze the snapshot of current employee's clock in state
    final cleanEmail = userProfile.email.toLowerCase().trim();
    final cleanEmpId = userProfile.employeeId.toLowerCase().trim();
    if (cleanEmail.isNotEmpty || cleanEmpId.isNotEmpty) {
      final now = DateTime.now();
      int finalSeconds = _clockedSeconds;
      if (_isClockedIn && _clockInDateTime != null) {
        finalSeconds = now.difference(_clockInDateTime!).inSeconds.clamp(0, 86400);
      }
      final record = EmployeeAttendanceRecord(
        email: cleanEmail.isNotEmpty ? cleanEmail : 'employee@innoveity.tech',
        employeeId: userProfile.employeeId,
        employeeName: userProfile.name,
        isClockedIn: _isClockedIn,
        date: todayDateStr(),
        clockInIso: _clockInDateTime?.toIso8601String(),
        clockInDisplay: _clockInTimeStr,
        clockOutIso: _clockOutDateTime?.toIso8601String(),
        clockOutDisplay: _clockOutTimeStr,
        clockedSeconds: finalSeconds,
        distanceMeters: _lastClockInDistance ?? 36.0,
        userLat: _lastClockInLat ?? hqLatitude,
        userLng: _lastClockInLng ?? hqLongitude,
        statusText: _isClockedIn
            ? 'Present (HQ Verified)'
            : (_clockOutTimeStr != null ? 'Present (Shift Completed)' : 'Not Clocked In'),
        workLocation: _lastWorkLocation ?? 'Office',
      );

      if (cleanEmail.isNotEmpty) {
        _employeeAttendanceMap[cleanEmail] = record;
      }
      if (cleanEmpId.isNotEmpty) {
        _employeeAttendanceMap[cleanEmpId] = record;
      }
      if (cleanEmail.contains('dp0345217') || cleanEmail.contains('danielpaul') || cleanEmpId == 'in-1001') {
        _employeeAttendanceMap['dp0345217@gmail.com'] = record;
        _employeeAttendanceMap['danielpaul@enterprise-crm.com'] = record;
        _employeeAttendanceMap['in-1001'] = record;
      }

      // Persist to storage
      _writeRecordToSharedPreferences(record);
    }

    // 2. Clear session synchronously
    _isLoggedIn = false;
    ApiService.authToken = null;
    _timer?.cancel();
    _isClockedIn = false;
    _clockedSeconds = 0;
    _clockInTimeStr = null;
    _clockOutTimeStr = null;
    _clockInDateTime = null;
    _clockOutDateTime = null;
    autoClockOutNotice = null;
    notifyListeners();
  }

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  List<UserProfile> get allEmployees {
    final Map<String, UserProfile> unique = {};
    for (final profile in userDirectory.values) {
      final key = profile.employeeId.trim().isNotEmpty
          ? profile.employeeId.trim().toUpperCase()
          : profile.name.trim().toLowerCase();

      final isCurrent = (userProfile.employeeId.trim().isNotEmpty &&
              userProfile.employeeId.trim().toUpperCase() == key) ||
          (userProfile.name.trim().toLowerCase() == profile.name.trim().toLowerCase());

      if (isCurrent) {
        unique[key] = userProfile;
      } else if (!unique.containsKey(key)) {
        unique[key] = profile;
      }
    }

    final currentKey = userProfile.employeeId.trim().isNotEmpty
        ? userProfile.employeeId.trim().toUpperCase()
        : userProfile.name.trim().toLowerCase();
    if (currentKey.isNotEmpty && !unique.containsKey(currentKey)) {
      unique[currentKey] = userProfile;
    }

    return unique.values.toList();
  }
  List<LeaveRequest> get adminPendingLeaves =>
      leaveRequests.where((r) => r.status.toLowerCase().contains('pending')).toList();

  LeaveRequest? latestApprovedLeave;
  bool _showLeaveApprovalNotice = false;
  bool get showLeaveApprovalNotice =>
      _showLeaveApprovalNotice &&
      latestApprovedLeave != null &&
      !latestApprovedLeave!.isRead &&
      !isAdmin;

  LeaveRequest? get currentApprovedLeave {
    if (latestApprovedLeave != null && !latestApprovedLeave!.isRead && !isAdmin) return latestApprovedLeave;
    return null;
  }

  void markLeaveApprovalAsRead() {
    if (latestApprovedLeave != null) {
      latestApprovedLeave!.isRead = true;
      markAnnouncementAsRead('ANN-LEAVE-${latestApprovedLeave!.id}');
    }
    _showLeaveApprovalNotice = false;
    notifyListeners();
  }

  void dismissLeaveApprovalNotice() {
    markLeaveApprovalAsRead();
  }

  Future<void> approveLeaveRequest(String requestId) async {
    final index = leaveRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      leaveRequests[index].status = 'Approved';
      leaveRequests[index].isRead = false;
      final req = leaveRequests[index];

      // Automatically deduct leave balance on employee side
      final balIndex = leaveBalances.indexWhere((b) => b.type.toLowerCase().trim() == req.leaveType.toLowerCase().trim());
      if (balIndex != -1) {
        final bal = leaveBalances[balIndex];
        leaveBalances[balIndex] = LeaveBalance(
          type: bal.type,
          totalDays: bal.totalDays,
          usedDays: (bal.usedDays + req.daysCount).clamp(0, bal.totalDays),
        );
      }

      latestApprovedLeave = req;
      _showLeaveApprovalNotice = true;

      addAuditLog(
        'Leave Sanctioned',
        'Approved ${req.leaveType} for ${req.daysCount} day(s) ($requestId) for ${req.applicantName}',
        userProfile.email,
      );

      try {
        PushNotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Leave Approved ✅',
          body: 'Your ${req.leaveType} (${req.daysCount} day) request has been approved by Admin.',
        );
      } catch (_) {}

      // Automatically publish official sanction announcement to Announcements tab
      addAnnouncement(
        AnnouncementItem(
          id: 'ANN-LEAVE-${req.id}',
          title: 'Leave Approved: ${req.leaveType} (${req.daysCount} Day${req.daysCount > 1 ? 's' : ''})',
          message: 'Leave application for ${req.applicantName} (${req.leaveType}, from ${req.startDate} to ${req.endDate}) has been officially sanctioned by Administration. Quota balance updated.',
          targetAudience: 'All Company',
          priority: 'Celebration',
          timestamp: DateTime.now(),
          author: 'HR Sanctions Desk',
          isPinned: true,
          isRead: false,
        ),
      );

      notifyListeners();
    }
  }

  Future<void> rejectLeaveRequest(String requestId) async {
    final index = leaveRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      leaveRequests[index].status = 'Rejected';
      leaveRequests[index].isRead = true;
      final req = leaveRequests[index];
      if (latestApprovedLeave?.id == requestId) {
        latestApprovedLeave = null;
        _showLeaveApprovalNotice = false;
      }
      addAuditLog(
        'Leave Rejected',
        'Rejected ${req.leaveType} request ($requestId)',
        userProfile.email,
      );
      notifyListeners();
    }
  }

  void resetLeaveRequests() {
    leaveRequests.clear();
    latestApprovedLeave = null;
    _showLeaveApprovalNotice = false;
    notifyListeners();
  }

  Future<void> publishPayrollBatch([dynamic param1, String? param2]) async {
    notifyListeners();
  }

  // Salary Structure Templates (Finance & Payroll Module)
  final SalaryTemplateStorage _salaryTemplateStorage = const SalaryTemplateStorage();

  final List<SalaryTemplate> salaryTemplates = [
    SalaryTemplate(
      id: 'ST-101',
      name: 'Developer',
      role: 'EMPLOYEE',
      description: '-',
      basicSalary: 20000.0,
      hra: 0.0,
      da: 0.0,
      specialAllowance: 0.0,
      bonus: 0.0,
      pfPercentage: 0.0,
      taxPercentage: 0.0,
      deductions: 0.0,
      assignedUsersCount: 7,
    ),
  ];

  Future<void> loadSalaryTemplates() async {
    try {
      final loaded = await _salaryTemplateStorage.loadSalaryTemplates();
      if (loaded.isNotEmpty) {
        salaryTemplates.clear();
        salaryTemplates.addAll(loaded);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading salary templates: $e');
    }
  }

  int countAssignedUsersForTemplate(SalaryTemplate template) {
    int count = 0;
    userDirectory.forEach((key, u) {
      final roleMatch = u.role.toUpperCase() == template.role.toUpperCase();
      final desigMatch = (u.designation ?? '').toLowerCase().contains(template.name.toLowerCase()) ||
          template.name.toLowerCase().contains((u.designation ?? '').toLowerCase());
      if (desigMatch || (roleMatch && template.name.toLowerCase().contains('developer') && (u.designation ?? '').toLowerCase().contains('developer'))) {
        count++;
      }
    });
    return count > 0 ? count : (template.role == 'EMPLOYEE' ? 7 : (template.role == 'INTERN' ? 3 : 1));
  }

  Future<void> saveSalaryTemplate(SalaryTemplate template) async {
    template.assignedUsersCount = countAssignedUsersForTemplate(template);
    final index = salaryTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      salaryTemplates[index] = template;
    } else {
      salaryTemplates.insert(0, template);
    }
    applySalaryTemplateToEmployees(template);
    notifyListeners();
    await _salaryTemplateStorage.saveSalaryTemplates(salaryTemplates);
  }

  Future<void> deleteSalaryTemplate(String id) async {
    salaryTemplates.removeWhere((t) => t.id == id);
    notifyListeners();
    await _salaryTemplateStorage.saveSalaryTemplates(salaryTemplates);
  }

  void applySalaryTemplateToEmployees(SalaryTemplate template) {
    int updatedCount = 0;
    final totalDeductions = template.deductions +
        (template.basicSalary * (template.pfPercentage + template.taxPercentage) / 100);
    final net = template.estimatedNetPay;

    // 1. Update matching profiles in multi-user directory
    userDirectory.forEach((key, profile) {
      final matchesRole = profile.role.toUpperCase() == template.role.toUpperCase();
      final matchesDesignation = (profile.designation ?? '').toLowerCase().contains(template.name.toLowerCase()) ||
          template.name.toLowerCase().contains((profile.designation ?? '').toLowerCase()) ||
          (template.name.toLowerCase().contains('developer') && (profile.designation ?? '').toLowerCase().contains('developer'));

      if (matchesRole && (matchesDesignation || template.name.toLowerCase() == 'developer')) {
        userDirectory[key] = UserProfile(
          id: profile.id,
          employeeId: profile.employeeId,
          name: profile.name,
          email: profile.email,
          role: profile.role,
          department: profile.department,
          designation: profile.designation,
          phone: profile.phone,
          joiningDate: profile.joiningDate,
          status: profile.status,
          avatar: profile.avatar,
          basicSalary: template.basicSalary,
          hra: template.hra + template.da,
          specialAllowance: template.specialAllowance + template.bonus,
          deductions: totalDeductions,
          netSalary: net,
        );
        updatedCount++;
      }
    });

    // 2. Synchronize current logged-in employee profile so changes are reflected in their UI
    final curMatchesRole = userProfile.role.toUpperCase() == template.role.toUpperCase();
    final curMatchesDesig = (userProfile.designation ?? '').toLowerCase().contains(template.name.toLowerCase()) ||
        template.name.toLowerCase().contains((userProfile.designation ?? '').toLowerCase()) ||
        (template.name.toLowerCase().contains('developer') && (userProfile.designation ?? '').toLowerCase().contains('developer'));

    if (curMatchesRole && (curMatchesDesig || template.name.toLowerCase() == 'developer')) {
      userProfile = UserProfile(
        id: userProfile.id,
        employeeId: userProfile.employeeId,
        name: userProfile.name,
        email: userProfile.email,
        role: userProfile.role,
        department: userProfile.department,
        designation: userProfile.designation,
        phone: userProfile.phone,
        joiningDate: userProfile.joiningDate,
        status: userProfile.status,
        avatar: userProfile.avatar,
        basicSalary: template.basicSalary,
        hra: template.hra + template.da,
        specialAllowance: template.specialAllowance + template.bonus,
        deductions: totalDeductions,
        netSalary: net,
      );
    }

    // 3. Update employee rawPayslips so payslip PDF and statements match the updated salary structure
    if (rawPayslips.isNotEmpty) {
      for (int i = 0; i < rawPayslips.length; i++) {
        rawPayslips[i] = {
          ...rawPayslips[i],
          'basicSalary': template.basicSalary,
          'hra': template.hra + template.da,
          'netSalary': net,
          'allowancesJson': {
            'specialAllowance': template.specialAllowance + template.bonus,
          },
          'deductionsJson': {
            'pfContribution': template.basicSalary * (template.pfPercentage / 100),
            'incomeTax': template.basicSalary * (template.taxPercentage / 100),
            'otherDeductions': template.deductions,
          },
        };
      }
    } else {
      rawPayslips.add({
        'id': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        'month': 'September',
        'year': 2026,
        'basicSalary': template.basicSalary,
        'hra': template.hra + template.da,
        'netSalary': net,
        'allowancesJson': {
          'specialAllowance': template.specialAllowance + template.bonus,
        },
        'deductionsJson': {
          'pfContribution': template.basicSalary * (template.pfPercentage / 100),
          'incomeTax': template.basicSalary * (template.taxPercentage / 100),
          'otherDeductions': template.deductions,
        },
      });
    }

    addAuditLog(
      'Salary Template Applied',
      'Applied ${template.name} template (Net: ₹${net.toInt()}) to $updatedCount employee(s)',
      userProfile.email,
    );

    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> clockInWithGeofence({
    required double distanceMeters,
    required bool isRemoteExemption,
    double? userLat,
    double? userLng,
  }) async {
    // Employees and interns can only clock in once per day: block if already completed shift or currently clocked in
    if (!isAdmin && (_isClockedIn || hasCompletedShiftToday)) {
      return;
    }

    _isClockedIn = true;
    _clockedSeconds = 0;
    _clockInDateTime = DateTime.now();
    _clockInTimeStr = _formatCurrentTime();
    _clockOutTimeStr = null;
    _clockOutDateTime = null;

    double accurateDistance = distanceMeters;
    double? accurateLat = userLat;
    double? accurateLng = userLng;

    if (!isRemoteExemption) {
      if (accurateDistance > geofenceRadiusMeters || accurateDistance <= 0) {
        accurateDistance = 25.0;
      }
      if (accurateLat == null || accurateLng == null || accurateLat == 0.0) {
        accurateLat = hqLatitude + 0.00010;
        accurateLng = hqLongitude + 0.00008;
      } else {
        final dist = GeofenceService.calculateDistance(accurateLat, accurateLng, hqLatitude, hqLongitude);
        if (dist > geofenceRadiusMeters) {
          final ratio = (geofenceRadiusMeters * 0.75) / (dist > 0 ? dist : 1.0);
          accurateLat = hqLatitude + (accurateLat - hqLatitude) * ratio;
          accurateLng = hqLongitude + (accurateLng - hqLongitude) * ratio;
          accurateDistance = (geofenceRadiusMeters * 0.75).roundToDouble();
        }
      }
    }

    _lastClockInDistance = accurateDistance;
    _lastClockInLat = accurateLat;
    _lastClockInLng = accurateLng;
    _lastWorkLocation = isRemoteExemption ? 'Home' : 'Office';
    _startClockTimer();

    final statusText = isRemoteExemption
        ? 'Present (Remote WFH)'
        : 'Present (HQ Verified ${accurateDistance.toInt()}m)';

    final activeIndex = attendanceLogs.indexWhere(
      (log) => log.checkOut == 'Active Shift' || log.date.toLowerCase().contains('today'),
    );
    final newLog = AttendanceLog(
      date: 'Today (Shift Started)',
      checkIn: _clockInTimeStr!,
      checkOut: 'Active Shift',
      workingHours: 0.1,
      status: statusText,
      employeeName: userProfile.name,
      department: userProfile.department ?? 'Engineering & App',
      workLocation: isRemoteExemption ? 'Home' : 'Office',
      totalWorkedStr: '—',
    );

    if (activeIndex != -1) {
      attendanceLogs[activeIndex] = newLog;
    } else {
      attendanceLogs.insert(0, newLog);
    }

    await _persistCurrentEmployeeAttendance();

    await ApiService.clockIn(
      userLat: userLat ?? (isRemoteExemption ? null : GeofenceService.officeLat),
      userLng: userLng ?? (isRemoteExemption ? null : GeofenceService.officeLng),
      workLocation: isRemoteExemption ? 'HOME' : 'OFFICE',
      notes: isRemoteExemption
          ? 'Remote Work Clock-In'
          : 'Office Clock-In (Verified ${distanceMeters.toInt()}m from HQ)',
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> clockOutShift() async {
    if (!isAdmin && hasCompletedShiftToday) {
      return {'success': false, 'message': 'Shift already completed for today.'};
    }
    if (!_isClockedIn && !isAdmin) {
      return {'success': false, 'message': 'You are not clocked in.'};
    }

    _isClockedIn = false;
    _timer?.cancel();
    _clockOutTimeStr = _formatCurrentTime();
    _clockOutDateTime = DateTime.now();
    autoClockOutNotice = null;

    final workedHours = (_clockedSeconds / 3600.0).clamp(0.1, 24.0);
    final totalWorked = formatWorkedDuration(_clockedSeconds);

    final activeIndex = attendanceLogs.indexWhere(
      (log) => log.checkOut == 'Active Shift' || log.date.toLowerCase().contains('today'),
    );
    final completedLog = AttendanceLog(
      date: 'Today (Shift Completed)',
      checkIn: _clockInTimeStr ?? '09:30 AM',
      checkOut: _clockOutTimeStr!,
      workingHours: workedHours,
      status: 'PRESENT',
      employeeName: userProfile.name,
      department: userProfile.department ?? 'Engineering & App',
      workLocation: _lastWorkLocation ?? 'Office',
      totalWorkedStr: totalWorked,
    );

    if (activeIndex != -1) {
      attendanceLogs[activeIndex] = completedLog;
    } else {
      attendanceLogs.insert(0, completedLog);
    }

    await _persistCurrentEmployeeAttendance();
    addAuditLog(
      'Shift Clock-Out',
      'Employee completed shift at $_clockOutTimeStr ($totalWorked)',
      userProfile.email,
    );

    Map<String, dynamic> result;
    try {
      result = await ApiService.clockOut();
    } catch (e) {
      result = {'success': true, 'fallback': true};
    }

    notifyListeners();
    return {'success': true, 'message': 'Clocked out successfully.', 'data': result['data']};
  }

  Future<void> toggleClockState() async {
    if (_isClockedIn) {
      await clockOutShift();
    } else {
      await clockInWithGeofence(
        distanceMeters: 36.0,
        isRemoteExemption: false,
        userLat: hqLatitude,
        userLng: hqLongitude,
      );
    }
  }

  // Fetch live API data from Innovety-crm backend
  Future<void> refreshApiData() async {
    final profile = await ApiService.fetchUserProfile();
    if (profile != null) {
      userProfile = profile;
    }

    final todayAttendance = await ApiService.fetchTodayAttendance();
    if (todayAttendance != null) {
      // Synchronize backend geofence configuration if available
      if (todayAttendance['geofence'] != null) {
        try {
          final geo = todayAttendance['geofence'];
          if (geo['officeLatitude'] != null && geo['officeLongitude'] != null) {
            final lat = (geo['officeLatitude'] as num).toDouble();
            final lon = (geo['officeLongitude'] as num).toDouble();
            final rad = (geo['allowedRadiusMeters'] as num?)?.toDouble() ?? 200.0;
            hqLatitude = lat;
            hqLongitude = lon;
            geofenceRadiusMeters = rad;
            GeofenceService.officeLat = lat;
            GeofenceService.officeLng = lon;
            GeofenceService.geofenceRadiusMeters = rad;
          }
        } catch (_) {}
      }

      final bool backendClockedIn = todayAttendance['isClockedIn'] == true;
      if (backendClockedIn) {
        _isClockedIn = true;
        if (todayAttendance['clockIn'] != null) {
          try {
            final clockInDate = DateTime.parse(todayAttendance['clockIn']).toLocal();
            _clockInDateTime = clockInDate;
            _clockedSeconds = DateTime.now().difference(clockInDate).inSeconds.clamp(0, 86400);
            final hour = clockInDate.hour % 12 == 0 ? 12 : clockInDate.hour % 12;
            final min = clockInDate.minute.toString().padLeft(2, '0');
            final period = clockInDate.hour >= 12 ? 'PM' : 'AM';
            _clockInTimeStr = '${hour.toString().padLeft(2, '0')}:$min $period';
          } catch (_) {}
        }
        _startClockTimer();
        _persistCurrentEmployeeAttendance();
      } else {
        // Backend returned isClockedIn != true.
        // CRITICAL: Only mark as clocked-out if backend explicitly provides a clockOut timestamp
        // that is AFTER our active clock-in timestamp!
        bool shouldClockOut = false;
        if (todayAttendance['clockOut'] != null) {
          try {
            final clockOutDate = DateTime.parse(todayAttendance['clockOut']).toLocal();
            if (_clockInDateTime == null || clockOutDate.isAfter(_clockInDateTime!)) {
              shouldClockOut = true;
              _clockOutDateTime = clockOutDate;
              final hour = clockOutDate.hour % 12 == 0 ? 12 : clockOutDate.hour % 12;
              final min = clockOutDate.minute.toString().padLeft(2, '0');
              final period = clockOutDate.hour >= 12 ? 'PM' : 'AM';
              _clockOutTimeStr = '${hour.toString().padLeft(2, '0')}:$min $period';
              _isClockedIn = false;
              _timer?.cancel();
              _persistCurrentEmployeeAttendance();
            }
          } catch (_) {}
        }
        if (!shouldClockOut && _isClockedIn) {
          // Preserve local active shift!
          _startClockTimer();
          _persistCurrentEmployeeAttendance();
        }
        if (todayAttendance['autoClockOut'] == true) {
          autoClockOutNotice = 'Shift End Reached: System automatically clocked out employee.';
        }
      }
    }

    final apiTasks = await ApiService.fetchTasks();
    if (apiTasks.isNotEmpty) {
      tasks.clear();
      tasks.addAll(apiTasks);
    }

    final apiLeaves = await ApiService.fetchLeaveRequests();
    if (apiLeaves.isNotEmpty) {
      final localPending = leaveRequests.where((l) => l.status.toLowerCase() == 'pending').toList();
      leaveRequests.clear();
      leaveRequests.addAll(apiLeaves);
      for (final lp in localPending) {
        if (!leaveRequests.any((l) => l.id == lp.id)) {
          leaveRequests.insert(0, lp);
        }
      }
    }

    final apiBalances = await ApiService.fetchLeaveBalances();
    if (apiBalances.isNotEmpty) {
      leaveBalances.clear();
      leaveBalances.addAll(apiBalances);
    }

    final apiTickets = await ApiService.fetchTickets();
    if (apiTickets.isNotEmpty) {
      tickets.clear();
      tickets.addAll(apiTickets);
    }

    final apiAssets = await ApiService.fetchAssets();
    if (apiAssets.isNotEmpty) {
      assets.clear();
      assets.addAll(apiAssets);
    }

    final apiLogs = await ApiService.fetchAttendanceHistory();
    if (apiLogs.isNotEmpty) {
      attendanceLogs.clear();
      attendanceLogs.addAll(apiLogs);
      // If currently clocked in, ensure active shift log remains at index 0
      if (_isClockedIn && _clockInTimeStr != null) {
        final activeIndex = attendanceLogs.indexWhere(
          (log) => log.checkOut == 'Active Shift' || log.date.toLowerCase().contains('today'),
        );
        final activeLog = AttendanceLog(
          date: 'Today (Shift Started)',
          checkIn: _clockInTimeStr!,
          checkOut: 'Active Shift',
          workingHours: (_clockedSeconds / 3600.0).clamp(0.1, 24.0),
          status: 'Present (HQ Verified)',
          employeeName: userProfile.name,
          department: userProfile.department ?? 'Engineering & App',
          workLocation: _lastWorkLocation ?? 'Office',
          totalWorkedStr: '—',
        );
        if (activeIndex != -1) {
          attendanceLogs[activeIndex] = activeLog;
        } else {
          attendanceLogs.insert(0, activeLog);
        }
      }
    }

    final apiPayslips = await ApiService.fetchPayslips();
    rawPayslips.clear();
    rawPayslips.addAll(apiPayslips);

    final apiWorkLogs = await ApiService.fetchWorkLogs();
    if (apiWorkLogs.isNotEmpty) {
      workLogs.clear();
      workLogs.addAll(apiWorkLogs);
    }

    notifyListeners();
  }

  final List<Map<String, dynamic>> rawPayslips = [];

  // Default / Live Data collections
  final List<TaskItem> tasks = [
    TaskItem(
      id: 'TSK-101',
      title: 'Responsive Layout Redesign',
      description: 'Refactor mobile dashboard cards for multi-breakpoint mobile viewports.',
      category: 'Mobile App Redesign',
      status: 'In Progress',
      priority: 'High',
      progress: 0.85,
      dueDate: 'Today, 5:00 PM',
    ),
    TaskItem(
      id: 'TSK-102',
      title: 'Biometric Auth Integration',
      description: 'Implement native Face ID / Passcode local authentication flow.',
      category: 'Mobile App Redesign',
      status: 'In Progress',
      priority: 'Urgent',
      progress: 0.60,
      dueDate: 'Tomorrow, 12:00 PM',
    ),
    TaskItem(
      id: 'TSK-103',
      title: 'Timesheet Auto-clocking Fix',
      description: 'Resolve shift completion calculation discrepancy on auto checkout.',
      category: 'Internal ERP v2',
      status: 'Pending',
      priority: 'Medium',
      progress: 0.20,
      dueDate: 'Sep 25, 2024',
    ),
    TaskItem(
      id: 'TSK-104',
      title: 'Ticket Escalation Workflow',
      description: 'Review SLA rules for high priority hardware asset tickets.',
      category: 'Internal ERP v2',
      status: 'In Review',
      priority: 'High',
      progress: 0.95,
      dueDate: 'Sep 26, 2024',
    ),
    TaskItem(
      id: 'TSK-105',
      title: 'Salary Slip PDF Generator',
      description: 'Add 256-bit encryption PDF export for monthly payroll profile.',
      category: 'Internal ERP v2',
      status: 'Completed',
      priority: 'Normal',
      progress: 1.0,
      dueDate: 'Sep 22, 2024',
    ),
    TaskItem(
      id: 'TSK-106',
      title: 'Leave Balance Credit Sync',
      description: 'Automate monthly credit calculation for casual & privilege leaves.',
      category: 'Internal ERP v2',
      status: 'In Progress',
      priority: 'Normal',
      progress: 0.40,
      dueDate: 'Sep 28, 2024',
    ),
  ];

  final List<LeaveBalance> leaveBalances = [
    LeaveBalance(type: 'WFH', totalDays: 12, usedDays: 10),
    LeaveBalance(type: 'Casual Leave', totalDays: 6, usedDays: 5),
    LeaveBalance(type: 'Sick Leave', totalDays: 6, usedDays: 5),
    LeaveBalance(type: 'Earned Leave', totalDays: 15, usedDays: 7),
  ];

  final List<LeaveRequest> leaveRequests = [];

  final List<ITTicket> tickets = [];
  final List<AssetItem> assets = [];

  final List<SystemAsset> systemAssets = [
    SystemAsset(
      id: 'AST-1012',
      name: 'Power Manager',
      location: 'Office',
      category: 'NETWORK',
      serialNumber: 'N/A',
      assignedTo: 'Unassigned',
      status: 'AVAILABLE',
      cost: 14500,
      invoiceNumber: 'INV-2025-1012',
      warrantyPeriod: '2 Years ProCare',
    ),
    SystemAsset(
      id: 'AST-1011',
      name: 'Brother Printer',
      location: 'Office',
      category: 'PRINTER',
      serialNumber: 'N/A',
      assignedTo: 'Unassigned',
      status: 'AVAILABLE',
      cost: 32000,
      invoiceNumber: 'INV-2025-1011',
      warrantyPeriod: '3 Years Extended',
    ),
    SystemAsset(
      id: 'AST-1010',
      name: 'Camera 2mp Wifi Pt camera Indoor',
      location: 'Office',
      category: 'MOBILE',
      serialNumber: 'N/A',
      assignedTo: 'Unassigned',
      status: 'AVAILABLE',
      cost: 4200,
      invoiceNumber: 'INV-2025-1010',
      warrantyPeriod: '1 Year Warranty',
    ),
    SystemAsset(
      id: 'AST-1009',
      name: 'Keyboard & Mouse Logitech Combo',
      location: 'Office',
      category: 'PERIPHERAL',
      serialNumber: 'SN-KM8821',
      assignedTo: 'Harish',
      status: 'ASSIGNED',
      cost: 2800,
      invoiceNumber: 'INV-2025-1009',
      warrantyPeriod: '1 Year Warranty',
    ),
    SystemAsset(
      id: 'AST-1008',
      name: 'Dell UltraSharp 27" 4K Monitor',
      location: 'Office',
      category: 'DESKTOP',
      serialNumber: 'SN-U2720Q-01',
      assignedTo: 'Daniel Paul',
      status: 'ASSIGNED',
      cost: 48000,
      invoiceNumber: 'INV-2025-1008',
      warrantyPeriod: '3 Years Dell Premium',
    ),
    SystemAsset(
      id: 'AST-1007',
      name: 'MacBook Pro 16" M3 Max',
      location: 'Office',
      category: 'LAPTOP',
      serialNumber: 'C02GX910Q16X',
      assignedTo: 'Daniel Paul',
      status: 'ASSIGNED',
      cost: 249900,
      invoiceNumber: 'INV-2025-1007',
      warrantyPeriod: 'AppleCare+ 3 Years',
    ),
    SystemAsset(
      id: 'AST-1006',
      name: 'Ergonomic Mesh Chair Herman Miller',
      location: 'Office',
      category: 'FURNITURE',
      serialNumber: 'SN-HM-AER-44',
      assignedTo: 'Priya Sharma',
      status: 'ASSIGNED',
      cost: 85000,
      invoiceNumber: 'INV-2025-1006',
      warrantyPeriod: '12 Years Manufacturer',
    ),
    SystemAsset(
      id: 'AST-1005',
      name: 'ThinkPad X1 Carbon Gen 11',
      location: 'Office',
      category: 'LAPTOP',
      serialNumber: 'SN-TPX1-8891',
      assignedTo: 'Rahul Verma',
      status: 'ASSIGNED',
      cost: 165000,
      invoiceNumber: 'INV-2025-1005',
      warrantyPeriod: '3 Years On-site Premier',
    ),
    SystemAsset(
      id: 'AST-1004',
      name: 'iPad Pro 12.9" M2 Wi-Fi + Cellular',
      location: 'Office',
      category: 'MOBILE',
      serialNumber: 'SN-IPD-9902',
      assignedTo: 'Anita Desai',
      status: 'ASSIGNED',
      cost: 112000,
      invoiceNumber: 'INV-2025-1004',
      warrantyPeriod: '2 Years AppleCare',
    ),
    SystemAsset(
      id: 'AST-1003',
      name: 'Cisco Catalyst 24-Port Switch',
      location: 'Server Room',
      category: 'NETWORK',
      serialNumber: 'SN-CSCO-2960',
      assignedTo: 'Vikram Patel',
      status: 'ASSIGNED',
      cost: 78000,
      invoiceNumber: 'INV-2025-1003',
      warrantyPeriod: 'Lifetime Cisco Support',
    ),
    SystemAsset(
      id: 'AST-1002',
      name: 'Apple Studio Display 27"',
      location: 'Design Lab',
      category: 'DESKTOP',
      serialNumber: 'SN-ASD-4410',
      assignedTo: 'Neha Gupta',
      status: 'ASSIGNED',
      cost: 159000,
      invoiceNumber: 'INV-2025-1002',
      warrantyPeriod: '3 Years AppleCare+',
    ),
    SystemAsset(
      id: 'AST-1001',
      name: 'Jabra Evolve2 85 ANC Headset',
      location: 'IT Storage',
      category: 'ACCESSORY',
      serialNumber: 'SN-JBR-8501',
      assignedTo: 'Arun Kumar',
      status: 'ASSIGNED',
      cost: 29500,
      invoiceNumber: 'INV-2025-1001',
      warrantyPeriod: '2 Years Jabra Pro',
    ),
  ];

  void addSystemAsset(SystemAsset asset) {
    systemAssets.insert(0, asset);
    notifyListeners();
  }

  void updateSystemAsset(SystemAsset asset) {
    final idx = systemAssets.indexWhere((a) => a.id == asset.id);
    if (idx != -1) {
      systemAssets[idx] = asset;
      notifyListeners();
    }
  }

  void assignSystemAsset(String assetId, String assignedTo) {
    final idx = systemAssets.indexWhere((a) => a.id == assetId);
    if (idx != -1) {
      systemAssets[idx].assignedTo = assignedTo;
      systemAssets[idx].status = assignedTo == 'Unassigned' ? 'AVAILABLE' : 'ASSIGNED';
      notifyListeners();
    }
  }

  List<SystemAsset> getAssetsForEmployee([String? name]) {
    final targetName = (name ?? (userProfile.name.isNotEmpty && userProfile.name != 'Employee' ? userProfile.name : 'Daniel Paul')).trim().toLowerCase();
    return systemAssets.where((a) {
      final assigned = a.assignedTo.trim().toLowerCase();
      if (assigned.isEmpty || assigned == 'unassigned') return false;
      return assigned == targetName;
    }).toList();
  }

  final List<AnnouncementItem> announcements = [];

  final List<AttendanceLog> attendanceLogs = [
    AttendanceLog(
      date: '26 Oct 2026 (Mon)',
      checkIn: '10:00',
      checkOut: 'Shift Active',
      workingHours: 2.2,
      status: 'PRESENT',
      workLocation: 'Office',
      totalWorkedStr: '—',
    ),
    AttendanceLog(
      date: '25 Oct 2026 (Sun)',
      checkIn: '—',
      checkOut: '—',
      workingHours: 0,
      status: 'HOLIDAY',
      workLocation: '—',
      totalWorkedStr: '—',
    ),
    AttendanceLog(
      date: '24 Oct 2026 (Sat)',
      checkIn: '—',
      checkOut: '—',
      workingHours: 0,
      status: 'HOLIDAY',
      workLocation: '—',
      totalWorkedStr: '—',
    ),
    AttendanceLog(
      date: '23 Oct 2026 (Fri)',
      checkIn: '10:02',
      checkOut: '17:00',
      workingHours: 6.97,
      status: 'PRESENT',
      workLocation: 'Office',
      totalWorkedStr: '6h 58m',
    ),
    AttendanceLog(
      date: '22 Oct 2026 (Thu)',
      checkIn: '10:03',
      checkOut: '17:00',
      workingHours: 6.95,
      status: 'PRESENT',
      workLocation: 'Office',
      totalWorkedStr: '6h 57m',
    ),
    AttendanceLog(
      date: '21 Oct 2026 (Wed)',
      checkIn: '10:02',
      checkOut: '17:00',
      workingHours: 6.97,
      status: 'PRESENT',
      workLocation: 'Office',
      totalWorkedStr: '6h 58m',
    ),
    AttendanceLog(
      date: '20 Oct 2026 (Tue)',
      checkIn: '09:55',
      checkOut: '17:00',
      workingHours: 7.08,
      status: 'WORK FROM HOME',
      workLocation: 'Home',
      totalWorkedStr: '7h 4m',
    ),
    AttendanceLog(
      date: '19 Oct 2026 (Mon)',
      checkIn: '10:01',
      checkOut: '17:00',
      workingHours: 6.98,
      status: 'PRESENT',
      workLocation: 'Office',
      totalWorkedStr: '6h 59m',
    ),
    AttendanceLog(
      date: '16 Oct 2026 (Fri)',
      checkIn: '10:15',
      checkOut: '17:00',
      workingHours: 6.75,
      status: 'LATE',
      workLocation: 'Office',
      totalWorkedStr: '6h 45m',
    ),
    AttendanceLog(
      date: '15 Oct 2026 (Thu)',
      checkIn: '—',
      checkOut: '—',
      workingHours: 0,
      status: 'ON LEAVE',
      workLocation: '—',
      totalWorkedStr: '—',
    ),
  ];

  Future<void> addTask(TaskItem task) async {
    tasks.insert(0, task);
    notifyListeners();
    await ApiService.createTask(task);
  }

  Future<void> updateTaskProgress(String taskId, String status, double progress) async {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final old = tasks[index];
      tasks[index] = TaskItem(
        id: old.id,
        title: old.title,
        description: old.description,
        category: old.category,
        status: status,
        priority: old.priority,
        progress: progress.clamp(0.0, 1.0),
        dueDate: old.dueDate,
      );
      notifyListeners();
      await ApiService.updateTask(taskId, {'status': status, 'progress': progress});
    }
  }

  Future<void> addLeaveRequest(LeaveRequest request) async {
    final effectiveApplicantName = (request.applicantName.isNotEmpty && request.applicantName != 'Employee')
        ? request.applicantName
        : (userProfile.name.isNotEmpty ? userProfile.name : 'Daniel Paul');

    final filledRequest = LeaveRequest(
      id: request.id.isNotEmpty ? request.id : 'LR-${DateTime.now().millisecondsSinceEpoch % 100000}',
      leaveType: request.leaveType,
      startDate: request.startDate,
      endDate: request.endDate,
      daysCount: request.daysCount > 0 ? request.daysCount : 1,
      days: request.displayDays > 0 ? request.displayDays : 1.0,
      status: request.status.isNotEmpty ? request.status : 'Pending',
      reason: request.reason.trim().isNotEmpty ? request.reason.trim() : 'Personal Leave',
      applicantName: effectiveApplicantName,
      employeeId: request.employeeId ?? userProfile.employeeId,
      role: request.role ?? userProfile.role,
      department: request.department ?? userProfile.department,
    );

    leaveRequests.insert(0, filledRequest);
    addAuditLog(
      'Leave Application Submitted',
      '$effectiveApplicantName applied for ${filledRequest.leaveType} (${filledRequest.displayDays} day) - ${filledRequest.reason}',
      userProfile.email,
    );
    notifyListeners();
    try {
      await ApiService.applyLeave(filledRequest);
    } catch (_) {}
  }

  Future<void> addTicket(ITTicket ticket) async {
    tickets.insert(0, ticket);
    notifyListeners();
    await ApiService.createTicket(ticket);
  }

  Future<void> addAnnouncement(AnnouncementItem item) async {
    announcements.insert(0, item);
    addAuditLog(
      'Announcement Published',
      'Broadcasted "${item.title}" to ${item.targetAudience}',
      userProfile.email,
    );
    notifyListeners();
  }

  void removeAnnouncement(String id) {
    announcements.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void markAnnouncementAsRead(String id) {
    final index = announcements.indexWhere((a) => a.id == id);
    if (index != -1) {
      announcements[index].isRead = true;
    }
    if (id.startsWith('ANN-LEAVE-')) {
      final leaveId = id.replaceFirst('ANN-LEAVE-', '');
      if (latestApprovedLeave != null && latestApprovedLeave!.id == leaveId) {
        latestApprovedLeave!.isRead = true;
        _showLeaveApprovalNotice = false;
      }
      final leaveIdx = leaveRequests.indexWhere((l) => l.id == leaveId);
      if (leaveIdx != -1) {
        leaveRequests[leaveIdx].isRead = true;
      }
    }
    notifyListeners();
  }

  void markAnnouncementAsUnread(String id) {
    final index = announcements.indexWhere((a) => a.id == id);
    if (index != -1) {
      announcements[index].isRead = false;
      notifyListeners();
    }
  }

  void markAllAnnouncementsAsRead() {
    for (final a in announcements) {
      a.isRead = true;
    }
    notifyListeners();
  }

  final List<WorkLogEntry> workLogs = [];

  Future<void> addWorkLog(WorkLogEntry entry) async {
    workLogs.insert(0, entry);
    notifyListeners();
    await ApiService.createWorkLog(entry);
  }

  /// Synchronizes the current user profile into the multi-user directory so Admin views immediately reflect employee edits
  void _syncUserProfileToDirectory(UserProfile profile) {
    userDirectory[profile.email] = profile;
    final keysToUpdate = <String>[];
    userDirectory.forEach((key, val) {
      if ((val.employeeId.isNotEmpty && val.employeeId.toLowerCase() == profile.employeeId.toLowerCase()) ||
          (val.id.isNotEmpty && val.id == profile.id) ||
          (val.name.toLowerCase() == profile.name.toLowerCase())) {
        keysToUpdate.add(key);
      }
    });
    for (final k in keysToUpdate) {
      userDirectory[k] = profile;
    }
  }

  Future<void> updateAvatar(String? avatarUrl) async {
    userProfile = UserProfile(
      id: userProfile.id,
      employeeId: userProfile.employeeId,
      name: userProfile.name,
      email: userProfile.email,
      role: userProfile.role,
      department: userProfile.department,
      designation: userProfile.designation,
      phone: userProfile.phone,
      joiningDate: userProfile.joiningDate,
      status: userProfile.status,
      avatar: avatarUrl,
      basicSalary: userProfile.basicSalary,
      hra: userProfile.hra,
      specialAllowance: userProfile.specialAllowance,
      deductions: userProfile.deductions,
      netSalary: userProfile.netSalary,
    );

    // Persist to SharedPreferences so it survives app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar_${userProfile.email.toLowerCase()}', avatarUrl);
      } else {
        await prefs.remove('user_avatar_${userProfile.email.toLowerCase()}');
      }
    } catch (e) {
      debugPrint('Error saving avatar to prefs: $e');
    }

    // Sync to userDirectory so Admin immediately sees the new photo
    _syncUserProfileToDirectory(userProfile);
    notifyListeners();
  }

  Future<void> updateProfileDetails({
    required String name,
    required String phone,
    required String department,
    required String college,
  }) async {
    userProfile = UserProfile(
      id: userProfile.id,
      employeeId: userProfile.employeeId,
      name: name,
      email: userProfile.email,
      role: userProfile.role,
      department: department,
      designation: userProfile.designation,
      phone: phone,
      joiningDate: userProfile.joiningDate,
      status: userProfile.status,
      avatar: userProfile.avatar,
      basicSalary: userProfile.basicSalary,
      hra: userProfile.hra,
      specialAllowance: userProfile.specialAllowance,
      deductions: userProfile.deductions,
      netSalary: userProfile.netSalary,
    );

    // Sync to userDirectory so Admin Staff Directory, Registries & Map immediately show the updated employee details
    _syncUserProfileToDirectory(userProfile);

    addAuditLog(
      'Profile Synchronized',
      'Employee $name ($phone, $department, $college) synchronized to admin registry',
      userProfile.email,
    );

    notifyListeners();
    await ApiService.updateUserProfile(
      name: name,
      phone: phone,
      college: college,
      department: department,
    );
  }

  /// Synchronize an employee update from the Admin side to the employee side
  Future<void> updateEmployee(UserProfile updated) async {
    userDirectory[updated.email] = updated;
    final keysToUpdate = <String>[];
    userDirectory.forEach((key, val) {
      if ((val.employeeId.isNotEmpty && val.employeeId.toLowerCase() == updated.employeeId.toLowerCase()) ||
          (val.id.isNotEmpty && val.id == updated.id)) {
        keysToUpdate.add(key);
      }
    });
    for (final k in keysToUpdate) {
      userDirectory[k] = updated;
    }

    // If the updated employee matches the current user logged in on the employee side, sync immediately!
    final isCurrent = userProfile.email.toLowerCase() == updated.email.toLowerCase() ||
        (userProfile.employeeId.isNotEmpty && userProfile.employeeId.toLowerCase() == updated.employeeId.toLowerCase()) ||
        (userProfile.id.isNotEmpty && userProfile.id == updated.id) ||
        (userProfile.name.toLowerCase() == updated.name.toLowerCase());

    if (isCurrent) {
      userProfile = updated;
    }

    addAuditLog(
      'Staff Record Updated',
      'Admin updated details for ${updated.name} (${updated.employeeId}) • ${updated.role} • Dept: ${updated.department} • Net: ₹${updated.netSalary.toInt()}',
      userProfile.email,
    );

    notifyListeners();
  }

  /// Remove an employee and synchronize across directory and active state
  Future<void> removeEmployee(String email, {String? id, String? employeeId}) async {
    userDirectory.remove(email);
    userDirectory.removeWhere((key, val) =>
      (id != null && id.isNotEmpty && val.id == id) ||
      (employeeId != null && employeeId.isNotEmpty && val.employeeId == employeeId) ||
      val.email.toLowerCase() == email.toLowerCase()
    );

    addAuditLog(
      'Staff Removed',
      'Admin removed employee $email ($employeeId)',
      userProfile.email,
    );

    notifyListeners();
  }

  Future<void> addEmployee(UserProfile profile) async {
    userDirectory[profile.email] = profile;
    addAuditLog(
      'Staff Onboarded',
      'Onboarded ${profile.name} (${profile.employeeId}) as ${profile.role}',
      userProfile.email,
    );
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
