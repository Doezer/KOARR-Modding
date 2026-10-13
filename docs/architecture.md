# Architecture and evidence gates

## Implemented components

All source is Lua 5.1 syntax. Modules return tables, avoiding `require` cache and
package-path changes in the game. `bootstrap.lua` loads files relative to the game
working directory. No adapter is shipped; calling bootstrap only runs the probe
and exposes project functions. Returned functions do not install anything until
an adapter is explicitly attached.

| File | Responsibility |
| --- | --- |
| `probe.lua` | Bounded raw table inspection, names/types only, no unknown API calls |
| `objectives.lua` | Strict state/reveal/coordinate filtering, collision-resistant keys, deterministic deduplication |
| `coordinates.lua` | Project each destination through the supplied host transform on every relevant refresh |
| `markers.lua` | Retain and remove only overlay handles created by the supplied renderer |
| `controller.lua` | Event lifecycle, snapshot refresh, session/region invalidation, retryable teardown |
| `config.lua`, `log.lua` | Local preferences and single-string logging |
| `bootstrap.lua` | Load modules; explicitly attach/detach an external verified adapter |

No game quest setters, save serialization, fast travel, native icon deletion,
global engine replacements, or polling loops are implemented. This describes the
source, not a claim of save safety under an untested third-party adapter.

## Host adapter interface — project-defined, not an Amalur API

These names are dependency-injection contracts implemented by tests. They must
not be called on game objects without a real verified mapping. Host methods are
plain functions; they receive no implicit `self` argument.

```lua
adapter.snapshot()                 -- fresh complete normalized snapshot below
adapter.map_state()                -- { open = boolean, ... opaque view state ... }
adapter.project(marker, view)      -- { x = screen_x, y = screen_y }, or nil if culled
adapter.renderer.create(marker)   -- new exclusively owned handle; nil/false fails
adapter.renderer.remove(handle)   -- true only when that owned marker is gone
adapter.subscribe(event, callback) -- unsubscribe closure returning true on success
```

Supported project events: `map_open`, `map_close`, `map_view_changed`,
`quests_changed`, `save_loaded`, `region_changed`. None is claimed to be an
existing framework event. A future host must connect real verified game hooks and
unregister or restore them exactly. `map_view_changed` must cover zoom, scrolling,
window resize, map scale and coordinate-origin changes. UI mutations must run on
the correct game/UI thread; the generic controller supplies no thread dispatch.

`map_state()` must return `open=false` outside the world map. `snapshot()` must be
complete and internally consistent, not a partial page of the journal. Example
**synthetic data**, not a game return value:

```lua
{
  session = "save-generation-2", region = "region-id",
  quests = {
    { id = "quest-id", name = "Quest title", state = "active", category = "side",
      tracked = false,
      objectives = {
        { id = "objective-id", complete = false, valid = true, locations = {
          { id = "destination-id", region = "region-id", x = 120, y = 230,
            known = true, revealed = true, valid = true, native_visible = false }
        } }
      }
    }
  }
}
```

`x/y` are normalized map-plane coordinates chosen by the host, not assumed game
world axes. Region and session IDs must be stable strings or finite integer IDs.
Each save load needs a new session generation even when loading the same save.
Map-view recreation must invalidate the generation or close the old map first.
Unknown objective/reveal validity is skipped; this is deliberately conservative.
`revealed` means the **game's actual permission to show this destination**, not
merely a flag indicating the area was visited. Discovering raw coordinates is
never permission to reveal them. `native_visible` must reflect actual native
markers: true prevents duplicates while leaving vanilla handles untouched.

Arrays must be dense. Duplicate `(quest, objective, location, region)` keys are
coalesced only at identical coordinates; conflicting duplicates reject the
snapshot. Distinct objectives at the same coordinates remain distinct. `nil`
projection culls an offscreen destination; region coordinates are not mixed.
Renderer marker records include quest/objective/location IDs, category, tracked
status, world-plane and screen positions. Styling/tooltips are host capabilities,
not implemented game features here. Render overlays without taking input focus
or intercepting fast-travel clicks.

## Ownership and failure behavior

Refreshes are event-driven. Marker changes remove/recreate only owned handles;
unchanged state makes no renderer calls. Every refresh reprojects through the
current view. Session/region changes clear old handles first. Read/projection
errors attempt to clear overlays; incomplete subscriptions unwind earlier ones.
A renderer remove/unsubscribe failure is logged, retains cleanup ownership and
can be retried. While stopping, callbacks are inert and restarting is refused
until cleanup succeeds. A host that cannot delete an icon can leave it visible:
this is reported as failure, never hidden as a successful cleanup.

Host callbacks must be atomic: a throwing `create` must not leave an allocated
unreturned object, and a throwing `subscribe` must not leave an unreturned
listener. Remove/unsubscribe must report true when already gone, making retries
idempotent. Lua `pcall` cannot make invalid native calls or stale userdata safe.
The engine adapter must establish validity before calling any C++ bindings.

Reentrant refreshes coalesce into at most one extra pass. Further changes wait
for the next real event; adapters should defer noisy nested notifications until
after their transaction. No per-frame polling is assumed or installed.

## Required gates before claiming a functional mod

1. **Loader**: target game/store/build and framework version recorded; observed
   working JSON trigger, path, initialization context and repeat-loading behavior.
2. **Quest access**: verified owner table, signatures, index base, all active quests,
   multiple current objectives, target IDs and completed/failed behavior. Compare
   with the journal while keeping tracked quest unchanged.
3. **Visibility**: trace the game's destination permission and selected-quest
   filtering separately. Prove hidden information stays hidden. Prefer A if a
   narrow existing visibility filter can safely be extended.
4. **One-marker proof**: display an additional legitimate destination with a
   verified native/UI operation; preserve the native tracked marker and fast
   travel. Confirm creation/removal and map-window lifetime in-game.
5. **Full integration**: implement the adapter (or replace the generic overlay
   route with a verified A hook), documented real lifecycle hooks, and cleanup.
6. **Runtime acceptance**: complete every mandatory item in `validation.md` and
   record failures as well as passes. Only then create an automatic full-mod ZIP.

Gates 1–4 are not passed in this environment. This release is intentionally a probe
plus testable independent work, not a disguised stub game adapter.
