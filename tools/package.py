#!/usr/bin/env python3
"""Build the native mod ZIP from an explicit public-file allowlist."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'mods/all_quest_markers_native.json'
PAYLOAD = (MANIFEST, 'README.md', 'CHANGELOG.md', 'LICENSE')


def build(output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    version = (ROOT / 'VERSION').read_text().strip()
    manifest = json.loads((ROOT / MANIFEST).read_text())
    if set(manifest) != {'patches'} or len(manifest['patches']) != 3:
        raise ValueError('The release must contain the three working native patches')
    archive = output / f'AllQuestMarkers-{version}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name in sorted(PAYLOAD):
            entry = zipfile.ZipInfo(name, date_time=(2026, 10, 15, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            z.writestr(entry, (ROOT / name).read_bytes())
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n')
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    args = parser.parse_args()
    print(build(args.output))
