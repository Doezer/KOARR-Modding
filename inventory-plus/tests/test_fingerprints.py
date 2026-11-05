"""Every native fingerprint must match the real executable at any load base.

Set KOA_EXE to a private supported koa.exe (needs pefile); otherwise skipped.
Regression for 0.6.0, whose reader fingerprints held a rebased absolute address.
"""
import os
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ('src/inventory_plus/native.c', 'src/inventory_stats_probe/native.c')


def checks(text):
    arrays = {name: bytes(int(b, 16) for b in body.split(','))
              for name, body in re.findall(r'unsigned char (\w+)\[\]=\{([^}]*)\}', text)}
    pairs = re.findall(r'memcmp\(\(void\*\)VA\((0x[0-9a-fA-F]+)\),(\w+),sizeof\(\2\)\)', text)
    return [(int(va, 16), arrays[name], name) for va, name in pairs if name in arrays]


class FingerprintTests(unittest.TestCase):
    def test_fingerprints_survive_relocation(self):
        path = os.environ.get('KOA_EXE')
        if not path:
            self.skipTest('Set KOA_EXE to a supported koa.exe')
        try:
            import pefile
        except ImportError:
            self.skipTest('pefile not installed')
        data = Path(path).read_bytes()
        for source in SOURCES:
            found = checks((ROOT / source).read_text(encoding='utf-8'))
            self.assertGreaterEqual(len(found), 8, source)
            for base in (0x400000, 0x3F0000, 0x150000):
                pe = pefile.PE(data=data)
                pe.relocate_image(base)
                image = pe.get_memory_mapped_image()
                for va, expected, name in found:
                    offset = va - 0x400000
                    self.assertEqual(image[offset:offset + len(expected)], expected,
                                     f'{source} {name} at base {base:#x}')
                for va in (0xe42140, 0xe421d0):  # rebased absolute operand after the prefix
                    if source.endswith('inventory_plus/native.c') or 'stats_probe' in source:
                        offset = va - 0x400000 + 11
                        self.assertEqual(int.from_bytes(image[offset:offset + 4], 'little'),
                                         0x1741aac - 0x400000 + base)
