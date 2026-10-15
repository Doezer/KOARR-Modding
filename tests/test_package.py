import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


package = module('package', ROOT / 'tools/package.py')
verifier = module('verifier', ROOT / 'tools/verify_executable.py')


class PackageTests(unittest.TestCase):
    def test_release_contains_only_installable_manifest_and_public_documentation(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = package.build(tmp)
            self.assertEqual(archive.name, 'AllQuestMarkers-1.0.1.zip')
            with zipfile.ZipFile(archive) as z:
                self.assertEqual(set(z.namelist()), {
                    'mods/all_quest_markers_native.json', 'README.md', 'CHANGELOG.md', 'LICENSE'})
                for name in z.namelist():
                    self.assertFalse(name.startswith('/') or '..' in Path(name).parts)
                    self.assertEqual(z.read(name), (ROOT / name).read_bytes())
                self.assertIn('no console command', z.read('README.md').decode())
                self.assertNotIn('PACKAGE-STATUS.txt', z.namelist())

    def test_reproducible_archive_and_checksum(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            first, second = package.build(a), package.build(b)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            checksum = hashlib.sha256(first.read_bytes()).hexdigest()
            self.assertEqual(first.with_suffix('.zip.sha256').read_text(), f'{checksum}  {first.name}\n')

    def test_extracted_mod_uses_three_native_patches_without_script_triggers(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = package.build(Path(tmp) / 'out')
            game = Path(tmp) / 'game'
            with zipfile.ZipFile(archive) as z:
                z.extractall(game)
            manifest = json.loads((game / package.MANIFEST).read_text())
            self.assertEqual(set(manifest), {'patches'})
            self.assertEqual(len(manifest['patches']), 3)
            for i, patch in enumerate(manifest['patches']):
                self.assertEqual(set(patch), {'description', 'signature', 'patch'})
                self.assertTrue(patch['description'])
                signature = bytes.fromhex(patch['signature'])
                tokens = patch['patch'].split()
                self.assertEqual(len(signature), len(tokens))
                if i < 2:
                    self.assertEqual(tokens[:34], ['??'] * 34)
                    self.assertEqual(signature[34:36], bytes.fromhex('0F 84'))
                    self.assertEqual(tokens[34:], ['90'] * 6)
                else:
                    self.assertEqual(len(signature), 36)
                    self.assertEqual(bytes.fromhex(patch['patch'])[4:11], bytes.fromhex('83 BE 90 04 00 00 04'))

    def test_executable_verifier_rejects_unknown_build_without_writing_it(self):
        with tempfile.TemporaryDirectory() as tmp:
            exe = Path(tmp) / 'koa.exe'
            content = b'MZ unsupported build'
            exe.write_bytes(content)
            with self.assertRaisesRegex(ValueError, 'Unsupported executable SHA-256'):
                verifier.verify(exe)
            self.assertEqual(exe.read_bytes(), content)
