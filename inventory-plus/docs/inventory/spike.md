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


## 0.5.0 review and 0.5.1 hardening (2 November)

No newer commits or in-game feedback were available (HEAD 1edda2e), so 0.5.0 was
reviewed against the contracts above rather than assumed to work. Concrete risks
found in the shell and fixed Lua-only in 0.5.1 (native helper and bridge token
unchanged):

- **Blank page on failed entry.** The shell hid the ledger tree, then tried only
  the last viewed category. If that node was disabled (or entry timed out) the
  list never appeared, the tree stayed hidden and the attempt repeated every
  frame. It now tries every category, and on failure restores the native menu
  and stops retrying until the player leaves the Inventory branch or a list
  shows. Navigation timeouts and a missing node do the same.
- **Stranded hidden tree.** Only the Back path called `tree.show`. Any other
  exit from the branch (ledger shortcut jump) now restores it, and detach does too.
- **Unconfirmed button event contract.** `(event, window)` argument order was only
  ever mocked. `T.event` now treats the string argument as the event name, and
  logs each distinct event name and target type once (cap 8) so the next framework
  log settles the contract without another probe.
- Footer used an en dash that the game font may lack; it is now `Ctrl+1-7`, and
  the tab hint remains visible while a sort is active.

The inventory suite (14 tests, including new cases for swapped event arguments,
native-menu fallback without a retry loop, and tree restore on a non-Back exit)
passes. The Quest Hider package test could not run here because its ignored
native DLL is not built on this machine; nothing in that mod changed.

Stat sorting is still unimplemented. A local `koa.exe` exists but no captured
exports or disassembly of the ACTOR/TYPE damage and armor wrappers are present
in this checkout, and their three-argument meaning is unverified. Next step is a
private, read-only disassembly of the native item-card readers
(`0x00E8BF90` damage, `0x00E8C2D0` armor and their call sites), not a guess.


## Native damage/armor readers: static findings (2 November)

Read-only disassembly of the supported GOG `koa.exe` (SHA-256 matches
`common/tools/verify_game_vm.py`). Disassembly stays private in ignored `build/`.
Addresses are image-base 0x400000 VAs.

| Wrapper | Lua shape | Calls |
| --- | --- | --- |
| `0x00E8BF90` damage | `fn(actor_handle, int index, bool scaled)` | `0x00E42140` |
| `0x00E8C2D0` armor | `fn(actor_handle, int index, bool scaled)` | `0x00E421D0` |

- Argument 1 is decoded with the shared actor-handle decoder (`0x00E5F770`); 2 is
  read as an integer, 3 as a boolean. A wrong type returns the shared error value.
- Both resolve a per-actor component (`0x00F24EF0`: type 0xB for damage, 0xC for
  armor) and require its flag bit 0 (`[comp+0x20]&1`); otherwise they return 0.
  Lookup writes only to its local out-structure. The reads are pure.
- The component holds an array of 8-byte entries from +0x24: a float and a pointer
  to a float override. A set override wins. Negative values clamp to 0.
- `scaled=false` returns that clamped entry for `index`. For damage, `scaled=true`
  multiplies it by a clamped modifier at component +0x15C, except index 12, which
  is returned unscaled. The result is converted with `__ftol`, so Lua sees a
  truncated integer.
- Damage indices loop 0..13 in a helper, so the table has 14 slots. Which index
  the item card shows is not yet known; do not assume index 0.

The registered Lua names are not plain strings in the static image (runtime
data), so the names and the card's actual call site (game Lua) are unverified.
No sort is enabled. Next: a small diagnostic ZIP that, on request in the Inventory,
logs the values for indices 0..13, both modes, for the selected item, which the
user compares with the native card. It must not be written until that comparison
is planned for one game run.



## Stats probe 0.1.0 (2 November)

A separate diagnostic (own DLL, manifest and Lua; see [stats-probe.md](stats-probe.md)) calls the fingerprinted pure readers at 0x00E42140/0x00E421D0 for the selected item on Ctrl+D and logs slots 0..13 raw and scaled. It exists to learn which slot and mode the native card shows. The native call path is unexercised in-game; only its Lua side and packaging are covered offline.


## 0.6.0 provisional damage/armor sorting (4 November)

The native helper gains `stat(handle, spec)` and `stats(handle)` (and Ctrl+D
polling). They call the fingerprinted pure readers (`0x00E42140`, `0x00E421D0`)
only after the actor handle resolves to a valid inventory actor, and refuse to
register if either function's prologue differs. `spec` is a four-character string:
kind (`d`/`a`), two-digit slot 00..13, scaled flag 0/1; results return as text.
The bridge token is `InventoryPlus 0.6.0`, so the DLL and Lua must be replaced
together.

The adapter adds `dmg` (Primary/Secondary) and `arm` (Armor) orders, high to low,
unknown last, name then snapshot ordinal as tie-breakers, and resets them to
Name A-Z in other categories. The slot/mode table (`STATS` in `inventory_plus.lua`)
is **provisional**: slot 0, scaled. Ctrl+D logs every slot, both modes, for the
selected item so one in-game comparison against the native card can settle it.
17 offline tests pass (model, adapter, native build under `-Werror`); the native
call path itself has not run in the game. The separate stats probe remains for
diagnosis but is no longer needed for this check.


## 0.6.1 and the remaining sort keys (4 November)

Rarity, required level and value are not sortable yet. The wrappers registered
beside damage/armor (`0x00E8C060`, `0x00E8C130`) have the same `(actor, int, bool)`
shape and read the same family of stat tables, so they are not those keys, and
no static evidence ties any other wrapper to rarity, level or value. Their Lua
names are runtime data, and calling functions by name is not allowed. 0.6.1
(Lua-only) therefore adds an observation-only step to Ctrl+D: it lists, but never
calls, ACTOR/TYPE function names that mention value/level/rarity/quality/price/
cost/gold/worth/tier. The next iteration chooses readers from that list and the
card, verifying each natively before any sort uses it.


## 0.6.2: base-address regression (5 November)

The first 0.6.x game log showed the DLL loaded but `InventoryPlusNative` missing:
the helper's identity checks failed, so it registered nothing and the adapter
left vanilla alone. The run's framework addresses were exactly 0x10000 below the
preferred-base ones, i.e. the same executable loaded at 0x3F0000, not another
build. 0.6.0 added fingerprints for the damage/armor readers that included an
absolute operand (`mov edi, 0x1741aac`); the loader rebases it (0x1731aac at that
base), so the byte comparison failed. 0.6.2 compares the fixed prefix and then the
operand against the actual base. Every other fingerprint was already
relocation-free. `tests/test_fingerprints.py` (needs `KOA_EXE` and `pefile`)
relocates the private executable to three bases and checks every fingerprint in
both helpers; against the 0.6.1 source it reports exactly the two bad ones.
Lesson: fingerprint arrays must be checked at a non-preferred base, not only 0x400000.


Hardening for other players' PCs: the damage/armor reader fingerprints are now optional. If they ever fail to match, only the stat sorts are disabled (`has_stats` returns 0) and search, name sort, tabs and Back still load. A core-fingerprint mismatch (different game build) still disables the helper, and the log now says so: 'unsupported game build or incomplete install'.


Verification added in 0.6.2: `tools/verify_inventory_plus_stats.py` runs the game's real reader code (0x00E42140/0x00E421D0) in an x86 emulator at three image bases against a synthetic component (180 cases: raw/scaled, slot 12, override pointers, invalid component, stack balance), alongside the existing name-path emulation. The spec parser has a C unit test. In-game confirmation of the whole flow is still pending.


## 0.6.3 from the first working game log (5 November)

0.6.2 loaded: the helper registered, search, the tab controls and Ctrl+D worked.
Findings and changes:

- **Button events** arrive as `(event_name, window)`: ENTER, MOVE, PASSOVER, LEAVE,
  DOWN, PRESSED, CLICKED, UP, with a userdata window. The argument order assumed by
  the click guard is confirmed.
- **Armor key:** slot 0 matches the card. "Boiled Leather Hood" read raw 27 / scaled
  51, and ItemScaling's hover line for it says armor 51 (base 27); other pieces
  read 28 or 56 where raw equals scaled. Armor sorting therefore keeps slot 0,
  scaled. The damage slot is still unconfirmed (no weapon was dumped).
- **Value and required level:** the candidate-name list showed `get_item_cost`,
  `get_level_requirement` and `get_item_level` on ACTOR. Working third-party mods
  (Transmog, ItemScaling, SetSeeker) call them as `pcall(ACTOR.get_x, item)` and use
  the numeric result, so 0.6.3 adds Value and Lvl sorts on exactly that shape. Getters
  only; no setter is called. Ctrl+D logs the three values for comparison with the card.
  There is no rarity getter in the list, so rarity is still unavailable.
- **Footer overlap:** with a sort active the tab legend ran past the row it shares
  with native buttons. The legend is now capped at 34 characters in every state
  (tested); long queries shrink to fit and "No match" is shorter.
- **Weapon tabs did nothing.** The log has no navigation lines at all, so the cause
  cannot be read from it. 0.6.3 logs every refusal and every traversal step
  (`[nav] ...`, bounded to 60 lines), plus each tab click, so the next log shows
  whether the click reaches the tab, whether the route is refused, or where the
  native traversal stalls. Ctrl+1 and Ctrl+2 exercise the same path without the mouse.


## 0.6.4 from the 0.6.3 game log (5 November)

The `[nav]` lines found the weapon-tab bug exactly: `tab 1 refused: route does not
reach the tree root`, for Primary and Secondary only. The route was built by walking
`parent` links from the target; the Weapons subtree has none (while `find_node` and
`children` do reach it). The route now comes from a depth-first walk of `children` from
`m_tree`, and "inside Inventory" comes from the native path (`m_path[1] == 4242793`)
instead of a parent chain. A regression test builds a Weapons subtree without parents
and fails on 0.6.3. The earlier "Primary by default" entry silently fell back to Armor
because of the same refusal.

Ctrl+1 equipped the hovered item: the game binds the digit keys 1 and 2 to equipping.
The frame poll consumed our shortcut edge first, so the game's own key event reached the
equip action afterward. The helper gains `held("Ctrl+N")`, a real-time chord query that
does not consume the edge; while a chord is held (and until all keys are up) the
adapter swallows every non-Back ledger and inventory action, including equip. Plain 1
and 2 keep their native behavior. Back is never swallowed.

Card comparison: required "8 finesse" on the card while `get_level_requirement` read 0, so
the card shows an attribute requirement. The Req sort now takes the largest of the
might, finesse, intellect and level requirements (all single-handle getters, read in
Transmog's `req_of`); Ctrl+D logs all four. Value: the card showed 69 while
`get_item_cost` read 1803 (Boiled Leather Hood) and 84762 (Cap of the Wanderer). The
scale differs, so Value orders correctly only if the card value is a monotone function of
the cost; the item behind the 69 was not named, so this is unconfirmed. Ctrl+D
output next to the card values for two named items will settle it.


## 0.6.5: Damage and Armor sorts were never offered (5 November)

The tester cycled az, za, lvl, value and never saw Armor. Cause: `has_stats` returned
`stats_ok ? 1 : 0` from a Lua C function. That return value is the *number of results
pushed*, and nothing was pushed, so Lua received no number and the `== 1` check was always
false. The native-backed sorts (Dmg, Armor) depend on that check; the getter-backed ones
(Req, Value) do not, which is why those appeared. The unit test mock returned a real `1`,
which is why every test passed. `has_stats` now pushes "1"/"0", Lua compares text, the mock
returns text, and a source-level test requires the function to push. Other predicates
(`poll`, `held`, `idle`, `self_test`) return 1 with their argument still on the stack,
which Lua reads as a truthy value, and were confirmed working in game.


## 0.6.6: weapon tabs confirmed; damage slot settled (6 November)

The 0.6.5 log shows the weapon tabs working: routes such as `4242793>2468509>2627341`
walk down through Weapons, Primary and Secondary both switch, and entry lands in
Primary. Primary/Secondary switching also ran through repeated rapid presses without
a stall (a second press during a transition is refused as "already navigating").

Damage: "Crude Azurite Daggers" dumped damage slots `13,13,0,...` raw and scaled, and
the card shows 26. ItemScaling's tooltip lines show Physical 13 and Piercing 13 for the
same item. (An earlier note here also claimed a 11 + 11 weapon "showed 22"; that came from
ItemScaling's log lines, not from a card the tester read, and is withdrawn.) For this one
weapon type the card's damage is the sum over the damage types, and 0.6.6 sorts by the scaled total of slots 0..13 (a test
distinguishes 13+13 from a single 20). Armor stays on slot 0 scaled (matched on three
items). Value remains an item-cost order: the inventory does not display it, so it can
only be judged by merchant prices.


## 0.6.7: chained shortcuts; more weapon dumps (6 November)

Armor sort appears and Ctrl+1/2 no longer equip (tester). Remaining report: Ctrl+digits
switched categories only after all keys were released, and holding several in turn did
nothing. The log shows why: `tab 7 route ...`, `tab 6 refused: busy (already navigating)`,
then `Category navigation stopped`. Navigation advanced only when every key was up, a wait
designed for mouse clicks. Key-initiated moves now skip that wait (the chord guard already
swallows the game's own key events) and a newer key press retargets the move in progress.
Pointer moves keep the wait.

Weapon dumps from the same session (scaled slots; ItemScaling alters stats on hover, so the
card may show a value from before or after its adjustment):

| Weapon | Damage slots (raw / scaled) |
| --- | --- |
| Crude Azurite Daggers | 13,13 / 13,13 (card 26, per the tester) |
| Oak Staff | slot 4 = 35 |
| Oak Sceptre | slot 5 = 23 |
| Emboldening Chakrams | 16,_,_,16 / 25,_,_,16 |
| Infected Longsword | 31,12 |
| Trencher | 52,12 / 74,27 |
| Soldier's Hammer | slot 0 = 79 |

The tester reports cards showing 58 and 72 for two of these but did not say which, so
whether the sum rule holds across weapon types is still open; the sum is only confirmed for
the daggers. The card values and the item names are needed to compare.


## 0.6.8: the weapon headline is direct damage plus damage over time (6 November)

The tester supplied cards for two weapons whose number my slot sum could not explain:

| Card | Rows | Headline |
| --- | --- | --- |
| Emboldening Chakrams | 25 Physical, 16 Fire, 31 Burning over 3 s | 72 |
| Oak Staff | 35 Lightning, 23 Shocking over 5 s | 58 |
| Infected Longsword | 31 Physical, 12 Piercing, 19 Poison over 6 s | 62 |
| Trencher | 74 Physical, 27 Piercing | 101 |

So the headline is the direct rows plus the damage-over-time total. The 14-slot native table
holds only the direct part (hence its dumps of 41 and 35 for the first two), and the over-time
part is not in it. Working mods read both with the game's own functions: direct rows from
`character_data.get_item_damage_by_type(item, 0)` (`mod_b`, with bonuses) and over-time rows
from `character_data.get_item_dot_damage_by_type(item)` (`base`; the card asks without
bonuses). The Damage sort now sums exactly those, with no dependence on the native helper;
tests include the Oak Staff case (35 + 23 beats a plain 40). The earlier statements that the
card "adds the slots" were wrong for weapons with damage over time.

List scrolling: with the category buttons above it the list could not be scrolled to its
last rows. The buttons shrink the list's wrapper by 128 units, but the native list window
inside keeps its original height, so its bottom rows sat below the clipped area. The
wrapper's own list window (a window handle among the fields of `inventory_win.m_list` with the
wrapper's old height) is now resized with it and restored when the controls close. The
resize and the discovered window fields are logged as `[nav] list window ...`; this is
unconfirmed in game because the field names are not known offline.


## 0.6.9: buff-added elements, and the scroll window (6 November)

Two weapon cards disagreed with 0.6.8: Charged Faeblades showed 50 (26 Physical, 15 Piercing,
6 Lightning, 3 Shocking over 4 s) while the sort computed 41, and Blistering Faeblades showed 46
(23, 13, 6 Fire, 4 Burning over 5 s) against 36. The 6-point element and the over-time line are
buff-added: `character_data.get_item_damage_by_type` skips a type whose own amount is zero and
`get_item_dot_damage_by_type` reads without bonuses (Transmog documents both), so neither saw them.
The native scaled slots did see the element (`26,15,0,0,6`: 47), and 47 + 3 = 50. 0.6.9 reads every
damage type with bonuses through `ACTOR.get_weapon_damage(item, i, true)` and
`ACTOR.get_weapon_dot_damage(item, i, true)` (the shapes Transmog uses), and Ctrl+D lists each
type's `direct+over time` beside the total, so the next log can confirm the over-time part
against cards (the direct part is already confirmed). The 0.6.8 note that `character_data` rows
are the card's source is withdrawn.

Scrolling: the 0.6.8 log shows the list's only window field is `window` with height 3675 against
a 516-unit wrapper, so the same-height match found nothing to resize. That window is the scrolling
content. With the viewport shrunk by the reserved 128, the last 128 units fall past the native
scroll range. 0.6.9 adds the reserved height to the content window (and re-adds it whenever the
native rebuild resets it, checked each ledger update); closing the controls restores it. Whether
the native scroll range reads the content height live is unconfirmed; `[nav] padded list content`
lines in the log show it happening, and the user's scroll test shows whether it helps.


## 0.7.0: clickable Sort/Find; what the framework offers (8 November)

Layout. The tabs moved from two columns by four rows (128 units) to four columns by two rows
plus one slim row of two buttons, Sort and Find (96 units in total). Each button is a cloned
native header like the tabs: its click is owned through the same ledger-first interception,
queued, and run only after the release has drained (two idle ledger updates), so the action
(`cycle_sort` or `open_search`) never races the click's own UP event; Back cancels a queued
action. Captions update when the order, query or counts change (`Sort: Dmg`, `Find: frost 2/8`).
A correction to an earlier estimate: a list row is about 105 units tall at 1080p, so the layout
change frees about a third of a row, not three rows; its value is that Sort and Find are now
mouse-usable. A single row of seven tabs was rejected because labels do not fit: at about 19
units per character a 640-unit panel gives roughly 4 characters per cell at seven columns.
Label clipping at four columns (about 8 characters) is estimated, not measured.

Framework capabilities (read from `DevCortez/KoaModFramework`, the `dllmain.cpp` at the commit
the docs already cite; the Nexus page for the framework itself was not located, and the
distributed v1.4 may be newer): the manifest JSON accepts `scripts` (a Lua path loaded when a named
game module loads), `patches` (a byte signature plus replacement, optional `vars`) and `.dll`
files (loaded with `LoadLibraryA`). The only Lua function it registers is `print`. It provides no
UI, texture, widget or asset API, and no event system. Anything beyond those three hooks
(overlay, widgets, asset replacement) would come from a separate mod such as the new third-party
NativeCore, which would make this mod depend on it; that is why Inventory Plus stays on the
game's own modules plus its own helper DLL (see the Dependencies test).

