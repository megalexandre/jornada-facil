import 'package:jornadafacil/core/models/rbac.dart';

class UserModel {
  final String? id;
  final String username;
  final String name;
  final String email;

  /// Se o usuário registra jornada (bate ponto). Admins e afins têm `false`
  /// — a API recusa a abertura de jornada e o app esconde a aba de Registro.
  final bool tracksJourney;
  final List<String> permissions;
  final String? imageBase64;

  const UserModel({
    this.id,
    this.username = '',
    required this.name,
    required this.email,
    this.tracksJourney = true,
    required this.permissions,
    this.imageBase64,
  });

  /// Verifica uma permissão "resource:action", entendendo os atalhos que a
  /// API envia: "*" (acesso total ao domínio) e "resource:*".
  bool can(String permission) {
    if (permissions.contains(kPermissionWildcard)) return true;
    if (permissions.contains(permission)) return true;

    final resource = permission.split(':').first;
    return permissions.contains('$resource:$kPermissionWildcard');
  }

  String get initials {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(2)
        .join();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String?,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tracksJourney: json['tracks_journey'] as bool? ?? true,
      permissions: (json['permissions'] as List?)?.cast<String>() ?? const [],
      imageBase64: json['imageBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'tracks_journey': tracksJourney,
      'permissions': permissions,
      'imageBase64': imageBase64,
    };
  }
}
