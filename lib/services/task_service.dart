import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/crm_task.dart';

class TaskService {
  final ApiClient _api;
  TaskService(this._api);
  Future<List<CrmTask>> list() =>
      _api.request(() => _api.dio.get('/tasks'), (d) {
        final list = d is Map ? (d['data'] ?? d['tasks'] ?? []) : d;
        return (list as List)
            .map((x) => CrmTask.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
      });
  Future<CrmTask> get(String id) => _api.request(
    () => _api.dio.get('/tasks/$id'),
    (d) => CrmTask.fromJson(
      Map<String, dynamic>.from(d is Map && d['task'] != null ? d['task'] : d),
    ),
  );
  Future<CrmTask> updateStatus(String id, String status) => _api.request(
    () => _api.dio.put('/tasks/$id/status', data: {'status': status}),
    (d) => CrmTask.fromJson(
      Map<String, dynamic>.from(d is Map && d['task'] != null ? d['task'] : d),
    ),
  );
  Future<void> submit(String id, List<File> files) => _api.request(
    () => _api.dio.post(
      '/tasks/$id/submit',
      data: FormData.fromMap({
        'files': files.map((f) => MultipartFile.fromFileSync(f.path)).toList(),
      }),
    ),
    (_) {},
  );
  Future<void> comment(String id, String comment) => _api.request(
    () => _api.dio.post('/tasks/$id/comment', data: {'comment': comment}),
    (_) {},
  );
}
