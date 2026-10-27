import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _auth;
  final TokenStorage _storage;
  AuthController(this._auth, this._storage);
  bool isLoading = false;
  User? user;
  String? error;
  bool get isAuthenticated => user != null;
  Future<void> restoreSession() async {
    if (await _storage.readAccessToken() == null) return;
    try {
      user = await _auth.me();
    } catch (_) {
      await _storage.clear();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = (await _auth.login(email, password)).user;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    user = null;
    notifyListeners();
  }

  void sessionExpired() {
    user = null;
    error = 'Your session expired. Please sign in again.';
    notifyListeners();
  }
}
