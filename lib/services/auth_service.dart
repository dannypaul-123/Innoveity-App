import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';

class AuthSession {
  final String token;
  final String? refreshToken;
  final User user;
  const AuthSession({
    required this.token,
    this.refreshToken,
    required this.user,
  });
}

class AuthService {
  final ApiClient _api;
  final TokenStorage _storage;
  AuthService(this._api, this._storage);
  Future<AuthSession> login(String email, String password) async {
    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password, 'login': email, 'employeeId': email},
      );
      final json = Map<String, dynamic>.from(response.data as Map);
      final token = (json['token'] ?? json['accessToken'])?.toString();
      if (token == null || json['user'] == null) {
        throw const ApiException(
          'The server returned an invalid login response.',
        );
      }
      final refresh = json['refreshToken']?.toString();
      await _storage.save(accessToken: token, refreshToken: refresh);
      return AuthSession(
        token: token,
        refreshToken: refresh,
        user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data is Map
            ? (e.response!.data['message'] ?? 'Unable to sign in.').toString()
            : 'Unable to sign in.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<User> me() => _api.request(
    () => _api.dio.get('/auth/profile'),
    (d) => User.fromJson(
      Map<String, dynamic>.from(d is Map && d['user'] != null ? d['user'] : d),
    ),
  );
  Future<void> logout() async {
    try {
      await _api.dio.post('/logout');
    } finally {
      await _storage.clear();
    }
  }

  Future<void> forgotPassword(String email) => _api.request(
    () => _api.dio.post('/forgot-password', data: {'email': email}),
    (_) {},
  );
  Future<void> verifyResetOtp(String email, String otp) => _api.request(
    () =>
        _api.dio.post('/verify-reset-otp', data: {'email': email, 'otp': otp}),
    (_) {},
  );
  Future<void> resetPassword(String email, String otp, String password) =>
      _api.request(
        () => _api.dio.post(
          '/reset-password',
          data: {'email': email, 'otp': otp, 'password': password},
        ),
        (_) {},
      );
}
