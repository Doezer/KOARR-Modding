#!/usr/bin/env python3
"""Build the Inventory Plus keyboard helper with the pinned Zig toolchain."""
import argparse
import hashlib
import os
from pathlib import Path
import struct
import subprocess
import tarfile
import urllib.request
from build_quest_hider import VERSION, SHA256, DIRECTORY

ROOT = Path(__file__).resolve().parents[1]


def build(cache):
    cache = cache.resolve()
    cache.mkdir(parents=True, exist_ok=True)
    zig = cache / DIRECTORY / 'zig'
    if not zig.exists():
        archive = cache / f'zig-{VERSION}.tar.xz'
        if not archive.exists():
            urllib.request.urlretrieve(f'https://ziglang.org/download/{VERSION}/{DIRECTORY}.tar.xz', archive)
        if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
            raise ValueError('Official Zig archive checksum mismatch')
        with tarfile.open(archive) as tar:
            tar.extractall(cache, filter='data')
    output = ROOT / 'build/inventory_plus_native.dll'
    output.parent.mkdir(exist_ok=True)
    env = dict(os.environ, ZIG_GLOBAL_CACHE_DIR=str(cache / 'global-cache'),
               ZIG_LOCAL_CACHE_DIR=str(cache / 'local-cache'))
    subprocess.run([str(zig), 'cc', '-target', 'x86-windows-gnu', '-shared', '-static', '-s',
                    '-O2', '-Wall', '-Wextra', '-Werror', '-mno-sse', '-mno-sse2',
                    'src/inventory_plus/native.c', '-o', str(output), '-luser32'],
                   cwd=ROOT, env=env, check=True)
    data = bytearray(output.read_bytes())
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    struct.pack_into('<I', data, pe + 8, 0)
    output.write_bytes(data)
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', type=Path, default=Path('/workspace/.quest-hider-tools'))
    print(build(parser.parse_args().cache))
