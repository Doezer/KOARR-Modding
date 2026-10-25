# Inventory mod research

Research date: **16 October 2026**. Target: **Kingdoms of Amalur:
Re-Reckoning, GOG with Fatesworn, Mod Framework v1.4**, matching the existing mods
in this repository. This document supports the [Inventory Plus specification](spec.md).
It records research, not a working inventory prototype.

## Recommendation

Build a better inventory browser: directly accessible category tabs, item-name
search, useful filters and explicit sorting, while retaining the game's item
details and actions. Finding an item should not require repeatedly opening
folders and scrolling through unrelated loot.

Capacity, automatic junking and detailed stat comparison already have mods.
Inventory Plus should work alongside those where possible. The strongest gap
found is an integrated browsing interface. **No matching search/filter/tab
inventory overhaul was found in the catalogue reviewed; this is not proof that
none exists elsewhere.**

## What vanilla already offers

The Amalur Wiki describes six inventory categories: Weapons, Armor, Accessories,
Consumables, Items and Junk [S1]. Its Junk page describes marking items as junk
from the inventory or loot interface, then destroying junk [S2]. These pages
primarily document the original Reckoning; only search-index excerpts were
accessible during this research. They establish a baseline to check, not a
verified capture of every Re-Reckoning screen or shortcut.

We should therefore improve category access rather than advertise categories or
junk marking as entirely new features. Exact remaster navigation, current
sorting, subcategories, row density, comparison behavior and mouse/controller
bindings still need a baseline inventory capture on the target build.

There is a distinction between an item's visible presence and its use of bag
capacity. Players discussing stuck items explicitly disagree about capacity
impact [S4]. Hiding/filtering a row must not claim to free an inventory slot.

## Player needs supported by sources

| Need | Evidence | Product consequence | Evidence limit |
| --- | --- | --- | --- |
| Find and group gear by meaningful properties | A Re-Reckoning PC player asks for a stash Sort button and filters for armor sets, level and rarity [S3] | Name/rarity/required-level sorting and type filters; carry the model into stash later | One explicit request; about stash, not proof that carried inventory has no sorting |
| Reduce visual clutter from unremovable items | Re-Reckoning thread names Death Notice: Frea Almar and Strange Green Stone and asks to stash/junk them [S4] | Quest-item filtering and clear item status; do not change quest flags | Reports are not a verified list of safe-to-delete items |
| Make inventory navigation less cumbersome on PC | Launch-period inventory/equipment interface discussion [S5] | Visible controls, direct category access, mouse interaction and keyboard hints | Small qualitative sample, partly recalling the original game |
| Keep the interface readable at different sizes | PC discussions about 1440p UI and an ultrawide interface being cut off [S6]; existing scaling/texture fixes [M4–M6] | Test UI scale/resolution, retain readable fonts, avoid a fixed 1080p-only layout | No measured prevalence; does not justify claiming a universal scaling fix |
| Manage larger collections | Multiple inventory-capacity discussions and existing capacity mods [S7, M1, M2] | Test browsing with large bags; increasing capacity is outside this mod | Capacity complaints do not establish demand for any particular new tab layout |

This is a qualitative sample of PC discussions, not a survey or a ranking of the
community's most common complaints. Reddit results were found but direct access
returned 403; their noisy snippets were not used to establish specific behavior.

## Existing mods and overlap

Reviewed three accessible Nexus all-time listing pages, including their titles
and summaries: offsets 0, 30 and 60 [C1–C3]. They contained **77 distinct mod IDs**.
Read the relevant individual descriptions below. Descriptions show advertised
features; these mods were not downloaded, run or compatibility-tested here.

| Existing mod | Advertised scope | Consequence for Inventory Plus |
| --- | --- | --- |
| Deep Pockets [M1] | Practically infinite inventory; page summary also mentions stash | Preserve capacity rules; test with enlarged bags |
| New Characters — Inventory Set to 1500 [M2] | Edited character saves with larger inventory | Another existing capacity solution; no save editing needed for our UI |
| Auto Junk [M3] | Automatically sends items to junk with a configurable rarity threshold | Do not duplicate automated junk rules; handle externally moved items correctly |
| Better small UI mode [M4] | Changes small-mode scaling from 50% to 75%, with minimap adjustment | Treat global scale as an input, not a constant |
| Clean Menu and HUD Tweaks [M5] | Removes animated menu circles/glyphs; optional HUD changes | A visual cleanup, not evidence of item search or sort controls |
| 4K UI [M6] | Higher-resolution UI elements | Preserve native assets where possible; test layout/texture compatibility |
| Spyglass — In Game Stats Interface [M7] | Aggregated stats and hover-based item comparison in inventory, shops and loot | Keep native comparison; do not build another effect-aggregation system for v1 |
| AutoLoot [M8] | Automatic loot pickup, excluding theft according to its description | Inventory contents can change without a manual pickup action |
| Salvage mod [M9] | Changes salvage behavior | Stash, vendors and crafting/salvage screens need separate action audits |

Spyglass is especially relevant: its author describes an overlay window and
requires windowed/borderless mode. It demonstrates a possible separate-overlay
approach, not that arbitrary native inventory widgets can already be created.
Its default F9 shortcut should remain available. Its comparison calculations
also explicitly have coverage limits; we should not promise universally correct
"best item" scores.

## Design reference

[SkyUI's feature description][D1] provides a useful precedent: readable item lists,
search, sortable columns, category-specific data and retained equipment state.
Borrow those interaction principles, using Amalur's own visual style and assets.
SkyUI is an older mod, not an Amalur-compatible component or a technical SDK for
this project. A modern-feeling inventory does not require reproducing a tile
backpack or adding drag-and-drop item placement.

Useful principles are direct category access, one clear search scope, visible
sort direction, persistent selection while browsing, non-color status labels
and an explicit Clear Filters action. Comprehensive comparison and automated
cleanup can remain with existing mods.

## Technical evidence and uncertainty

The framework source supports script triggers after original modules load,
loading original Lua adapters, native DLL loading and signature-based memory
patches [T1]. The existing Quest Hider adapter demonstrates our own use of
journal wrapping and standard WINDOW functions [T2]. These are useful patterns;
they do not establish the inventory module's data structures or event contracts.

Static inspection of the user-supplied executable was read-only. Its SHA-256 is:

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

No game code was executed. No game scripts, full disassembly or executable are
included in this repository.

| Capability | Evidence observed | Confidence / remaining work |
| --- | --- | --- |
| Inventory enumeration | Registration entries named `get_all_inventory_of_type` and `sort_by_cost_then_name` | Registration found; namespace, arguments, return values and side effects must be checked in actual inventory call sites |
| Item pocket/status | Registration named `get_item_pocket`; strings for `is_equipped`, `get_pocket_contents`, `inventory_pocket_types` | Promising; pocket enums and item-instance handles are not yet mapped |
| Item metadata | Registration names include `get_inventory_description`, `get_item_level`, `is_quest_item`; names for cost, requirements and set membership also exist | Do not equate generated item level with required level, or base cost with merchant sale price |
| Search text input | Names include `on_editbox_event`, `get_editbox_text`, `set_editbox_text_limit`, `populate_edit_box` | Static names only; widget creation, Unicode handling and input focus remain unverified |
| Tables and navigation | Names include `add_table_data`, `set_table_sort_major`, `reverse_table_sort`, `set_tabnavwin_selected_index`, `get_active_nav_tab_id_string` | Static names only; cannot assume these work on the inventory's existing list |
| UI construction | Existing journal calls `WINDOW.create_window` with a UIXML template | Reusing a template is demonstrated; registering new original templates is not yet proven |
| Rarity and stable identity | Auto Junk advertises rarity-based rules; native item/pocket interfaces exist | Exact rarity access and an instance ID stable across saves, stacks and characters are unverified |

Names alone are **not a callable API contract**. No new native address or guessed
function signature should be invoked to discover its parameters. Inspect the
original module's uses first, then validate a small read-only snapshot in-game.
At the time of this research, inventory module names and framework trigger
strings had not been confirmed. The subsequent [technical spike](spike.md)
identifies observed names from the earlier user-provided runtime log.

A UI change must preserve an item's native handle and original context through
filtering and sorting. A displayed row number cannot be used as the inventory
index when equipping, using or junking items. This is the main correctness risk.

## Research outcome

Proceed to the specification with a native-UI-first approach. The first
implementation milestone should prove row identity/action routing and native
text input before a larger layout is attempted. Search and an All view are target
features, not claims of completed feasibility. Favorites, locks, bulk operations
and stash/shop integration require additional evidence and are later work.

## Sources

All sources below were checked on 16 October 2026. Individual Nexus descriptions
and Steam threads were accessible unless explicitly marked otherwise.

- **S1** — [Amalur Wiki: Inventory](https://amalur.fandom.com/wiki/Inventory).
  Search-index excerpt only; direct page returned 402. Lists the six categories;
  original-game documentation.
- **S2** — [Amalur Wiki: Junk](https://amalur.fandom.com/wiki/Junk).
  Search-index excerpt only; describes native junk marking/destruction.
- **S3** — [Steam: “Sort” button in stash?](https://steamcommunity.com/app/1041720/discussions/0/4328514571300357560/), 18 October 2021.
- **S4** — [Steam: Stuck items in inventory — Devs please let us stash or junk them](https://steamcommunity.com/app/1041720/discussions/0/3041607712746478026/), 8 September 2021.
- **S5** — [Steam: Game UI and Interface](https://steamcommunity.com/app/1041720/discussions/0/2950376208546546362/), 7 September 2020.
- **S6** — [Steam: UI discussion search](https://steamcommunity.com/app/1041720/discussions/search/?q=UI).
  Read the visible excerpts, including [1440p UI](https://steamcommunity.com/app/1041720/discussions/0/2950376844046607461/)
  and [borderless ultrawide clipping](https://steamcommunity.com/app/1041720/discussions/0/3472855915025773587/).
- **S7** — [Steam: Inventory Mod](https://steamcommunity.com/app/1041720/discussions/0/2958292387831633363/), September 2021;
  [inventory discussion search](https://steamcommunity.com/app/1041720/discussions/search/?q=inventory).
- **C1** — [Nexus catalogue, offset 0](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/topalltime/).
- **C2** — [Nexus catalogue, offset 30](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/topalltime/?offset=30).
- **C3** — [Nexus catalogue, offset 60](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/topalltime/?offset=60).
- **M1** — [Deep Pockets](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/77).
- **M2** — [New Characters — Inventory Set to 1500](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/35).
  Catalogue description reviewed.
- **M3** — [Auto Junk](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/86).
- **M4** — [Better small UI mode](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/27).
- **M5** — [Clean Menu and HUD Tweaks](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/20).
- **M6** — [4K UI](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/61).
- **M7** — [Spyglass — In Game Stats Interface](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/84).
- **M8** — [AutoLoot](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/85).
- **M9** — [Salvage mod](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/10).
  Catalogue description reviewed; individual page also retrieved.
- **D1** — [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604),
  “General Features” / “Inventory Menu.”
- **T1** — [Framework source, pinned revision](https://github.com/DevCortez/KoaModFramework/blob/66bd89343fa516d5dfec0f7bed3961edc15ab33f/re_mod/dllmain.cpp).
- **T2** — [Quest Hider adapter](../../../quest-hider/mods/QuestHider/bootstrap.lua).

[D1]: https://www.nexusmods.com/skyrimspecialedition/mods/12604

[S1]: https://amalur.fandom.com/wiki/Inventory
[S2]: https://amalur.fandom.com/wiki/Junk
[S3]: https://steamcommunity.com/app/1041720/discussions/0/4328514571300357560/
[S4]: https://steamcommunity.com/app/1041720/discussions/0/3041607712746478026/
[S5]: https://steamcommunity.com/app/1041720/discussions/0/2950376208546546362/
[S6]: https://steamcommunity.com/app/1041720/discussions/search/?q=UI
[S7]: https://steamcommunity.com/app/1041720/discussions/0/2958292387831633363/
[C1]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/topalltime/
[C2]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/topalltime/?offset=30
[C3]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/topalltime/?offset=60
[M1]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/77
[M2]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/35
[M3]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/86
[M4]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/27
[M5]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/20
[M6]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/61
[M7]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/84
[M8]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/85
[M9]: https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/10
[T1]: https://github.com/DevCortez/KoaModFramework/blob/66bd89343fa516d5dfec0f7bed3961edc15ab33f/re_mod/dllmain.cpp
[T2]: ../../mods/QuestHider/bootstrap.lua
