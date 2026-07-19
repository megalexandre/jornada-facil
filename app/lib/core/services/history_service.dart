import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/network/api_client.dart';

/// Histórico da semana do usuário autenticado.
/// Reaproveita o mesmo payload da revisão semanal (WeeklyReviewDetailModel),
/// mas exposto pelo endpoint self-service gateado por history:view.
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();

  factory HistoryService() => _instance;

  HistoryService._internal();

  final ApiClient _api = ApiClient();

  /// GET /api/v1/history — semana do próprio usuário. Sem [weekStart] o
  /// servidor cai no default da semana corrente; com ele (YYYY-MM-DD) traz a
  /// semana pedida (o servidor normaliza para a segunda-feira).
  Future<WeeklyReviewDetailModel> getWeek({String? weekStart}) async {
    final json = await _api.get(
      '/api/v1/history',
      query: weekStart == null ? null : {'week_start': weekStart},
    ) as Map<String, dynamic>;
    return WeeklyReviewDetailModel.fromJson(json);
  }
}
