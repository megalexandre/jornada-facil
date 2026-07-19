// Espelha o catálogo RBAC do backend (api/app/services/rbac.rb).
// A API serializa permissions com atalhos: "resource:*" = todas as ações
// do resource, "*" = todas as ações de todos os resources (domínio + admin).
const String kPermissionWildcard = '*';

abstract class Resources {
  // Domínio (Rbac::DOMAIN_RESOURCES)
  static const String journey = 'journey';
  static const String history = 'history';
  static const String profile = 'profile';

  // Administração (Rbac::ADMIN_RESOURCES)
  static const String users = 'users';
  static const String roles = 'roles';
  static const String permissions = 'permissions';
  static const String notification = 'notification';
  static const String weeklyReview = 'weekly_review';
}

abstract class Actions {
  static const String view   = 'view';
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
}
