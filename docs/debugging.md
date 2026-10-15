> Historical Lua prototype/research documentation. See the [current mod README](../README.md) for installation and supported behavior.

# Debugging and the next concrete experiment

Confirmed validation target: **GOG PC edition with Mod Framework v1.4** (user-provided).
The exact game executable build/file version and DLC set have not been supplied.
Compatibility and in-game behavior remain untested.

## Safe probe procedure

Record the PC store, exact game build/file version, installed DLCs, framework
package/version, and other active mods. The cloud machine has no game executable,
game asset archives or live save session. It cannot validate this procedure in-game.

Install the probe as in the README, then enter this no-whitespace command in the
framework's own console after loading a save:

```lua
assert(loadfile('mods/AllQuestMarkers/probe.lua'))()
```

Expect `[AllQuestMarkers][probe] BEGIN`, symbol path/type lines, and `END` with
counts and a truncation flag. This does not announce that map APIs work. If no
symbols are found, that is evidence of an unavailable namespace, not evidence that
the game has no quest/map functionality. Keep error messages verbatim.

Repeat these captures, labeling the resulting text outside the game:

1. Loaded save, map closed, at least two active quests with legitimate locations.
2. Same save with world map open.
3. Another tracked quest, while other quests remain active.
4. Another map region, and then the same save reloaded.

Do not paste logs containing unrelated personal paths or private mod data. The
probe itself prints no scalar values, does not call discovered functions, skips
standard library tables, never indexes userdata or metatables, and bounds depth,
entries, table count and output. It does not inspect `debug` registry/upvalues.
A truncated report cannot establish absence of an API; inspect a known plain
module table separately if its identity is verified.

To retain the helper explicitly (first confirm this variable name is unused):

```lua
AQMProbe=assert(loadfile('mods/AllQuestMarkers/probe.lua'))()
AQMProbe.scan(_G,'map-open')
```

For a confirmed plain Lua module table, pass that table instead of `_G`. Do not
supply fabricated table names or resolve unknown userdata properties. Clear the
optional helper namespace with `AQMProbe=nil` when done. No event listener needs
removal for the standalone probe.

## Obtain concrete binding evidence

The probe only locates structural leads. To turn them into safe calls, inspect
local framework sample JSON/Lua and game map/journal scripts. The framework prints
`Finished loading script ...` and `Found script ... for ...`; capture the exact
strings around world-map and quest-journal opening to identify candidate triggers.
An observed module load is not proof that it fires on every map-open event.

Using the official unpacker on a locally installed game, from the game directory:

```text
mkdir patch_0_unpacked
.\modding\pakfileunpacker.exe .\data\patch_0.pak unpack .\patch_0_unpacked
```

This command shape is documented by Toolbox mod 15; it was not executed here.
Use separate existing-empty output directories for `initial_0.pak` and `data_0.pak`
as needed. Keep original archives and unpacked reference files unchanged. Search
asset-name/ID tables for map, journal, quest, target, marker and UI names. Determine
which packed script/definition is authoritative under the game's patch load order.
Compiled Havok Script has custom bytecode: standard `luac` is not a decompiler or
compatibility validator for it. Do not attempt to execute unpacked unknown code in
this repository's test runner or distribute proprietary extracted content.

For each candidate binding, document:

- Exact owner/module and a real call site, argument/return types, index bases.
- Quest and objective IDs compared with visible journal state.
- How reveal permission differs from raw target existence.
- How native tracked icons are selected, projected and removed.
- Which map-window object owns icons, its thread and lifetime.
- Verified subscribe/restore/unsubscribe behavior across map close/load/region change.

Only after those are confirmed, implement one additional legitimate marker in a
scratch integration and test creation, projection and removal. `pcall` catches
ordinary Lua errors; it cannot prevent access violations from wrong native
signatures, stale pointers or wrong-thread UI access. Do not invoke legacy symbol
names or memory addresses as experiments without their real signatures.

## Logs from an eventual adapter

Enable `debug=true` for core marker keys and coordinates. The adapter should add
map-open state, view/region/session generation, quest/objective counts, native
marker counts and skip reasons without exposing hidden destinations or save data.
Current core errors include invalid snapshots, conflicting duplicate coordinates,
projection failures, creation/removal failures and incomplete listener teardown.

If cleanup returns false, retry after the host recovers. Do not reload over a
controller that still owns live handles/listeners. Exit the game if cleanup cannot
be completed. No such host integration is included yet.
