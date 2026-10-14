# Passive call tracer

The targeted GOG/v1.4 scan identified engine functions, but not their calling
signatures. `trace.lua` observes calls the game already makes. It does not initiate
native calls, switch tracked quests, advance objectives, create/remove icons,
reveal fog or modify saves. It does temporarily replace selected Lua table
functions with forwarding wrappers. Unlike the standalone probe, it installs
transient hooks. Havok Script behavior remains untested until a runtime log arrives.

## Run

With the game closed, install `mods/AllQuestMarkers/trace.lua` from the updated
package (or download that single file). Start the game and load a test save.
In the same F2 code field that successfully ran the probe, enter:

```lua
assert(loadfile('mods/AllQuestMarkers/trace.lua'))()
```

Look for `[AllQuestMarkers][trace] READY`. Then open and close the world map and
open and close the quest journal. Return to F2 and enter:

```lua
AQMTrace.stop()
```

Capture the console from `[AllQuestMarkers][trace] BEGIN` through `STOP`. If the
console says `LIMIT reached` before the map was opened, run `AQMTrace.reset()`
before the next map opening (while the tracer is still installed). The limit
bounds log volume, not forwarded calls; original game functions continue to run.
If anything behaves unexpectedly, exit the game; the tracer is not autoloaded and
cannot persist after process exit. Do not overwrite another mod's `AQMTrace`
namespace. Repeated loading refuses to install a second set of wrappers.

## What it records

- The selected functions, an optional `debug.getinfo` source/line description for
  already-known functions if the standard debug library is exposed, then READY.
- CALL/RETURN pairs with a shared sequence ID, argument/return counts, scalar
  values and shallow raw-table fields. Calls already initiated by the game are
  forwarded exactly once. Nil slots and multiple returns are preserved.
- Opaque session-local labels such as `ui64#3` or `userdata#9`; the tracer never
  invokes userdata or custom-type `__tostring`/`__index` methods. IDs are not cast
  to floating-point numbers. Matching opaque labels aid call correlation only.
- At most 300 call/return log records. Tables/strings/argument lists are bounded.

No unknown function is executed to discover its parameters. No quest progression,
tracking setters, fast-travel handlers, or fog functions are wrapped. Map mutators
in the trace are invoked by the game as usual; the tracer only forwards them.
Logging errors are isolated. Original game errors still propagate normally.

## Cleanup and limits

`AQMTrace.stop()` deactivates logging and restores each function only if its
current value is still this tracer's wrapper. If another mod replaced a binding,
it is left intact and a conflict is printed; restart the game for full cleanup.
Any retained tracer wrapper then becomes an inert forwarding function. No other
mod's current binding is overwritten during cleanup.

The tracer cannot intercept native internal calls or aliases cached before
installation. Zero calls for a function does not prove the function is unused.
A stock Lua forwarding test does not establish compatibility with native stack
inspection, yield behavior, function-identity checks or the proprietary VM.
Treat runtime errors as evidence to investigate, not as permission to guess a
native signature. Never publish raw game traces without reviewing their content.
