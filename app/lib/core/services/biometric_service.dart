import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();

  factory BiometricService() => _instance;

  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _auth.canCheckBiometrics;
      final isDeviceCredentialSupported = await _auth.isDeviceSupported();


      return isDeviceSupported || isDeviceCredentialSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final isBiometricAvailable = await this.isBiometricAvailable();

      if (!isBiometricAvailable) {
        return false;
      }

      final isAuthenticated = await _auth.authenticate(
        localizedReason: 'Use sua biometria para validar o registro',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
}
