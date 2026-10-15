import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('package', ROOT / 'tools/package.py')
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class PackageTests(unittest.TestCase):
    def test_payload_layout_and_no_unsupported_autoload_or_third_party_assets(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = package.build(tmp)
            with zipfile.ZipFile(archive) as z:
                names = z.namelist()
                self.assertIn('mods/AllQuestMarkers/bootstrap.lua', names)
                self.assertIn('mods/AllQuestMarkers/probe.lua', names)
                self.assertIn('docs/research.md', names)
                self.assertEqual(len([n for n in names if n.endswith('.lua')]), 10)
                for name in names:
                    self.assertFalse(name.startswith('/') or '..' in Path(name).parts)
                    self.assertTrue(name.endswith(('.lua', '.md', '.txt')) or name == 'LICENSE')
                self.assertIn('DOES NOT display quest markers', z.read('PACKAGE-STATUS.txt').decode())
                for path in (ROOT / 'mods/AllQuestMarkers').glob('*.lua'):
                    self.assertEqual(z.read(path.relative_to(ROOT).as_posix()), path.read_bytes())

    def test_reproducible_archive_and_checksum(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            first, second = package.build(a), package.build(b)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            checksum = hashlib.sha256(first.read_bytes()).hexdigest()
            self.assertEqual(first.with_suffix('.zip.sha256').read_text(), f'{checksum}  {first.name}\n')

    def test_manifest_uses_explicit_trigger_and_confirmed_loader_schema(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = package.build(tmp, 'observed/test_module')
            with zipfile.ZipFile(archive) as z:
                manifest = json.loads(z.read('mods/all_quest_markers_probe.json'))
                self.assertEqual(manifest, {'scripts': [{
                    'trigger': 'observed/test_module', 'path': '.\\mods\\AllQuestMarkers\\probe.lua'}]})
                self.assertIn('mods/AllQuestMarkers/probe.lua', z.namelist())

    def test_empty_or_control_character_trigger_rejected(self):
        for trigger in ('', 'bad\ntrigger', 'x' * 257):
            with self.subTest(trigger=repr(trigger)), tempfile.TemporaryDirectory() as tmp:
                with self.assertRaises(ValueError):
                    package.build(tmp, trigger)

    def test_extracted_bootstrap_and_probe_execute_from_game_working_directory(self):
        lua = os.environ.get('AQM_LUA', '/workspace/.aqm-tools/lua-5.1.5/src/lua')
        self.assertTrue(Path(lua).is_file(), 'Lua runtime must be installed, not skipped')
        with tempfile.TemporaryDirectory() as tmp:
            archive = package.build(Path(tmp) / 'out')
            game = Path(tmp) / 'game'
            with zipfile.ZipFile(archive) as z:
                z.extractall(game)
            code = ("local m=assert(loadfile('mods/AllQuestMarkers/bootstrap.lua'))();"
                    "assert(m.status=='game-adapter-unverified');assert(m.detach());"
                    "assert(m.refresh()==false);assert(m.attach({})==false)")
            result = subprocess.run([lua, '-e', code], cwd=game, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('[AllQuestMarkers][probe] BEGIN', result.stdout)
            self.assertIn('no verified game adapter', result.stdout)
