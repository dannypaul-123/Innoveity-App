import '../core/network/api_client.dart';
import '../models/payslip.dart';

class PayslipService {
  final ApiClient _api;
  PayslipService(this._api);
  Future<List<Payslip>> list() =>
      _api.request(() => _api.dio.get('/payslips'), (d) {
        final list = d is Map ? (d['data'] ?? d['payslips'] ?? []) : d;
        return (list as List)
            .map((x) => Payslip.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
      });
  Future<Payslip> get(String id) => _api.request(
    () => _api.dio.get('/payslips/$id'),
    (d) => Payslip.fromJson(
      Map<String, dynamic>.from(
        d is Map && d['payslip'] != null ? d['payslip'] : d,
      ),
    ),
  );
  Future<void> email(String id) =>
      _api.request(() => _api.dio.post('/payslips/$id/email'), (_) {});
}
