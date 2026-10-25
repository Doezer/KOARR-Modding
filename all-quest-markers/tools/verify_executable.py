#!/usr/bin/env python3
"""Read-only exact-build and patch-signature verification; never writes an EXE."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SHA256 = '16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314'


def verify(executable):
    data = Path(executable).read_bytes()
    if hashlib.sha256(data).hexdigest() != EXPECTED_SHA256:
        raise ValueError('Unsupported executable SHA-256; this is not the analyzed GOG build')
    pe_offset = struct.unpack_from('<I', data, 0x3c)[0]
    if data[:2] != b'MZ' or data[pe_offset:pe_offset + 4] != b'PE\0\0':
        raise ValueError('Expected a Windows PE executable')
    machine, count = struct.unpack_from('<HH', data, pe_offset + 4)
    optional_size = struct.unpack_from('<H', data, pe_offset + 20)[0]
    optional = pe_offset + 24
    if machine != 0x14c or struct.unpack_from('<H', data, optional)[0] != 0x10b:
        raise ValueError('Expected the 32-bit GOG executable')
    size = struct.unpack_from('<I', data, optional + 56)[0]
    headers = struct.unpack_from('<I', data, optional + 60)[0]
    image = bytearray(size)
    image[:headers] = data[:headers]
    for index in range(count):
        section = optional + optional_size + index * 40
        rva, raw_size, raw_offset = struct.unpack_from('<III', data, section + 12)
        image[rva:rva + raw_size] = data[raw_offset:raw_offset + raw_size]
    manifest = json.loads((ROOT / 'mods/all_quest_markers_native.json').read_text())
    occupied = set()
    results = []
    for patch in manifest['patches']:
        signature = bytes.fromhex(patch['signature'])
        match = image.find(signature)
        if match < 0 or image.find(signature, match + 1) >= 0:
            raise ValueError(f"Signature must match exactly once: {patch['description']}")
        tokens = patch['patch'].split()
        if len(tokens) != len(signature):
            raise ValueError('Patch/signature length mismatch')
        region = set(range(match, match + len(tokens)))
        if occupied & region:
            raise ValueError('Overlapping patches')
        occupied |= region
        for token in tokens:
            if token != '??' and (len(token) != 2 or not 0 <= int(token, 16) <= 255):
                raise ValueError('Invalid patch byte')
        results.append((patch['description'], match))
    if len(results) != 3:
        raise ValueError('Expected all three native patches')
    return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    args = parser.parse_args()
    try:
        results = verify(args.executable)
    except (ValueError, OSError) as error:
        parser.exit(1, f'Verification failed: {error}\n')
    for description, rva in results:
        print(f'PASS RVA {rva:08X}: {description}')
    print('Exact executable hash and all three non-overlapping signatures verified; file unchanged.')
