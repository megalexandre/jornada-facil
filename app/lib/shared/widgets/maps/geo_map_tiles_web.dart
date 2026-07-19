import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Fonte de tiles para a web: os mesmos tiles de ruas offline do mobile, só que
/// empacotados como assets individuais em vez de mbtiles.
///
/// A web não tem sqlite3 nativo, então o mbtiles (geo_map_tiles_io.dart) não roda
/// aqui. Em vez de depender do OSM em rede, servimos a mesma cobertura (Lages do
/// Batata e região, zoom 13–16) a partir de PNGs empacotados em `assets/maps/tiles/`,
/// gerados de `lages_do_batata.mbtiles` por `tool/build_web_tiles.py`. Assim o
/// mapa também fica offline na web. © OpenStreetMap contributors.
///
/// Os arquivos usam nomes achatados `{z}_{x}_{y}.png` (XYZ, y=0 no norte — a
/// conversão de TMS→XYZ é feita na geração) e ficam num único diretório porque a
/// declaração de assets do Flutter não é recursiva por subpasta.
///
/// O `flutter_map` escolhe esta implementação por conditional import quando
/// `dart:io` não está disponível.

/// PNG transparente de 1×1, usado para tiles fora da cobertura (as bordas da
/// viewport podem cair fora da área coberta). Sem isso o `AssetTileProvider`
/// lançaria exceção ao não achar o asset; com ele, o tile ausente fica vazio —
/// mesmo comportamento do mbtiles no mobile.
final MemoryImage _transparentTile = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0B, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x60, 0x00, 0x02, 0x00,
    0x00, 0x05, 0x00, 0x01, 0xE9, 0xFA, 0xDC, 0xD8, 0x00, 0x00, 0x00, 0x00,
    0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

Future<Widget> buildGeoTileLayer({
  required int minZoom,
  required int maxZoom,
}) {
  return Future.value(
    TileLayer(
      urlTemplate: 'assets/maps/tiles/{z}_{x}_{y}.png',
      tileProvider: AssetTileProvider(),
      minNativeZoom: minZoom,
      maxNativeZoom: maxZoom,
      minZoom: minZoom.toDouble(),
      maxZoom: maxZoom.toDouble(),
      errorImage: _transparentTile,
    ),
  );
}
