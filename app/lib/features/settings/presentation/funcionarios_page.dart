import 'package:flutter/material.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/core/models/employee_model.dart';
import 'package:jornadafacil/core/models/user_model.dart';
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/employee_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/features/settings/presentation/widgets/funcionario_form_page.dart';
import 'package:jornadafacil/shared/utils/responsive.dart';

/// Lista os funcionários (ativos e inativos) e permite criar, editar e
/// inativar/reativar. Cada ação é gateada pela permissão `users:*` do admin.
class FuncionariosPage extends StatefulWidget {
  const FuncionariosPage({super.key});

  @override
  State<FuncionariosPage> createState() => _FuncionariosPageState();
}

class _FuncionariosPageState extends State<FuncionariosPage> {
  final EmployeeService _service = EmployeeService();

  bool _loading = true;
  String? _error;
  List<EmployeeModel> _employees = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final employees = await _service.listEmployees();
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openForm({EmployeeModel? employee}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FuncionarioFormPage(employee: employee),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _inactivate(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inativar funcionário'),
        content: Text(
          '${employee.name} deixará de conseguir entrar e bater ponto. '
          'Você pode reativar depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() => _service.inactivateEmployee(employee.id));
  }

  Future<void> _restore(EmployeeModel employee) async {
    await _runAction(() => _service.restoreEmployee(employee.id));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.appState.currentUser;
    final canCreate = user.can('users:create');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
        actions: [
          if (canCreate)
            IconButton(
              tooltip: 'Novo funcionário',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => _openForm(),
            ),
        ],
      ),
      body: _buildBody(user),
    );
  }

  Widget _buildBody(UserModel user) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _RetryState(message: _error!, onRetry: _load);
    }
    if (_employees.isEmpty) {
      return const Center(child: Text('Nenhum funcionário cadastrado.'));
    }

    final canUpdate = user.can('users:update');
    final canDelete = user.can('users:delete');

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          // Sem o cap a lista esticaria pela janela inteira no desktop/web; num
          // celular o maxWidth não restringe.
          constraints: const BoxConstraints(maxWidth: Breakpoints.expanded),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalMargin,
              vertical: AppSpacing.md,
            ),
            itemCount: _employees.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final employee = _employees[index];
              return _EmployeeTile(
                employee: employee,
                canUpdate: canUpdate,
                canDelete: canDelete,
                onEdit: () => _openForm(employee: employee),
                onInactivate: () => _inactivate(employee),
                onRestore: () => _restore(employee),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final EmployeeModel employee;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onRestore;

  const _EmployeeTile({
    required this.employee,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onInactivate,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = !employee.active;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: inactive ? AppColors.surface : AppColors.primary,
        foregroundColor: inactive ? AppColors.textSecondary : AppColors.onPrimary,
        child: Text(employee.initials),
      ),
      title: Text(
        employee.name,
        style: TextStyle(color: inactive ? AppColors.textSecondary : null),
      ),
      subtitle: Text('@${employee.username} · ${employee.email}'),
      trailing: _buildTrailing(context, inactive),
    );
  }

  Widget? _buildTrailing(BuildContext context, bool inactive) {
    final entries = <PopupMenuEntry<String>>[
      if (canUpdate)
        const PopupMenuItem(value: 'edit', child: Text('Editar')),
      if (canDelete)
        PopupMenuItem(
          value: inactive ? 'restore' : 'inactivate',
          child: Text(inactive ? 'Reativar' : 'Inativar'),
        ),
    ];

    final badge = inactive
        ? const Chip(
            label: Text('Inativo'),
            visualDensity: VisualDensity.compact,
          )
        : null;

    if (entries.isEmpty) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?badge,
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'inactivate':
                onInactivate();
              case 'restore':
                onRestore();
            }
          },
          itemBuilder: (_) => entries,
        ),
      ],
    );
  }
}

class _RetryState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RetryState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
