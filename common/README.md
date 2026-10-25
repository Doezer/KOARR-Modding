# Shared development utilities

- `src/vm_bridge.h`: balanced Lua library registration used by Quest Hider and Inventory Plus.
- `tools/zig_toolchain.py`: shared, checksum-pinned Zig version for native builds.
- `tools/verify_game_vm.py`: optional read-only emulator checks against a privately supplied supported executable; requires pefile and unicorn.
- `tools/test_all.py`: run each mod's independent offline tests from the repository root.

Native builds use Zig 0.13.0 (the build scripts fetch and verify its official
archive when absent). Tests require Python 3, a host C compiler and Lua 5.1;
set `QH_LUA` to the interpreter path if it is not on PATH. No common runtime
installation is needed: each mod ZIP includes its own required files.
