import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';

/// Tabela simples dos turnos do dia: uma linha por jornada, com entrada e
/// saída. Mostra ao menos duas linhas (1º e 2º Turno) como placeholder,
/// mesmo sem registros ainda.
class JourneyTurnsTable extends StatelessWidget {
  /// Jornadas de hoje, da mais antiga para a mais recente (1º Turno primeiro).
  final List<JourneyModel> journeys;

  const JourneyTurnsTable({super.key, this.journeys = const []});

  static const int _minRows = 2;

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-- : --';
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final rowCount =
        journeys.length < _minRows ? _minRows : journeys.length;

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
          for (int i = 0; i < rowCount; i++)
            _buildRow(
              context,
              index: i,
              journey: i < journeys.length ? journeys[i] : null,
            ),
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
          Expanded(flex: 3, child: Text('TURNO', style: style)),
          Expanded(flex: 2, child: Text('ENTRADA', style: style)),
          Expanded(flex: 2, child: Text('SAÍDA', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required int index,
    required JourneyModel? journey,
  }) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        );
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
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
            child: Text('${index + 1}º Turno', style: labelStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatTime(journey?.startedAt), style: valueStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatTime(journey?.finishedAt), style: valueStyle),
          ),
        ],
      ),
    );
  }
}
