#!/usr/bin/env python3
"""Optional read-only emulation of the native damage/armor readers; needs pefile/unicorn.

Runs the game's real reader code (0x00E42140 damage, 0x00E421D0 armor) from a privately
supplied supported koa.exe, relocated to several bases, against a synthetic component.
Only the actor-component lookup (0x00F24EF0) is replaced by a stub that supplies it.
"""
import argparse
import hashlib
from pathlib import Path
import struct
import sys
import pefile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_ESP, UC_X86_REG_EIP
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'common/tools'))
from verify_game_vm import SHA256


def trunc(value):
    return int(value) if value > 0 else 0


def run(data, base):
    pe = pefile.PE(data=data)
    pe.relocate_image(base)
    vm = Uc(UC_ARCH_X86, UC_MODE_32)
    vm.mem_map(base, 0x173d000)
    vm.mem_write(base, pe.get_memory_mapped_image())
    vm.mem_map(0x3000000, 0x20000)
    manager, comp, stack, stop = 0x3000000, 0x3010000, 0x3018000, 0x301f000
    va = lambda a: base + a - 0x400000
    vm.mem_write(va(0x19fe9c4), struct.pack('<I', manager))  # global stats manager pointer
    state = {'flag': 1}

    def lookup_stub(uc, address, size, user):
        if address != va(0xf24ef0):
            return
        this = uc.reg_read(UC_X86_REG_ECX)
        esp = uc.reg_read(UC_X86_REG_ESP)
        uc.mem_write(this + 4, struct.pack('<I', comp if state['flag'] else 0))
        uc.reg_write(UC_X86_REG_EIP, struct.unpack('<I', uc.mem_read(esp, 4))[0])
        uc.reg_write(UC_X86_REG_ESP, esp + 4 + 8)  # return, popping two stdcall arguments

    vm.hook_add(UC_HOOK_CODE, lookup_stub)

    def call(entry, handle, index, scaled):
        vm.mem_write(stack, struct.pack('<IIII', stop, handle, index, scaled))
        vm.reg_write(UC_X86_REG_ESP, stack)
        vm.reg_write(UC_X86_REG_ECX, manager + 0x3d28)
        vm.emu_start(va(entry), stop, count=5000)
        assert vm.reg_read(UC_X86_REG_ESP) == stack + 4 + 12, 'stack not balanced (ret 0xc)'
        return struct.unpack('<i', struct.pack('<I', vm.reg_read(UC_X86_REG_EAX)))[0]

    # Table: 8-byte entries from comp+0x24 {float base, float* override}; scale at comp+0x24+0x15c.
    values = [12.7, 0.0, -5.0, 40.9, 7.5, 3.25] + [1.0] * 8
    for index, value in enumerate(values):
        vm.mem_write(comp + 0x24 + index * 8, struct.pack('<fI', value, 0))
    vm.mem_write(comp + 0x20, struct.pack('<I', 1))
    vm.mem_write(comp + 0x24 + 0x15c, struct.pack('<f', 1.5))
    cases = 0
    for index, value in enumerate(values):
        clamped = max(value, 0.0)
        assert call(0xe42140, 7, index, 0) == trunc(clamped), ('raw damage', index)
        scaled = clamped if index == 12 else clamped * 1.5
        assert call(0xe42140, 7, index, 1) == trunc(scaled), ('scaled damage', index)
        assert call(0xe421d0, 7, index, 0) == trunc(clamped), ('raw armor', index)
        assert call(0xe421d0, 7, index, 1) >= 0, ('scaled armor', index)
        cases += 4
    # A raw override pointer wins over the stored float.
    vm.mem_write(comp + 0x100, struct.pack('<f', 99.9))
    vm.mem_write(comp + 0x24 + 8 + 4, struct.pack('<I', comp + 0x100))
    assert call(0xe42140, 7, 1, 0) == 99 and call(0xe421d0, 7, 1, 0) == 99
    vm.mem_write(comp + 0x24 + 8 + 4, struct.pack('<I', 0))
    # An invalid component reads as zero, never a fault.
    state['flag'] = 0
    assert call(0xe42140, 7, 0, 1) == 0 and call(0xe421d0, 7, 0, 0) == 0
    return cases + 4


def verify(path):
    data = Path(path).read_bytes()
    assert hashlib.sha256(data).hexdigest() == SHA256, 'Unsupported executable'
    total = 0
    for base in (0x400000, 0x3F0000, 0x150000):
        total += run(data, base)
    return total


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    print(f'{verify(parser.parse_args().executable)} emulated reader cases passed at 3 image bases')
