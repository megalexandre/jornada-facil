import 'package:jornadafacil/core/models/employee_model.dart';
import 'package:jornadafacil/core/network/api_client.dart';

/// CRUD de funcionários (usuários que batem ponto) para a tela de Configurações.
/// Exige permissões `users:*`. Falhas sobem como [ApiException].
class EmployeeService {
  static final EmployeeService _instance = EmployeeService._internal();

  factory EmployeeService() => _instance;

  EmployeeService._internal();

  final ApiClient _api = ApiClient();

  /// GET /api/v1/users — só funcionários (tracks_journey) incluindo inativos.
  Future<List<EmployeeModel>> listEmployees() async {
    final json = await _api.get(
      '/api/v1/users',
      query: {'tracks_journey': 'true', 'include_inactive': 'true'},
    ) as List<dynamic>;
    return json
        .map((item) => EmployeeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/users (exige users:create).
  Future<EmployeeModel> createEmployee({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final json = await _api.post(
      '/api/v1/users',
      body: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;
    return EmployeeModel.fromJson(json);
  }

  /// PATCH /api/v1/users/:id (exige users:update). Senha só troca se informada.
  Future<EmployeeModel> updateEmployee(
    String id, {
    required String name,
    required String username,
    required String email,
    String? password,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'username': username,
      'email': email,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    final json = await _api.patch('/api/v1/users/$id', body: body)
        as Map<String, dynamic>;
    return EmployeeModel.fromJson(json);
  }

  /// PATCH /api/v1/users/:id/inactivate (exige users:delete).
  Future<EmployeeModel> inactivateEmployee(String id) async {
    final json = await _api.patch('/api/v1/users/$id/inactivate')
        as Map<String, dynamic>;
    return EmployeeModel.fromJson(json);
  }

  /// PATCH /api/v1/users/:id/restore (exige users:delete).
  Future<EmployeeModel> restoreEmployee(String id) async {
    final json = await _api.patch('/api/v1/users/$id/restore')
        as Map<String, dynamic>;
    return EmployeeModel.fromJson(json);
  }
}
