import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/employee_model.dart';
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/employee_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/shared/utils/password_generator.dart';

/// Formulário de criar/editar funcionário. Devolve `true` no `pop` quando salva,
/// para a lista recarregar. Em edição a senha é opcional (só troca se preenchida).
class FuncionarioFormPage extends StatefulWidget {
  final EmployeeModel? employee;

  const FuncionarioFormPage({super.key, this.employee});

  bool get isEditing => employee != null;

  @override
  State<FuncionarioFormPage> createState() => _FuncionarioFormPageState();
}

class _FuncionarioFormPageState extends State<FuncionarioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = EmployeeService();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _saving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _nameController = TextEditingController(text: employee?.name ?? '');
    _usernameController = TextEditingController(text: employee?.username ?? '');
    _emailController = TextEditingController(text: employee?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      _passwordController.text = generateStrongPassword();
      _obscurePassword = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = '';
    });

    try {
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (widget.isEditing) {
        await _service.updateEmployee(
          widget.employee!.id,
          name: name,
          username: username,
          email: email,
          password: password,
        );
      } else {
        await _service.createEmployee(
          name: name,
          username: username,
          email: email,
          password: password,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _errorMessage = 'Erro inesperado. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar funcionário' : 'Novo funcionário'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_saving,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Informe o usuário'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_saving,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_saving,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: widget.isEditing
                          ? 'Nova senha (opcional)'
                          : 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Gerar senha segura',
                            icon: const Icon(Icons.casino_outlined),
                            onPressed: _saving ? null : _generatePassword,
                          ),
                          IconButton(
                            tooltip: _obscurePassword ? 'Mostrar' : 'Ocultar',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: _saving
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
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
                  ],
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(widget.isEditing ? 'Salvar' : 'Criar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o e-mail';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(text) ? null : 'E-mail inválido';
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    // Na edição, senha vazia = manter a atual.
    if (widget.isEditing && text.isEmpty) return null;
    if (text.isEmpty) return 'Informe a senha';
    if (text.length < 6) return 'Mínimo de 6 caracteres';
    return null;
  }
}
