import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jornadafacil/core/constants/app_constants.dart';
import 'package:jornadafacil/core/providers/app_state.dart';
import 'package:jornadafacil/core/providers/timer_notifier.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/features/auth/presentation/authentication_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppState _appState;
  late TimerNotifier _timerNotifier;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _timerNotifier = TimerNotifier()..init();
    _appState.init(); // fire and forget, não bloqueia a UI
  }

  @override
  void dispose() {
    _appState.dispose();
    _timerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_appState, _timerNotifier]),
      builder: (context, child) => _AppScope(
        appState: _appState,
        timerNotifier: _timerNotifier,
        child: MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          locale: const Locale(AppConstants.defaultLanguage, AppConstants.defaultCountry),
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthenticationScreen(),
        ),
      ),
    );
  }
}

class _AppScope extends InheritedWidget {
  final AppState appState;
  final TimerNotifier timerNotifier;

  const _AppScope({
    required this.appState,
    required this.timerNotifier,
    required super.child,
  });

  static _AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(_AppScope oldWidget) {
    return appState != oldWidget.appState ||
        timerNotifier != oldWidget.timerNotifier;
  }
}

// Export para uso nos widgets
extension AppContext on BuildContext {
  AppState get appState => _AppScope.of(this).appState;
  TimerNotifier get timerNotifier => _AppScope.of(this).timerNotifier;
}
