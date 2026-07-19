import 'package:jornadafacil/core/models/user_model.dart';

/// Guarda o usuário da sessão ativa (definido pelo AuthService após
/// login ou restauração da sessão persistida).
class CurrentUserService {
  static final CurrentUserService _instance = CurrentUserService._internal();

  factory CurrentUserService() => _instance;

  CurrentUserService._internal();

  UserModel? _currentUser;

  bool get hasUser => _currentUser != null;

  UserModel getCurrentUser() {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Nenhum usuário autenticado. Faça login primeiro.');
    }
    return user;
  }

  void setUser(UserModel user) {
    _currentUser = user;
  }

  void clear() {
    _currentUser = null;
  }

  bool hasPermission(String permission) =>
      _currentUser?.can(permission) ?? false;
}
