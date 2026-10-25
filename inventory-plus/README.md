# Inventory Plus — search and name sorting, 0.4.0 preview

Find an item by name in your current inventory category, then use the game's
normal item details and actions. Sort names within the native subcategories
without changing their order or merging their item contexts.

**0.4.0 category-button preview:** six clickable tabs appear above the item list
in two columns and three rows. Click a tab or press Ctrl+1–6 to switch categories.
They appear only inside an item category, not on the original landing menu.
Brackets identify the active category; captions are English in this preview.

Navigation now uses the native tree's normal parent/child transitions, including
its loading callbacks. Search and sort are retained. Back cancels a pending
switch; there is no blanket input guard. Native controller navigation remains
available, but focus on the added buttons is not implemented.

The 0.3.0 direct-jump implementation is not reused. 22 offline tests pass, but
this replacement needs an in-game test. Damage/stat sorting, an All view and
clickable search/sort controls remain planned.

[Download 0.4.0 preview](https://raw.githubusercontent.com/Doezer/KOARR-Modding/main/inventory-plus/dist/InventoryPlus-0.4.0-preview.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-Modding/main/inventory-plus/dist/InventoryPlus-0.4.0-preview.zip.sha256)

## Installation

Requires GOG Re-Reckoning with Fatesworn and Mod Framework v1.4, matching the build
used for Quest Hider and the inventory exports. The native helper checks PE
identity, Lua API fingerprints and the framework registration hook. Other builds
are disabled. Quest Hider and All Quest Markers are optional and unchanged.

Close the game and extract the complete ZIP beside `koa.exe`, merging `mods`.
When upgrading, replace the complete ZIP, including the DLL, JSON and the new
`mods/InventoryPlus/navigation.lua`. The 0.4.0 adapter requires the matched 0.4.0
DLL. Restart the game completely. Remove `mods/inventory_plus_probe.json` after
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

- **Click tabs / Ctrl+1–6:** switch categories while browsing an item list.
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

1. Open inventory: the original landing menu should have no overlapping tabs.
2. Enter Primary Weapon. Six tabs should appear above the list. Click Armor,
   Accessories and Weapons, checking the correct items and native actions appear.
3. Try Ctrl+1–6 and Back. Back must work during or after a category switch.
4. Search for an item-name fragment, switch categories and check the query is
   retained. Clear with Escape and try name sorting again.
5. Close and reopen inventory; check there are no leftover or duplicated controls.

A screenshot and the framework log will help check this new layout. The
[0.3.2 search/sort-only build](https://raw.githubusercontent.com/Doezer/KOARR-Modding/44a118a/inventory-plus/dist/InventoryPlus-0.3.2-preview.zip)
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
