# Inventory Plus — technical spike findings

Updated 17 October 2026. Current build: **0.2.0 search/sort preview**. The user
confirmed the native input trial; projected rows need the next game check.
This is the implementation record for the
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

## Current gate status

| Gate | Status | Remaining evidence |
| --- | --- | --- |
| Module discovery | Complete: 125 checksum-validated function exports, including 93 inventory functions | None needed for this stage |
| Baseline inventory layout | Existing native windows reused in the UI trial | Target check of hint placement and modal layout |
| Row identity / read-only snapshot | Native `m_last_set` rows contain `item_id` or `header_id`; selected/focused indices resolve through that same table | Duplicate-item and action routing checks after filtered/sorted rows are implemented |
| One native edit box / category control | User confirmed text focus, confirm/cancel, untouched items and return; hint visible | New compact hint check; category-control layout remains separate |
| Sorted/filtered list and correct actions | 0.2.0 implementation and offline handle-routing checks complete | Target-game matching, counts, selection and native actions |
| Property and compatibility audit | Action, pocket and equipment paths exported | Typed metadata readers, broader UI compatibility and localization |

Offline mocks do not establish gameplay behavior. The user has now passed the
text-input gate. The [current search/sort preview](README.md) exercises the next
row/action gate. The old export probe is no longer needed.

## Source contracts established from the complete export

- `get_surplus_inventory()` builds category headers and item rows; rows carry
  `header_id`/`header_text` or `item_id`. Collapsed categories omit their child
  rows. Native ordering includes category/equipment-specific logic.
- `rebuild_list_win()` obtains those rows, assigns `m_last_set`, clears/repopulates
  the native list, restores/clamps its selected index and refreshes details.
- `get_selected_item(allow_header)` resolves selected/focused list indices through
  `m_last_set` and returns the row's native item handle or optional header ID.
  An item's position cannot substitute for its handle. This gives a future
  adapter boundary around the returned row table, not the actor's inventory.
- `handle_input(input)` reads `input.info` and marks `input.handled` after handling
  an action. The ledger dispatcher also navigates its button tree before calling
  the current module, so guarding inventory input alone is insufficient during
  text entry. The trial guards that dispatcher and verified direct actions too.
- `name_win.launch(title, default_text, is_default_localized, text_limit,
  callback, cant_cancel)` creates the native modal. Its init registers modal
  input and focuses the edit box. The two callback arguments are text and a
  cancellation boolean. Confirmation invokes the callback before destroying
  the window; the adapter must keep its action guard through that interval.
- Native name confirmation substitutes the initial text when input is empty.
  A future Clear Filters action must be explicit instead of relying on deleting
  all text in this dialog.
- `menu_tools.create_tabbed_title_bar(parent, types, titles)` expects existing
  template children for its left/current/right controls. It does not establish
  arbitrary layout creation or a row of all six proposed inventory categories.
  Creating that layout remains separate work; no guessed widgets are shipped.

No proprietary function bodies, bytecode or disassembly are tracked. The native
input helper only exposes a Ctrl+F edge and a key-release check, with exact-build
Lua API fingerprints and balanced callback registration. It is independent of
Quest Hider at runtime. The older snapshot observer's `math.floor` failure is no
longer relevant to export collection: all 125 exports were already complete.

## Next work

1. Validate the 0.2.0 search/sort preview in-game: real name matching, collapsed
   groups, empty results, duplicate items and native item actions.
2. Refine metadata/localization behavior from that result, keeping native handles
   and original category contexts.
3. Add visible clickable controls and direct category navigation once their
   template/layout and focus contracts have been established.
4. Audit rarity/type/requirement readers and mixed-category action routing before
   adding their filters or a combined All view.

## Historical results from the first target runs (17 October)

The first log stops after Quest Hider's native renderer-install message during
`minimap_win`, while the probe had finished its menu helper export and startup
had continued. The user then reached the game and browsed inventory with Quest
Hider removed and the probe still installed. Keep Quest Hider disabled for the
next inventory run; its separate startup mitigation remains unverified in-game.

The second log contains 19 complete, checksum-validated function exports: the
standard-list helper, ten name-window functions and eight inventory-manager
functions. They were reconstructed and inspected privately. The input window's
launch function takes six arguments (title, default text, localization flag,
text limit, callback and cancellation restriction). Its initialization registers
modal input, finds an edit box, sets its title/limit and focuses it. Confirmation
reads the edit-box text and invokes the supplied callback; cancellation also
returns through the callback. This is a concrete path to investigate for search
input. It has not yet been launched for inventory or tested for input isolation.

The manager's inventory-count function calls `get_player()` and ACTOR inventory
readers, excludes certain native equipment/quest categories, and handles the
Autosell pocket separately. Bag capacity count therefore cannot be assumed equal
to the number of visible rows. These call sites are evidence; the probe does not
invoke them or change native limits.

The log also reveals a probe defect: `inventory_win` and `ledger_win` exist as
metadata-only tables during the manager trigger, before their bodies finish
loading. Probe 0.1.0 permanently marked those tables as seen, exporting zero
functions and installing no inventory observers. It therefore missed the later
real inventory module even though the user performed the requested test.

Probe 0.1.1 rescans on later triggers, tracks exported names individually and
installs observers once the functions appear. A regression reproduces exactly
the placeholder-then-populated loading order and verifies that exports occur
once, original callbacks are exported and returned values remain unchanged.
The reader now explains this known failure instead of telling the tester simply
to open inventory again; `--allow-partial` can retain the valid utility exports.
The next target run needs only the probe Lua file replaced, with Quest Hider
still disabled. Inventory row/action contracts remain the missing gate.


## Complete export and UI trial (17 October)

The later probe 0.1.1 log contains all 125 functions, including 93 inventory
functions and seven ledger functions. They have been checksum-validated and
decoded privately; no further export run is needed. Quest Hider's separate bug
is now fixed and its 1.0.0 journal hide/restore was confirmed by the user.

The first installable Inventory Plus UI trial is 0.1.0. It deliberately leaves
rows/actions unchanged outside its owned text dialog. Host C checks cover
shortcut edges/modifiers/focus, and Lua checks cover guard lifetime, confirmation,
cancellation, held keys, callback errors, placeholders and native return values.
Target-game focus/layout/coexistence still require the single test linked above.


## Input gate passed; 0.2.0 view projection (17 October)

The latest log records native search requests, accepted text and input restored.
The user explicitly confirms typing did not act on inventory items and that
Cancel/Back returns cleanly. The screenshot confirms a native hint is visible,
but its original trial text is too long. 0.2.0 replaces that with a bounded query
excerpt, counts and compact controls. The first text-focus gate has therefore
passed on the user's setup; this does not validate projected item rows yet.

Static native registration tracing identifies `ACTOR.get_actor_display_name` as
a one-argument, read-only actor-handle reader returning a string. Its actor class
registration/vtable establishes the namespace, rather than guessing it from the
name. The adapter checks `ACTOR.is_valid` before reading a display name and before
returning a selected handle in an active view. No raw getter address is called.

Projection wraps `get_surplus_inventory`: temporary category expansion allows a
full category snapshot, then flags are restored before matching/sorting. Header
rows are cloned with updated counts and the category-index map is replaced as a
unit; item rows retain their native handles/fields. User category expansion
before search is saved and restored on clear/close. Matching counts include
collapsed groups; displayed children respect the current collapse flags.

Rebuild captures the selected item handle and remaps it before the native
`update_selected_window` call. Restoring only after `rebuild_list_win` returned
would be too late: item-card observers could already have seen the different
item at the old numeric index. Tests explicitly check all intermediate card
observations retain the intended handle. A no-result view contains only headers;
selected-item actions are suppressed when no item exists. Bulk junk destruction
is blocked during search because it includes concealed items.

The independent native helper now accepts Ctrl+F/Ctrl+S and offers UTF-8 invariant
Unicode lowercase through documented Windows conversion APIs. Invalid UTF-8 or
allocation/conversion failures return no result; projection then restores the
native view. This is not full Unicode case folding or locale collation. The
helper's string return reuses the fingerprinted pushstring routine already
verified for Quest Hider. Bridge token is now `InventoryPlus 0.2.0`, requiring a
matched DLL/adapter update and the JSON that loads the row model first.

The current [preview and test](README.md) replaces the UI trial as the next game
build. Direct tabs/clickable controls, a combined All view and metadata filters
remain unimplemented. The model and mock tests do not validate real getter text,
projected selection/actions, Windows lowercase or layout in the user's process.
