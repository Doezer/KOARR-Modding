# Research record

Research performed 14 October 2026 (Europe/Paris). Facts below describe inspected
sources, not successful game execution. Full third-party sources/binaries are not
included in this repository.

## Source ledger

| Source | Observed evidence | Limits |
| --- | --- | --- |
| [Mod Framework](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9) | Description: v1.2 custom Lua; v1.4 console Lua and print to stdout. Install beside `koa.exe`; mods in `mods`; sample in download; original-game mods incompatible. | Header version is `1`, description has v1.4 notes. Files URLs returned HTTP 403. Download/sample not inspected. |
| [Framework C++ source](https://github.com/DevCortez/KoaModFramework/blob/66bd89343fa516d5dfec0f7bed3961edc15ab33f/re_mod/dllmain.cpp) | Actual loader, script hook, print wrapper and console implementation inspected. | Public HEAD is from October 2020; no GitHub release assets found. Cannot equate source HEAD with a particular Nexus DLL or current game build. |
| [KOA Reforged](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/89) | Description lists v1.3.5, updated October 2026; Lua modules, native-style custom screens, HUD resistance text, input-driven menus, classic-menu fallback. Module ZIPs merge into `mods`; example path `mods/ItemScaling/item_scaling.lua` via `mods/item_scaling.json`. | Source/download file access unavailable (HTTP 403). No actual UI methods, subscriptions or teardown code confirmed. No assets/code reused. Modification and asset use require permission. |
| [F2 Console](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/14) | Description confirms cheat-menu listener replacement on F2/dpad down, running `mods/console.lua`, arbitrary valid Lua and a command window. | Does not document quest/map methods or establish safe call signatures. Its files/article were not available. |
| [Modding Utility Toolbox](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/15) | Official unpacker/builder workflow for `initial_0.pak`, `data_0.pak`, `patch_0.pak`; asset-name/ID tables and texture conversion. | No game archives here. Texture conversion does not prove a world-map UI editor or Lua decompiler exists. |
| [Kender2 reverse-engineering research](https://github.com/Kender2/amalur/tree/314e878609f42e9f53cb407c5dab72564ad5fdeb) | `korevm.md` describes Lua 5.1-derived Havok Script/Kore VM with expanded opcodes and 4-byte numbers. `functions.txt` contains quest and map symbols listed below. | Explicitly original Reckoning research; not Re-Reckoning API documentation. No namespaces/signatures/ownership provided. Its addresses are NOT used. |
| [Amalur resource collection](https://github.com/thunderer/Amalur) | Links to Kender2 research and asset/save tools; quest list. | Quest names and save editors do not expose runtime objective locations. |
| [Vortex extension research](https://github.com/Doezer/Vortex-extension-for-Kingdoms-of-Amalur/blob/main/docs/research.md) | Led to public framework source; records manifest paths and loader behavior. | Secondary evidence only; framework source inspected independently. Extension fixtures are not working game samples. |
| [AmalurBxmlConverter](https://github.com/ZucchiniZap/AmalurBxmlConverter) | Repository page reachable; potential tooling lead for binary XML. | Not built or executed; compatibility with world-map assets not established. |

GitHub repository searches for `KoaModFramework`, `amalur lua`, `KOA Reforged`,
`amalur quest mod`, and framework variants found the framework source above but
no inspectable Reforged source, newer compatible implementation, or relevant
all-quest-marker implementation. This is not proof none exists. GitHub search API
returned HTTP 502; HTML repository search worked. No authentication or download
restriction was bypassed.

## Confirmed framework contract

In the pinned `re_mod/dllmain.cpp`:

- Lines 332–358: `LoadMod` parses `scripts` as an array; each entry has string
  `trigger` and `path`. It groups paths by exact trigger string. There is no
  evidence for invented fields such as `on_map_open`, `init`, or `unload`.
- Lines 233–260: after a required game script loads, the hook registers the print
  replacement, then loads/executes custom scripts matching that module's name.
  No wildcard trigger is established. Hook recursion is suppressed while running
  custom scripts. Script execution is not a documented recurring update callback.
- Lines 177–195: print replacement writes string arguments to stdout. Our logging
  passes exactly one string.
- Lines 534–539: directory enumeration is directly over `mods`, without recursive
  discovery. An autoload JSON would belong directly under `mods`.
- Lines 542–569: console uses `std::cin >> user_input`, writes `_temp.lua`, and
  loads/runs it in the tracked state while suspending/resuming game threads. Use
  commands without whitespace. Lua errors/native failures are not guaranteed to
  be caught safely by its C++ exception handling.

This verifies the loader schema from implementation, but no working quest/map
trigger sample was obtained. The package deliberately does not invent one.

The framework's inspected Lua registration adds `print`, not a dedicated quest/map
API. Existing engine modules may be reachable in the game's Lua state, but the
framework source does not tell us their namespaces, arguments or object lifetimes.
There is no generic listener-unregistration service confirmed in that source.

## Quest and map leads, with strict confidence limits

The legacy function list includes:

- Quest state/enumeration: `get_num_active_quests`, `get_active_id`,
  `get_num_completed_quests`, `is_quest_active`, `is_quest_completed`,
  `get_is_failed`, `get_current_quest`, `get_quest_type`.
- Objectives: `get_stage`, `get_num_stage_subtasks`,
  `get_is_stage_subtask_complete`, `get_target_indexes`, `get_target_types`.
- Map: `add_object_icon`, `add_gor_icon`, `set_object_icon_visible`,
  `set_gor_icon_visible`, `set_object_world_location`, `world_to_window_coords`,
  `window_to_world_coords`, `register_map_window`, `set_map_window_region`.

Names show that the original engine had quest, target and native map concepts.
They do NOT tell us calling conventions, which table owns a method, index bases,
return shapes, whether targets include all quests, or visibility/reveal rules.
Repeated names such as `get_version` indicate that treating this flat symbol list
as a global API would be especially unjustified. The probe looks for names/types;
it never executes these candidates. No memory addresses are copied into the mod.

## Feasibility, investigated in required order

### A — Native marker visibility (preferred; not yet verified)

Determine from extracted map scripts whether an all-quest destination collection
is already populated and filtered by current quest. If so, a scoped Lua hook to
that filter could preserve native projection, style, tooltips, and interaction.
No such collection/filter has been located. We cannot claim removing a visibility
restriction works. Never cycle `set_current_quest`: that changes tracking state
and could trigger progression/UI side effects, contrary to the requirements.

### B — Custom UI markers (conditional fallback)

Legacy map APIs and Reforged's menu/HUD descriptions make this worth inspecting,
but they do not establish usable Re-Reckoning APIs. The implemented pure Lua core
accepts explicitly revealed, normalized destinations and delegates projection and
rendering to a host adapter. It tests synchronization without guessing game
functions. It is not yet an implemented game integration or selected final route.
Native projection should be preferred to reconstructing map transforms. If only
a UI overlay is possible, verify region transforms, viewport origin, clipping,
zoom, scrolling, scale and input hit-testing first.

### C — Native extension (deferred for lack of necessary evidence)

Framework DLL loading exists, but a native quest/map extension is unjustified
until A/B are ruled out. No target executable, symbols, version fingerprints,
owned-marker lifetimes or reliable hook signatures are available. No C++ patch,
injection binary, memory address or instruction patch is included. A future
extension must match known builds and refuse unsupported versions; validate
thread affinity, restoration, cleanup and crash behavior against the actual game.

## Current technical conclusion

The existence of an internal all-active-objective location list versus a
tracked-only target generator remains unresolved. The correct next experiment is
read-only symbol discovery plus local inspection of the journal/map game scripts,
then a single additional native marker under controlled in-game validation. Only
then implement the game adapter or a narrower native-filter hook. See
`debugging.md` for concrete evidence collection and `architecture.md` for gates.

## User-supplied GOG/v1.4 runtime evidence

The original broad probe ran three times and reached its 500-symbol limit each
time. A subsequent targeted scan completed with `symbols=237 inspected=396
truncated=false`. The reported VM version is `2.5 r7786`. This validates manual
probe loading and raw table inspection on that user session, not marker behavior.

Observed tables and functions include `QUEST.get_num_active_quests`,
`QUEST.get_active_id`, `QUEST.get_target_indexes`, `QUEST.get_target_types`,
`MAP.add_object_icon`, `MAP.add_gor_icon`, `MAP.world_to_window_coords`,
`map_manager.add_object_specific`, and `map_data.lookup_location_data`.
`quests_win.m_quest_data` contains `quests` and `quests_rev` tables. Neither their
contents nor call signatures were printed. Do not infer parameters or meaning
from names alone. Quest-related fields can have the engine-specific `ui64` type;
converting IDs to Lua floating-point numbers could lose precision and is not a
valid normalization strategy.

Framework logs show modules `map_manager`, `map_data`, `quests_win`, and
`minimap_win` loading, but this does not establish recurring map-open callbacks.
No raw user logs or proprietary script implementations are redistributed.
The follow-up passive tracer observes naturally occurring calls and returns,
without executing exploratory native calls or wrapping tracking setters.

## First passive trace result and correction

The supplied `passive-v1` trace installed 30 hooks and stopped with `conflicts=0`.
Of 150 captured calls, 149 were `QUEST.get_stage(ui64) -> number`; the remaining
call was `QUEST.get_target_indexes() -> table`, containing one `ui64` value at
index 1. This verifies those observed call shapes but does not establish that
all active quest destinations are available. Neither map signatures nor active
quest enumeration were captured.

The global 300-record limit filled with background quest-stage polling, leaving
no budget for the later map interaction. `passive-v2` gives every function four
calls of its own, with the global cap retained. A regression test simulates
100,000 quest calls before a map call and verifies that map arguments/results
are still logged. This is a logger correction, not evidence of marker behavior.
