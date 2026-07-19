import 'package:flutter/material.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';

/// Card azul de destaque com a taxa de conformidade da semana e o delta
/// em relação à semana anterior.
class ComplianceCard extends StatelessWidget {
  final int complianceRate;
  final int? delta;

  const ComplianceCard({
    super.key,
    required this.complianceRate,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAXA DE CONFORMIDADE',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.primaryFixed,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$complianceRate%',
            style: textTheme.displaySmall?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  delta! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: AppColors.primaryFixed,
                ),
                const SizedBox(width: 4),
                Text(
                  '${delta! >= 0 ? '+' : ''}$delta% vs semana anterior',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryFixed,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
