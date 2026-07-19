import 'package:flutter/material.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';

/// Navegação de semana: ‹ 06 a 12 de julho ›. O avanço é bloqueado na
/// semana atual (não há revisão de semanas futuras).
class WeekHeader extends StatelessWidget {
  final DateTime weekStart;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const WeekHeader({
    super.key,
    required this.weekStart,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Semana anterior',
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormatHelper.formatWeekRange(weekStart, weekEnd),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
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
    );
  }
}
