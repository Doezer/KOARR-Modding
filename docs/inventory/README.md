# Inventory Plus — search and name sorting, 0.2.0 preview

Find an item by name in your current inventory category, then use the game's
normal item details and actions. Sort names within the native subcategories
without changing their order or merging their item contexts.

This is a functional preview, not the complete redesigned inventory. Direct
category tabs, clickable search/sort controls, an All view, rarity/type filters
and additional columns remain planned.

[Download 0.2.0 preview](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/InventoryPlus-0.2.0-preview.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/InventoryPlus-0.2.0-preview.zip.sha256)

## Installation

Requires GOG Re-Reckoning with Fatesworn and Mod Framework v1.4, matching the build
used for Quest Hider and the inventory exports. The native helper checks PE
identity, Lua API fingerprints and the framework registration hook. Other builds
are disabled. Quest Hider and All Quest Markers are optional and unchanged.

Close the game and extract the complete ZIP beside `koa.exe`, merging `mods`.
When upgrading from the input trial, replace the DLL **and JSON**, and add both
Lua files. Keep the old export probe disabled. `ui_trial.lua` from 0.1.0 is no
longer referenced and can be removed.

```text
mods/
├── inventory_plus.json
├── inventory_plus_native.dll
└── InventoryPlus/
    ├── model.lua
    └── inventory_plus.lua
```

No console command is needed. The model is loaded by the framework before its
adapter; no nested asset loader is used during startup.

## Controls

- **Ctrl+F:** open the native search dialog. Confirm to apply a name filter.
- **Ctrl+S:** cycle native order → Name A–Z → Name Z–A → native order.
- **Escape / native Back action:** clear an active search first. A further press
  follows the normal Back behavior. This retains your chosen sort.
- Cancel in the search dialog keeps your previous query.

The shorter footer shows the controls when idle, or a short query/count and
**Esc: Clear** during search. Counts mean matching items / items in the current
native category, not used bag capacity. Names in the hint are shortened; Ctrl+F
shows the full query for editing. Sorting applies within each native header.

Search expands the category groups when it starts, so items in previously
collapsed subcategories can match. You can collapse/expand groups while searching;
header counts still describe all matches. Clearing search restores the expansion
state from before the search. Search text resets when the native inventory page
opens; sort stays selected during the running session.

The native dialog retains its initial text if confirmed completely empty. Use
Escape after leaving the dialog to clear search. Keyboard shortcuts are required
for the new controls in this preview; ordinary mouse/controller browsing remains
native. Full controller-only search is not claimed.

## Matching and item behavior

Search uses literal substrings of the actor's display name. Windows invariant
Unicode lowercase handles case; accents remain significant. This does not
promise every language's full case-folding equivalences or locale-specific sort
order. Name sorting compares the lowercase UTF-8 names, retaining native order
for duplicate names.

Filtering/sorting projects a fresh native row snapshot. Each item row retains its
original handle and stack/context fields. Selection follows that handle when it
remains visible, or moves to the nearest remaining item. Selection is restored
before the original item-card refresh, including tooltip observers. Native
category headers and their index map are rebuilt together.

No matches leaves category headers with zero counts and no selected item details
or item actions. Missing name/normalization data disables the view change and
shows the native list rather than silently omitting unrecognized items. Removed
handles are checked before a selected item is returned while a view is active.

**Destroy all junk is blocked while search is active**, because that native
operation includes items hidden by the query. Clear search to use it. Single-item
Equip/Use/Junk and their native confirmation paths retain the game's behavior.
The mod does not add automated item actions, capacity changes or save edits.

## What has been validated

The user confirmed the 0.1.0 dialog opens, typing leaves items untouched, both
confirmation and cancellation return cleanly, and the hint appears. The supplied
screenshot exposed an overlong footer, which is shortened in this build.

Offline checks cover native-handle routing after filtering/sorting, duplicate
names, stacks, collapsed groups and header counts, empty results, removed items,
metadata failures, Unicode-aware model behavior, 1,000-entry duplicate ordering,
modal guards and original native return values. The new Windows lowercase
routine is cross-compiled; its real runtime behavior and the projected inventory
still need this game's test. This preview is not a claim that every item action,
locale, resolution or other UI mod has been tested in-game.

## Focused game test

1. Open a category with several items. Search for part of a visible item's name,
   such as **staff**. Check only matching items remain and counts look correct.
2. Press Escape to clear. Try a query with no matches and clear it again.
3. Press Ctrl+S to try both name directions. Select each of two same-named items,
   if available, and check its native details correspond to the selected item.
4. Check the normal action you want to use acts on that selected item, then clear
   search and return to native sort. Confirm the compact hint is readable.

Send the framework log and report any wrong names, counts, details or input
behavior. No new export run is needed. Search and sorting are category-scoped;
this build does not navigate between categories for you.

## Removal and development

Close the game. Remove both `mods/inventory_plus.json` and
`mods/inventory_plus_native.dll`, plus `mods/InventoryPlus/`, then restart.
The framework loads DLLs even without their JSON. No preferences are stored.

```sh
python tools/build_inventory_plus.py
QH_LUA=/path/to/lua5.1 python -m unittest discover -s tests -q
python tools/package_inventory_plus.py
```

See the [source audit and gate status](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/inventory/spike.md)
and [target specification](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/inventory/spec.md).
No game code or assets are distributed.
