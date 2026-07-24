import 'package:flutter/material.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';

class LocalDateTimeCard extends StatelessWidget {
  const LocalDateTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([context.timerNotifier, context.appState]),
      builder: (context, _) {
        final timerNotifier = context.timerNotifier;
        final appState = context.appState;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'HORA ATUAL',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormatHelper.formatTime(timerNotifier.currentTime),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!appState.isLoading && !appState.isInsideGeofence) ...[
                  const SizedBox(height: 16),
                  _OutOfFenceNotice(distance: appState.distance),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OutOfFenceNotice extends StatelessWidget {
  const _OutOfFenceNotice({required this.distance});

  final String distance;

  @override
  Widget build(BuildContext context) {
    final message = distance.isEmpty
        ? 'Você está fora da área da FJ-Telecom. Desloque-se antes de '
              'iniciar ou terminar a jornada.'
        : 'Você está a $distance da FJ-Telecom. Desloque-se para dentro da '
              'área antes de iniciar ou terminar a jornada.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_off,
            size: 18,
            color: AppColors.onWarningContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onWarningContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
