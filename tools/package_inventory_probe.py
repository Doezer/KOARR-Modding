#!/usr/bin/env python3
"""Package the independent diagnostic spike, not the Inventory Plus overhaul."""
import argparse
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD = {
    'mods/inventory_plus_probe.json': 'mods/inventory_plus_probe.json',
    'mods/InventoryPlusProbe/probe.lua': 'mods/InventoryPlusProbe/probe.lua',
    'README.md': 'docs/inventory/probe.md',
    'LICENSE': 'LICENSE',
}


def build(output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    archive = output / 'InventoryPlus-Probe-0.1.1.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, source in sorted(PAYLOAD.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 10, 16, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            z.writestr(info, (ROOT / source).read_bytes())
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n')
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    print(build(parser.parse_args().output))
