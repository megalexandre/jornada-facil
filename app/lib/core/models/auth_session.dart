import 'package:jornadafacil/core/models/user_model.dart';

class AuthSession {
  final String token;
  final DateTime expiresAt;
  final UserModel user;

  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'user': user.toJson(),
    };
  }
}
