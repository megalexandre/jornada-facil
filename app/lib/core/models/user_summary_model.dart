/// Item da listagem de usuários (GET /api/v1/users): { id, name }.
/// Contrato menor que o UserModel da sessão — não reusar.
class UserSummaryModel {
  final String id;
  final String name;

  const UserSummaryModel({required this.id, required this.name});

  String get initials {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(2)
        .join();
  }

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );
  }
}
