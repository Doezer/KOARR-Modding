# Quest Hider — 1.0.0

Hide ongoing quests from your journal and their objective icons from maps.
Use the hidden-quest list to restore them whenever you want. Quest progress and
your tracked quest selection are preserved.

An independently installable mod in the same collection as All Quest Markers.
The user has confirmed journal hiding, list switching and restoration work on
the supported GOG build. Routine startup and action debug logs are removed in
1.0.0; errors remain available in the framework log.

[Download Quest Hider 1.0.0](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-1.0.0.zip)
· [SHA-256](https://raw.githubusercontent.com/Doezer/KOARR-World-map-enhanced/main/dist/QuestHider-1.0.0.zip.sha256)

## Requirements

- Windows PC, GOG Re-Reckoning with Fatesworn.
- [Mod Framework v1.4](https://www.nexusmods.com/kingdomsofamalurrereckoning/mods/9).
- The supported executable has this SHA-256; other builds are disabled:

```text
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
```

All Quest Markers is optional. The mods use separate configuration files and
renderer hooks.

## Installation and upgrades

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

When upgrading from a preview, replace both the DLL and `bootstrap.lua`; the
1.0.0 bridge versions must match. Preserve `mods/QuestHider/profiles/` and carry
your custom settings into `config.lua`. Existing preference files are compatible.
Native map filtering becomes active when you first open the quest journal during
the session.

## Controls

Open the quest journal and select an ongoing quest row.

- **F6:** hide the selected quest, or restore it from the hidden list.
- **F7:** switch between the normal journal and hidden quests.

The journal reminder area shows **F6: Hide | F7: Show Hidden** in the normal list
and **F6: Restore | F7: Show Normal** in the hidden list. It follows the configured
keys, and the original reminder returns when leaving the journal. If the label
cannot be identified, the controls remain available and are printed in the log.

Category headers remain available; expand a category to view its quests. Hidden
rows have a `[Hidden]` prefix. Closing and reopening the journal returns to the
normal list. Empty categories can remain visible.

To change the keys, edit `mods/QuestHider/config.lua` with the game closed.
Defaults are Windows virtual-key codes F6 = 117 and F7 = 118. Choose distinct keys
that do not conflict with other mods. These are keyboard controls, including
when navigating the journal with a controller.

## Preferences and scope

Preferences are saved under `mods/QuestHider/profiles/`, outside game saves. They
follow the character name across saves. **Characters with identical names share
preferences.** Set `profile` in the config to a unique string to choose a profile
manually. Up to 1,024 quests can be hidden per profile.

The map filter targets tracked and untracked objective icons on world/local maps
and the minimap. Shared objectives remain visible if any registered owner quest
is visible; unresolved ownership also stays visible. Quest giver, fast-travel and
other point-of-interest icons are outside this filter.

The tracked quest stays selected internally. Its HUD text and overhead billboards
remain visible. Hidden quests can still progress and complete normally. Completed
quests cannot be newly hidden; a previously hidden quest can still be restored
after completion.

Journal hide/restore is confirmed in-game. Map filtering, persistence across full
restarts and compatibility across quests, DLC and other UI mods have offline
coverage where applicable but still need broader gameplay testing.

## Troubleshooting

Errors use the `[QuestHider]` or `[QuestHider][native]` prefix in the framework log.
Preference failures include the operation, Windows error code and file path;
existing preferences stay unchanged when saving fails. Include the affected quest
and any shared objective when reporting a problem.

To disable the mod, close the game and move **both** `mods/quest_hider.json` and
`mods/quest_hider_native.dll` out of `mods`, then restart. The framework loads DLLs
even when their JSON is absent.

## Uninstall or reset

Close the game. Remove `mods/quest_hider.json`, `mods/quest_hider_native.dll` and
`mods/QuestHider/`, then restart. This restores the original journal and renderer.
To reset only hidden preferences, delete `mods/QuestHider/profiles/` with the game
closed. Keep framework files and files belonging to other mods.

## Development

Original C/Lua/assembly sources are MIT licensed; no game scripts, executable or
framework binary are bundled. See [Quest Hider development](https://github.com/Doezer/KOARR-World-map-enhanced/blob/main/docs/quest-hider-development.md)
for the reproducible build and offline checks.
