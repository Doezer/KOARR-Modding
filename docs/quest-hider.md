# Quest Hider — 0.1.2 preview

Hide ongoing quests from the journal and filter their objective icons from maps.
Restore them through a separate hidden-quest view. Quest progress and your tracked
quest selection are preserved.

**Experimental; journal and native filtering still need in-game validation.**
The latest 0.1.2 log advances past the former startup stop into gameplay, but its
Lua adapter disables itself because the game does not expose `math.floor`.
The corrected 0.1.2 candidate removes that dependency from both key and quest ID
validation. It uses the same DLL as the previous 0.1.2 candidate.

The original failed log ends after the native renderer-install message during
`minimap_win`. It does not prove which following operation blocked. The current
candidate fixes a verified native-library registration stack leak: registering
`QuestHiderNative` pushes a table, and both native registration paths now restore
the original Lua stack height. Native logging uses one console output path.

Config is loaded by the framework, Lua bootstrap errors are guarded, and native
renderer initialization waits until the quest journal opens. A small native
bridge self-test runs first and logs whether a value returns successfully to Lua,
without reading game objects or installing a patch. This separates a bridge
failure from renderer initialization in the next log. Native DLL registration
still happens when the framework loads DLLs. A native hang cannot be caught by
Lua `pcall`. The latest log does not reach the bridge self-test because of the
earlier Lua error; its native and journal behavior remains unverified.

To disable the mod, close the game and move **both** `mods/quest_hider.json` and
`mods/quest_hider_native.dll` out of `mods`. Removing the JSON alone does not stop
the framework loading the DLL.

**Experimental: built and tested offline, awaiting in-game validation.** This is
an independent mod in the same repository as All Quest Markers. It does not require
All Quest Markers, and its renderer hook occupies a different code range.

[Download preview ZIP](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-0.1.2-preview.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-0.1.2-preview.zip.sha256)

## Requirements and installation

- Windows PC, GOG Re-Reckoning with Fatesworn, and
  [Mod Framework v1.4](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9).
- Only the executable with SHA-256 below is supported. The helper checks the hash
  before installing its renderer hook and disables itself on a mismatch.

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

When testing the mitigation separately, replace the DLL, JSON, `config.lua` and
`bootstrap.lua` together if upgrading from an older version. If you already
installed the complete 0.1.2 candidate, replace only
`mods/QuestHider/bootstrap.lua` for the `math.floor` correction. The DLL and config
have not changed. Keep your profile files.

Close the game. Extract the ZIP into the folder containing `koa.exe`, merging
`mods`, then restart. No console command is needed. Native filtering remains inactive until you first
open the quest journal during that game session.

```text
mods/
├── quest_hider.json
├── quest_hider_native.dll
└── QuestHider/
    ├── bootstrap.lua
    └── config.lua
```

## Focused startup test for 0.1.2

1. Close the game and temporarily move `mods/inventory_plus_probe.json` out of
   `mods` to keep this diagnostic run focused on Quest Hider.
2. Extract the complete 0.1.2 ZIP beside `koa.exe`, replacing all Quest Hider mod
   files. Keep `mods/QuestHider/profiles/` if it exists. If you customized the
   config, carry the settings into the new config format.
3. Start the game. Check that the main menu appears, then load your save and open
   the quest journal. No hiding/restoring action is needed for this first check.
4. Send the full framework log, including whether the stop happened before the
   menu or when opening the journal.

A successful journal initialization includes:

```text
[QuestHider] Bridge self-test: returned expected value.
[QuestHider] Native initialize: returned success.
```

These are diagnostic milestones, not a substitute for marker/journal validation.
If startup still blocks, close the game and disable both the Quest Hider JSON and
DLL as described above. Inventory work can continue with Quest Hider disabled.

## Controls

Open the quest journal and select an ongoing quest row.

- **F6:** hide the selected quest, or restore it from the hidden list.
- **F7:** switch between the normal journal and hidden quests.

The journal reminder area shows **F6: Hide | F7: Show Hidden** in the normal
list and **F6: Restore | F7: Show Normal** in the hidden list. It follows the
configured keys. The original reminder is restored when leaving the journal.
Hint placement still needs an in-game check; if the reminder label cannot be
identified, the mod logs a message and keeps its existing keyboard controls.

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
