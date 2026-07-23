import 'package:flutter/material.dart';
import 'package:jornadafacil/app/app.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/core/theme/app_theme.dart';

class LocalDateTimeCard extends StatelessWidget {
  const LocalDateTimeCard({super.key});

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Escuta o relógio (tick de 1s) e o AppState (estado da cerca) juntos,
      // para o aviso de fora-da-cerca aparecer/sumir na hora.
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
                  _formatTime(timerNotifier.currentTime),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Só após o primeiro fix de GPS (!isLoading), para o aviso não
                // piscar antes de sabermos a posição real.
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

/// Aviso âmbar exibido no card de hora quando o usuário está fora da cerca da
/// FJ-Telecom. Segue o padrão visual de banner de aviso do app (cores
/// warning + ícone à esquerda).
class _OutOfFenceNotice extends StatelessWidget {
  const _OutOfFenceNotice({required this.distance});

  /// Texto de distância pronto do [AppState] (ex.: "300m de distância"); pode
  /// vir vazio se ainda não houver cálculo.
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
