# Inventory Plus — technical spike findings

Updated 16 October 2026. This is the implementation record for the
[specification's feasibility gates](spec.md#technical-approach-and-feasibility-gates).

## Confirmed evidence

The user's earlier full framework startup log, supplied during the world-map
work, contains these actual `Finished loading script` entries:

- `menu_tools`
- `name_win`
- `player_inventory_manager`
- `ledger_win`
- `inventory_win`

This resolves the module-name uncertainty in the research: `inventory_win` is an
observed trigger on the user's setup. It does **not** yet establish the global
table shape or function signatures inside that module. The probe checks whether
the corresponding globals exist after loading and exports what is actually there.

The framework executes custom script triggers after the original module loads.
The existing game's standard `string.dump` implementation was already confirmed
to work during the earlier quest/map exports. The game lacks `io.open`, so this
spike exports checksummed hexadecimal chunks into the framework log. It needs no
new native helper, startup memory patch or console command.

The supplied executable allows static inspection of native registrations, but
not reconstruction of the asset-loaded inventory/name-entry Lua bodies. Their
exports are needed to inspect exact item enumeration, row selection/action and
edit-box call sites without guessing or invoking unknown native signatures.

## Work implemented

- Independent, removable `inventory_plus_probe.json` and `InventoryPlusProbe/`.
- Exports for the original inventory/manager/name-entry functions and selected
  menu/ledger helpers. Exports occur before inventory observers are attached.
- Bounded passive snapshots after naturally occurring inventory events. Existing
  callbacks keep their arguments, all return values and original errors.
- No item getters, row rebuilds, UI creation, game setters or automated actions.
- A strict export reader that refuses incomplete/corrupt data and writes private
  analysis under ignored `build/`.
- Offline Lua/Python behavioral checks and a reproducible diagnostic ZIP.

## Gate status

| Gate | Status | Remaining evidence |
| --- | --- | --- |
| Module discovery | Trigger names confirmed from existing runtime log | Confirm corresponding global table contents in the new export |
| Baseline inventory layout | Pending target capture | Current category navigation, available sorts, scale and bindings |
| Row identity / read-only snapshot | Probe implemented; offline checks pass | Actual inventory fields and item handle/context use; duplicate-name items |
| One native edit box / category control | Not implemented | Original name-entry initialization and focus handling, then a focused UI trial |
| Sorted/filtered list and correct actions | Not implemented | Native row index/handle/action contract and input ownership |
| Property and compatibility audit | Static leads only | Verified rarity, type, requirement and value semantics; tests with other mods |

No gate requiring native UI behavior is marked passed from a mock. There is no
inventory search implementation or item-action interception in this diagnostic
build, and no working-overhaul release has been created.

## Why the next game run is necessary

The missing inputs are the actual module bodies and live table shape. The cloud
workspace has the executable and previous logs, but no running game session or
original inventory module exports. Adding a search box or reordering rows now
would depend on guessed UI and item-action contracts.

The [single diagnostic test](probe.md#one-test-run) collects these inputs without
manual F2 commands. Its `name_win` export is passive; the tester need not enter
character creation or rename anything. A screenshot is helpful for layout but
not required to reconstruct the exported functions.

## Next work after receiving the log

1. Validate/reconstruct the exports with `tools/read_inventory_probe.py`, keeping
   originals and disassembly outside tracked paths.
2. Inspect the original inventory enumeration, row/selection model and all native
   item action call sites. Identify handles, stack semantics and category context.
3. Inspect original name-entry/menu helper code to establish widget creation,
   existing templates, edit events, focus ownership and exit behavior.
4. Build the smallest UI trial using those verified contracts: one category
   control and one edit box, with no filtering/action changes until input
   isolation has been demonstrated on the target build.
5. Record the in-game result before implementing name filtering and sorting.
