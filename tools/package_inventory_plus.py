#!/usr/bin/env python3
"""Package the independent Inventory Plus search UI trial."""
import argparse
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.0-ui-trial'
PAYLOAD = {
    'mods/inventory_plus_native.dll': 'build/inventory_plus_native.dll',
    'mods/inventory_plus.json': 'mods/inventory_plus.json',
    'mods/InventoryPlus/ui_trial.lua': 'mods/InventoryPlus/ui_trial.lua',
    'README.md': 'docs/inventory/ui-trial.md',
    'LICENSE': 'LICENSE',
}


def build(output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f'InventoryPlus-{VERSION}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, source in sorted(PAYLOAD.items()):
            entry = zipfile.ZipInfo(name, date_time=(2026, 10, 17, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            z.writestr(entry, (ROOT / source).read_bytes())
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n')
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    print(build(parser.parse_args().output))
