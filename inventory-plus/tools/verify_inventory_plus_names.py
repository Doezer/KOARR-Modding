#!/usr/bin/env python3
"""Optional read-only emulation of the GOG inventory name path; needs pefile/unicorn.

Uses the privately supplied game executable, never packaged or modified on disk.
Checks real handle decoding, actor lookup and name(false), including custom names.
"""
import argparse
import hashlib
from pathlib import Path
import struct
import pefile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_ESP, UC_X86_REG_EIP
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'common/tools'))
from verify_game_vm import SHA256


def verify(path):
    data = Path(path).read_bytes()
    assert hashlib.sha256(data).hexdigest() == SHA256, 'Unsupported executable'
    cases = 0
    for base in (0x400000, 0x150000):
        pe = pefile.PE(data=data)
        pe.relocate_image(base)
        vm = Uc(UC_ARCH_X86, UC_MODE_32)
        vm.mem_map(base, 0x173d000)
        vm.mem_write(base, pe.get_memory_mapped_image())
        vm.mem_map(0x3000000, 0x10000)
        state, values, stack, stop = 0x3000000, 0x3001000, 0x3008000, 0x300f000
        actor, manager, ids, actors = 0x3002000, 0x3003000, 0x3004000, 0x3004100
        def put(at, *words):
            vm.mem_write(at, struct.pack('<'+'I'*len(words), *words))
        def read(at):
            return struct.unpack('<I', vm.mem_read(at, 4))[0]
        def call(va, args, this=0, popped=0):
            put(stack, stop, *args)
            vm.reg_write(UC_X86_REG_ESP, stack)
            vm.reg_write(UC_X86_REG_ECX, this)
            vm.emu_start(base+va-0x400000, stop, count=2000)
            assert vm.reg_read(UC_X86_REG_EIP) == stop
            assert vm.reg_read(UC_X86_REG_ESP) == stack+4+popped
            return vm.reg_read(UC_X86_REG_EAX)
        # Real Havok typed actor handle: tag 0xb, actor type 0xf, handle payload.
        put(state+0x24, values+8, values)
        put(values, 0xfb, 0x10001)
        out = 0x3001100
        assert call(0xe5f770, [out, state, 1]) == out and read(out) == 0x10001
        put(manager+0xc, actors)
        put(manager+0x1c, ids, 2)
        put(ids+4, 0x10001)
        put(actors+4, actor)
        assert call(0xf23c10, [read(out)], manager, 4) == actor
        # actor::name(false) is exactly what ECDC20 uses for formatted item labels.
        for custom in (False, True):
            vm.mem_write(actor+0x11c, bytes([custom]))
            name = call(0xef3b20, [0], actor, 4)
            assert name == actor+(0x110 if custom else 0x24)
            # true selects the base name; the bridge must always pass false.
            assert call(0xef3b20, [1], actor, 4) == actor+0x24
            cases += 1
    print(f'{cases} real-engine name cases passed at two image bases (typed handles, actor lookup, custom/base names).')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    verify(parser.parse_args().executable)
