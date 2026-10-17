# Quest Hider — 0.1.3 preview

Hide ongoing quests from the journal and filter their objective icons from maps.
Restore them through a separate hidden-quest view. Quest progress and your tracked
quest selection are preserved.

**Experimental: startup and journal opening work in the user's test, and F7
switches between lists. The corrected 0.1.3 candidate fixes the quest-key text
conversion used by F6. Hiding/restoring, persistence and map filtering still need
an in-game check.**

The diagnostic log identified `key=0; Invalid quest key (Win32 0)`. A positive
integer quest key had passed Lua validation, but `string.format("%.0f", key)`
turned it into the text `"0"` in the game's runtime. The corrected Lua adapter
uses `tostring(key)` to preserve the integer. The native helper correctly refused
the zero key before attempting any file write; that log does not show a folder
permissions failure.

The existing 0.1.3 native diagnostics remain available for any subsequent failure:
they report the failing operation, Windows code and preference path through the
framework log. Preference location and DLL are unchanged by this correction.

The candidate retains the earlier native registration stack fix and the Lua
integer checks that work without `math.floor`. Native renderer initialization
waits until the journal opens, after a bridge self-test. Both initialization
steps returned successfully in the latest 0.1.2 game logs.

To disable the mod, close the game and move **both** `mods/quest_hider.json` and
`mods/quest_hider_native.dll` out of `mods`. Removing the JSON alone does not stop
the framework loading the DLL.

**Experimental: built and tested offline, awaiting in-game validation.** This is
an independent mod in the same repository as All Quest Markers. It does not require
All Quest Markers, and its renderer hook occupies a different code range.

[Download preview ZIP](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-0.1.3-preview.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-0.1.3-preview.zip.sha256)

## Requirements and installation

- Windows PC, GOG Re-Reckoning with Fatesworn, and
  [Mod Framework v1.4](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9).
- Only the executable with SHA-256 below is supported. The helper checks the hash
  before installing its renderer hook and disables itself on a mismatch.

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

If you already installed the complete 0.1.3 diagnostic candidate, replace only
`mods/QuestHider/bootstrap.lua` for this key-conversion correction. When upgrading
from 0.1.2 or earlier, replace both the DLL and bootstrap so their bridge versions
match. The JSON and config are unchanged; keep your custom config and profiles.

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

## Focused preference-save test for 0.1.3

1. Close the game. Replace `bootstrap.lua` with the corrected file. If your DLL
   predates 0.1.3, replace that from the ZIP too. Keep your config and profiles.
2. Load your save, open the quest journal, select an ongoing quest row and press F6.
3. Check that the row disappears, then press F7 and restore it with F6. On
   failure, send the framework log; the error includes the key, action, failing
   operation, Windows code and file path.

A reported Windows code of zero means a validation/internal failure, rather than
an error returned by Windows. The original preference state remains unchanged on
failure.

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
