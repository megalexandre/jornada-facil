import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';

/// Tabela simples dos dias da semana: DATA · DIA · TOTAL.
/// Recebe os 7 dias (seg→dom) já calculados pela API; total 0 vira "--:--".
class DailyRecordsTable extends StatelessWidget {
  final List<WeeklyReviewDayModel> days;

  const DailyRecordsTable({super.key, required this.days});

  String _monthAbbrev(DateTime date) {
    return DateFormatHelper.monthNames[date.month - 1]
        .substring(0, 3)
        .toUpperCase();
  }

  /// dayNames é seg→dom (índice 0 = segunda), mesma ordem dos dias vindos da
  /// API; mostramos só o nome curto capitalizado (ex.: "segunda-feira" → "Segunda").
  String _weekdayLabel(int index) {
    final base = DateFormatHelper.dayNames[index].split('-').first;
    return '${base[0].toUpperCase()}${base.substring(1)}';
  }

  String _total(WeeklyReviewDayModel day) {
    if (day.workedMinutes == 0) return '--:--';
    return DateFormatHelper.hoursMinutes(day.workedMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(context),
          for (int i = 0; i < days.length; i++)
            _buildRow(context, index: i, day: days[i]),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        );

    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('DATA', style: style)),
          Expanded(flex: 3, child: Text('DIA', style: style)),
          Expanded(
            flex: 2,
            child: Text('TOTAL', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required int index,
    required WeeklyReviewDayModel day,
  }) {
    final worked = day.workedMinutes > 0;

    final dateStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );
    final dayStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        );
    final totalStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: worked ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: worked ? FontWeight.w600 : FontWeight.w400,
        );

    return Container(
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : const Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${day.date.day.toString().padLeft(2, '0')} ${_monthAbbrev(day.date)}',
              style: dateStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(_weekdayLabel(index), style: dayStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _total(day),
              style: totalStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
