import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../utils/storage.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Kiểm tra thiết bị có phần cứng sinh trắc học và đã cài đặt hay chưa
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Lấy danh sách các loại sinh trắc học hỗ trợ (Vân tay / Face ID / Mống mắt)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Get available biometrics error: $e');
      return [];
    }
  }

  /// Tên loại sinh trắc học thân thiện (Vân tay hoặc Face ID)
  static Future<String> getBiometricDisplayName() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID / Khuôn mặt';
    } else if (biometrics.contains(BiometricType.fingerprint) || biometrics.contains(BiometricType.strong)) {
      return 'Vân tay (Fingerprint)';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Mống mắt (Iris)';
    }
    return 'Sinh trắc học';
  }

  /// Thực hiện quét vân tay / Face ID
  static Future<bool> authenticate({String reason = 'Xác thực sinh trắc học để đăng nhập Enigma'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Cho phép dùng vân tay/Face ID và fallback PIN máy ảo
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        debugPrint('Biometric not available');
      } else if (e.code == auth_error.notEnrolled) {
        debugPrint('No biometrics enrolled on device');
      } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        debugPrint('Biometric temporarily locked');
      } else {
        debugPrint('Biometric auth error: ');
      }
      return false;
    } catch (e) {
      debugPrint('Biometric unknown error: ');
      return false;
    }
  }

  /// Kiểm tra xem người dùng đã bật tính năng Đăng nhập sinh trắc học trong Cài đặt chưa
  static bool get isBiometricEnabled => StorageUtil.isBiometricEnabled;

  /// Bật / Tắt sinh trắc học
  static Future<void> setBiometricEnabled(bool enabled) async {
    await StorageUtil.setBiometricEnabled(enabled);
  }
}
