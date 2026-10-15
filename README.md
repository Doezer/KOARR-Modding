# AllQuestMarkers

Confirmed validation target: **GOG PC edition with Mod Framework v1.4** (user-provided).
The exact game executable build/file version and DLC set have not been supplied.
Compatibility and in-game behavior remain untested.

**Status: partially implemented; game integration blocked. This is a runnable
read-only probe and tested Lua core, not a working all-quest map mod. It currently
adds no markers. No in-game functionality has been validated.**

The intended mod displays legitimately revealed destinations for all active,
incomplete quest objectives while preserving native tracked-quest and fast-travel
markers. The PC Re-Reckoning quest/map binding, module triggers, method signatures,
and UI lifetime rules still need runtime evidence. We do not guess them.

## Download and install the probe

Use `dist/AllQuestMarkers-probe-0.1.4.zip`. Its `mods/AllQuestMarkers/` directory
contains only this project's Lua source; no game assets or framework DLLs.

1. Obtain [Mod Framework v1.4](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9)
   from its author and install it beside `koa.exe` using the author's instructions.
   Compatibility with your current game build must be checked separately. This
   repository does not install or update the framework.
2. With the game closed, extract this ZIP into the folder containing `koa.exe`.
   Do not overwrite an existing `mods/AllQuestMarkers` installation without backing
   up your settings. The default package contains **no autoload manifest** because
   no usable quest/map script trigger has been verified.
3. Start the game, load a save, and use the Mod Framework's own console. Enter this
   single line (no spaces; its source reads a whitespace-delimited command):

   ```lua
   assert(loadfile('mods/AllQuestMarkers/probe.lua'))()
   ```

   It logs matching Lua symbol paths/types to the framework console. `loadfile` and
   the standard Lua libraries must be exposed in that VM; if unavailable, stop and
   capture the exact error. The script is syntactically tested under stock Lua 5.1,
   but loading it in Havok Script remains untested.
4. Repeat with the map open, after closing it, and after a region/save change.
   Follow [debugging](docs/debugging.md). Do not call discovered engine functions
   merely because their names resemble getters.

The [F2 Console](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/14)
is optional. Its page confirms arbitrary Lua execution from `mods/console.lua`,
but the default framework console is sufficient for this probe if `loadfile` is
exposed. This package does not replace the F2 Console's files or listeners.

## Disable or uninstall

The default probe installs no hooks, listeners, persistent globals, or map objects.
Exit the game and remove only `mods/AllQuestMarkers/`. If you generated an optional
probe autoload manifest, also remove `mods/all_quest_markers_probe.json`. Do not
remove other mods or shared framework files. No save edits or packed-asset patches
are made.

If experimenting with an externally supplied adapter, call the returned module's
`detach()` and confirm it returns true before hot reload. Cleanup failures remain
retryable; exit the game before removing files. There is no verified game adapter
in this release.

## Develop and test

From this checkout on Linux, with GCC, make, curl and Python 3 available:

```sh
./tools/setup_lua.sh
./tools/check.sh
python3 tools/package.py
```

Setup downloads official Lua 5.1.5 with TLS verification and the SHA-256 published
on lua.org, then builds it in `/workspace/.aqm-tools`. It does not install system
packages. Set `AQM_TOOLS_DIR` before setup and checks to choose another cache.
Tests use simulated normalized quest data and a simulated renderer, never the game.
Stock Lua 5.1 tests do not establish Havok Script compatibility.

To generate a probe-only autoload manifest **after** observing an exact game-module
trigger in a working Re-Reckoning example/log:

```sh
python3 tools/package.py --probe-trigger 'EXACT_OBSERVED_TRIGGER' --output /tmp/aqm-triggered
```

Replace the placeholder with evidence; it is not a valid trigger supplied by this
project. This uses the verified framework JSON shape but does not establish runtime
compatibility. The manifest loads only the probe. A full mod manifest must wait for
verified quest/map lifecycle integration.

## Documentation

- [Research and source evidence](docs/research.md)
- [Architecture and host adapter contract](docs/architecture.md)
- [Configuration](docs/configuration.md)
- [Debugging and evidence collection](docs/debugging.md)
- [Validation checklist and known limitations](docs/validation.md)

## What is needed to complete the mod

Provide the working framework sample's JSON/Lua files and read-only probe logs
from the target PC build. Locally extracted quest-journal and world-map Lua/UI
scripts would allow checking signatures, visibility rules, and marker filtering.
Keep proprietary scripts private; they are for local inspection, not redistribution.
Actual game execution is required to prove marker placement, interaction, and save
safety. See the evidence gates in the architecture document.

## Follow-up after the targeted scan

The supplied GOG/v1.4 logs confirm manual probe execution and expose `QUEST`,
`MAP`, `map_manager`, `map_data`, and `quests_win`. The targeted scan completed
with 237 symbols and no truncation; native calling signatures remain unknown.
The VM reports `2.5 r7786`, so stock Lua tests are not engine-version proof.

The optional `trace.lua` records existing game-initiated calls through temporary
Lua wrappers. It does not create markers or call guessed engine functions. It is
not automatically loaded by bootstrap or the probe. See [trace instructions](docs/tracing.md).

## Local script inspection

The optional `inspect.lua` helper serializes already-loaded map/journal Lua
functions to a numbered `AllQuestMarkers-inspection-NNN.txt` in the game working
directory when file writing is available. With io.open unavailable (as confirmed
on the user's GOG VM), it prints the same report to the console instead.
It does not install hooks, call the exported functions, or dump saves.
This is proprietary game bytecode for private analysis; do not publish the output.
The package contains only our exporter, never its game-generated outputs.
See [inspection instructions](docs/inspection.md).
