import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:jornadafacil/core/config/app_config.dart';
import 'package:jornadafacil/core/services/auth_service.dart';
import 'package:jornadafacil/core/services/biometric_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/features/auth/presentation/login_screen.dart';
import 'package:jornadafacil/shared/widgets/layouts/main_scaffold.dart';

/// Orquestra o fluxo de autenticação em duas camadas:
/// 1. Identidade de servidor: restaura a sessão persistida ou pede login.
/// 2. Presença local: biometria do aparelho (pulada em development e na web).
class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

enum _AuthStage { restoring, login, biometric, done }

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _authService = AuthService();
  final _biometricService = BiometricService();

  _AuthStage _stage = _AuthStage.restoring;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored = await _authService.restoreSession();
    if (!mounted) return;

    if (restored) {
      _enterBiometricStage();
    } else {
      setState(() => _stage = _AuthStage.login);
    }
  }

  void _enterBiometricStage() {
    // Biometria só existe no app nativo (mobile). Em development e na web não
    // há biometria do aparelho — na web o login+senha já é a autenticação —,
    // então vai direto pra tela principal em vez de travar no gate.
    if (AppEnvironment.isDevelopment || kIsWeb) {
      setState(() => _stage = _AuthStage.done);
      return;
    }

    setState(() => _stage = _AuthStage.biometric);
    _attemptBiometricAuth();
  }

  Future<void> _attemptBiometricAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final isAuthenticated = await _biometricService.authenticate();
    if (!mounted) return;

    if (isAuthenticated) {
      setState(() {
        _stage = _AuthStage.done;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha na autenticação. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _AuthStage.restoring:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      case _AuthStage.login:
        return LoginScreen(onSuccess: _enterBiometricStage);
      case _AuthStage.biometric:
        return _buildBiometricGate();
      case _AuthStage.done:
        return const MainScaffold();
    }
  }

  Widget _buildBiometricGate() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Jornada Fácil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use sua biometria para continuar',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else ...[
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton.icon(
                onPressed: _attemptBiometricAuth,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
