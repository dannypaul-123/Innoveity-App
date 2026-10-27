import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/payslip.dart';
import '../../services/payslip_service.dart';

class PayslipsController extends ChangeNotifier {
  final PayslipService _service;
  PayslipsController(this._service);
  List<Payslip> payslips = [];
  bool loading = false;
  String? error;
  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      payslips = await _service.list();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
