import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAccountCredential {
  final String email;
  final String password;
  final String? label;
  final DateTime savedAt;

  SavedAccountCredential({
    required this.email,
    required this.password,
    this.label,
    required this.savedAt,
  });

  factory SavedAccountCredential.fromJson(Map<String, dynamic> json) {
    return SavedAccountCredential(
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      label: json['label']?.toString(),
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (label != null) 'label': label,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _savedAccountsKey = 'saved_user_accounts_passwords';
  static const _savedUserLoginKey = 'saved_user_login';
  static const _hasInitializedKey = 'has_initialized_saved_accounts_vault';

  static final Map<String, String> _memoryCache = {};

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final FlutterSecureStorage _storage;

  const TokenStorage([
    this._storage = const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    ),
  ]);

  static List<SavedAccountCredential> get defaultSeedAccounts => [
    SavedAccountCredential(
      email: 'antorajan501@gmail.com',
      password: '123456',
      label: 'Employee Portal',
      savedAt: DateTime(2026, 1, 1),
    ),
    SavedAccountCredential(
      email: 'admin@enterprise-crm.com',
      password: 'Admin123!',
      label: 'System Admin',
      savedAt: DateTime(2026, 1, 1),
    ),
    SavedAccountCredential(
      email: 'danielpaul@enterprise-crm.com',
      password: '123456',
      label: 'Engineering Intern',
      savedAt: DateTime(2026, 1, 1),
    ),
  ];

  Future<File?> _getAccountsFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/innoveity_saved_credentials.json');
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  // --- TOKEN METHODS ---
  Future<String?> readAccessToken() async {
    if (_memoryCache.containsKey(_accessKey)) return _memoryCache[_accessKey];
    try {
      final token = await _storage.read(key: _accessKey);
      if (token != null) {
        _memoryCache[_accessKey] = token;
        return token;
      }
    } catch (_) {}
    try {
      final prefs = await _getPrefs();
      final token = prefs?.getString(_accessKey);
      if (token != null) {
        _memoryCache[_accessKey] = token;
        return token;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> readRefreshToken() async {
    if (_memoryCache.containsKey(_refreshKey)) return _memoryCache[_refreshKey];
    try {
      final token = await _storage.read(key: _refreshKey);
      if (token != null) {
        _memoryCache[_refreshKey] = token;
        return token;
      }
    } catch (_) {}
    try {
      final prefs = await _getPrefs();
      final token = prefs?.getString(_refreshKey);
      if (token != null) {
        _memoryCache[_refreshKey] = token;
        return token;
      }
    } catch (_) {}
    return null;
  }

  Future<void> save({required String accessToken, String? refreshToken}) async {
    _memoryCache[_accessKey] = accessToken;
    try {
      await _storage.write(key: _accessKey, value: accessToken);
    } catch (_) {}
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_accessKey, accessToken);
    } catch (_) {}

    if (refreshToken != null) {
      _memoryCache[_refreshKey] = refreshToken;
      try {
        await _storage.write(key: _refreshKey, value: refreshToken);
      } catch (_) {}
      try {
        final prefs = await _getPrefs();
        await prefs?.setString(_refreshKey, refreshToken);
      } catch (_) {}
    }
  }

  // --- LAST USER LOGIN EMAIL ---
  Future<String?> readSavedUserLogin() async {
    if (_memoryCache.containsKey(_savedUserLoginKey)) {
      final mem = _memoryCache[_savedUserLoginKey];
      if (mem != null && mem.isNotEmpty) return mem;
    }
    try {
      final email = await _storage.read(key: _savedUserLoginKey);
      if (email != null && email.isNotEmpty) {
        _memoryCache[_savedUserLoginKey] = email;
        return email;
      }
    } catch (_) {}
    try {
      final prefs = await _getPrefs();
      final email = prefs?.getString(_savedUserLoginKey);
      if (email != null && email.isNotEmpty) {
        _memoryCache[_savedUserLoginKey] = email;
        return email;
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveUserLogin(String email) async {
    final clean = email.trim();
    _memoryCache[_savedUserLoginKey] = clean;
    try {
      await _storage.write(key: _savedUserLoginKey, value: clean);
    } catch (_) {}
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_savedUserLoginKey, clean);
    } catch (_) {}
  }

  // --- MULTI-LAYER SAVED ACCOUNTS PERSISTENCE ---
  Future<void> _persistAccountsRaw(String jsonString) async {
    _memoryCache[_savedAccountsKey] = jsonString;

    // 1. SharedPreferences (survives app kill, APK runs, device restarts)
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_savedAccountsKey, jsonString);
      await prefs?.setBool(_hasInitializedKey, true);
    } catch (e) {
      debugPrint('SharedPreferences persist error: $e');
    }

    // 2. Direct File Vault in App Documents Directory
    try {
      final file = await _getAccountsFile();
      if (file != null) {
        await file.writeAsString(jsonString, flush: true);
      }
    } catch (e) {
      debugPrint('File vault persist error: $e');
    }

    // 3. Hardware / Keystore Encrypted Secure Storage
    try {
      await _storage.write(key: _savedAccountsKey, value: jsonString);
    } catch (e) {
      debugPrint('SecureStorage persist error: $e');
    }
  }

  Future<String?> _readAccountsRaw() async {
    // 1. Memory Cache
    if (_memoryCache[_savedAccountsKey] != null &&
        _memoryCache[_savedAccountsKey]!.isNotEmpty) {
      return _memoryCache[_savedAccountsKey];
    }

    // 2. FlutterSecureStorage
    try {
      final raw = await _storage.read(key: _savedAccountsKey);
      if (raw != null && raw.isNotEmpty && raw != '[]') {
        _memoryCache[_savedAccountsKey] = raw;
        return raw;
      }
    } catch (e) {
      debugPrint('SecureStorage read warning: $e');
    }

    // 3. SharedPreferences
    try {
      final prefs = await _getPrefs();
      final raw = prefs?.getString(_savedAccountsKey);
      if (raw != null && raw.isNotEmpty && raw != '[]') {
        _memoryCache[_savedAccountsKey] = raw;
        // heal SecureStorage in background
        _storage.write(key: _savedAccountsKey, value: raw).catchError((_) {});
        return raw;
      }
    } catch (e) {
      debugPrint('SharedPreferences read warning: $e');
    }

    // 4. Local File Vault
    try {
      final file = await _getAccountsFile();
      if (file != null && await file.exists()) {
        final raw = await file.readAsString();
        if (raw.isNotEmpty && raw != '[]') {
          _memoryCache[_savedAccountsKey] = raw;
          // heal other layers in background
          _persistAccountsRaw(raw).catchError((_) {});
          return raw;
        }
      }
    } catch (e) {
      debugPrint('File vault read warning: $e');
    }

    return null;
  }

  Future<List<SavedAccountCredential>> readSavedAccounts() async {
    try {
      final raw = await _readAccountsRaw();
      if (raw != null && raw.isNotEmpty && raw != '[]') {
        final List decoded = jsonDecode(raw);
        final list = decoded
            .map((e) => SavedAccountCredential.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((e) => e.email.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }

      // Check if user has explicitly cleared accounts before
      final prefs = await _getPrefs();
      final hasInit = prefs?.getBool(_hasInitializedKey) ?? false;
      if (!hasInit) {
        // Cold start on fresh install: populate default enterprise accounts so 1-tap login works immediately
        final seeds = defaultSeedAccounts;
        final encoded = jsonEncode(seeds.map((s) => s.toJson()).toList());
        await _persistAccountsRaw(encoded);
        await saveUserLogin(seeds.first.email);
        return seeds;
      }

      return [];
    } catch (e) {
      debugPrint('readSavedAccounts error: $e');
      return defaultSeedAccounts;
    }
  }

  Future<void> saveAccountCredential({
    required String email,
    required String password,
    String? label,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();
      if (cleanEmail.isEmpty || cleanPassword.isEmpty) return;

      final list = await readSavedAccounts();
      list.removeWhere(
        (c) => c.email.trim().toLowerCase() == cleanEmail.toLowerCase(),
      );
      list.insert(
        0,
        SavedAccountCredential(
          email: cleanEmail,
          password: cleanPassword,
          label: label,
          savedAt: DateTime.now(),
        ),
      );

      final encoded = jsonEncode(list.map((c) => c.toJson()).toList());
      await _persistAccountsRaw(encoded);
      await saveUserLogin(cleanEmail);
    } catch (e) {
      debugPrint('saveAccountCredential error: $e');
    }
  }

  Future<void> deleteSavedAccount(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final list = await readSavedAccounts();
      list.removeWhere((c) => c.email.trim().toLowerCase() == cleanEmail);

      final encoded = jsonEncode(list.map((c) => c.toJson()).toList());
      await _persistAccountsRaw(encoded);

      // If last saved email was deleted, update to next available or clear
      final currentLast = await readSavedUserLogin();
      if (currentLast != null && currentLast.toLowerCase() == cleanEmail) {
        if (list.isNotEmpty) {
          await saveUserLogin(list.first.email);
        } else {
          _memoryCache.remove(_savedUserLoginKey);
          try {
            await _storage.delete(key: _savedUserLoginKey);
          } catch (_) {}
          try {
            final prefs = await _getPrefs();
            await prefs?.remove(_savedUserLoginKey);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('deleteSavedAccount error: $e');
    }
  }

  Future<void> clearSavedAccounts() async {
    _memoryCache.remove(_savedAccountsKey);
    _memoryCache.remove(_savedUserLoginKey);
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_savedAccountsKey, '[]');
      await prefs?.remove(_savedUserLoginKey);
      await prefs?.setBool(_hasInitializedKey, true);
    } catch (_) {}
    try {
      final file = await _getAccountsFile();
      if (file != null && await file.exists()) {
        await file.writeAsString('[]', flush: true);
      }
    } catch (_) {}
    try {
      await _storage.write(key: _savedAccountsKey, value: '[]');
      await _storage.delete(key: _savedUserLoginKey);
    } catch (_) {}
  }

  /// Clears only session tokens (access_token and refresh_token) on sign out.
  /// IMPORTANT: Saved account credentials and passwords are strictly preserved!
  Future<void> clear() async {
    _memoryCache.remove(_accessKey);
    _memoryCache.remove(_refreshKey);
    try {
      await _storage.delete(key: _accessKey);
    } catch (_) {}
    try {
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
    try {
      final prefs = await _getPrefs();
      await prefs?.remove(_accessKey);
      await prefs?.remove(_refreshKey);
    } catch (_) {}
  }
}
