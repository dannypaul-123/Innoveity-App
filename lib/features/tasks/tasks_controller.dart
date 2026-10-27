import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/crm_task.dart';
import '../../services/task_service.dart';

class TasksController extends ChangeNotifier {
  final TaskService _service;
  TasksController(this._service);
  List<CrmTask> tasks = [];
  bool loading = false;
  String? error;
  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      tasks = await _service.list();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String id, String status) async {
    await _service.updateStatus(id, status);
    await refresh();
  }
}
