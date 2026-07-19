import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/weekly_review_detail_model.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';

/// Selo de status da revisão semanal (lista) ou do dia (detalhe).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  factory StatusBadge.review(WeeklyReviewStatus status, {Key? key}) {
    switch (status) {
      case WeeklyReviewStatus.alert:
        return StatusBadge(
          key: key,
          label: 'ALERTA',
          background: AppColors.errorContainer,
          foreground: AppColors.onErrorContainer,
        );
      case WeeklyReviewStatus.pending:
        return StatusBadge(
          key: key,
          label: 'PENDENTE',
          background: AppColors.warningContainer,
          foreground: AppColors.onWarningContainer,
        );
      case WeeklyReviewStatus.approved:
        return StatusBadge(
          key: key,
          label: 'APROVADA',
          background: AppColors.successContainer,
          foreground: AppColors.onSuccessContainer,
        );
      case WeeklyReviewStatus.rejected:
        return StatusBadge(
          key: key,
          label: 'REPROVADA',
          background: AppColors.errorContainer,
          foreground: AppColors.onErrorContainer,
        );
    }
  }

  factory StatusBadge.day(WeeklyDayStatus status, {Key? key}) {
    switch (status) {
      case WeeklyDayStatus.pending:
        return StatusBadge(
          key: key,
          label: 'Pendente',
          background: AppColors.warningContainer,
          foreground: AppColors.onWarningContainer,
        );
      case WeeklyDayStatus.approved:
        return StatusBadge(
          key: key,
          label: 'Aprovada',
          background: AppColors.successContainer,
          foreground: AppColors.onSuccessContainer,
        );
      case WeeklyDayStatus.overtime:
        return StatusBadge(
          key: key,
          label: 'Hora extra',
          background: AppColors.errorContainer,
          foreground: AppColors.onErrorContainer,
        );
      case WeeklyDayStatus.absence:
        return StatusBadge(
          key: key,
          label: 'Falta',
          background: AppColors.errorContainer,
          foreground: AppColors.onErrorContainer,
        );
      case WeeklyDayStatus.rest:
        return StatusBadge(
          key: key,
          label: 'Descanso',
          background: AppColors.secondaryContainer,
          foreground: AppColors.onSecondaryContainer,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
