# Workflow, tools and delivery

## Local setup

Use Python 3.12+, a host C compiler and Lua 5.1 for offline checks. Windows native
helpers cross-compile on Linux with official **Zig 0.13.0**, pinned in
`common/tools/zig_toolchain.py`:

```text
SHA-256 d45312e61ebcc48032b77bc4cf7fd6915c11fa16e4aad116b66c9468211230ea
```

Build scripts fetch and verify the official archive if absent. Default Zig cache:
`/workspace/.quest-hider-tools`; override with `--cache`. A previously prepared
Lua is often `/workspace/.aqm-tools/lua-5.1.5/src/lua`; check it exists rather
than assuming that path is universal. `quest-hider/tools/setup_quest_hider.py`
can prepare pinned Lua and build/test Quest Hider. It is not an all-mod installer.
Do not repurpose HOME or CODEX_HOME for caches.

From the repository root:

```sh
python quest-hider/tools/build_quest_hider.py
python inventory-plus/tools/build_inventory_plus.py
QH_LUA=/path/to/lua5.1 python common/tools/test_all.py
```

The all-mod runner invokes each test suite from its own mod directory. To focus
on one mod, change into that directory and run:

```sh
QH_LUA=/path/to/lua5.1 python -m unittest discover -s tests -q
```

Build outputs live in each mod's ignored `build/`. Package tests need the native
DLL already built. Do not write compiled DLLs directly into source `mods/`.

## Optional analysis

Use a private legally supplied `koa.exe`. Hash it before analysis. Existing
read-only tools:

```sh
python all-quest-markers/tools/verify_executable.py /private/path/koa.exe
python common/tools/verify_game_vm.py /private/path/koa.exe
python inventory-plus/tools/verify_inventory_plus_names.py /private/path/koa.exe
```

The latter two need `pefile` and `unicorn`; previously used versions are
`pefile==2024.8.26`, `unicorn==2.1.4`. Capstone is useful for private disassembly.
Quest Hider also has an optional hook emulator; run from `quest-hider/`:
`python tests/quest_hider_hook.py` after building its DLL. Do not confuse emulator
coverage with running Windows/game code on the target machine.

## Probe workflow

Read `inventory-plus/docs/inventory/probe.md` and
`inventory-plus/mods/InventoryPlusProbe/probe.lua` before extending diagnostics.
Probe 0.1.2 captures ledger traversal functions and runtime tree closures without
calling them. Observe naturally triggered callbacks, preserve returns/errors,
cap events and bytes, and detach cleanly. Do not invoke getters to discover
whether they are safe. Use raw table inspection where appropriate; avoid opaque
`__tostring` calls. String dumping is supported; `io.open` was absent in-game.

Probe export format: `[InventoryPlusProbe] BEGIN version=...`, then
`BLOB-BEGIN module.function size`, zero-based 96-byte hex `BLOB-CHUNK` records,
and `BLOB-END` Adler-32. Reader limits are 32 KiB/function and 384 KiB/session;
read current code for exact accepted versions. Reconstruct privately:

```sh
python inventory-plus/tools/read_inventory_probe.py /private/log.txt \
  --output inventory-plus/build/probe-private
```

Keep a complete startup log because exports may precede the visible test run.
For a genuinely truncated fragment, preserve the raw input, validate each blob's
length/chunks/checksum and explicitly label any inferred session header.
`--allow-partial` allows a session without inventory exports; it does not excuse
corrupt or incomplete blobs. Do not relax the public reader's validation to
silently accept bad data. A dump being present does not mean its code executed.

Private historical exports may remain under the old root `build/` after the
repository reorganization. Search existing ignored build directories before
asking the user to repeat a capture. Temporary decoder scripts may be gone.
The VM is not stock Lua: standard luac cannot decode its game bytecode. Preserve
and verify a private decoder against existing known bin/disassembly pairs.

Ask for a precise, short test: restart, visit specified screens, use native
controls, exit, attach the full framework log. F2's Enter Code field truncated
long snippets; do not make it the diagnostic or final user workflow. Prefer a
small framework-loaded diagnostic ZIP requiring no console command.

## Packaging

Run each packaging tool from its mod root, or invoke its path from the repo root:

| Mod | Script |
| --- | --- |
| All Quest Markers | `all-quest-markers/tools/package.py` |
| Quest Hider | `quest-hider/tools/package_quest_hider.py` |
| Inventory Plus | `inventory-plus/tools/package_inventory_plus.py` |
| Inventory probe | `inventory-plus/tools/package_inventory_probe.py` |

Default outputs go to that mod's `dist/`. Use `--output` with a temporary or
ignored directory when validating an existing release version; do not overwrite
its committed archive. Package allowlists must contain only runtime payload,
README and license. Include dependencies in manifest order, license and checksum.
Keep runtime names `mods/<manifest>.json`, `mods/<helper>.dll`, `mods/<Mod>/...`.
Do not add `inventory-plus/` or another repository folder inside a game ZIP.

Verify ZIP contents, reproducibility where supported, SHA-256 and mixed-version
handling. Full restart is needed after DLL updates and to clear native state
left by a failed navigation preview. For a Lua-only update, identify which files
changed and whether the native ABI token stays the same.

## Git and downloads

Inspect branch/remotes and preserve unrelated user edits. Historically the local
branch is `work` and remote branch `main`; use `git push origin HEAD:main` only
when authorized and appropriate to current state. Do not assume local `main`.
Canonical repo: `Doezer/KOARR-Modding`. Old commit/tag URLs retain old layouts;
only current-branch links get rewritten for moved files.

After authorized publication, provide an immutable commit URL, for example:

```text
https://raw.githubusercontent.com/Doezer/KOARR-Modding/<commit>/inventory-plus/dist/<archive>.zip
```

Download that URL and compare bytes/hash with the local artifact before saying
it works. An unpushed workspace path is not a downloadable public link. Do not
create a new release/tag or replace unrelated stable assets unless requested.

## Nexus material

Use actual README requirements and current evidence. Quest Hider's draft listing
and metadata are in `quest-hider/docs/`; banners live in each mod's `docs/images/`.
Nexus descriptions use BBCode. Preserve user editorial choices. Do not invent
support for Vortex deployment, stores, DLC combinations, controller-only UI or
languages without testing. For DLL quarantine, provide native source, shared
bridge and build-script links. Do not declare a scanner result a false positive
without evidence or promise that open source guarantees safety.
