import 'package:flutter/material.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/core/models/rbac.dart' as rbac;
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/core/services/location_service.dart';
import 'package:jornadafacil/shared/widgets/layouts/app_bar_custom.dart';
import 'package:jornadafacil/shared/widgets/layouts/user_drawer.dart';
import 'package:jornadafacil/features/admin/presentation/weekly_review_page.dart';
import 'package:jornadafacil/features/history/presentation/history_page.dart';
import 'package:jornadafacil/features/register/presentation/register_page.dart';

class _Tab {
  final Widget page;
  final IconData icon;
  final String label;
  final String permission;

  /// Aba que só faz sentido para quem bate ponto (Registro). Escondida de
  /// admins e afins, cujo usuário tem `tracksJourney == false`.
  final bool requiresTracking;

  _Tab({
    required this.page,
    required this.icon,
    required this.label,
    required this.permission,
    this.requiresTracking = false,
  });
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final GlobalKey<ScaffoldState> _scaffoldKey;

  // Abas gateadas por permissão + regra de ponto. Quem bate ponto vê
  // Registro/Histórico; o admin (users:view, não bate ponto) cai direto na
  // Revisão da equipe, que é a primeira aba que sobra pra ele.
  final List<_Tab> _allTabs = [
    _Tab(
      page: const WeeklyReviewPage(),
      icon: Icons.fact_check_outlined,
      label: 'Revisão',
      permission: '${rbac.Resources.users}:${rbac.Actions.view}',
    ),
    _Tab(
      page: const RegisterPage(),
      icon: Icons.access_time,
      label: 'Registro',
      permission: '${rbac.Resources.journey}:${rbac.Actions.view}',
      requiresTracking: true,
    ),
    _Tab(
      page: const HistoryPage(),
      icon: Icons.history,
      label: 'Histórico',
      permission: '${rbac.Resources.history}:${rbac.Actions.view}',
      // Histórico é a jornada do próprio usuário: só para quem bate ponto.
      // Assim o admin fica só com a Revisão (1 aba) e o rodapé some.
      requiresTracking: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission =
        await LocationService().checkAndRequestPermission();

    if (!hasPermission && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão de Localização'),
        content: const Text(
          'Para usar a localização, abra as configurações do app e conceda a permissão de localização.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }  

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.appState,
      builder: (context, _) {
        final user = context.appState.currentUser;
        final allowedTabs = _allTabs
            .where((tab) => user.can(tab.permission))
            // Quem não bate ponto (admin e afins) não vê a aba de Registro.
            .where((tab) => user.tracksJourney || !tab.requiresTracking)
            .toList();

        // Se o índice atual não é válido (tab foi removida), reset para 0
        if (_currentIndex >= allowedTabs.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentIndex = 0;
            });
          });
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBarCustom(
            onProfilePressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          endDrawer: UserDrawer(user: user),
          body: IndexedStack(
            index: _currentIndex,
            children: allowedTabs.map((tab) => tab.page).toList(),
          ),
          bottomNavigationBar: allowedTabs.length >= 2
              ? SafeArea(
                  // Respiro inferior garantido para a barra não colar na base
                  // (gestos do Android têm inset pequeno).
                  minimum: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Material(
                    color: AppColors.surface,
                    elevation: 6,
                    shadowColor: AppColors.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    clipBehavior: Clip.antiAlias,
                    child: NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      destinations: allowedTabs
                          .map((tab) => NavigationDestination(
                                icon: Icon(tab.icon),
                                label: tab.label,
                              ))
                          .toList(),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
