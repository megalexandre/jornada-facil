/// Funcionário (usuário que bate ponto) na tela de administração.
/// Espelha o `Users::EmployeeSerializer` da API.
class EmployeeModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final bool tracksJourney;
  final bool active;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.tracksJourney,
    required this.active,
  });

  String get initials {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(2)
        .join();
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tracksJourney: json['tracks_journey'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
    );
  }
}
