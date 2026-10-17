# Quest Hider development

This preview lives beside All Quest Markers. Its build, package, configuration and
preferences are separate. Do not rebuild or overwrite the existing AllQuestMarkers
release ZIP merely to update Quest Hider.

## Linux build and checks

Use an existing checkout; no separate worktree is necessary. Requirements: Python
3.12+, a host C compiler (`cc`), Lua 5.1, and the official Linux x86_64 Zig 0.13.0
compiler. The builder downloads Zig over verified HTTPS when absent and checks
the pinned upstream SHA-256 before extraction. Its cache defaults to
`/workspace/.quest-hider-tools` and can be overridden with `--cache`.

For the complete verified tool setup and test run, use
`python tools/setup_quest_hider.py`. To run individual steps:

```sh
python tools/build_quest_hider.py
QH_LUA=/path/to/lua5.1 python -m unittest discover -s tests -v
python tools/package_quest_hider.py
```

The DLL is generated under ignored `build/`; only the preview ZIP contains the
compiled helper. Neither build nor tests need game files. To run the optional x86
hook emulator, install `pefile==2024.8.26` and `unicorn==2.1.4` in a development
virtual environment, then run `python tests/quest_hider_hook.py`. It tests all
four combinations of native-hidden and mod-hidden flags and verifies register,
stack and SSE preservation while simulating a clobbering helper call.

Offline tests cover strict preference parsing/roundtrip, bounded storage, failed
parses retaining prior state, shared-marker policy, journal filtering/restoration,
selection, collapsed rows, multiple/nil returns, render errors, failed writes,
character changes, duplicate bootstrap, reminder hints in both views, custom key
labels, reminder restoration, shared UI setter cleanup after errors and package
isolation. They do not execute
the proprietary game or establish in-game compatibility.

## Integration

The framework loads `mods/quest_hider_native.dll`. The helper chains the existing
framework Lua-state registration hook. The Lua adapter requires that registered
table; it no longer calls `package.loadlib` during startup.
Both paths register `QuestHiderNative`, then the `quests_win` and `minimap_win`
script triggers attach the original Lua adapter. Original game Lua files are
never replaced or distributed.

Native initialization is deferred until the quest journal SHOW event. Config
loads through the framework before the bootstrap; it no longer uses nested
`loadfile` calls. Lua bootstrap errors are caught, and initialize enter/return
markers narrow a subsequent failure. A reported 0.1.0 startup hang is not yet
confirmed fixed on the target build; keep Quest Hider disabled for inventory
probe runs.

The helper first checks PE identity and API fingerprints, then verifies the exact
on-disk executable SHA-256 before installing the renderer hook. Preferred image
base is 0x00400000; addresses are rebased at runtime.

- Renderer hook: 0x01006CFB, 10 original bytes
  `F6 45 04 01 0F 85 0F 06 00 00`.
- Continue at 0x01006D05; skip objective icon at 0x01007314.
- All Quest Markers' renderer patch begins at 0x01006DA0, outside this range.
- Only objective icon IDs 0x007F3718 and 0x01AB7635 are filtered.

Marker ownership is read from the quest target registry. Hidden asset keys are
resolved through the read-only loaded-asset lookup; it does not load quest assets.
Groups with visible or unknown owners stay visible. A bounded 200 ms cache limits
registry scans. Character-pointer changes disable filtering until profile sync.

The assembly hook preserves flags, general registers and FPU/SSE state around
the native helper, then reproduces the original test/branch for visible icons.
Preference files use an encoded profile header and atomic replacement. Journal
visibility masking is temporary and restored even when the original rebuild
raises an error. Quest progression, tracking and save data are not written.

Pinned framework source consulted:
[DevCortez/KoaModFramework at 66bd893](https://github.com/DevCortez/KoaModFramework/tree/66bd89343fa516d5dfec0f7bed3961edc15ab33f).
The GOG executable and private bytecode exports are not in this repository.

The journal key hint reuses the existing ledger reminder label. While the original
journal SHOW handler calls `ledger_win.set_reminder`, the adapter briefly observes
the supported WINDOW label setters to identify the actual label handle. All shared
setters are restored even if the reminder throws. It then writes the configured
keys and current list actions, refreshing on journal updates. Closing the journal
or detaching restores the original reminder through its original setter/arguments;
another ledger page taking ownership drops the cached label. No guessed UI hashes
or duplicated UI templates are introduced. Actual placement requires game testing.
