#!/usr/bin/env python3
"""Package the diagnostic stats probe (not Inventory Plus)."""
import argparse
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.1'
PAYLOAD = {
    'mods/inventory_plus_stats_probe_native.dll': 'build/inventory_plus_stats_probe_native.dll',
    'mods/inventory_plus_stats_probe.json': 'mods/inventory_plus_stats_probe.json',
    'mods/InventoryPlusStatsProbe/stats_probe.lua': 'mods/InventoryPlusStatsProbe/stats_probe.lua',
    'README.md': 'docs/inventory/stats-probe.md',
    'LICENSE': '../LICENSE',
}


def build(output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f'InventoryPlus-StatsProbe-{VERSION}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, source in sorted(PAYLOAD.items()):
            entry = zipfile.ZipInfo(name, date_time=(2026, 11, 2, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            data = (ROOT / source).read_bytes()
            if not name.endswith('.dll'):
                data = data.replace(b'\r\n', b'\n')
            z.writestr(entry, data)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_bytes(f'{digest}  {archive.name}\n'.encode())
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    print(build(parser.parse_args().output))
