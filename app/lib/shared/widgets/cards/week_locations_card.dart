import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/shared/utils/date_format_helper.dart';
import 'package:jornadafacil/shared/widgets/maps/geo_map.dart';

/// Card com o mapa dos pontos de entrada (azul) e saída (verde) registrados
/// na semana iniciada em [weekStart] (segunda a domingo). Cada ponto carrega a
/// data para rotular o pino com a inicial do dia da semana. Tocar no mapa abre
/// em tela cheia (arrasto + zoom).
class WeekLocationsCard extends StatelessWidget {
  static const Color _entryColor = AppColors.primary;
  static const Color _exitColor = AppColors.success;

  final DateTime weekStart;
  final List<({GeoPoint point, DateTime date})> entries;
  final List<({GeoPoint point, DateTime date})> exits;

  const WeekLocationsCard({
    super.key,
    required this.weekStart,
    required this.entries,
    required this.exits,
  });

  static String _dayLabel(DateTime date) =>
      DateFormatHelper.shortDayNames[date.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final markers = [
      for (final e in entries)
        GeoMapMarker(
          point: e.point,
          color: _entryColor,
          label: _dayLabel(e.date),
        ),
      for (final e in exits)
        GeoMapMarker(
          point: e.point,
          color: _exitColor,
          label: _dayLabel(e.date),
        ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'LOCALIZAÇÕES DA SEMANA',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  DateFormatHelper.formatWeekRange(weekStart, weekEnd),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (markers.isEmpty)
              const _EmptyState()
            else
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GeoMapFullscreenPage(
                      markers: markers,
                      title: 'Localizações da semana',
                      legend: const _LegendChip(),
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    GeoMap(markers: markers),
                    const Positioned(left: 8, bottom: 8, child: _LegendChip()),
                    const Positioned(right: 8, top: 8, child: _ExpandHint()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Sem registros com localização nesta semana',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Dica visual de que o mapa abre em tela cheia ao toque.
class _ExpandHint extends StatelessWidget {
  const _ExpandHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Icon(
        Icons.fullscreen,
        size: 18,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LegendEntry(color: WeekLocationsCard._entryColor, label: 'Entrada'),
          SizedBox(width: 10),
          _LegendEntry(color: WeekLocationsCard._exitColor, label: 'Saída'),
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendEntry({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
