# Private inspection export

The focused trace confirms runtime call shapes but not the game logic that
selects targets and renders quest markers. This helper serializes the relevant
already-loaded Lua functions so that logic can be examined without speculative
engine calls or another interaction trace.

1. Close the game and install the current ZIP beside `koa.exe`.
2. Start the game and load a save. No map/journal interaction is required.
3. In the F2 field that successfully ran the probe, enter:

   ```lua
   assert(loadfile('mods/AllQuestMarkers/inspect.lua'))()
   ```

4. In the confirmed GOG VM, `string.dump` exists but `io.open` does not. The helper
   now falls back to console output. Copy everything from `BEGIN console-export-v2`
   through `END console-export-v2` and upload it as private pasted text. No disk
   file is expected in this mode.
5. On a VM with file-writing support, look for `[AllQuestMarkers][inspect] SAVED AllQuestMarkers-inspection-001.txt`.
   The number increases if a previous file exists. The file is in the game's
   working directory, normally beside `koa.exe`. Upload that text file privately
   in this conversation. Do not post it publicly or put it in the GitHub repo.
6. If it prints an error or exports zero functions, send that console message.
   Missing standard-library support is a diagnostic result, not an installation
   success. Do not attempt to fix it with unknown native calls.

By default the exporter examines only raw Lua function fields of `minimap_win`,
`map_manager` and `quests_win`. An optional argument can select one known module
for a smaller export, for example:

```lua
assert(loadfile('mods/AllQuestMarkers/inspect.lua'))('minimap_win')
```

The allowlist also includes `map_data` and `target_win_manager`. It never invokes those functions,
dumps save data, starts quests, changes tracking, installs hooks, or loads the
serialized bytecode. Standard `string.dump` must be exposed. It was confirmed present in the target
VM; serialization of the game functions themselves remains unverified. File
writing is optional.

Output contains compiled proprietary game Lua, not ordinary source text. It is
for private local analysis only. This project distributes no exported game code.
Generated `AllQuestMarkers-inspection-*.txt` files are ignored by Git, and the
package builder includes only original project files, not inspection outputs.

The helper chooses a new numbered output filename, refuses an existing file it
cannot check safely, and bounds exports to 256 functions, 128 KiB each, 1 MiB total
binary payload. The hex text is about twice the binary size. C/native functions
that cannot be dumped are reported as skipped. No output bytecode is executed
by the helper or tests. No uninstaller action beyond deleting the inspection text
file and optional helper is necessary; no persistent hooks or globals are added.

The long inline export command was truncated by the F2 code field, producing a
compile error ending near `for i=1,#s,12`. Keep the export in the helper script
and use only the short loadfile command above in F2. The field length limit is
not established precisely; the screenshot demonstrates truncation.
