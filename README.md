# All Quest Markers

Show objective markers for untracked quests alongside your tracked quest on the
world map in **Kingdoms of Amalur: Re-Reckoning**. This includes distant objectives
that the original game only shows while their quest is tracked.

**Version 1.0.0.** The combined three-patch mod has been confirmed working in-game
by its tester on the GOG PC edition with Mod Framework v1.4. Other stores, game
builds, DLC combinations and every quest/visibility case have not been verified.

## Download

- [Download AllQuestMarkers-1.0.0.zip](https://github.com/Doezer/KOARR-World-map-enhanced/releases/download/v1.0.0/AllQuestMarkers-1.0.0.zip)
- [Latest release and checksum](https://github.com/Doezer/KOARR-World-map-enhanced/releases/latest)

Use the release ZIP for installation. The repository also retains historical Lua
research helpers; they are not required or included in the release ZIP.

## Requirements

- Kingdoms of Amalur: Re-Reckoning, PC. Tested on the supplied GOG executable.
- [Mod Framework v1.4 by DevCortez](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9),
  installed according to its author's instructions.

The framework is a separate download. This mod does not include framework DLLs.
The original 2012 Kingdoms of Amalur: Reckoning and console editions are unsupported.

## Installation

1. Close the game and install Mod Framework v1.4 if needed.
2. Extract the release ZIP into the game folder containing `koa.exe`. Merge the
   `mods` folder with your existing one.
3. Confirm the file is at `mods/all_quest_markers_native.json` beside `koa.exe`.
4. Start the game, load your save and open the world map. It loads automatically;
   no console command or F2 Console mod is required.

After extraction, the relevant layout is:

```text
Kingdoms of Amalur Re-Reckoning/
├── koa.exe
└── mods/
    └── all_quest_markers_native.json
```

If you used the earlier two-file test version, remove
`mods/all_quest_markers_world_scope.json`: its patch is already included here.
Remove an old `mods/all_quest_markers_probe.json` if present; it belongs to the
retired diagnostic releases. Other mods and framework files can stay installed.

## Features and scope

- Displays native objective markers for untracked quests on the world map.
- Allows distant untracked objectives through the extra world-map renderer check.
- Covers both initial map population and subsequent target updates.
- Uses the game's own marker data and inactive-objective icon path.
- Keeps your selected quest as the tracked quest; the mod does not cycle tracking.

The mod contains three native memory patches in one JSON manifest. It does not
write to `koa.exe` on disk or edit saves. It does not invent destinations the
engine cannot resolve. The local map and minimap retain their original behavior.
There are no settings or larger-region filtering variants in this release.

## Compatibility and limitations

Tested executable SHA-256:

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

Steam, Epic, other executable builds and other framework versions are unverified.
The JSON uses instruction signatures, not a whole-file hash check. A game update
or another mod changing the same native code may prevent it from loading or cause
a conflict. The framework applies the patches separately; if any signature fails,
remove this mod and restart rather than using a partially applied set.

In-game success was reported for the tester's setup. Quest completion, all
interiors, all DLC, undiscovered areas and every interaction/save-load case have
not been exhaustively checked. Earlier native visibility checks remain in place,
but complete preservation of reveal rules is not claimed. Report specific cases
with the game build and mod list if markers are missing or unexpected.

## Uninstall

Close the game, delete `mods/all_quest_markers_native.json`, then restart.
Do not delete the shared `mods` folder or Mod Framework files used by other mods.

## Troubleshooting

If markers do not appear, first check that the JSON is directly inside `mods`,
not inside an extra archive folder or named `.json.txt`. Restart after installing
or changing it. Check the framework startup log for
`Reading mod ...all_quest_markers_native.json` and the following signature/address
messages. All three patches must load.

When reporting a problem, include the game store/build, framework version, other
native patches, the affected quest/region, and those startup log lines.
Do not upload the game executable or private game script exports publicly.

## Development

The release source is `mods/all_quest_markers_native.json`. Build and check its
package with Python 3 (no extra Python packages):

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/package.py
```

To check signatures against your own legally installed executable, without
modifying it:

```sh
python3 tools/verify_executable.py /path/to/koa.exe
```

The verifier accepts only the exact analyzed SHA-256. Passing it checks the file
and signatures; it does not establish every aspect of in-game compatibility.

Historical Lua prototype tests can also run with `./tools/setup_lua.sh` followed by
`./tools/check.sh`. They test the earlier core/helpers and do not validate the
native mod in the game. See [native patch details](docs/native-patches.md) and
[historical research](docs/runtime-findings.md).

## Credits and license

Mod Framework by [DevCortez](https://github.com/DevCortez/KoaModFramework).
Thanks to the in-game tester who supplied diagnostic results and confirmed the
combined patch works. This project's original code and documentation use the
[MIT license](LICENSE). Game files and third-party framework binaries are not
included.
