"""Emulate the built x86 renderer trampoline (requires pefile and unicorn)."""
from pathlib import Path
import struct
import pefile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *

ROOT = Path(__file__).resolve().parents[1]
p = pefile.PE(str(ROOT / 'build/quest_hider_native.dll'))
base = p.OPTIONAL_HEADER.ImageBase
image = p.get_memory_mapped_image()
signature = bytes.fromhex('9c6089e081ec1002000083e4f00fae0424')
start = image.index(signature)
assert image.count(signature) == 1
call = start + 26
assert image[call] == 0xe8
callee = base + call + 5 + struct.unpack_from('<i', image, call + 1)[0]
assert image[start+57:start+59] == b'\xff\x25'
continue_slot = struct.unpack_from('<I', image, start+59)[0]
skip_slot = struct.unpack_from('<I', image, start+67)[0]
regs = [UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ECX, UC_X86_REG_EDX,
        UC_X86_REG_ESI, UC_X86_REG_EDI, UC_X86_REG_EBP, UC_X86_REG_ESP]
for hide in (0, 1):
    for native_hidden in (0, 1):
        u = Uc(UC_ARCH_X86, UC_MODE_32)
        u.mem_map(base, (len(image)+4095)//4096*4096)
        u.mem_write(base, image)
        u.mem_map(0x200000, 0x10000)
        u.mem_write(continue_slot, struct.pack('<I', 0x200100))
        u.mem_write(skip_slot, struct.pack('<I', 0x200200))
        values = [0x111,0x222,0x333,0x444,0x555,0x202000,0x203000,0x20f000]
        for r,v in zip(regs,values):u.reg_write(r,v)
        u.reg_write(UC_X86_REG_EFLAGS,0x247)
        u.reg_write(UC_X86_REG_XMM0,0x123456789abcdef123456789abcdef)
        u.mem_write(0x203004, bytes([native_hidden]))
        expected = 0x200200 if hide or native_hidden else 0x200100
        visited = []
        def hook(uc, address, size, data):
            if address == callee:
                sp = uc.reg_read(UC_X86_REG_ESP)
                assert struct.unpack('<II', uc.mem_read(sp+4,8)) == (0x202000,0x203000)
                ret = struct.unpack('<I',uc.mem_read(sp,4))[0]
                for r in regs[:-1]:uc.reg_write(r,0xdeadbeef)
                uc.reg_write(UC_X86_REG_EAX,hide)
                uc.reg_write(UC_X86_REG_XMM0,0)
                uc.reg_write(UC_X86_REG_EFLAGS,0x202)
                uc.reg_write(UC_X86_REG_ESP,sp+4)
                uc.reg_write(UC_X86_REG_EIP,ret)
            elif address in (0x200100,0x200200):
                visited.append(address);uc.emu_stop()
        u.hook_add(UC_HOOK_CODE,hook)
        u.emu_start(base+start,base+start+100,count=100)
        assert visited == [expected]
        assert [u.reg_read(r)for r in regs] == values
        assert u.reg_read(UC_X86_REG_XMM0)==0x123456789abcdef123456789abcdef
        if hide:assert u.reg_read(UC_X86_REG_EFLAGS)==0x247
print('Four renderer hook paths passed; registers, stack and SSE state preserved.')
