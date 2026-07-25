import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/features/dashboard/presentation/dashboard_page.dart';
import 'package:jornadafacil/features/register/presentation/register_page.dart';
import 'package:patrol/patrol.dart';

/// Grupo ANDROID (Patrol). Dirige a UI real e lida com o diálogo NATIVO de
/// permissão de localização — o que só o Patrol faz e a suíte de serviço não
/// alcança. Fluxo: login como admin -> concede a permissão nativa -> cai no
/// Dashboard (admin não bate ponto, então não vê a aba Registro).
///
/// Requer emulador + API no ar e semeada. Rode com:
///   patrol test -t integration_test/android \
///     --dart-define-from-file=config/dev.json
/// (dev.json já aponta a API para http://10.0.2.2:3000 e pula a biometria).
void main() {
  patrolTest('admin faz login e cai no Dashboard', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    // AppState.init() já pede localização ao subir; concede se o diálogo estiver
    // na tela antes mesmo do login.
    await _grantLocationIfAsked($);

    await $(TextFormField).at(0).enterText('admin');
    await $(TextFormField).at(1).enterText('Senha123');
    await $('Entrar').tap();

    // MainScaffold pede a permissão ao montar, após o login — este é o ponto
    // que exercita o diferencial nativo do Patrol.
    await _grantLocationIfAsked($);
    await $.pumpAndSettle();

    expect($(DashboardPage), findsOneWidget);
    expect($(RegisterPage), findsNothing);
  });
}

Future<void> _grantLocationIfAsked(PatrolIntegrationTester $) async {
  final mobile = $.platform.mobile;
  if (await mobile.isPermissionDialogVisible(
    timeout: const Duration(seconds: 5),
  )) {
    await mobile.grantPermissionWhenInUse();
  }
}
