#!/usr/bin/env python3
"""Cross-compile Quest Hider with the official, checksum-pinned Zig toolchain."""
import argparse
import sys
import hashlib
import os
from pathlib import Path
import subprocess
import struct
import tarfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'common/tools'))
from zig_toolchain import VERSION, SHA256, DIRECTORY


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
    env = dict(os.environ, ZIG_GLOBAL_CACHE_DIR=str(cache / 'global-cache'),
               ZIG_LOCAL_CACHE_DIR=str(cache / 'local-cache'))
    output = ROOT / 'build/quest_hider_native.dll'
    output.parent.mkdir(exist_ok=True)
    subprocess.run([str(zig), 'cc', '-target', 'x86-windows-gnu', '-shared', '-static', '-s',
                    '-O2', '-Wall', '-Wextra', '-Werror', '-mno-sse', '-mno-sse2',
                    'src/quest_hider/native.c', 'src/quest_hider/store.c',
                    'src/quest_hider/render_hook.S', '-o', str(output), '-lbcrypt', '-luser32'],
                   cwd=ROOT, env=env, check=True)
    # Unsigned DLL: normalize the PE timestamp for repeatable packaging.
    data = bytearray(output.read_bytes())
    pe_offset = struct.unpack_from("<I", data, 0x3c)[0]
    struct.pack_into("<I", data, pe_offset + 8, 0)
    output.write_bytes(data)
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', type=Path, default=Path('/workspace/.quest-hider-tools'))
    print(build(parser.parse_args().cache))
