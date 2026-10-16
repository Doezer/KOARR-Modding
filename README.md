# Re-Reckoning utility mods

A collection of independently installable mods. Pick the ZIP for the mod you want.

| Mod | Status | Download / details |
| --- | --- | --- |
| All Quest Markers on World Map | Confirmed working · 1.0.1 | [Nexus Mods](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/97) · details below |
| Quest Hider | Experimental · 0.1.0 preview · awaiting in-game test | [Preview ZIP](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-0.1.0-preview.zip) · [controls and installation](docs/quest-hider.md) |
| Inventory Plus | Research and specification · no installer yet | [Proposed features and implementation plan](docs/inventory/spec.md) · [Research](docs/inventory/research.md) |

Quest Hider adds **F6** to hide/restore a journal quest and **F7** to switch to the
hidden list, with persistent preferences and objective map filtering. It has its
own files and does not require All Quest Markers. See its documentation for preview
limits and the first in-game test.

---

![All Quest Markers — On the World Map](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/docs/images/header.png)

# All Quest Markers on World Map

Show objective markers for untracked quests alongside your tracked quest on the
world map. See where your other quests lead without repeatedly switching the
tracked quest, including distant objectives that normally appear only when tracked.

**Confirmed working on GOG with Fatesworn and Mod Framework v1.4.**

## Download

- **[Nexus Mods — install with Vortex or download manually](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/97)**
- [GitHub ZIP — AllQuestMarkers 1.0.1](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/v1.0.1/dist/AllQuestMarkers-1.0.1.zip)
- [SHA-256 checksum](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/v1.0.1/dist/AllQuestMarkers-1.0.1.zip.sha256) · [GitHub release](https://github.com/Doezer/KOARR-World-map-enhanced/releases/latest)

Use the mod ZIP for manual installation. GitHub's automatically generated
**Source code** archives contain development files.

## Features

- Displays native objective markers for untracked quests on the world map,
  beyond the vanilla local-map-only behavior.
- Keeps your selected quest as the tracked quest.

## Screenshot

![World map showing quest objective markers across the Faelands](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/docs/images/world-map-screenshot.webp)

In-game screenshot from [the mod's Nexus Mods page](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/97?tab=images).

## Requirements

[Mod Framework v1.4 by DevCortez](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9).
Install the framework separately using its author's instructions.

Confirmed working on the GOG edition of **Kingdoms of Amalur: Re-Reckoning**
with **Fatesworn** and **Mod Framework v1.4**. Steam, Epic, other executable
builds/framework versions and all DLC combinations have not been verified.

## Automatic installation

Install the mod using **Vortex** from the
[Nexus Mods page](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/97),
then enable and deploy it.

## Manual installation

1. Close the game and install Mod Framework v1.4.
2. Extract the mod's ZIP into the game folder containing `koa.exe`, merging the
   `mods` folder.
3. Check that the installed file is `mods/all_quest_markers_native.json`.
4. Start the game, load your save and open the world map. There is
   no console command to enter.

```text
Kingdoms of Amalur Re-Reckoning/
├── koa.exe
└── mods/
    └── all_quest_markers_native.json
```

If you used the earlier two-file test version, remove
`mods/all_quest_markers_world_scope.json`; its patch is included in the combined
file.

## Scope and compatibility

This release shows world-map objectives using the game's native marker data.
The local map and minimap retain their original behavior. It does not create
destinations the engine cannot resolve, and it has no larger-region filter or
configuration menu.

The mod applies three patches to game memory. It does not modify `koa.exe` on disk
or edit save files. Game updates or other mods changing the same code may cause
conflicts. If any patch signature fails in the framework startup log, remove this
mod and restart.

The combined mod has been confirmed working in-game, but every quest, interior,
DLC, undiscovered-area and save/load case has not been exhaustively tested.
Existing earlier visibility checks remain, but complete preservation of reveal
rules is not claimed.

Tested executable SHA-256:

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

## Uninstall

Close the game, then **disable the mod in Vortex**, or delete
`mods/all_quest_markers_native.json` if you installed it manually. Restart the game.
Keep shared framework files required by other mods.

## Troubleshooting

Make sure the JSON is directly inside `mods`, not an extra nested folder or a
`.json.txt` file. Restart after installation. For missing markers, include your
game store/build, framework version, other mods, affected quest/region and startup
log lines for `all_quest_markers_native.json`.

## Source and documentation

- [Mod JSON](mods/all_quest_markers_native.json)
- [Changelog](CHANGELOG.md)
- [Development and verification](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/development.md)
- [Native patch details](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/native-patches.md)
- [Published Nexus description (BBCode)](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/nexus-description.txt)

Game files and framework binaries are not bundled.

## Credits and license

Mod Framework by [DevCortez](https://github.com/DevCortez/KoaModFramework).
Original project code and documentation are [MIT licensed](LICENSE).
The in-game screenshot is from the author's Nexus Mods page; game imagery belongs
to its respective owners. The header is original generated artwork.
