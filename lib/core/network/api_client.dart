import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final TokenStorage tokenStorage;
  final Dio dio;
  VoidCallback? onSessionExpired;
  bool _refreshing = false;
  Completer<String?>? _refreshCompleter;

  ApiClient({required this.tokenStorage, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: {'Accept': 'application/json'},
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readAccessToken();
          if (token != null &&
              !options.path.endsWith('/login') &&
              !options.path.endsWith('/refresh'))
            options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.extra['retried'] == true ||
              request.path.endsWith('/refresh'))
            return handler.next(error);
          final token = await _refreshToken();
          if (token == null) {
            await tokenStorage.clear();
            onSessionExpired?.call();
            return handler.next(error);
          }
          request.extra['retried'] = true;
          request.headers['Authorization'] = 'Bearer $token';
          try {
            return handler.resolve(await this.dio.fetch(request));
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }

  Future<String?> _refreshToken() async {
    if (_refreshing) return _refreshCompleter!.future;
    _refreshing = true;
    _refreshCompleter = Completer<String?>();
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null) return null;
      final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
          .post('/refresh', data: {'refreshToken': refreshToken});
      final data = _map(response.data);
      final accessToken =
          data['token'] as String? ?? data['accessToken'] as String?;
      if (accessToken != null)
        await tokenStorage.save(
          accessToken: accessToken,
          refreshToken: data['refreshToken'] as String? ?? refreshToken,
        );
      return accessToken;
    } catch (_) {
      return null;
    } finally {
      _refreshCompleter!.complete(_refreshing ? null : null);
      _refreshing = false;
    }
  }

  Future<T> request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic) parse,
  ) async {
    try {
      return parse((await call()).data);
    } on DioException catch (e) {
      throw ApiException(_message(e), statusCode: e.response?.statusCode);
    }
  }

  String _message(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null)
      return body['message'].toString();
    return e.type == DioExceptionType.connectionError
        ? 'Network connection unavailable.'
        : 'Unable to complete the request.';
  }

  static Map<String, dynamic> _map(dynamic data) => data is Map<String, dynamic>
      ? data
      : Map<String, dynamic>.from(data as Map);
}

typedef VoidCallback = void Function();
