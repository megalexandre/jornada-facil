import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:jornadafacil/core/models/journey_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';

// Fonte de tiles específica por plataforma. Na web (sem `dart:io`) usa tiles de
// rede do OSM; no mobile/desktop usa o mbtiles offline empacotado. Ambos expõem
// `buildGeoTileLayer(...)`, então `dart:io`/`path_provider`/`mbtiles` nunca são
// referenciados num build web.
import 'geo_map_tiles_web.dart'
    if (dart.library.io) 'geo_map_tiles_io.dart';

/// Ponto a plotar no [GeoMap], com a cor do pino e a inicial do dia da semana.
class GeoMapMarker {
  final GeoPoint point;
  final Color color;

  /// Rótulo curto exibido no pino (ex.: inicial do dia da semana "SEG").
  final String label;

  const GeoMapMarker({
    required this.point,
    required this.color,
    this.label = '',
  });

  @override
  bool operator ==(Object other) =>
      other is GeoMapMarker &&
      other.point.latitude == point.latitude &&
      other.point.longitude == point.longitude &&
      other.color == color &&
      other.label == label;

  @override
  int get hashCode =>
      Object.hash(point.latitude, point.longitude, color, label);
}

/// Mapa de ruas que recebe uma lista de pontos geográficos e os plota como
/// pinos rotulados com a inicial do dia. Sempre inicia no centro fixo
/// ([initialCenter]). No card (`interactive: false`) fica sem gestos, para não
/// roubar o scroll da tela; em tela cheia (`interactive: true`) permite
/// arrasto e pinch-zoom. Os tiles vêm da fonte da plataforma (mbtiles offline
/// no mobile, tiles offline na web); ambos © OpenStreetMap contributors.
/// Zoom 13–16.
class GeoMap extends StatelessWidget {
  static const int _minZoom = 13;
  static const int _maxZoom = 16;

  /// Centro fixo em que o mapa sempre inicia (Lages do Batata/BA).
  static const LatLng initialCenter = LatLng(-11.0533216, -40.7818665);
  static const double _initialZoom = 15;

  final List<GeoMapMarker> markers;

  /// Altura do mapa; `null` faz o mapa preencher o pai (usado em tela cheia).
  final double? height;
  final BorderRadius borderRadius;

  /// Habilita arrasto e pinch-zoom. Desligado no card (preserva o scroll).
  final bool interactive;

  const GeoMap({
    super.key,
    required this.markers,
    this.height = 180,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final map = FutureBuilder<Widget>(
      future: buildGeoTileLayer(minZoom: _minZoom, maxZoom: _maxZoom),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('GeoMap: falha ao montar a fonte de tiles: '
              '${snapshot.error}');
          return _MapPlaceholder(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const _MapPlaceholder();
        }
        return _buildMap(snapshot.data!);
      },
    );

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: height == null
            ? SizedBox.expand(child: map)
            : SizedBox(height: height, width: double.infinity, child: map),
      ),
    );
  }

  Widget _buildMap(Widget tileLayer) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: _initialZoom,
        minZoom: _minZoom.toDouble(),
        maxZoom: _maxZoom.toDouble(),
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.scrollWheelZoom | // roda do mouse (desktop/web)
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.flingAnimation
              : InteractiveFlag.none,
        ),
        backgroundColor: AppColors.lightGrey,
      ),
      children: [
        tileLayer,
        MarkerLayer(
          markers: [
            for (final marker in markers)
              Marker(
                point: LatLng(marker.point.latitude, marker.point.longitude),
                width: 48,
                height: 36,
                alignment: Alignment.bottomCenter,
                child: _PinMarker(color: marker.color, label: marker.label),
              ),
          ],
        ),
        const _OsmAttribution(),
      ],
    );
  }
}

/// Página de mapa em tela cheia: mesmo [GeoMap] interativo (arrasto + zoom),
/// preenchendo a tela, com botão voltar e a legenda de entrada/saída.
class GeoMapFullscreenPage extends StatelessWidget {
  final List<GeoMapMarker> markers;
  final String? title;
  final Widget? legend;

  const GeoMapFullscreenPage({
    super.key,
    required this.markers,
    this.title,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title == null ? null : Text(title!),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GeoMap(
              markers: markers,
              height: null,
              interactive: true,
              borderRadius: BorderRadius.zero,
            ),
          ),
          if (legend != null) Positioned(left: 12, bottom: 12, child: legend!),
        ],
      ),
    );
  }
}

/// Pino em forma de "balão" colorido com o rótulo do dia (ex.: "SEG"). A ponta
/// do triângulo cai exatamente na coordenada (alinhamento bottomCenter).
class _PinMarker extends StatelessWidget {
  final Color color;
  final String label;

  const _PinMarker({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.white, width: 1),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
        CustomPaint(size: const Size(10, 6), painter: _PinTipPainter(color)),
      ],
    );
  }
}

/// Triângulo apontando para baixo, ligando o balão à coordenada.
class _PinTipPainter extends CustomPainter {
  final Color color;

  const _PinTipPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTipPainter oldDelegate) => oldDelegate.color != color;
}

/// Fundo enquanto os tiles carregam. Em debug, mostra a mensagem de erro caso a
/// fonte de tiles falhe (ajuda a diagnosticar build sem rebuild no mobile).
class _MapPlaceholder extends StatelessWidget {
  final Object? error;

  const _MapPlaceholder({this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null && kDebugMode) {
      return Container(
        color: AppColors.lightGrey,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          'Mapa indisponível:\n$error',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }
    return Container(color: AppColors.lightGrey);
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        color: AppColors.white.withValues(alpha: 0.7),
        child: Text(
          '© OpenStreetMap',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
