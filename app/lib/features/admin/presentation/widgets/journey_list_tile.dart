import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';

/// Uma jornada na revisão do admin: início, fim (ou "Em andamento").
class JourneyListTile extends StatelessWidget {
  final JourneyModel journey;

  const JourneyListTile({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        journey.isOpen ? Icons.play_circle_outline : Icons.check_circle_outline,
        color: journey.isOpen ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text('Início: ${DateFormatHelper.formatDateTime(journey.startedAt)}'),
      subtitle: journey.isOpen
          ? const Text(
              'Em andamento',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          : Text('Fim: ${DateFormatHelper.formatDateTime(journey.finishedAt!)}'),
    );
  }
}
