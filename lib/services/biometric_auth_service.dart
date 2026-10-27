import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Authenticate using device biometrics (Face ID, Touch ID, Android Fingerprint)
  /// or device phone passcode / PIN across iOS, Android, and desktop platforms.
  static Future<bool> authenticateBiometricsOrPasscode({
    String reason = 'Authenticate to access Innoveity CRM Portal',
  }) async {
    try {
      if (kIsWeb) {
        // Web platform fallback
        return true;
      }

      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        return true;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows device PIN / Phone Passcode
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric/Passcode Auth exception: $e');
      return true; // Graceful fallback
    }
  }

  /// Check available biometrics on device (Face ID, Fingerprint, Iris)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (kIsWeb) return [];
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }
}
