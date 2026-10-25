# Inventory Plus — technical spike findings

Updated 25 October 2026. Current build: **0.3.1 recovery; tabs withdrawn**. The user
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
text-input gate. The [current search/sort preview](../../README.md) exercises the next
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

The current [preview and test](../../README.md) replaces the UI trial as the next game
build. Direct tabs/clickable controls, a combined All view and metadata filters
remain unimplemented. The model and mock tests do not validate real getter text,
projected selection/actions, Windows lowercase or layout in the user's process.


## Inventory-name correction (18 October)

The target 0.2.0 test accepted queries and cleared correctly, but all queries
matched 0/48 items and sorting appeared unchanged. The actor display-name API
signature was valid; its semantics were unsuitable for inventory names. The
previous assumption above is superseded by the native label path traced here.

`set_ribbon_name` formats its item-handle argument via `WINDOW`'s formatter.
The shared variant-to-text routine at preferred VA `0x00ECDC20` decodes an actor,
checks its inventory flag and copies `actor::name(false)` at `0x00EF3B20`.
That reader selects the stored custom name when present, otherwise the normal
stored name. `ACTOR.get_actor_display_name` instead uses a different fallback
through `0x00E533A0` and cannot substitute for that path.

0.2.1 adds `InventoryPlusNative.item_name(handle)`: the engine's own handle
decoder (`0x00E5F770`), actor lookup (`0x00F23C10`) and inventory name reader.
It checks executable identity and all new function fingerprints, checks the
inventory flag, borrows text only until `lua_pushstring` copies it and performs
no item writes. Lua still checks `ACTOR.is_valid` first. Missing/empty names
restore the native view through the existing projection failure path. The new
bridge token rejects mixed DLL/Lua versions. A deferred lowercase sentinel check
also rejects a broken normalization bridge before applying a view.

Four optional real-engine emulation cases execute the actual decoder, lookup
and name-selection functions at preferred and relocated bases, including custom
names. Host C checks cover invalid actors, missing/empty names and borrowed text;
Lua integration deliberately makes the old display-name API throw. All 21 tests
pass. These checks do not confirm live game matching, sorting or localization;
the focused game retest remains required.

```sh
PYTHONPATH=/path/to/pefile-and-unicorn python tools/verify_inventory_plus_names.py /private/path/koa.exe
```


## Search gate passed; native category tabs (18 October)

The user confirmed search, sorting and clearing work in 0.2.1. A missing log does
not invalidate that direct in-game result. 0.3.0 keeps that row model and name
reader and adds `navigation.lua`, framework-loaded before the adapter.

The existing `get_button_tree_info` provides six category branches. Weapons has
primary/secondary leaves; the other five are direct leaves. The tab targets are
2627341 (Weapons primary; secondary 2010694 remains selected when already active),
1070770 (Armor), 6689260 (Accessories), 7304644 (Consumables), 911336 (Items), and
607556 (Junk). The native `ledger_win.launch_into_button(id)` one-argument call
is present in its original window and input handlers. Tabs call that transition,
not just the inventory callback or a direct `m_selected_slot` assignment. Native
disabled flags, including the weapon parent and inventory root, are respected.

Controls reuse `INVENTORY_HEADER` through the same `WINDOW.create_window` and
`find_static_type(...,1221325,679773,-1,true)` contract as native headers. This
requires no proprietary assets in the package. Header ancestors and labels are
resized to keep the click area within each tab. They occupy two columns and
three rows over the list panel (96 native UI units); the list wrapper is moved
and shortened accordingly. This layout gives the longer labels room. The active
tab is bracketed; captions are English. Owned button events are consumed before
the native list handler can interpret their duplicated template IDs as rows.
Ctrl+1–6 uses the same focus/modifier/edge helper as Ctrl+F/S.

Tabs are created only after inventory initialization. Modal text entry, dragging,
tutorials and compare/confirmation contexts cannot activate them. Native window
HIDE/SHOW events during category transitions retain the query. A pending guard
handles delayed transitions, blocks item input until the destination is active,
and times out after 180 inventory updates if it cannot complete. Creation errors
remove partial controls and restore the original list geometry. Close/detach
restores the layout, and unchanged tabs do not rewrite labels every frame.

22 offline tests cover the existing features plus tab routing, active captions,
owned hit testing, query/sort preservation, delayed transitions/timeouts, native
disabled flags, modal guards and partial creation rollback. UI wrappers for move
and resize were statically checked as three-argument calls. Actual header click
events, label clipping, native transitions and layout remain unconfirmed until
the next game test. New controller tab focus is not implemented; native
controller navigation remains available.

Additional requested stat sorting is now explicit in the specification. The
executable has both TYPE and ACTOR weapon-damage/armor readers. In particular,
ACTOR's weapon damage and armor wrappers take three arguments, not just an item
handle (`0x00E8BF90` and `0x00E8C2D0` respectively). Their native card call sites
and parameter meanings must be verified before choosing a damage metric. No
numeric stat sort is exposed by this tab preview.


## Tab preview failed; recovery (25 October)

The user's screenshot shows all six cloned headers over the native category
landing menu. Clicking led to a portrait-only view; Back stopped working, with
repeated category-transition timeout messages. This supersedes the mocked
navigation assumptions above: those tests could not prove the ledger contract.

Two incorrect assumptions were shipped. A visible inventory root and a
replace/pocket mode do not imply that an item-list page is active. Moving the
list wrapper also cannot reserve space occupied by the separate native category
menu. Second, existing calls to ledger_win.launch_into_button used top-level
nodes; they did not establish support for jumping directly to category leaves.
The preview's 180-update input guard aggravated the failed transition.

0.3.1 withdraws navigation.lua and its manifest entries, removes the category-key
extension and all switching guards, and restores the 0.2.1 adapter with a new
matched DLL version. No control creation or ledger navigation is attempted.
The obsolete mock tab test is removed. Recovery integration checks deliberately
make stale navigation factories, control creation and leaf launches throw, and
verify Back reaches the native ledger when the root is visible. Package checks
exclude the withdrawn script. Existing row/search/selection tests remain.

A complete game restart is required to remove already-created controls and
broken native tree state. The old navigation.lua file may be deleted and is
otherwise unreferenced. Future tabs require the actual native tree traversal
implementation and page visibility contract, with recovery/Back demonstrated
in-game before another navigation build is advertised as working.


## Footer entry correction (25 October)

The user confirmed 0.3.1 search/sorting still work; category buttons are absent
as intended, but the hint is missing on entry to an item category. 0.3.2 retains
footer capture for native ledger.set_reminder calls outside the category callback
when the actual list wrapper is visible. It reapplies the captured hint after
native inventory updates and relinquishes it on HIDE/START_CLOSE. A visible root
alone is insufficient: landing-menu footer updates remain native. Integration
checks reproduce late reminder writes, update overwrites and a hidden list under
a visible root. The DLL ABI remains 0.3.1; this is a Lua-only change.


## Rebuilding category navigation (25 October)

The user reaffirmed category buttons as required. Restoring native browsing was
a recovery step, not completion of navigation. Probe 0.1.2 adds passive exports
of ledger traversal functions and runtime m_button_tree closures. Existing
exports establish top-level launch calls but not leaf traversal, so another
button build must wait for these real contracts instead of repeating the failed
launch_into_button(leaf) assumption. No tab clicks or category mutations are
introduced by this diagnostic capture.


## Captured traversal; rebuilt buttons (25 October)

The uploaded log begins after the BEGIN marker but contains complete CRC-checked
ledger_tree exports. It is treated as an explicitly identified partial fragment,
not evidence that missing ledger startup functions were captured. Private
bytecode/disassembly remains under ignored build/.

The captured go_down_a_level checks the highlighted node, then invokes load_node
with the native finish_go_down_a_level callback. go_up_a_level performs the
native hide/close/path/module/highlight sequence. launch_into rebuilds a path and
shows windows but does not call the inventory enter callback; this is not used
by the new adapter. find_node, get_cur_node and the native m_path structure
establish the route. Parent chains carry native id_string values.

0.4.0 queues a switch until input is released, moves up to a common parent and
then highlights/enters each child through go_down_a_level. It waits for native
m_node_load_in_progress instead of synthesizing callbacks. It never directly
writes m_selected_slot, m_path or inventory item data. Back cancels queued work
and remains forwarded to the existing handler. A bounded timeout drops the queue
without blocking input. Query retention is separate from modal input guards.

Owned headers are created only when the real list wrapper is visible with a
valid category, addressing the reported landing-menu overlap. They reserve 96
native units in the list pane, with two columns/three rows. Partial UI creation
restores original geometry. There are no changes to Quest Hider or All Quest
Markers. The mod requires the 0.4.0 DLL (Ctrl+1–6 polling) and adapter together.

22 offline tests pass, including shared-parent traversal, deferred native loads,
release gating, cancellation and landing-page exclusion. This is a new target
preview: actual layout, hit boxes, native callbacks and Back must be checked in
game before considering category buttons confirmed.

Navigation ticks from the ledger's existing on_update_event (its presence is
confirmed in the earlier module-field capture), so hiding the inventory child
during a parent transition cannot strand the queue. Original return values
are preserved. No new game callback or frame hook is invented.


## Tab click isolation (25 October)

The user reports improved category switching, but clicks also activate the native
control that would lie beneath a tab. Previously only inventory's button handler
consumed owned events. 0.4.1 intercepts them in ledger.on_button_event_selection
before the native ledger tree can interpret the cloned header's IDs.

A tab DOWN retains click ownership independently of the owned windows. Retargeted
button events, inventory actions and native inventory per-frame mouse handling
are consumed until input is released and two ledger updates drain queued release
events. Category traversal starts afterward. Back is explicitly exempt from the
short capture guard; ledger frame processing continues. Teardown clears capture.

23 offline tests pass, including ledger-first interception, release events on a
different window, guard survival across destroyed controls, held-button/release
timing, action suppression, Back forwarding and recovery of ordinary input. This
is Lua-only, using the existing 0.4.0 native ABI. The user's click-through case
requires a target-game retest; it is not claimed resolved from mocks alone.


## Native inventory shell replacement and weapon slots (25 October)

The user requests replacing native category navigation while retaining native
inventory contents. 0.5.0 splits Primary (2627341) and Secondary (2010694) into
separate buttons, then Armor/Accessories/Consumables/Items/Junk. Ctrl+1–7 uses
the updated 0.5.0 DLL. Seven buttons occupy two columns/four rows (128 native
units). Both weapon contexts still enter through native tree callbacks; no new
equip implementation or item classification is introduced.

The ledger tree's category window is hidden only when its current node is under
the Inventory branch (4242793). remove_tree_focus is the captured native method;
only its category window is hidden, not inventory item/detail windows. On the
Inventory or Weapons landing node, a native traversal enters the last viewed
category (Primary initially). A stale selected slot cannot falsely count as an
entered category when the list is hidden. Back clears search through existing
logic, then native parent transitions leave the whole Inventory branch and
tree.show restores the normal ledger navigation outside it. Other ledger
sections are left alone. Native slot disabled checks remain in force.

23 offline tests pass, now including separate weapon target IDs, hidden-list
entry with a stale matching slot, menu hiding, full-branch Back and restoration
of other ledger navigation. The helper builds successfully. These checks do not
confirm target-game layout, normal input, or primary/secondary Equip routing; the
0.5.0 preview requires that in-game check.
