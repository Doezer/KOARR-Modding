# Quest Hider development

Run the commands below from the repository’s `quest-hider/` folder.

Quest Hider lives beside All Quest Markers. Its build, package, configuration and
preferences are separate. Do not rebuild or overwrite the existing AllQuestMarkers
release ZIP merely to update Quest Hider.

## Version 1.0.0

The user confirmed the corrected journal behavior, and the final log records two
quests hidden and both restored through the hidden list. Version 1.0.0 removes
routine bootstrap, bridge, initialization, profile and action logs. Actionable
errors and the fallback key hint remain. Internal bridge checks, initialization
ordering and preference error details remain active. Both DLL and bootstrap use
the `QuestHider bridge 1.0.0` token. Preference format and keys are unchanged.

The sections recording preview failures below are historical investigation notes;
current installation and validation status are in `README.md`.

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

The DLL is generated under ignored `build/`; only the release ZIP contains the
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
The state hook registers `QuestHiderNative`; the exported Lua loader shares the
same balanced registration helper. The `quests_win`, `minimap_win` and `ledger_win`
script triggers attach the original Lua adapter. The ledger trigger permits
late-loaded reminder helpers to attach after the journal module has loaded. Original game Lua files are
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

## Native bridge investigation — 0.1.2

The game implementation confirms that named `luaL_register` leaves the library
table on the Lua value stack. The old state hook left that extra value in place.
`vm_bridge.h` now measures and restores stack height around registration, shared
by the state hook and exported Lua loader. A native C regression performs 200
registrations without growing the stack or changing pre-existing values.

The pop binding at preferred VA 0x00A9F9A0 is fingerprint-checked before use.
With `pefile` and `unicorn` installed, the following optional check uses only a
local, exact-hash executable and reads/emulates its small stack API routines:

```sh
python ../common/tools/verify_game_vm.py /private/path/to/koa.exe
```

Eight emulated cases cover stack pop/count at the preferred image base and the
0x00150000 base observed in the user's log. The same check exercises the native
`assert` success path: it returns an existing argument without appending a new
value. That establishes that the bridge's existing-argument result convention
is supported by this VM; it is not being replaced on speculation. No executable
or extracted game code is included in the check or distributed with the mod.

The game's `loadfile` and the framework file loader call the same underlying
file loader. The frozen log alone therefore does not justify blaming nested
`loadfile`. Removing that dependency and deferring initialization remain useful
startup mitigations, not a proven root-cause diagnosis.

A `self_test` callback now exercises the native-to-Lua result boundary before any
renderer initialization. Lua checks its exact versioned return value. A missing,
wrong or failed result disables filtering, preserves the original journal call,
and logs the failure. Native logs write only to the console handle; the redundant
`OutputDebugString` sink was removed so a debugger/overlay output path is not
part of a native API return. This is not a claim that that sink caused the hang.

### Follow-up log: missing `math.floor`

The user's 0.1.2 log continues through startup into gameplay, but each bootstrap
trigger reports `function expected instead of nil` at `valid_key`, line 23.
That call is `math.floor`; the protected bootstrap disables the adapter before
native self-test or renderer initialization. This log therefore supplies no
in-game result for either deferred native operation.

The correction replaces both integer checks (configured virtual keys and quest
asset keys) with modulo arithmetic. Startup and journal regressions now run with
`math.floor` removed and check fractional, out-of-range, string, infinite and NaN
inputs. The corrected ZIP retains version 0.1.2 and its unchanged DLL/bridge
protocol; users with the complete previous 0.1.2 installation can replace only
`mods/QuestHider/bootstrap.lua`. Commit-pinned download links distinguish the two
candidates. The journal/native path still requires target-game validation.


## Preference-save investigation — 0.1.3

The subsequent 0.1.2 logs confirm bootstrap, native bridge, renderer initialization
and profile loading complete. The user confirms the journal opens and F7 works.
F6 logs `Could not save preference; quest left unchanged.` The old native API
returns no result for several validation and I/O failures, so this message alone
does not identify a filesystem error or justify a permissions workaround.

0.1.3 records a failure for every `set_hidden` exit: inactive profile, argument/key/
action validation, capacity, encoding/path, temporary-file creation, write, short
write, flush, close and replacement. Windows errors are captured before cleanup
can overwrite them. `save_error()` returns the detail to Lua, which prints it
through the framework logger alongside key/action. Native console output was not
present in the latest uploaded log, so native-only logging is insufficient.

The new diagnostic string return uses the exact-build `lua_pushstring` routine
at preferred VA 0x00AA3560, guarded by its byte fingerprint. Optional target-VM
checks emulate its real strlen/hash/stack-write code at both image bases, stubbing
only string interning. They apply PE relocations to the copied hash jump table.
The Lua regression checks that detailed and unavailable/throwing diagnostics leave
quest state unchanged. The bridge token is 0.1.3, so replace DLL and bootstrap
together. This candidate improves diagnosis; it does not establish the cause or
fix the preference failure. Preference location is unchanged.


### Follow-up: zero key from floating-point formatting

The 0.1.3 diagnostic reports `key=0, action=hide; Invalid quest key (Win32 0)`.
Lua had already required the numeric key to be positive, integral and within the
asset-key range before calling `string.format("%.0f", key)`. Thus the textual zero
was introduced by that conversion; the native parser correctly rejected it
before storage was attempted. There is no evidence of a filesystem failure in
that log.

The adapter now uses `tostring(key)`. The native integer-to-string path uses
integer decimal formatting, avoiding the failing floating-point format. The
journal regression reproduces the observed formatter returning `"0"` and checks
hide/restore with ordinary keys, 16777217 and the maximum 268435455. No DLL or
bridge change is needed. The corrected ZIP retains version 0.1.3, with immutable
commit-pinned links identifying the revised candidate. In-game behavior still
requires the user's validation.
