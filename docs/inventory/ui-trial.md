# Inventory Plus — historical search UI trial 0.1.0

The user has confirmed this input trial. Continue with the [0.2.0 search preview](README.md).

This is the first native UI trial for Inventory Plus. It opens the game's own
text-entry dialog from the inventory and returns the entered text to the
inventory reminder area.

**This build does not filter or sort items, add tabs, or replace the inventory.**
Its purpose is to check text focus, confirmation, cancellation and return to the
inventory on the actual game before enabling row changes.

[Download UI trial](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/211d2ae/dist/InventoryPlus-0.1.0-ui-trial.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/211d2ae/dist/InventoryPlus-0.1.0-ui-trial.zip.sha256)

## Installation

Requires the supported GOG Re-Reckoning/Fatesworn build and Mod Framework v1.4,
matching the game used for the previous exports. The helper checks the game's PE
identity, Lua API bytes and framework hook before registering its keyboard API.
It reads Windows keyboard state; it does not read or change item memory.

1. Close the game. Disable the old export probe by moving
   `mods/inventory_plus_probe.json` out of `mods` if it is still installed.
2. Extract this ZIP beside `koa.exe`, merging `mods`.
3. Start the game, load a save and open the ordinary inventory list.

```text
mods/
├── inventory_plus.json
├── inventory_plus_native.dll
└── InventoryPlus/
    └── ui_trial.lua
```

Quest Hider 1.0.0 can stay installed; it is not required. Its files and the All
Quest Markers release are not included or changed. The helper chains the existing
framework Lua registration callback, using the same stack-balancing mechanism
as Quest Hider. Coexistence on the target game is part of this trial.

## One focused test

1. Look for **Ctrl+F: Search (UI trial)** in the inventory reminder area.
2. Press **Ctrl+F**. A native dialog titled **Search items** should open.
3. Type a short item name. Include letters normally used for game actions, such
   as E or R. Check that typing does not equip, consume, junk or destroy an item.
4. Confirm through the dialog's normal control. Release the keys. The inventory
   should remain open, with **Search entered: …** in its reminder area. Its rows,
   selection and contents should be unchanged by this mod.
5. Open the dialog again and cancel through its normal Back/Cancel control.
   The previous text should stay intact. Check ordinary inventory navigation
   works again. If using a controller, also try its native cancel control.

Send the framework log and report whether the hint appeared, the dialog opened,
confirmation/cancellation returned cleanly, and typing caused any inventory
interaction. No F2 command or additional script export is needed.

The entered text resets on a fresh inventory visit. The dialog's native empty-
confirmation behavior can retain its initial text; this trial has no Clear
Filters control because it does not apply a filter.

## Input and current limits

While this mod owns the dialog, it guards the ledger action dispatcher, inventory
input/button handlers, drag/drop and the verified direct item-action functions.
The native text dialog keeps its own modal handlers. After confirmation/cancel,
the guard waits for the dialog to close and all keyboard/mouse buttons to be
released, then consumes one update before resuming native inventory updates.

The offline tests exercise those guards, multiple/nil native return values,
placeholder module loading, duplicate attachment, failed dialog creation, hidden
inventory, wrong bridge and cleanup after UI errors. They do not establish
in-game focus behavior, controller event ordering, layout or compatibility with
all other UI mods. Those are the reasons for this focused game test.

The Ctrl+F shortcut is fixed in this trial. Visible clickable search and direct
category tabs remain planned. Full search, filters and sorting are not claimed
as implemented or validated here.

## Removal

Close the game and remove **both** `mods/inventory_plus.json` and
`mods/inventory_plus_native.dll`, plus `mods/InventoryPlus/`, then restart.
Removing the JSON alone does not stop the framework loading DLLs.
This trial stores no preferences and writes no save or item data.

## Development

```sh
python tools/build_inventory_plus.py
QH_LUA=/path/to/lua5.1 python -m unittest discover -s tests -q
python tools/package_inventory_plus.py
```

The build reuses the checksum-pinned Zig toolchain already prepared for Quest
Hider. No game files, original game scripts or exports are distributed. The
private source audit and gate status are summarized in [spike.md](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/inventory/spike.md).
