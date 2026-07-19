import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart'
    show formatMinutes;
import 'package:jornadafacil/core/network/api_exception.dart';
import 'package:jornadafacil/core/services/history_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/features/history/presentation/widgets/daily_records_table.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';
import 'package:jornadafacil/shared/utils/week_utils.dart';

/// Histórico do próprio usuário (seg→dom): período, soma de horas da semana
/// e total por dia. Navega entre as semanas do mês corrente — sem passar da
/// semana atual (não há jornada futura) nem antes da 1ª semana do mês.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();

  late DateTime _weekStart;
  bool _loading = true;
  String? _error;
  WeeklyReviewDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _weekStart = WeekUtils.mondayOfWeek(DateTime.now());
    _load();
  }

  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Segunda-feira da semana atual (limite superior: não há jornada futura).
  DateTime get _currentWeekStart => WeekUtils.mondayOfWeek(DateTime.now());

  /// Segunda-feira da 1ª semana que toca o mês corrente (limite inferior).
  DateTime get _monthFirstWeekStart {
    final now = DateTime.now();
    return WeekUtils.mondayOfWeek(DateTime(now.year, now.month, 1));
  }

  bool get _canGoNext => _weekStart.isBefore(_currentWeekStart);
  bool get _canGoPrevious => _weekStart.isAfter(_monthFirstWeekStart);

  void _changeWeek(int days) {
    setState(() => _weekStart = _weekStart.add(Duration(days: days)));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail =
          await _historyService.getWeek(weekStart: _isoDate(_weekStart));
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final detail = _detail!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _PeriodCard(
            weekStart: detail.weekStart,
            weekEnd: detail.weekEnd,
            canGoPrevious: _canGoPrevious,
            canGoNext: _canGoNext,
            onPrevious: () => _changeWeek(-7),
            onNext: () => _changeWeek(7),
          ),
          const SizedBox(height: 16),
          _WeekSummaryCard(
            totalMinutes: detail.totalMinutes,
            expectedMinutes: detail.expectedMinutes,
          ),
          const SizedBox(height: 24),
          Text(
            'Registros Diários',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          DailyRecordsTable(days: detail.days),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PeriodCard({
    required this.weekStart,
    required this.weekEnd,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: canGoPrevious ? onPrevious : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Semana anterior',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'PERÍODO',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormatHelper.formatWeekRange(weekStart, weekEnd),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Próxima semana',
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekSummaryCard extends StatelessWidget {
  final int totalMinutes;
  final int expectedMinutes;

  const _WeekSummaryCard({
    required this.totalMinutes,
    required this.expectedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESUMO SEMANA',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormatHelper.hoursMinutes(totalMinutes),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Meta: ${formatMinutes(expectedMinutes)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
