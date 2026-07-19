#!/usr/bin/env python3
"""Explode o mbtiles offline em PNGs individuais para uso na web.

O mobile (Android/iOS) lê o mbtiles direto via flutter_map_mbtiles, mas a web não
tem sqlite3 nativo. Este script deriva, a partir do MESMO mbtiles, uma árvore de
tiles como assets do Flutter, que a web consome via AssetTileProvider.

Saída: assets/maps/tiles/{z}_{x}_{y}.png  (nomes achatados num único diretório,
para o pubspec precisar de apenas uma entrada de asset — a declaração de assets do
Flutter não é recursiva por subpasta).

Conversão de esquema: o mbtiles guarda os tiles em TMS (y=0 no sul); o urlTemplate
do flutter_map espera XYZ (y=0 no norte), então invertemos: y_xyz = 2^z - 1 - row.

Rode a partir de app/:  python3 tool/build_web_tiles.py
"""
import shutil
import sqlite3
import sys
from pathlib import Path

MBTILES = Path("assets/maps/lages_do_batata.mbtiles")
OUT_DIR = Path("assets/maps/tiles")


def main() -> int:
    if not MBTILES.exists():
        print(f"erro: {MBTILES} não encontrado (rode a partir de app/)", file=sys.stderr)
        return 1

    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)
    OUT_DIR.mkdir(parents=True)

    db = sqlite3.connect(str(MBTILES))
    rows = db.execute(
        "select zoom_level, tile_column, tile_row, tile_data from tiles"
    )
    count = 0
    total_bytes = 0
    for z, x, tms_row, data in rows:
        y_xyz = (2**z - 1) - tms_row
        (OUT_DIR / f"{z}_{x}_{y_xyz}.png").write_bytes(data)
        count += 1
        total_bytes += len(data)
    db.close()

    print(f"gerados {count} tiles em {OUT_DIR}/ ({total_bytes/1024:.1f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
