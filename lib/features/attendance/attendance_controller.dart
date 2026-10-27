import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceService _service;
  AttendanceController(this._service);
  Attendance? status;
  List<Attendance> history = [];
  bool loading = false;
  String? error;
  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      status = await _service.status();
      history = await _service.history();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> clockIn(Map<String, dynamic> data) async {
    status = await _service.clockIn(data: data);
    await refresh();
  }

  Future<void> clockOut(Map<String, dynamic> data) async {
    status = await _service.clockOut(data: data);
    await refresh();
  }
}
