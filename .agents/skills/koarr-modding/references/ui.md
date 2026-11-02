# Inventory, journal and UI contracts

Read current source before modifying these contracts. The current inventory
navigation preview is not fully validated in-game; preserve a working rollback.

## Native inventory dataset and item identity

`inventory_win.get_surplus_inventory()` builds a category-specific snapshot from
`m_button_definitions[m_selected_slot]`. Entries can use a lookup function or
native equippable inventory. It applies native pocket, equipment-slot and
subcategory rules. Do not replace it with a guessed all-inventory API.

Rows are native headers (`header_id`, `header_text`, `len`) and item entries
(`item_id`, plus any original fields). `m_last_set` is the displayed dataset;
`m_cur_categories` maps header IDs to row indices. `m_category_status[id].collapsed`
controls expansion. Sorting/filtering must update header counts and index maps
alongside rows, preserve original item tables/handles, and avoid modifying source
headers or item arrays. Count matching items even inside collapsed groups.

`m_list` is a native standard list. `get_selected_item(allow_header)` looks up
its selected/focused row in `m_last_set`. `rebuild_list_win` refreshes rows,
rebuilds widgets, sets/clamps selection and calls `update_selected_window`
**before it returns**. Remap the exact selected item handle before that card
update, not afterward. Otherwise other UI mods can observe a transient wrong
item. On a category transition keep the native default selection; an old index
has no meaning in a new context. In a same-context rebuild preserve the exact
handle, then nearest remaining item, then no selection if no items remain.

Never call `set_selected_item` just to reorder rows: it can remove new-item
markers. Use the existing list selection contract and retain original action
paths. Revalidate handles before actions. Empty results must not leave stale
item cards or enabled equipment/destruction actions. Block native Destroy All
Junk while filtering, since it also destroys concealed entries.

## Names, normalization and numeric properties

`ACTOR.get_actor_display_name` has a valid actor signature but is unsuitable for
inventory item names. It caused all 48 items to fail search and left sorting
apparently unchanged. The native inventory ribbon formats item handles through
`WINDOW.set_label_text_formatted`, and its variant-to-text converter uses the
stored inventory name, including custom names.

Current native reader follows the verified path:

| Operation | Preferred VA |
| --- | --- |
| shared variant-to-text converter, for evidence | `0x00ECDC20` |
| decode Lua actor handle | `0x00E5F770` |
| actor lookup | `0x00F23C10` |
| `actor::name(false)` | `0x00EF3B20` |

Validate actor handles first, check the inventory flag, borrow the afstring text
only until pushstring copies it, and never free the game's name storage. Consult
`inventory-plus/src/inventory_plus/item_name.h` for the actual layout.

Search uses literal substrings after Windows invariant UTF-8 lowercase. Accents
remain significant; this is neither full Unicode case folding nor locale-aware
collation. Unknown names or failed normalization restore the native list instead
of silently removing items. Duplicate names keep snapshot ordinal as tie-breaker.

Damage/armor/value/rarity/required-level sorts require separate semantic audits.
Names found in a binary are leads, not signatures. Both TYPE and ACTOR expose
similarly named damage/armor functions. Captured native wrappers for ACTOR damage
(`0x00E8BF90`) and armor (`0x00E8C2D0`) take **three arguments**: actor handle,
integer slot index (14-slot table), boolean scaled flag; they return a truncated
integer. Which index the card shows is unverified (see spike notes). Do not call them
with a handle alone, parse localized tooltip text, infer DPS, or conflate item
level and required level. Verify the exact native card's value and scaling flags.
Unknown numeric values sort last in either direction, not as zero.

## Text input and footer

The verified six-argument dialog call is:

```lua
name_win.launch('Search items', query, false, 64, callback, false)
-- callback(text, cancelled)
```

The callback runs before modal destruction. Store the pending query, wait until
`name_win.m_inited` is false and all held keys are released, consume that update,
then return input to inventory. Cancellation retains the query. Native empty
confirmation can substitute the initial text; Escape outside the dialog clears
search. Keep its native text handlers active while suppressing inventory/ledger
item actions. A further Back after clearing must remain available.

`inventory_win.handle_input` uses `input.info` and `input.handled`. Ledger action
dispatch runs before inventory handlers, so guarding inventory alone is too late.
Native keyboard polling requires foreground-process focus, modifier checks and
per-key edge state. `InventoryPlusNative.idle` checks all virtual keys; it does
not itself mean queued UI release events have been delivered.

Footer labels can be captured during native `ledger_win.set_reminder` by
scoping temporary WINDOW setter wrappers, calling originals, restoring setters,
then updating the captured label. Keep return values and cleanup on errors.
Late reminder writes can occur outside `button_tree_callback`; retain ownership
while the real list is visible. Root visibility alone is insufficient. Reapply
as needed after native updates, release on HIDE/START_CLOSE, and keep hints short:
the original trial's long footer clipped badly at the user's resolution.

## Category navigation

The native dataset has distinct contexts:

| Context | Native node ID | 0.5.0 shortcut |
| --- | --- | --- |
| Inventory branch | `4242793` | outer native ledger entry |
| Weapons parent | `2468509` | internal traversal |
| Primary | `2627341` | Ctrl+1 |
| Secondary | `2010694` | Ctrl+2 |
| Armor | `1070770` | Ctrl+3 |
| Accessories | `6689260` | Ctrl+4 |
| Consumables | `7304644` | Ctrl+5 |
| Items | `911336` | Ctrl+6 |
| Junk | `607556` | Ctrl+7 |

Do not merge Primary and Secondary. Their native candidate lists, exclusions,
comparison and Equip action contexts matter. Switching views must not equip
anything. Preserve disabled flags on every ancestor and the target.

### Failure history to avoid

0.3.0 created tabs whenever the inventory root was visible in replace/pocket
mode. That also described the native category landing menu, so controls overlapped
it. Direct `ledger_win.launch_into_button(leaf_id)` led to portrait-only screens;
a blanket pending-transition input guard also broke Back. Its mocked tests did
not establish the engine contract. It was withdrawn in 0.3.1.

The 0.1.2 probe captured runtime `ledger_win.m_button_tree` closures. Their
verified semantics:

- `find_node(id)` returns a node; nodes link to `parent`, `children`, `id_string`.
- `get_cur_node()` resolves the current `m_path` (native IDs, not row indices).
  `find_path_to_node` returns child indices: do not confuse those representations.
- `go_up_a_level()` runs hide/close callbacks, removes a path entry, restores
  extra windows/module context and highlight.
- `set_highlight(index)` calls the native highlight callback and updates UI.
- `go_down_a_level()` checks disabled/override, then uses `load_node` with the
  native completion callback. Wait for `m_node_load_in_progress` to clear.
- `launch_into` reconstructs paths/shows windows but does not itself run the
  inventory enter callback needed for the failed direct-jump scenario.
- `hide()` hides only the tree window and removes tree focus;
  `remove_tree_focus()` changes enabled state and updates UI;
  `show()` restores the tree window and native focus.

Use native parent/child traversal through a shared ancestor. Never assign
`m_selected_slot` or `m_path` to imitate a transition. Advance from the ledger's
`on_update_event`: a normal parent transition can hide the inventory child, so
that child's update callback alone may stop before traversal finishes. Bound
queued work and cancel on Back; never gate all input until a timeout.

The user requested replacing the inventory category menu while keeping Inventory
in the outer native ledger and preserving native items/details/actions. Current
0.5.0 hides only the tree window while inside the Inventory branch, enters the
last category (Primary initially), and exits the full branch on Back after
clearing search. Other ledger sections must stay native. Seven header controls
use two columns/four rows, reserving 128 native list units. This entry/exit flow
and slot behavior are awaiting an in-game check. 0.5.1 adds a fallback: if no
category can be entered or navigation times out, restore the native category menu
(`tree.show`) and stop auto-entering until the branch is left; a hidden tree is
also returned on any non-Back exit. Never leave the tree hidden without a list.

### Controls and click ownership

Reusing `INVENTORY_HEADER` is proven as a construction path, not proof that every
layout/hit target works. Native creation uses:

```lua
WINDOW.create_window(UIXML_ID('inventory_win'), 'INVENTORY_HEADER', parent)
WINDOW.find_static_type(root, 1221325, 679773, -1, true)
```

Move/resize wrappers take window plus two numeric arguments. Resize the actual
hit area/ancestors as well as the label. Save/restore original list geometry;
remove partially created controls on failure and all owned controls on close.
Gate visual creation on the actual list wrapper being visible with a valid
category, not just the root window. Do not presume arbitrary custom XML loading
or new widget schemas are supported.

0.4.0 improved navigation but tab clicks also reached native controls underneath.
Intercept owned events in **ledger.on_button_event_selection before native tree
handling**, as well as inventory handlers. Native template IDs are duplicated;
compare owned window identities/ancestry, not IDs alone. Retain click ownership
independent of tab window lifetime. Consume retargeted release events and item
activation until button release plus queued-event drainage (currently two ledger
updates). Clear stale mouse-event/hover fields, then start navigation. Back is
exempt from this short capture. Do not turn pointer capture into another generic
navigation lock. Test ordinary item clicks after capture ends.

## Quest Hider-specific behavior

Preserve tracked quest selection internally. Hiding visibility is not abandoning
or completing a quest. Shared objectives stay visible if any owner remains
visible; unresolved ownership remains visible. Quest-giver/fast-travel icons are
outside its objective filter. The tracked quest's HUD text and overhead billboards
remain visible. Completed quests cannot be newly hidden, though previously hidden
ones can be restored. Map filtering starts after the first journal open in a
session. See `quest-hider/README.md` for current scope, profile collisions and keys.

## Minimal target checks

Choose checks relevant to the actual change:

- Startup reaches menu; opening/closing affected UI works repeatedly.
- Known substring and no-result searches; clear/cancel; input does not act on items.
- Duplicate item selection, native tooltips/actions, depleted stacks and removed handles.
- Click press/release over tabs, native controls beneath them, repeated clicks,
  Back during transition and reopening screens; no leftover controls.
- Primary/Secondary eligibility, comparison and correct Equip destination.
- Controller fallback and smaller/larger UI scales; disclose untested layouts.
- Quest hide/restore, tracked selection, shared objectives, character/profile
  transitions and full restart when those behaviors change.

Ask for the full framework log and a screenshot when they resolve a specific
unknown. A user confirmation is evidence for the behavior they tested even if
no log was saved. Keep that evidence narrower than a blanket compatibility claim.
