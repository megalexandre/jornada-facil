import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';

// Payload de GET /api/v1/users/:user_id/weekly_review: sempre 7 dias
// seg→dom, horários já formatados HH:MM no fuso de negócio pelo servidor
// (exibidos como vêm), localizações opcionais de entrada/saída por
// intervalo, review null enquanto a semana está pendente.

enum WeeklyDayStatus {
  pending,
  approved,
  overtime,
  absence,
  rest;

  static WeeklyDayStatus fromApi(String? value) {
    return WeeklyDayStatus.values.asNameMap()[value] ?? WeeklyDayStatus.pending;
  }
}

class DayIntervalModel {
  final String start;
  final String? end;
  final GeoPoint? startLocation;
  final GeoPoint? endLocation;

  const DayIntervalModel({
    required this.start,
    this.end,
    this.startLocation,
    this.endLocation,
  });

  factory DayIntervalModel.fromJson(Map<String, dynamic> json) {
    return DayIntervalModel(
      start: json['start'] as String,
      end: json['end'] as String?,
      startLocation: json['start_location'] == null
          ? null
          : GeoPoint.fromJson(json['start_location'] as Map<String, dynamic>),
      endLocation: json['end_location'] == null
          ? null
          : GeoPoint.fromJson(json['end_location'] as Map<String, dynamic>),
    );
  }
}

class WeeklyReviewDayModel {
  final DateTime date;
  final bool weekend;
  final int workedMinutes;
  final int overtimeMinutes;
  final bool absence;
  final WeeklyDayStatus status;
  final List<DayIntervalModel> intervals;

  const WeeklyReviewDayModel({
    required this.date,
    required this.weekend,
    required this.workedMinutes,
    required this.overtimeMinutes,
    required this.absence,
    required this.status,
    required this.intervals,
  });

  factory WeeklyReviewDayModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReviewDayModel(
      date: DateTime.parse(json['date'] as String),
      weekend: json['weekend'] as bool? ?? false,
      workedMinutes: json['worked_minutes'] as int? ?? 0,
      overtimeMinutes: json['overtime_minutes'] as int? ?? 0,
      absence: json['absence'] as bool? ?? false,
      status: WeeklyDayStatus.fromApi(json['status'] as String?),
      intervals: (json['intervals'] as List<dynamic>? ?? const [])
          .map((item) => DayIntervalModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WeeklyReviewInfoModel {
  final String id;
  final WeeklyReviewStatus status;
  final String? comment;
  final String reviewerName;
  final DateTime reviewedAt;

  const WeeklyReviewInfoModel({
    required this.id,
    required this.status,
    required this.comment,
    required this.reviewerName,
    required this.reviewedAt,
  });

  factory WeeklyReviewInfoModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReviewInfoModel(
      id: json['id'] as String,
      status: WeeklyReviewStatus.fromApi(json['status'] as String?),
      comment: json['comment'] as String?,
      reviewerName: json['reviewer_name'] as String? ?? '',
      reviewedAt: DateTime.parse(json['reviewed_at'] as String),
    );
  }
}

class WeeklyReviewDetailModel {
  final String userId;
  final String userName;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalMinutes;
  final int standardMinutes;
  final int overtimeMinutes;
  final int expectedMinutes;
  final int absences;
  final WeeklyReviewInfoModel? review;
  final List<WeeklyReviewDayModel> days;

  const WeeklyReviewDetailModel({
    required this.userId,
    required this.userName,
    required this.weekStart,
    required this.weekEnd,
    required this.totalMinutes,
    required this.standardMinutes,
    required this.overtimeMinutes,
    required this.expectedMinutes,
    required this.absences,
    required this.review,
    required this.days,
  });

  List<WeeklyReviewDayModel> get weekdays =>
      days.where((day) => !day.weekend).toList();

  List<WeeklyReviewDayModel> get weekendDays =>
      days.where((day) => day.weekend).toList();

  int get weekendOvertimeMinutes =>
      weekendDays.fold(0, (sum, day) => sum + day.overtimeMinutes);

  factory WeeklyReviewDetailModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final review = json['review'] as Map<String, dynamic>?;

    return WeeklyReviewDetailModel(
      userId: user['id'] as String? ?? '',
      userName: user['name'] as String? ?? '',
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      totalMinutes: json['total_minutes'] as int? ?? 0,
      standardMinutes: json['standard_minutes'] as int? ?? 0,
      overtimeMinutes: json['overtime_minutes'] as int? ?? 0,
      expectedMinutes: json['expected_minutes'] as int? ?? 0,
      absences: json['absences'] as int? ?? 0,
      review: review == null ? null : WeeklyReviewInfoModel.fromJson(review),
      days: (json['days'] as List<dynamic>? ?? const [])
          .map((item) =>
              WeeklyReviewDayModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
