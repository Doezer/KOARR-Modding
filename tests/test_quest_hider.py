"""Behavioral checks for the independent Quest Hider mod."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class QuestHiderTests(unittest.TestCase):
    def test_preference_store(self):
        with tempfile.TemporaryDirectory() as folder:
            binary = str(Path(folder) / 'store-test')
            subprocess.run(['cc', '-std=c99', '-Wall', '-Wextra', '-Werror',
                            '-Isrc/quest_hider', 'tests/quest_hider_store.c',
                            'src/quest_hider/store.c', '-o', binary], cwd=ROOT, check=True)
            subprocess.run([binary], check=True)

    def test_native_library_registration_balances_the_lua_stack(self):
        with tempfile.TemporaryDirectory() as folder:
            binary = str(Path(folder) / 'bridge-test')
            subprocess.run(['cc', '-std=c99', '-Wall', '-Wextra', '-Werror',
                            '-Isrc/quest_hider', 'tests/quest_hider_vm_bridge.c',
                            '-o', binary], cwd=ROOT, check=True)
            subprocess.run([binary], check=True)

    def test_journal_adapter(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua, 'Set QH_LUA to a Lua 5.1 interpreter')
        subprocess.run([lua, 'tests/quest_hider_journal.lua'], cwd=ROOT, check=True)

    def test_startup_native_initialization_is_deferred(self):
        lua = os.environ.get('QH_LUA') or shutil.which('lua5.1') or shutil.which('lua')
        self.assertIsNotNone(lua, 'Set QH_LUA to a Lua 5.1 interpreter')
        subprocess.run([lua, 'tests/quest_hider_startup.lua'], cwd=ROOT, check=True)

    def test_release_package(self):
        spec = importlib.util.spec_from_file_location('qh_package', ROOT / 'tools/package_quest_hider.py')
        package = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(package)
        with tempfile.TemporaryDirectory() as folder:
            archive = package.build(folder)
            first = archive.read_bytes()
            self.assertEqual(first, package.build(folder).read_bytes())
            with zipfile.ZipFile(archive) as z:
                self.assertEqual(set(z.namelist()), set(package.PAYLOAD))
                self.assertNotIn('mods/all_quest_markers_native.json', z.namelist())
                self.assertEqual(z.read('mods/quest_hider_native.dll')[:2], b'MZ')
                import json
                scripts = json.loads(z.read('mods/quest_hider.json'))['scripts']
                for trigger in ('quests_win', 'minimap_win', 'ledger_win'):
                    names = [entry['path'].replace('\\', '/').split('/')[-1]
                             for entry in scripts if entry['trigger'] == trigger]
                    self.assertEqual(names, ['config.lua', 'bootstrap.lua'])


if __name__ == '__main__':
    unittest.main()
