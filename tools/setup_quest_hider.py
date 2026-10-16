#!/usr/bin/env python3
"""Prepare and validate the Linux Quest Hider development environment."""
import hashlib
import os
from pathlib import Path
import subprocess
import tarfile
import urllib.request
from build_quest_hider import ROOT, build

CACHE = Path('/workspace/.aqm-tools')
LUA_SHA256 = '2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333'


def setup():
    CACHE.mkdir(parents=True, exist_ok=True)
    archive = CACHE / 'lua-5.1.5.tar.gz'
    if not archive.exists():
        urllib.request.urlretrieve('https://www.lua.org/ftp/lua-5.1.5.tar.gz', archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != LUA_SHA256:
        raise ValueError('Official Lua archive checksum mismatch')
    source = CACHE / 'lua-5.1.5'
    if not source.exists():
        with tarfile.open(archive) as tar:
            tar.extractall(CACHE, filter='data')
    # The generic target avoids an unnecessary readline dependency.
    subprocess.run(['make', 'generic'], cwd=source, check=True)
    subprocess.run([str(source / 'src/lua'), '-v'], check=True)
    build(Path('/workspace/.quest-hider-tools'))
    env = dict(os.environ, QH_LUA=str(source / 'src/lua'))
    subprocess.run(['python', '-m', 'unittest', 'discover', '-s', 'tests', '-v'],
                   cwd=ROOT, env=env, check=True)


if __name__ == '__main__':
    setup()
