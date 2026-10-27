import '../core/network/api_client.dart';
import '../models/attendance.dart';

class AttendanceService {
  final ApiClient _api;
  AttendanceService(this._api);
  Future<Attendance?> status() =>
      _api.request(() => _api.dio.get('/attendance/status'), (d) {
        if (d == null) return null;
        final j = Map<String, dynamic>.from(
          d is Map && d['attendance'] != null ? d['attendance'] : d,
        );
        return Attendance.fromJson(j);
      });
  Future<Attendance> clockIn({Map<String, dynamic>? data}) => _api.request(
    () => _api.dio.post('/attendance/clock-in', data: data),
    (d) => Attendance.fromJson(
      Map<String, dynamic>.from(
        d is Map && d['attendance'] != null ? d['attendance'] : d,
      ),
    ),
  );
  Future<Attendance> clockOut({Map<String, dynamic>? data}) => _api.request(
    () => _api.dio.post('/attendance/clock-out', data: data),
    (d) => Attendance.fromJson(
      Map<String, dynamic>.from(
        d is Map && d['attendance'] != null ? d['attendance'] : d,
      ),
    ),
  );
  Future<List<Attendance>> history() => _list('/attendance/history');
  Future<List<Attendance>> logs() => _list('/attendance/logs');
  Future<List<Attendance>> _list(String path) => _api.request(
    () => _api.dio.get(path),
    (d) {
      final list = d is Map ? (d['data'] ?? d['attendance'] ?? []) : d;
      return (list as List)
          .map((x) => Attendance.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    },
  );
}
