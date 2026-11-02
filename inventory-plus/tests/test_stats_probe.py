"""Packaging and Lua behavior of the diagnostic stats probe."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class StatsProbeTests(unittest.TestCase):
    def test_lua_dump_is_read_only_and_detaches(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua, 'Set QH_LUA to Lua 5.1')
        subprocess.run([lua, 'tests/inventory_stats_probe.lua'], cwd=ROOT, check=True)

    def test_package_contains_only_probe(self):
        spec = importlib.util.spec_from_file_location('sp_package', ROOT / 'tools/package_stats_probe.py')
        package = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(package)
        with tempfile.TemporaryDirectory() as folder:
            archive = package.build(folder)
            self.assertEqual(archive.read_bytes(), package.build(folder).read_bytes())
            with zipfile.ZipFile(archive) as z:
                self.assertEqual(set(z.namelist()), set(package.PAYLOAD))
                self.assertEqual(z.read('mods/inventory_plus_stats_probe_native.dll')[:2], b'MZ')
