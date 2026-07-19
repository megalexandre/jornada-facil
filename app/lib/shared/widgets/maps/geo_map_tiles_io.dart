import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:path_provider/path_provider.dart';

/// Fonte de tiles para plataformas com sistema de arquivos (Android/iOS/desktop):
/// mbtiles de ruas offline empacotado nos assets (© OpenStreetMap contributors).
/// Cobertura: Lages do Batata e região (~38x24 km), zoom 13–16.
///
/// A implementação web equivalente ([buildGeoTileLayer] em geo_map_tiles_web.dart)
/// usa tiles de rede; o `flutter_map` escolhe uma das duas via conditional import,
/// então `dart:io`/`path_provider`/`mbtiles` nunca são referenciados na web.
const _asset = 'assets/maps/lages_do_batata.mbtiles';

Future<Widget>? _cached;

/// Abre o mbtiles offline (uma vez por sessão) e devolve o `TileLayer`
/// correspondente. O `mbtiles` só lê arquivos do disco, então o asset é copiado
/// para um diretório gravável antes de abrir.
///
/// Não cacheia falha: se abrir der erro (ex.: asset/plugin nativo ainda não
/// presentes numa build sem rebuild completo), zera para tentar de novo.
Future<Widget> buildGeoTileLayer({
  required int minZoom,
  required int maxZoom,
}) {
  return _cached ??= _open(minZoom, maxZoom).onError<Object>((error, stack) {
    _cached = null;
    Error.throwWithStackTrace(error, stack);
  });
}

Future<Widget> _open(int minZoom, int maxZoom) async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}/lages_do_batata.mbtiles');
  final data = await rootBundle.load(_asset);
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  final mbtiles = MbTiles(mbtilesPath: file.path);
  return TileLayer(
    // silenceTileNotFound: com o arrasto habilitado o usuário pode sair da área
    // coberta (Lages do Batata); sem isto, o mbtiles lança exceção por tile
    // ausente em debug (o APK do CI é --debug). true => tile transparente,
    // mesmo comportamento gracioso da web fora da cobertura.
    tileProvider: MbTilesTileProvider(
      mbtiles: mbtiles,
      silenceTileNotFound: true,
    ),
    minNativeZoom: minZoom,
    maxNativeZoom: maxZoom,
  );
}
