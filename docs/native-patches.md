# Native patch implementation

The release manifest is `mods/all_quest_markers_native.json`. All three entries
are required for the intended coverage; they address different code paths.

1. **Target updates:** removes a world-map-only skip branch when an objective's
   owner is not the currently tracked quest. The native inactive-icon path runs.
2. **Initial population:** removes the equivalent skip while a map window is
   populated from registered targets.
3. **Renderer scope:** bypasses the additional inactive-objective region/path
   eligibility predicate on world-map kind `4`. Other map kinds retain the
   original classification and predicate behavior.

The two six-byte branches are replaced with NOP instructions. The third patch
rewrites a 36-byte block in place and uses a direct comparison equivalent to the
native type-0 inactive-icon classifier. Relative control flow avoids fixed load
addresses. No new code allocation, Lua hook, quest setter or asset edit is used.
The byte-identical patch instructions were confirmed working by the tester after
combining the manifests. The public descriptions have been renamed for clarity.

Compatibility is pinned by analysis to the supplied GOG executable with SHA-256
`16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314`.
The framework itself matches signatures; it does not enforce that whole-file hash.

Offline checks against that private executable established unique signatures,
instruction boundaries, branch destinations, non-overlapping patch ranges and
matching signatures after PE base relocation. Isolated x86 emulation compared
50 renderer-block cases and checked non-world paths, stack balance and preserved
registers. These tests do not execute the game. The user's in-game confirmation
is separate evidence and does not cover every quest, DLC or reveal rule.

The framework schema and `??` patch-byte preservation semantics were checked in
[`re_mod/dllmain.cpp`](https://github.com/DevCortez/KoaModFramework/blob/66bd89343fa516d5dfec0f7bed3961edc15ab33f/re_mod/dllmain.cpp).
Only the short signatures needed for patch identification are distributed.
The executable, extracted game scripts and full disassemblies stay private.
