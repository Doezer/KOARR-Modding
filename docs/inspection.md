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

4. Look for `[AllQuestMarkers][inspect] SAVED AllQuestMarkers-inspection-001.txt`.
   The number increases if a previous file exists. The file is in the game's
   working directory, normally beside `koa.exe`. Upload that text file privately
   in this conversation. Do not post it publicly or put it in the GitHub repo.
5. If it prints an error or exports zero functions, send that console message.
   Missing standard-library support is a diagnostic result, not an installation
   success. Do not attempt to fix it with unknown native calls.

The exporter examines only raw Lua function fields of `minimap_win`, `map_manager`,
`quests_win`, `map_data` and `target_win_manager`. It never invokes those functions,
dumps save data, starts quests, changes tracking, installs hooks, or loads the
serialized bytecode. Standard `string.dump` and `io.open` must be exposed by the
VM; that has not yet been demonstrated in the target build.

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
