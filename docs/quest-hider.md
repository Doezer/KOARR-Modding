# Quest Hider — 0.1.0 preview

Hide ongoing quests from the journal and filter their objective icons from maps.
Restore them through a separate hidden-quest view. Quest progress and your tracked
quest selection are preserved.

**Experimental: built and tested offline, awaiting in-game validation.** This is
an independent mod in the same repository as All Quest Markers. It does not require
All Quest Markers, and its renderer hook occupies a different code range.

[Download preview ZIP](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-0.1.0-preview.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-0.1.0-preview.zip.sha256)

## Requirements and installation

- Windows PC, GOG Re-Reckoning with Fatesworn, and
  [Mod Framework v1.4](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9).
- Only the executable with SHA-256 below is supported. The helper checks the hash
  before installing its renderer hook and disables itself on a mismatch.

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

Close the game. Extract the ZIP into the folder containing `koa.exe`, merging
`mods`, then restart. No console command is needed.

```text
mods/
├── quest_hider.json
├── quest_hider_native.dll
└── QuestHider/
    ├── bootstrap.lua
    └── config.lua
```

## Controls

Open the quest journal and select an ongoing quest row.

- **F6:** hide the selected quest, or restore it from the hidden list.
- **F7:** switch between the normal journal and hidden quests.

Category headers remain available; expand a category to view its quests. Hidden
rows have a `[Hidden]` prefix. Closing and reopening the journal returns to the
normal list. Empty categories can remain visible.

Edit `mods/QuestHider/config.lua` with the game closed to change the two Windows
virtual-key codes. Defaults are F6 = 117 and F7 = 118. Choose different keys and
avoid conflicts with other mods. This preview has keyboard controls, including
when navigating the journal with a controller.

## Persistence and scope

Preferences are saved atomically under `mods/QuestHider/profiles/`, outside game
saves. They follow the character name across saves. **Characters with identical
names share preferences.** Set `profile` in the config to a unique string to
choose a profile manually. Names are encoded inside the preference file to detect
filename-hash collisions. Up to 1,024 quests can be hidden per profile.

The renderer filter targets tracked and untracked objective icons on world/local
maps and the minimap. A shared objective stays visible if any registered owner
quest is visible; unresolved ownership stays visible. Quest giver, fast-travel
and other point-of-interest icons are outside this filter.

The tracked quest stays selected internally. Its HUD text and overhead billboards
are outside this preview's filter. Hidden quests can still progress and complete
normally; this mod calls no quest lifecycle setters. Completed quests cannot be
newly hidden, but a previously hidden quest can be restored after completion.

Other game builds are disabled. Compatibility with every quest, DLC, map state,
save/load transition and other UI mods still needs in-game testing. The native
helper changes game memory and requires a full restart after installation/removal.

## First in-game test

1. Load a save, open the journal and select an ongoing quest. Press F6.
2. Check that the row disappears; press F7, select its `[Hidden]` row and press F6
   to restore it. Press F7 again to return to the normal list.
3. Hide a quest with a known objective, then reopen the world map and local map.
   Check its marker disappears, including when using All Quest Markers.
4. Restore it, check the marker returns, then hide it and restart the game to
   check persistence. Also test loading a different character.

If loading fails, close the game and remove the files listed below. Include log
lines containing `[QuestHider]` or `[QuestHider][native]` when reporting problems,
plus the affected quest and whether its objective is shared with another quest.

## Uninstall or reset

Close the game. Remove `mods/quest_hider.json`, `mods/quest_hider_native.dll` and
`mods/QuestHider/`, then restart. This restores the original journal and renderer.
To reset only hidden preferences, delete `mods/QuestHider/profiles/` with the game
closed. Keep framework files and files belonging to other mods.

## Development

Original C/Lua/assembly sources are MIT licensed; no game scripts, executable or
framework binary are bundled. See [Quest Hider development](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/quest-hider-development.md)
for the reproducible build and offline checks.
