#!/usr/bin/env python3
"""Read-only x86 emulation of the supported game's Lua stack APIs and assert return.

Requires pefile and unicorn. The proprietary executable is supplied locally and
is never modified, executed as a process or packaged with the project.
"""
import argparse
import hashlib
import struct
from pathlib import Path
import pefile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import *

SHA256 = '16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314'


def verify(path):
    data = Path(path).read_bytes()
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError('Unsupported executable hash')
    pe = pefile.PE(data=data)
    preferred = pe.OPTIONAL_HEADER.ImageBase
    # Verify the new pop binding, rather than trusting its name/address alone.
    expected = bytes.fromhex('8b4c24088b442404f7d903c903c903c9014824c3')
    assert pe.get_data(0xa9f9a0 - preferred, len(expected)) == expected
    cases = 0
    for relocated_base in (preferred, 0x150000):
        for count in (0, 1, 3, 20):
            vm = Uc(UC_ARCH_X86, UC_MODE_32)
            for address, size in ((0x3000000, 0x10000), (0x3100000, 0x10000),
                                  (0x3200000, 0x10000), (0x3300000, 0x1000)):
                vm.mem_map(address, size)
            state, values, cpu_stack, stop = 0x3000000, 0x3100000, 0x3208000, 0x3300000
            def put(address, *values):
                vm.mem_write(address, struct.pack('<' + 'I' * len(values), *values))
            def read(address):
                return struct.unpack('<I', vm.mem_read(address, 4))[0]
            def call(address, args):
                put(cpu_stack, stop, *args)
                vm.reg_write(UC_X86_REG_ESP, cpu_stack)
                vm.emu_start(address, stop, count=500)
                assert vm.reg_read(UC_X86_REG_EIP) == stop
                assert vm.reg_read(UC_X86_REG_ESP) == cpu_stack + 4
                return vm.reg_read(UC_X86_REG_EAX)
            for va, size in ((0xa9f980, 0x40), (0x10ca240, 0x120)):
                target = relocated_base + va - preferred
                vm.mem_map(target & ~4095, 4096)
                vm.mem_write(target, pe.get_data(va - preferred, size))
            top_address = relocated_base + 0xa9f980 - preferred
            pop_address = relocated_base + 0xa9f9a0 - preferred
            put(state + 0x24, values + 32 * 8, values)
            assert call(top_address, [state]) == 32
            call(pop_address, [state, count])
            assert call(top_address, [state]) == 32 - count
            assert read(state + 0x28) == values
            # Native assert returns its existing true argument, without appending a value.
            put(values, 1, 1)
            put(state + 0x24, values + 8, values)
            assert call(relocated_base + 0x10ca240 - preferred, [state]) == 1
            assert read(state + 0x24) == values + 8 and read(values) == 1
            cases += 1
    print(f'{cases} target-VM cases passed: gettop/pop at two image bases; existing-argument return is supported.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=Path)
    args = parser.parse_args()
    verify(args.executable)
