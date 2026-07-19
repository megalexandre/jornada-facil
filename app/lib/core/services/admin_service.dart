import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/models/user_summary_model.dart';
import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';
import 'package:jornadafacil/core/network/api_client.dart';

/// Consome os endpoints administrativos da API (exigem users:view).
/// Falhas sobem como [ApiException] com a mensagem da API.
class AdminService {
  static final AdminService _instance = AdminService._internal();

  factory AdminService() => _instance;

  AdminService._internal();

  final ApiClient _api = ApiClient();

  /// GET /api/v1/users — lista todos os usuários ativos, ordenados por nome.
  Future<List<UserSummaryModel>> listUsers() async {
    final json = await _api.get('/api/v1/users') as List<dynamic>;
    return json
        .map((item) => UserSummaryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/users/:id/journeys — jornadas do usuário, mais recentes primeiro.
  Future<List<JourneyModel>> listUserJourneys(String userId) async {
    final json = await _api.get('/api/v1/users/$userId/journeys') as List<dynamic>;
    return json
        .map((item) => JourneyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/weekly_reviews — resumo da semana de todos os usuários.
  /// [weekStart] em YYYY-MM-DD; o servidor faz snap para a segunda-feira.
  Future<WeeklyReviewSummaryModel> getWeeklyReview({
    required String weekStart,
  }) async {
    final json = await _api.get(
      '/api/v1/weekly_reviews',
      query: {'week_start': weekStart},
    ) as Map<String, dynamic>;
    return WeeklyReviewSummaryModel.fromJson(json);
  }

  /// GET /api/v1/users/:id/weekly_review — detalhe da semana de um usuário.
  Future<WeeklyReviewDetailModel> getUserWeeklyReview(
    String userId, {
    required String weekStart,
  }) async {
    final json = await _api.get(
      '/api/v1/users/$userId/weekly_review',
      query: {'week_start': weekStart},
    ) as Map<String, dynamic>;
    return WeeklyReviewDetailModel.fromJson(json);
  }

  /// POST /api/v1/users/:id/weekly_review/approve (exige weekly_review:update).
  Future<void> approveWeeklyReview(
    String userId, {
    required String weekStart,
  }) async {
    await _api.post(
      '/api/v1/users/$userId/weekly_review/approve',
      body: {'week_start': weekStart},
    );
  }
}
