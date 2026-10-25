#!/usr/bin/env python3
"""Run each mod's offline checks from its independent development root."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
for mod in ('all-quest-markers', 'quest-hider', 'inventory-plus'):
    print(f'Testing {mod}', flush=True)
    subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests', '-q'],
                   cwd=ROOT / mod, check=True)
