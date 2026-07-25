import 'package:flutter/material.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/features/settings/presentation/funcionarios_page.dart';

/// Aba de administração. Por enquanto expõe o card de Funcionários; feita para
/// receber mais cards de configuração no futuro.
class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _SettingsCard(
              icon: Icons.groups_outlined,
              title: 'Funcionários',
              subtitle: 'Cadastrar, editar e inativar quem bate ponto',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FuncionariosPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
