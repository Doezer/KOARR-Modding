# Inventory Plus — technical probe 0.1.0

This is a **diagnostic build**, not the inventory overhaul. It collects the
original inventory Lua function exports and bounded snapshots of existing module
data needed to implement search, tabs and sorting correctly.

It does not add a search box, sort/filter the inventory, call inventory getters,
change items, or alter the existing mods. It requires Mod Framework v1.4 on the
GOG Re-Reckoning setup used for the earlier tests. No extra DLL is included.

[Download diagnostic ZIP](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/InventoryPlus-Probe-0.1.0.zip)
· [Checksum](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/InventoryPlus-Probe-0.1.0.zip.sha256)

## One test run

1. Close the game. Extract this ZIP into the folder containing `koa.exe`, merging
   `mods`. Leave All Quest Markers and Quest Hider installed if you use them.
2. Start the game and load a save. Open the inventory, browse **Weapons** and
   **Consumables**, and select two different items. If readily available, select
   two copies of the same named item; do not obtain or modify items just for this.
3. Close the inventory and exit the game. Send the **full framework log as a
   `.txt` file**, using the same log source as the earlier map-mod tests. Search
   for `[InventoryPlusProbe]` to check that its output is present. Do not trim it
   to the last few lines: exports begin during startup and can be long.
4. If convenient, include one inventory screenshot to establish the current
   layout and UI scale. No console command or F2 input is needed.

Do not rename a character, buy, sell, junk or destroy anything for this test. The
probe observes the actions you naturally take; it never opens the name-entry
window. A `name_win` function export is used only to inspect how the native text
entry control is built and how its input focus works.

A healthy run includes `BEGIN version=0.1.0`, `MODULE inventory_win`,
`BLOB-BEGIN` / `BLOB-CHUNK` / `BLOB-END` lines and `SNAPSHOT` lines. A console
message saying `READY` confirms the probe loaded, not that search or sorting works.
If there is no `MODULE inventory_win`, send the startup log anyway so we can
identify the loading difference.

After the run, close the game and remove only:

```text
mods/inventory_plus_probe.json
mods/InventoryPlusProbe/
```

The original callbacks are restored on the next launch. Shared framework files
and the other mods stay installed.

## What is collected

The probe uses standard `string.dump` to export a bounded set of original Lua
functions from `inventory_win`, `player_inventory_manager`, `name_win`,
`menu_tools` and `ledger_win`. The exact trigger names were found in the earlier
user-provided framework log. Exports are hexadecimal text with per-function
Adler-32 checksums; they are never executed by the analysis tool.

It briefly wraps available inventory window, selection, input-action and edit-box
event callbacks. Each original callback runs with its original arguments, return
values and errors. After at most **12 successful observed events**, further
snapshots stop. No per-frame hook is installed.

Only existing raw Lua table fields are inspected. The probe does not enumerate
native inventory through guessed APIs, invoke userdata methods, use opaque
`__tostring` methods, alter row order or test item actions automatically. Opaque
objects get bounded session-local tokens. **Those tokens do not prove stable
native item identity**, especially if different ui64 wrappers represent the same
item. Function exports must establish the actual row/action contract next.

Limits: 32 KiB per function, 384 KiB total function bytes, 96-byte log chunks,
96 functions per module and bounded table traversal. Oversized or non-dumpable
functions are reported as `SKIP`. Modules are exported once per Lua session.
The snapshot may include displayed item names and other existing inventory
strings. Keep these logs and the proprietary bytecode private; do not attach them
to public GitHub issues or commit them into the repository.

## Development and offline verification

```sh
QH_LUA=/path/to/lua5.1 python -m unittest discover -s tests -v
python tools/package_inventory_probe.py
python tools/read_inventory_probe.py /path/to/framework-log.txt
```

The reader chooses the latest probe session in a log, validates chunk boundaries,
complete coverage, size budgets and Adler-32, then writes reconstructed functions
and observations under ignored `build/inventory-probe-private/`. An incomplete
latest session is rejected instead of silently falling back to an older run.
Inside this repository, private output is restricted to `build/`.

Offline tests cover observation without calling game APIs, original return/error
preservation, object-token distinction for same-name rows, observer failure,
event budgets, duplicate loading, detach, export roundtrip and corrupted/missing
chunks. They cannot confirm game module layout, native item identity, search
widget creation, text focus, visual layout or action routing.

See the [spike findings](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/inventory/spike.md)
for the current gate status, and the
[specification](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/inventory/spec.md)
for the intended inventory overhaul.
