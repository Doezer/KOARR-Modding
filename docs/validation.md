# Validation and known limitations

Confirmed validation target: **GOG PC edition with Mod Framework v1.4** (user-provided).
The exact game executable build/file version and DLC set have not been supplied.
Compatibility and in-game behavior remain untested.

## Actual automated results

Run from the repository root:

```sh
./tools/check.sh
```

The Lua suite uses stock Lua 5.1.5, the same language generation as the documented
legacy Kore VM, but not the proprietary VM. It tests 27 scenarios including strict
reveal filtering, quest states, multiple destinations, deduplication, finite
coordinates, category filtering, cap failure, idempotent refresh, native-handle
isolation, objective completion/acceptance, pan/zoom projection, save and region
invalidations, close/disable/uninstall, read/projection/renderer failures,
subscription rollback, retryable teardown, reentrancy, and read-only probe bounds.
Python package tests check ZIP paths/content, no DLLs/assets, deterministic builds,
SHA-256, optional manifest schema and actual extracted bootstrap execution.
`luac -p` checks every Lua file, including tests. Automated tests do not contact or
emulate the game's engine, quest system or UI. Counts/results are reported by the
runner and are not game test counts.

## Mandatory in-game acceptance checklist — ALL UNRUN

Use a backed-up test save and record game/framework versions, active mods,
observations, logs and failures. Do not mark items passed from simulated tests.

| Scenario | Acceptance evidence required | Current status |
| --- | --- | --- |
| Multiple active quests | Compare every legitimately revealed destination with journal; all appear together | Unrun |
| Change tracked quest | Vanilla tracked appearance retained; all other eligible markers remain; tracking only changes by player action | Unrun |
| Complete objective | Only completed/invalid destinations removed immediately | Unrun |
| Accept quest | New destinations appear without restarting or changing tracking | Unrun |
| Load save | Old handles dropped; correct objectives rebuilt, including reloading the same save | Unrun |
| Change region/map window | No cross-region leakage or stale window references; correct local destinations | Unrun |
| Pan/zoom/resize | Native-aligned position and clipping at all view scales; no drift | Unrun |
| Multiple objectives/destinations | Every current incomplete destination present; collocated distinct objectives not lost | Unrun |
| Hidden/missing destinations | No fog/reveal bypass; unknown/malformed data safely skipped without crashing | Unrun |
| Disable/uninstall | Only owned overlay/hook state removed; listener count stable over repeated reloads | Unrun |
| Fast travel/native interactions | Fast-travel selection/clicks/controller navigation unchanged; no overlay focus interception | Unrun |
| Save/tracking safety | No adapter calls that set tracking/progression; inspect save semantics and compare reload behavior | Unrun |

## Release blockers

- No Re-Reckoning quest enumeration, target/reveal binding, map-window access,
  projection signature, icon constructor or event teardown has been verified.
- No working quest/map module trigger sample was available. Manifest shape is
  source-confirmed; the default ZIP is manual-load probe only.
- No target Windows executable, local assets, saves or game process is present.
  No extra marker was displayed, and no mandatory in-game behavior is claimed.
- Legacy symbol names/addresses cannot establish remaster compatibility. Source
  is Lua 5.1 syntax, not proven compatible with the actual exposed Havok VM.
- Generic adapter tests cannot prove save safety, reveal semantics, rendering,
  thread affinity, controller behavior, fast-travel compatibility or performance.
- Renderer cleanup failure may leave an icon until the host recovers or the game
  exits; this is reported, retains ownership and blocks restart.

## Optional features

Enable/filter preferences and tracked/category metadata exist in the independent
core. No game keybind, category-enum mapping, different icon colors, hover tooltip,
or settings UI is implemented or validated. Those features wait until the required
marker integration works. No native patch is included.

## Distribution classification

`AllQuestMarkers-probe-0.1.0.zip` is a **probe/core development package**, not an
all-quest-marker release. Its installable layout is `mods/AllQuestMarkers/`, with
manual console loading. It contains no proprietary game assets, third-party DLLs,
Reforged code, copied third-party mod files or generated fake bindings. Publish a
functional release only after completing the evidence gates and runtime checklist.
