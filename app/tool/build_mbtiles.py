#!/usr/bin/env python3
"""Gera um arquivo .mbtiles offline para uma bounding box e faixa de zoom.

Uso:
    python3 tool/build_mbtiles.py

Baixa os tiles raster (256x256 PNG) do OpenStreetMap para a área de Lages do
Batata e empacota tudo em assets/maps/lages_do_batata.mbtiles (SQLite no
formato MBTiles 1.3, esquema de linhas TMS).

Licença dos dados: © OpenStreetMap contributors (ODbL). A atribuição é
obrigatória e já vai gravada no metadata do arquivo. Para volume maior ou uso
recorrente, renderize seus próprios tiles ou use um provedor com plano offline
em vez do tile server público do OSM.
"""

import math
import sqlite3
import time
import urllib.request
from pathlib import Path

# Bounding box (Lages do Batata e região, ~38x24 km) — oeste, sul, leste, norte.
WEST, SOUTH, EAST, NORTH = -40.9015666, -11.1651426, -40.5511305, -10.9442581
MIN_ZOOM, MAX_ZOOM = 13, 16

TILE_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
USER_AGENT = "jornadafacil-mbtiles-builder/1.0 (megalexandre@gmail.com)"
OUT_PATH = Path(__file__).resolve().parent.parent / "assets" / "maps" / "lages_do_batata.mbtiles"
REQUEST_DELAY_S = 0.1  # gentileza com o tile server


def lon2x(lon: float, z: int) -> int:
    return int((lon + 180.0) / 360.0 * (1 << z))


def lat2y(lat: float, z: int) -> int:
    r = math.radians(lat)
    return int((1.0 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2.0 * (1 << z))


def fetch(z: int, x: int, y: int, attempts: int = 4) -> bytes:
    req = urllib.request.Request(
        TILE_URL.format(z=z, x=x, y=y), headers={"User-Agent": USER_AGENT}
    )
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.read()
        except Exception as err:  # noqa: BLE001 - transitório (timeout/429/5xx)
            if attempt == attempts:
                raise
            wait = attempt * 2  # backoff simples: 2s, 4s, 6s
            print(f"  z{z}/{x}/{y}: tentativa {attempt} falhou ({err}); "
                  f"repetindo em {wait}s")
            time.sleep(wait)
    raise RuntimeError("inalcançável")


def main() -> None:
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    if OUT_PATH.exists():
        OUT_PATH.unlink()

    db = sqlite3.connect(OUT_PATH)
    db.executescript(
        """
        CREATE TABLE metadata (name TEXT, value TEXT);
        CREATE TABLE tiles (
            zoom_level INTEGER, tile_column INTEGER,
            tile_row INTEGER, tile_data BLOB
        );
        CREATE UNIQUE INDEX tile_index
            ON tiles (zoom_level, tile_column, tile_row);
        """
    )
    center_lon = (WEST + EAST) / 2
    center_lat = (SOUTH + NORTH) / 2
    db.executemany(
        "INSERT INTO metadata (name, value) VALUES (?, ?)",
        [
            ("name", "Lages do Batata e região"),
            ("format", "png"),
            ("bounds", f"{WEST},{SOUTH},{EAST},{NORTH}"),
            ("center", f"{center_lon},{center_lat},{MIN_ZOOM}"),
            ("minzoom", str(MIN_ZOOM)),
            ("maxzoom", str(MAX_ZOOM)),
            ("type", "baselayer"),
            ("version", "1.0"),
            ("attribution", "© OpenStreetMap contributors"),
        ],
    )

    total = downloaded = 0
    for z in range(MIN_ZOOM, MAX_ZOOM + 1):
        x0, x1 = lon2x(WEST, z), lon2x(EAST, z)
        y0, y1 = lat2y(NORTH, z), lat2y(SOUTH, z)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                total += 1
                data = fetch(z, x, y)
                # MBTiles usa linha TMS (y invertido em relação ao esquema XYZ).
                tms_y = (1 << z) - 1 - y
                db.execute(
                    "INSERT INTO tiles VALUES (?, ?, ?, ?)",
                    (z, x, tms_y, sqlite3.Binary(data)),
                )
                downloaded += 1
                time.sleep(REQUEST_DELAY_S)
        db.commit()
        print(f"z{z}: {(x1 - x0 + 1) * (y1 - y0 + 1)} tiles")

    db.commit()
    db.close()
    size_mb = OUT_PATH.stat().st_size / (1024 * 1024)
    print(f"\nOK: {downloaded}/{total} tiles → {OUT_PATH} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
