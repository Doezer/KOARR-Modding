#!/usr/bin/env python3
"""Build the diagnostic stats-probe helper with Zig 0.13.0 (PATH `zig` or `python -m ziglang`)."""
import argparse
import shutil
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def default_zig():
    found = shutil.which('zig')
    return [found] if found else [sys.executable, '-m', 'ziglang']


def build(zig):
    output = ROOT / 'build/inventory_plus_stats_probe_native.dll'
    output.parent.mkdir(exist_ok=True)
    subprocess.run([*zig, 'cc', '-target', 'x86-windows-gnu', '-shared', '-static', '-s', '-O2',
                    '-Wall', '-Wextra', '-Werror', '-mno-sse', '-mno-sse2',
                    'src/inventory_stats_probe/native.c', '-o', str(output), '-luser32'],
                   cwd=ROOT, check=True)
    data = bytearray(output.read_bytes())
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    struct.pack_into('<I', data, pe + 8, 0)  # reproducible PE timestamp
    output.write_bytes(data)
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--zig', nargs='+', default=default_zig())
    print(build(parser.parse_args().zig))
