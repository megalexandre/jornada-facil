// Payload de GET /api/v1/weekly_reviews: a semana, as taxas de conformidade
// e uma linha por usuário com minutos (inteiros) e status da revisão.

/// "8h" / "8h 30m" a partir de minutos.
String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest.toString().padLeft(2, '0')}m';
}

enum WeeklyReviewStatus {
  alert,
  pending,
  approved,
  rejected;

  /// Status desconhecido cai em pending para não quebrar com API mais nova.
  static WeeklyReviewStatus fromApi(String? value) {
    return WeeklyReviewStatus.values.asNameMap()[value] ??
        WeeklyReviewStatus.pending;
  }
}

class WeeklyReviewUserRowModel {
  final String id;
  final String name;
  final WeeklyReviewStatus status;
  final int workedMinutes;
  final int expectedMinutes;
  final int overtimeMinutes;
  final int absences;

  const WeeklyReviewUserRowModel({
    required this.id,
    required this.name,
    required this.status,
    required this.workedMinutes,
    required this.expectedMinutes,
    required this.overtimeMinutes,
    required this.absences,
  });

  String get initials {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(2)
        .join();
  }

  String get workedLabel =>
      '${formatMinutes(workedMinutes)} / ${formatMinutes(expectedMinutes)}';

  double get progress {
    if (expectedMinutes == 0) return 0;
    return (workedMinutes / expectedMinutes).clamp(0.0, 1.0);
  }

  bool get isOverExpected => workedMinutes > expectedMinutes;

  factory WeeklyReviewUserRowModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReviewUserRowModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      status: WeeklyReviewStatus.fromApi(json['status'] as String?),
      workedMinutes: json['worked_minutes'] as int? ?? 0,
      expectedMinutes: json['expected_minutes'] as int? ?? 0,
      overtimeMinutes: json['overtime_minutes'] as int? ?? 0,
      absences: json['absences'] as int? ?? 0,
    );
  }
}

class WeeklyReviewSummaryModel {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int complianceRate;
  final int? previousComplianceRate;
  final List<WeeklyReviewUserRowModel> users;

  const WeeklyReviewSummaryModel({
    required this.weekStart,
    required this.weekEnd,
    required this.complianceRate,
    required this.previousComplianceRate,
    required this.users,
  });

  int? get complianceDelta => previousComplianceRate == null
      ? null
      : complianceRate - previousComplianceRate!;

  factory WeeklyReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReviewSummaryModel(
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      complianceRate: json['compliance_rate'] as int? ?? 0,
      previousComplianceRate: json['previous_compliance_rate'] as int?,
      users: (json['users'] as List<dynamic>? ?? const [])
          .map((item) =>
              WeeklyReviewUserRowModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
