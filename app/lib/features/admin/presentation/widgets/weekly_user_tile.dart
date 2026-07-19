import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/weekly_review_summary_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/features/admin/presentation/widgets/status_badge.dart';

/// Linha da lista de revisão semanal: avatar, nome, selo de status e
/// horas trabalhadas vs esperadas com barra de progresso.
class WeeklyUserTile extends StatelessWidget {
  final WeeklyReviewUserRowModel user;
  final VoidCallback onTap;

  const WeeklyUserTile({super.key, required this.user, required this.onTap});

  bool get _highlightAsAlert =>
      user.isOverExpected || user.status == WeeklyReviewStatus.alert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryFixed,
        foregroundColor: AppColors.primary,
        child: Text(user.initials),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          StatusBadge.review(user.status),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            user.workedLabel,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: user.progress,
              minHeight: 6,
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                _highlightAsAlert ? AppColors.error : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
