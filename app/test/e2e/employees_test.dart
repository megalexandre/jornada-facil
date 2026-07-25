import 'package:flutter_test/flutter_test.dart';
import 'package:jornadafacil/core/models/employee_model.dart';
import 'package:jornadafacil/core/services/employee_service.dart';

import 'support.dart';

/// E2E de gestão de funcionários: admin cria/edita/inativa/reativa via
/// EmployeeService real (Flutter → Rails → DB). Requer API no ar e semeada.
///
/// Idempotente: reusa um funcionário de username fixo entre execuções (não há
/// hard delete), reativando-o quando estiver inativo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useRealApi);

  const username = 'e2e.employee';

  Future<EmployeeModel> ensureActiveEmployee() async {
    final all = await EmployeeService().listEmployees();
    EmployeeModel? existing;
    for (final employee in all) {
      if (employee.username == username) {
        existing = employee;
        break;
      }
    }
    if (existing == null) {
      return EmployeeService().createEmployee(
        name: 'E2E Employee',
        username: username,
        email: 'e2e.employee@example.com',
        password: 'Senha123',
      );
    }
    return existing.active
        ? existing
        : EmployeeService().restoreEmployee(existing.id);
  }

  test('admin gerencia o ciclo de vida de um funcionário', () async {
    await loginAs(username: 'admin', password: 'Senha123');

    final employee = await ensureActiveEmployee();
    expect(employee.tracksJourney, isTrue);
    expect(employee.active, isTrue);

    final updated = await EmployeeService().updateEmployee(
      employee.id,
      name: 'E2E Employee Renomeado',
      username: username,
      email: 'e2e.employee@example.com',
    );
    expect(updated.name, 'E2E Employee Renomeado');

    final inactive = await EmployeeService().inactivateEmployee(employee.id);
    expect(inactive.active, isFalse);

    final restored = await EmployeeService().restoreEmployee(employee.id);
    expect(restored.active, isTrue);
  });
}
