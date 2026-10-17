#!/usr/bin/env python3
"""Package the independent Quest Hider preview; never changes AllQuestMarkers artifacts."""
import argparse
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.3-preview'
PAYLOAD = {
    'mods/quest_hider_native.dll': 'build/quest_hider_native.dll',
    'mods/quest_hider.json': 'mods/quest_hider.json',
    'mods/QuestHider/bootstrap.lua': 'mods/QuestHider/bootstrap.lua',
    'mods/QuestHider/config.lua': 'mods/QuestHider/config.lua',
    'README.md': 'docs/quest-hider.md',
    'LICENSE': 'LICENSE',
}


def build(output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f'QuestHider-{VERSION}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, source in sorted(PAYLOAD.items()):
            data = (ROOT / source).read_bytes()
            entry = zipfile.ZipInfo(name, date_time=(2026, 10, 17, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            z.writestr(entry, data)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n')
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    print(build(parser.parse_args().output))
