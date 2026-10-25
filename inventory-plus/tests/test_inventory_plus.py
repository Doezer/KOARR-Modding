"""Input isolation and packaging for the Inventory Plus preview."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class InventoryPlusTests(unittest.TestCase):
    def test_shortcut_edges_and_focus(self):
        with tempfile.TemporaryDirectory() as folder:
            binary = str(Path(folder) / 'input-test')
            subprocess.run(['cc', '-std=c99', '-Wall', '-Wextra', '-Werror',
                            '-Isrc/inventory_plus', 'tests/inventory_plus_input.c',
                            '-o', binary], cwd=ROOT, check=True)
            subprocess.run([binary], check=True)

    def test_native_name_borrowing_and_invalid_items(self):
        with tempfile.TemporaryDirectory() as folder:
            binary = str(Path(folder) / 'names-test')
            subprocess.run(['cc', '-std=c99', '-Wall', '-Wextra', '-Werror',
                            '-Isrc/inventory_plus', 'tests/inventory_plus_names.c',
                            '-o', binary], cwd=ROOT, check=True)
            subprocess.run([binary], check=True)

    def test_native_dialog_guard_and_return_to_inventory(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua, 'Set QH_LUA to Lua 5.1')
        subprocess.run([lua, 'tests/inventory_plus_ui.lua'], cwd=ROOT, check=True)

    def test_tab_click_does_not_reach_native_controls(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua)
        subprocess.run([lua, 'tests/inventory_click_guard.lua'], cwd=ROOT, check=True)

    def test_native_navigation(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua)
        subprocess.run([lua, 'tests/inventory_navigation.lua'], cwd=ROOT, check=True)

    def test_handle_preserving_view_model(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua, 'Set QH_LUA to Lua 5.1')
        subprocess.run([lua, 'tests/inventory_plus_model.lua'], cwd=ROOT, check=True)

    def test_preview_package(self):
        spec = importlib.util.spec_from_file_location('ip_package', ROOT / 'tools/package_inventory_plus.py')
        package = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(package)
        with tempfile.TemporaryDirectory() as folder:
            archive = package.build(folder)
            self.assertEqual(archive.read_bytes(), package.build(folder).read_bytes())
            with zipfile.ZipFile(archive) as z:
                self.assertEqual(set(z.namelist()), set(package.PAYLOAD))
                self.assertEqual(z.read('mods/inventory_plus_native.dll')[:2], b'MZ')
                self.assertNotIn('mods/inventory_plus_probe.json', z.namelist())
                self.assertIn('mods/InventoryPlus/navigation.lua', z.namelist())
                self.assertNotIn('mods/quest_hider_native.dll', z.namelist())
                import json
                scripts = json.loads(z.read('mods/inventory_plus.json'))['scripts']
                for trigger in ('inventory_win', 'name_win', 'ledger_win'):
                    paths = [entry['path'].replace('\\', '/').split('/')[-1]
                             for entry in scripts if entry['trigger'] == trigger]
                    self.assertEqual(paths, ['model.lua', 'navigation.lua', 'inventory_plus.lua'])
