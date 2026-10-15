# All Quest Markers

Display objective markers for untracked quests alongside your tracked quest on
the world map in **Kingdoms of Amalur: Re-Reckoning**. See where your other quests
lead without repeatedly switching your tracked quest, including distant objectives.

**Current release: 1.0.1.** The combined mod has been confirmed working in-game on
the **GOG PC edition with Mod Framework v1.4**. Version 1.0.1 updates the release
documentation; its three native patches are unchanged from 1.0.0.

## Download

- **[Download AllQuestMarkers-1.0.1.zip](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/v1.0.1/dist/AllQuestMarkers-1.0.1.zip)**
- [SHA-256 checksum](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/v1.0.1/dist/AllQuestMarkers-1.0.1.zip.sha256)
- [Release page](https://github.com/Doezer/KOARR-World-map-enhanced/releases/latest)

Download the mod ZIP linked above. GitHub's automatically generated **Source code**
archives contain development files and are not the installation package.

## Features

- Shows native objective markers for untracked quests on the world map.
- Includes distant objectives that normally appear only when their quest is tracked.
- Handles both opening the map and later target updates.
- Keeps your selected quest as the tracked quest.
- Loads automatically; no F2 command or configuration is required.

The mod uses the game's existing marker data. The local map and minimap retain
their original behavior. It does not add destinations the engine cannot resolve
and does not include a larger-region filter.

## Requirements

- **Kingdoms of Amalur: Re-Reckoning** on PC.
- **[Mod Framework v1.4 by DevCortez](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9)**,
  installed separately using its author's instructions.

The original 2012 Reckoning and console editions are unsupported. Steam, Epic,
other executable builds and other framework versions have not been verified.

## Installation

1. Close the game and install Mod Framework v1.4 if needed.
2. Extract the mod ZIP into the game folder containing `koa.exe`. Merge its `mods`
   folder with your existing one.
3. Check that the file is installed at `mods/all_quest_markers_native.json`.
4. Start the game, load your save and open the world map. There is
   no console command to enter.

```text
Kingdoms of Amalur Re-Reckoning/
├── koa.exe
└── mods/
    └── all_quest_markers_native.json
```

**Upgrading from the test version:** remove
`mods/all_quest_markers_world_scope.json` if present; its patch is already included
in the combined file. Remove an old `mods/all_quest_markers_probe.json` too.
Diagnostic Lua helpers are not required by this release.

## Compatibility

Confirmed working on the supplied GOG executable with SHA-256:

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

All DLC combinations, quests, interiors, undiscovered areas and save/load cases
have not been exhaustively tested. Earlier visibility checks remain in place,
but complete preservation of reveal rules is not claimed.

The mod applies three patches to game memory. It does not modify `koa.exe` on disk
or edit save files. Game updates or other mods changing the same code may cause
conflicts. The framework checks instruction signatures rather than the whole-file
hash; if any of the three signatures fails, remove this mod and restart.

## Uninstall

Close the game, delete `mods/all_quest_markers_native.json`, then restart.
Keep the shared `mods` folder and framework files needed by other mods.

## Troubleshooting

Check that the JSON is directly inside `mods`, not inside another nested folder
or named `.json.txt`. Restart after installing or changing it.

Check the framework startup log for
`Reading mod ...all_quest_markers_native.json` and three successful patch address
messages. For bug reports, include your game store/build, framework version,
other mods, affected quest/region and those log lines.

## Source and documentation

- [Mod JSON](mods/all_quest_markers_native.json)
- [Changelog](CHANGELOG.md)
- [Development and verification](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/development.md)
- [Native patch details](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/native-patches.md)
- [Nexus Mods description (BBCode)](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/nexus-description.txt)

Historical Lua research remains in the repository for reference and is excluded
from the release ZIP. Game files and framework binaries are not bundled.

## Credits and license

Mod Framework by [DevCortez](https://github.com/DevCortez/KoaModFramework).
Thanks to the in-game tester for diagnostic reports and validation.
Original project code and documentation are [MIT licensed](LICENSE).
