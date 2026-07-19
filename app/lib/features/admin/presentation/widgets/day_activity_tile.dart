import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/status_badge.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';

/// Um dia útil no detalhe semanal: dia, total, intervalos de batidas
/// (horários HH:MM prontos do servidor) e o selo de status do dia.
///
/// Quando [onTap] é fornecido, o tile fica clicável para destacar só esse dia no
/// mapa; [selected] realça o tile do dia atualmente selecionado.
class DayActivityTile extends StatelessWidget {
  final WeeklyReviewDayModel day;
  final VoidCallback? onTap;
  final bool selected;

  const DayActivityTile({
    super.key,
    required this.day,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dayName = DateFormatHelper.shortDayNames[day.date.weekday - 1];
    final dayNumber = day.date.day.toString().padLeft(2, '0');
    final radius = BorderRadius.circular(AppRadius.lg);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      color: selected
          ? AppColors.primary.withValues(alpha: 0.06)
          : AppColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$dayName, $dayNumber',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusBadge.day(day.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                day.overtimeMinutes > 0
                    ? '${formatMinutes(day.workedMinutes)} '
                          '(+${formatMinutes(day.overtimeMinutes)})'
                    : formatMinutes(day.workedMinutes),
                style: textTheme.bodySmall?.copyWith(
                  color: day.overtimeMinutes > 0
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (day.intervals.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                ...day.intervals.map(
                  (interval) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          interval.end == null
                              ? '${interval.start} - em andamento'
                              : '${interval.start} - ${interval.end}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (day.absence) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sem registros',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
