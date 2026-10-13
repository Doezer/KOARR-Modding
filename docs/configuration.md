# Configuration

`mods/AllQuestMarkers/config.lua` returns a Lua table. Back it up before replacing
an installation. It is not a framework manifest and is not written to save data.

| Setting | Default | Behavior in the independent core |
| --- | --- | --- |
| `enabled` | `true` | Whether a verified attached adapter would render overlays; false clears owned markers on refresh |
| `debug` | `false` | Log owned quest/objective/location keys and world/screen coordinates |
| `categories` | all four true | Allow `main`, `faction`, `side`, `task`; unknown categories fail closed |
| `max_markers` | `2000` | Reject an unexpectedly large snapshot, log failure and clear overlays; never silently truncate it |

These settings do not enable in-game markers in this release: there is no game
adapter. The read-only probe runs regardless of `enabled`, and logs symbol names
and types only. It does not log world locations, scalar data, save content or
function results. No configuration setting reveals undiscovered destinations.

To load the core manually from the framework console, after ensuring you are not
overwriting an existing variable with the same name:

```lua
AllQuestMarkers=assert(loadfile('mods/AllQuestMarkers/bootstrap.lua'))()
```

This creates one project namespace and prints the adapter-unverified status. It
still installs no markers/hooks. The returned object provides `attach(adapter)`,
`detach()`, `refresh()`, and `set_enabled(boolean)` for future verified integration.
Do not attach a guessed engine object. Before reloading the core, call
`AllQuestMarkers.detach()` and confirm the result is true. To clear this optional
namespace afterward: `AllQuestMarkers=nil`. Restarting the game also clears it.

Categories, colors and tooltip behavior are not mapped to game IDs or resources.
No guessed category enums, texture IDs or UI constructors are supplied.
