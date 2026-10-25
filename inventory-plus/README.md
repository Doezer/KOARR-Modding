# Inventory Plus — search and name sorting, 0.5.0 preview

Find an item by name in your current inventory category, then use the game's
normal item details and actions. Sort names within the native subcategories
without changing their order or merging their item contexts.

**0.5.0 navigation preview:** Inventory keeps its native item list, details,
equipment comparisons and actions, while the original category menu is replaced
by seven buttons: **Primary, Secondary, Armor, Accessories, Consumables, Items,
Junk**. Primary and Secondary are the game's separate weapon-slot contexts, not
a combined weapon filter. Their native eligibility checks and Equip behavior
remain in use. No items are equipped merely by browsing either slot.

Click the buttons or use **Ctrl+1–7**. Opening Inventory enters the last viewed
category (Primary initially). Back clears an active search first, then leaves
Inventory instead of reopening the old category hierarchy. Other ledger sections
keep their native navigation. The new controls use two columns and four rows,
leaving the item details and character pane native. Captions are English.

This includes the 0.4.1 full-click isolation guard. The native helper and Lua
adapter both require 0.5.0; replace the complete package. 23 offline tests pass,
but automatic entry, native-menu replacement, Back and weapon slot actions need
an in-game check. Stat sorting and an All view remain planned.

[Download 0.5.0 preview](https://raw.githubusercontent.com/Doezer/KOARR-Modding/main/inventory-plus/dist/InventoryPlus-0.5.0-preview.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-Modding/main/inventory-plus/dist/InventoryPlus-0.5.0-preview.zip.sha256)

## Installation

Requires GOG Re-Reckoning with Fatesworn and Mod Framework v1.4, matching the build
used for Quest Hider and the inventory exports. The native helper checks PE
identity, Lua API fingerprints and the framework registration hook. Other builds
are disabled. Quest Hider and All Quest Markers are optional and unchanged.

Close the game and extract the complete ZIP beside `koa.exe`, merging `mods`.
When upgrading, replace the complete ZIP, including the DLL, JSON and the new
`mods/InventoryPlus/navigation.lua`. The 0.5.0 adapter requires the 0.5.0 native bridge DLL included in this ZIP. Restart the game completely. Remove `mods/inventory_plus_probe.json` after
the diagnostic run; the working mod does not require it.

```text
mods/
├── inventory_plus.json
├── inventory_plus_native.dll
└── InventoryPlus/
    ├── model.lua
    ├── navigation.lua
    └── inventory_plus.lua
```

No console command is needed. The model is loaded by the framework before its
adapter; no nested asset loader is used during startup.

## Controls

- **Click tabs / Ctrl+1–7:** switch categories while browsing an item list.
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
native. Full controller-only search is not claimed. The new category buttons require mouse
or Ctrl+1–7; controller-only category switching is not yet implemented.

## Matching and item behavior

Search uses literal substrings of the item's displayed inventory name, including
custom names. The helper reads the same stored name as the native label formatter. Windows invariant
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

The 0.2.0 game test exposed the unsuitable actor display-name reader. 0.2.1
replaced it with the inventory formatter's name reader, including custom names;
four real-engine emulation cases verified the handle/lookup/name-selection path
at two image bases. The user confirmed search, name sorting and clearing work
in 0.2.1. 0.3.1 restores that implementation and withdraws the failed 0.3.0
navigation path. Its DLL builds and 21 offline tests pass; fresh-session recovery
still needs the user's in-game confirmation.

Offline checks cover native-handle routing after filtering/sorting, duplicate
names, stacks, collapsed groups and header counts, empty results, removed items,
metadata failures, Unicode-aware model behavior, 1,000-entry duplicate ordering,
modal guards and original native return values. The new Windows lowercase
routine is cross-compiled; its real runtime behavior and the projected inventory
still need this game's test. This preview is not a claim that every item action,
locale, resolution or other UI mod has been tested in-game.

## Focused game test

1. Open Inventory: it should enter Primary directly with seven buttons and no
   old category menu. Reopen after visiting Armor; it should remember Armor.
2. Switch Primary → Secondary and check that each displays the native candidates
   for that slot. Select a weapon in each and verify the native Equip action
   targets the intended slot; browsing alone must not change equipment.
3. Try Accessories, Consumables, Items and Junk using clicks and Ctrl+1–7.
   Check the native item details/actions and no click-through to other controls.
4. Search, switch categories and clear with Escape. A further Back should leave
   Inventory for the native ledger, without reopening the old category hierarchy.
5. Open another ledger section and check its original navigation is still usable.

The [0.4.1 preview](https://raw.githubusercontent.com/Doezer/KOARR-Modding/d51206a/inventory-plus/dist/InventoryPlus-0.4.1-preview.zip)
remains available for rollback.
Send the framework log and report any wrong names, counts, details or input
behavior. No new export run is needed. Search and sorting are category-scoped;
the new buttons change the native category without merging item contexts.

## Removal and development

Run the development commands from the repository’s `inventory-plus/` folder.

Close the game. Remove both `mods/inventory_plus.json` and
`mods/inventory_plus_native.dll`, plus `mods/InventoryPlus/`, then restart.
The framework loads DLLs even without their JSON. No preferences are stored.

```sh
python tools/build_inventory_plus.py
QH_LUA=/path/to/lua5.1 python -m unittest discover -s tests -q
python tools/package_inventory_plus.py
```

See the [source audit and gate status](https://github.com/Doezer/KOARR-Modding/blob/main/inventory-plus/docs/inventory/spike.md)
and [target specification](https://github.com/Doezer/KOARR-Modding/blob/main/inventory-plus/docs/inventory/spec.md).
No game code or assets are distributed.
