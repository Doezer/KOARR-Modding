#!/usr/bin/env python3
"""Validate Inventory Plus probe logs and reconstruct private bytecode exports.

No game code is executed. Keep output in ignored build/, never publish game dumps.
"""
import argparse
from dataclasses import dataclass, field
import json
from pathlib import Path
import re
import zlib

ROOT = Path(__file__).resolve().parents[1]
PREFIX = '[InventoryPlusProbe] '
KEY = r'[A-Za-z_][A-Za-z0-9_]{0,95}\.[A-Za-z_][A-Za-z0-9_]{0,95}'
MAX_FUNCTION = 32768
MAX_TOTAL = 393216


@dataclass
class Blob:
    size: int
    chunks: dict = field(default_factory=dict)
    checksum: int | None = None


def parse_log(text):
    """Read the most recent BEGIN block; reject missing/conflicting/truncated data."""
    sessions = []
    current = None
    for line in text.splitlines():
        if PREFIX not in line:
            continue
        message = line.split(PREFIX, 1)[1].strip()
        if message.startswith('BEGIN '):
            if message != 'BEGIN version=0.1.0':
                raise ValueError('Unsupported probe log version')
            current = []
            sessions.append(current)
        elif current is not None:
            current.append(message)
    if not sessions:
        raise ValueError('No InventoryPlusProbe BEGIN marker found')
    blobs = {}
    total = 0
    messages = sessions[-1]
    for message in messages:
        if not message.startswith('BLOB-'):
            continue
        begin = re.fullmatch(rf'BLOB-BEGIN ({KEY}) ([0-9]+)', message)
        chunk = re.fullmatch(rf'BLOB-CHUNK ({KEY}) ([0-9]+) ([0-9a-f]+)', message)
        end = re.fullmatch(rf'BLOB-END ({KEY}) ([0-9a-f]{{8}})', message)
        if begin:
            key, size = begin[1], int(begin[2])
            if key in blobs or not 0 < size <= MAX_FUNCTION:
                raise ValueError(f'Duplicate or oversized function: {key}')
            total += size
            if total > MAX_TOTAL:
                raise ValueError('Probe export exceeds total byte budget')
            blobs[key] = Blob(size)
        elif chunk:
            key, offset = chunk[1], int(chunk[2])
            if key not in blobs or len(chunk[3]) % 2:
                raise ValueError(f'Invalid chunk: {key}')
            blob = blobs[key]
            data = bytes.fromhex(chunk[3])
            if (blob.checksum is not None or offset % 96 or offset in blob.chunks
                    or len(data) != min(96, blob.size - offset) or offset >= blob.size):
                raise ValueError(f'Duplicate, late or invalid chunk offset/length: {key}')
            blob.chunks[offset] = data
        elif end:
            key = end[1]
            if key not in blobs or blobs[key].checksum is not None:
                raise ValueError(f'Invalid end marker: {key}')
            blobs[key].checksum = int(end[2], 16)
        else:
            raise ValueError('Malformed probe export record')
    exports = {}
    for key, blob in blobs.items():
        if blob.checksum is None or set(blob.chunks) != set(range(0, blob.size, 96)):
            raise ValueError(f'Incomplete export: {key}; send the full log file')
        data = b''.join(blob.chunks[offset] for offset in sorted(blob.chunks))
        if zlib.adler32(data) != blob.checksum:
            raise ValueError(f'Checksum mismatch: {key}')
        exports[key] = data
    if not exports:
        raise ValueError('No complete function exports in the most recent session')
    return exports, messages, len(sessions)


def extract(log_path, output):
    output = Path(output).resolve()
    # Game bytecode and snapshots must stay outside public tracked directories.
    if (output == ROOT or ROOT in output.parents) and output != ROOT / 'build' and ROOT / 'build' not in output.parents:
        raise ValueError('Inside this repository, use the ignored build/ directory for private output')
    text = Path(log_path).read_text(encoding='utf-8-sig', errors='replace')
    exports, messages, sessions = parse_log(text)
    if not any(key.startswith('inventory_win.') for key in exports):
        raise ValueError('No inventory_win functions found. Open the inventory before collecting the log.')
    # Validate the complete session before writing anything.
    output.mkdir(parents=True, exist_ok=True)
    index = {'probe_version': '0.1.0', 'selected_session': sessions,
             'functions': {key: len(data) for key, data in sorted(exports.items())}}
    for key, data in exports.items():
        (output / f'{key}.bin').write_bytes(data)
    (output / 'index.json').write_text(json.dumps(index, indent=2) + '\n')
    (output / 'observations.txt').write_text('\n'.join(
        m for m in messages if not m.startswith('BLOB-')) + '\n')
    return index


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'build/inventory-probe-private')
    args = parser.parse_args()
    try:
        index = extract(args.log, args.output)
    except (ValueError, OSError) as error:
        parser.exit(1, f'{error}\n')
    print(f'Validated {len(index["functions"])} functions from session {index["selected_session"]}.')
    print(f'Private output: {args.output}')
