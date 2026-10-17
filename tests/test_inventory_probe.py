"""Check passive probe behavior and corruption-resistant private export handling."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile
import zlib
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import read_inventory_probe as reader
import package_inventory_probe as package


def log_for(data=b'example bytecode'):
    key = 'inventory_win.get_selected'
    lines = ['[InventoryPlusProbe] BEGIN version=0.1.0',
             f'[InventoryPlusProbe] BLOB-BEGIN {key} {len(data)}']
    lines.extend(f'[InventoryPlusProbe] BLOB-CHUNK {key} {offset} {data[offset:offset+96].hex()}'
                 for offset in range(0, len(data), 96))
    lines.append(f'[InventoryPlusProbe] BLOB-END {key} {zlib.adler32(data):08x}')
    return '\n'.join(lines)


class InventoryProbeTests(unittest.TestCase):
    def test_passive_lua_probe_and_roundtrip(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua, 'Set QH_LUA to a Lua 5.1 interpreter')
        with tempfile.TemporaryDirectory() as folder:
            subprocess.run([lua, 'tests/inventory_probe.lua', folder], cwd=ROOT, check=True)
            index = reader.extract(Path(folder) / 'probe.log', Path(folder) / 'private')
            self.assertIn('inventory_win.get_selected_item', index['functions'])
            self.assertEqual((Path(folder) / 'private/inventory_win.get_selected_item.bin').read_bytes(),
                             (Path(folder) / 'expected.bin').read_bytes())

    def test_placeholder_module_is_revisited_after_its_body_loads(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua, 'Set QH_LUA to a Lua 5.1 interpreter')
        with tempfile.TemporaryDirectory() as folder:
            subprocess.run([lua, 'tests/inventory_probe_placeholder.lua', folder], cwd=ROOT, check=True)
            index = reader.extract(Path(folder) / 'placeholder.log', Path(folder) / 'private')
            self.assertEqual(index['probe_version'], '0.1.1')
            self.assertIn('inventory_win.on_window_event', index['functions'])

    def test_partial_utility_log_can_be_retained_explicitly(self):
        log = log_for().replace('inventory_win.get_selected', 'menu_tools.create_standard_list')
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / 'input.log'
            source.write_text(log)
            with self.assertRaises(ValueError):
                reader.extract(source, Path(folder) / 'default')
            index = reader.extract(source, Path(folder) / 'partial', allow_partial=True)
            self.assertIn('menu_tools.create_standard_list', index['functions'])

    def test_truncated_duplicate_and_corrupt_exports_rejected(self):
        good = log_for(bytes(range(256)))
        lines = good.splitlines()
        cases = [good.rsplit('\n', 1)[0], '\n'.join(lines[:2] + lines[3:]),
                 '\n'.join(lines[:3] + [lines[2]] + lines[3:]),
                 good.replace(' 0 00', ' 0 ff'),
                 good.replace('inventory_win.get_selected', '../escape'),
                 good.replace(' 256', ' 999999'),
                 good.replace('BLOB-CHUNK', 'BLOB-BROKEN'),
                 good.replace(' 96 ', ' 97 ')]
        for bad in cases:
            with self.subTest(log=bad[:100]):
                with self.assertRaises(ValueError):
                    reader.parse_log(bad)

    def test_newest_session_selected_and_incomplete_latest_rejected(self):
        data, _, count = reader.parse_log(log_for(b'first') + '\n' + log_for(b'second'))
        self.assertEqual(count, 2)
        self.assertEqual(data['inventory_win.get_selected'], b'second')
        with self.assertRaises(ValueError):
            reader.parse_log(log_for() + '\n[InventoryPlusProbe] BEGIN version=0.1.0')

    def test_invalid_log_writes_nothing_and_repo_output_guard(self):
        with tempfile.TemporaryDirectory() as folder:
            log = Path(folder) / 'log.txt'
            log.write_text(log_for().rsplit('\n', 1)[0])
            destination = Path(folder) / 'output'
            with self.assertRaises(ValueError):
                reader.extract(log, destination)
            self.assertFalse(destination.exists())
            with self.assertRaises(ValueError):
                reader.extract(log, ROOT / 'mods/private-dumps')

    def test_reproducible_probe_package_contains_no_existing_mod(self):
        with tempfile.TemporaryDirectory() as folder:
            archive = package.build(folder)
            before = archive.read_bytes()
            self.assertEqual(before, package.build(folder).read_bytes())
            with zipfile.ZipFile(archive) as z:
                self.assertEqual(set(z.namelist()), set(package.PAYLOAD))
                self.assertFalse(any(name.endswith(('.bin', '.dll')) for name in z.namelist()))
                manifest = z.read('mods/inventory_plus_probe.json')
                self.assertIn(b'"trigger": "inventory_win"', manifest)


if __name__ == '__main__':
    unittest.main()
