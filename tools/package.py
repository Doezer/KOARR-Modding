#!/usr/bin/env python3
"""Package only our source/docs. Never guess a framework trigger."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def build(output, trigger=None):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    payload = {}
    for path in sorted((ROOT / 'mods' / 'AllQuestMarkers').glob('*.lua')):
        payload[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    for path in [ROOT / 'README.md', ROOT / 'LICENSE', *sorted((ROOT / 'docs').glob('*.md'))]:
        payload[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    if trigger is not None:
        if not trigger or len(trigger) > 256 or any(ord(c) < 32 for c in trigger):
            raise ValueError('Supply an exact observed framework script trigger, without control characters')
        # Confirmed shape: DevCortez/KoaModFramework LoadMod scripts[].trigger/path.
        payload['mods/all_quest_markers_probe.json'] = (json.dumps({'scripts': [{
            'trigger': trigger, 'path': '.\\mods\\AllQuestMarkers\\probe.lua'
        }]}, indent=2) + '\n').encode()
    payload['PACKAGE-STATUS.txt'] = (
        'AllQuestMarkers 0.1.4 — PROBE AND TESTED CORE ONLY\n'
        'No game adapter is implemented. This package DOES NOT display quest markers.\n'
        + ('Probe autoload trigger supplied by operator; runtime compatibility unverified.\n'
           if trigger else 'Manual console load; no autoload manifest or guessed trigger.\n')
    ).encode()
    archive = output / 'AllQuestMarkers-probe-0.1.4.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, data in sorted(payload.items()):
            entry = zipfile.ZipInfo(name, date_time=(2026, 10, 14, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            z.writestr(entry, data)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n')
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    parser.add_argument('--probe-trigger', help='Exact trigger observed in a working sample/framework log; optional')
    args = parser.parse_args()
    print(build(args.output, args.probe_trigger))
