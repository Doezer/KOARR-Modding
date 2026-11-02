# Game runtime and native integration

## Supported executable

These facts apply only to the analyzed GOG build:

```text
koa.exe SHA-256:
16a400f6e8fc10dbe446a9e57717de9fbe975ef17c004f4ca405e2e4e09cb314
Architecture: PE32 / x86
Preferred image base: 0x00400000
PE timestamp: 0x63F74827
SizeOfImage: 0x0173D000
Observed relocated base in a user session: 0x00150000
```

Rebase preferred VAs as `actual_base + preferred_va - 0x00400000`. Never hardcode
the observed relocated base. PE identity alone is weaker than full file hashing;
use each existing helper's exact checks and fingerprint all new bindings. Quest
Hider checks the disk hash before installing its renderer hook. Inventory Plus
checks PE identity and the bound code fingerprints; do not misdescribe those
as equivalent guarantees.

## Mod Framework

Source reference: DevCortez/KoaModFramework, pinned revision
`66bd89343fa516d5dfec0f7bed3961edc15ab33f`:
https://github.com/DevCortez/KoaModFramework/tree/66bd89343fa516d5dfec0f7bed3961edc15ab33f

The framework supports JSON signature patches, post-module Lua script triggers
and native DLL loading. Use the actual manifests as schemas; do not invent a
mod-manager metadata format or arbitrary asset-registration capability.

All Quest Markers uses three JSON patches and no custom Lua. For adapters,
manifest entries have `trigger` and game-relative `path`, for example:

```json
{"scripts":[
  {"trigger":"inventory_win","path":".\\mods\\InventoryPlus\\model.lua"},
  {"trigger":"inventory_win","path":".\\mods\\InventoryPlus\\navigation.lua"},
  {"trigger":"inventory_win","path":".\\mods\\InventoryPlus\\inventory_plus.lua"}
]}
```

Repeat ordered dependencies on each relevant trigger. Inventory uses
`inventory_win`, `name_win`, `ledger_win`. Quest Hider uses `quests_win`,
`minimap_win`, `ledger_win`, loading config before bootstrap.

Native DLLs are loaded even if their JSON is removed. To disable a native mod,
remove/move both manifest and DLL, then restart. Do not remove framework files or
another mod's files. No console command is needed for installed adapters.

## Havok Lua pitfalls

The game reports **Havok Lua 2.5 r7786**. Host Lua 5.1 is a useful test harness,
not a promise of standard-library parity.

- `math.floor` was unavailable: use validated integral values and `% 1 == 0`
  when needed, without introducing another unverified function.
- `string.format('%.0f', integer)` returned `"0"` in-game. Quest Hider saved the
  wrong preference key until integer keys used `tostring(key)`. Do not use float
  formatting as an integer serializer. Hex formatting used by the probe works.
- `string.dump` is available; `io.open` was nil. Print bounded checksummed hex
  through the framework log instead of assuming filesystem access from Lua.
- Original function signatures and opaque userdata differ from stock Lua.
  Do not coerce handles to strings/numbers unless that path has been verified.
- Never call new native/game functions during early circular module loading.
  Quest Hider's initial startup hang occurred before the main menu. The working
  design defers game initialization to journal SHOW, loads dependencies via
  the framework and catches partial-bootstrap errors.

Wrap original callbacks with packed results `{n=select('#',...),...}` and
`unpack(t,1,t.n)`. Keep `pcall` status separate from actual return values. Restore
shared setters/temporary flags before rethrowing original errors. Duplicate
triggers should attach once per function and handle late-defined methods.

## Native Lua bridge

Use `common/src/vm_bridge.h`. Named library registration leaves a table on the
Lua value stack. Capture top before/after, pop the added count and verify balance.
Do not replace this helper with stock Lua macros whose semantics are unproven.
The game's bound pop routine takes a **count**, not stock `lua_settop` semantics.

Known preferred VAs (read current fingerprints in helper source):

| Binding | Preferred VA |
| --- | --- |
| gettop | `0x00A9F980` |
| tostring | `0x00A9F8B0` |
| count-based pop | `0x00A9F9A0` |
| register library | `0x010ADCA0` |
| pushstring | `0x00AA3560` |
| existing framework new-state hook site | `0x010D2C25` |

The framework hook's verified prefix occupies 16 bytes, followed by `push eax`,
a rel32 call at +17 and `ret` at +22. Existing helpers replace only that call's
rel32 target, invoke the previous stdcall callback, and register on its returned
state. Chain other mods' callbacks; do not overwrite their hooks. Validate that
the expected previous target is outside the game image as the source does.
Calling convention and returned stack state are part of the contract.

A C function returning 1 without pushing a value returns an existing stack value.
This is intentional only in checked token/argument-return APIs; it is not a
boolean-return shortcut. For actual strings use the verified pushstring binding;
it copies/interns the text before temporary storage is freed. Check argument
counts and conversion failures. Keep native tables and Lua adapters versioned
with explicit handshake strings.

## Hooks and preferences

Windows helpers are built `x86-windows-gnu`, shared/static-linked, with the
repository's `-mno-sse -mno-sse2` C settings. The renderer assembly explicitly
preserves flags, general registers, FPU/SSE state, stack and calling convention.
Do not assume the C compiler preserves flags or all volatile registers. Verify
branch destinations and displaced instruction behavior with emulator checks.
Keep page-protection changes and instruction-cache flushing scoped to the patch.

Quest Hider renderer locations, for this build only:

- Hook: `0x01006CFB`; original bytes `F6 45 04 01 0F 85 0F 06 00 00`.
- Continue: `0x01006D05`; skip icon: `0x01007314`.
- All Quest Markers renderer patch starts at `0x01006DA0`, outside that hook.
- Filtered objective icon IDs: `0x007F3718`, `0x01AB7635`.

Read actual source for registry offsets and ownership traversal; this document
is not a substitute for verifying pointers and code on a new build. Unknown or
shared-visible owners must remain visible. Keep registry scans bounded/cached.

Quest Hider profiles are external to saves under `mods/QuestHider/profiles/`.
Same-named characters share preferences unless config selects a unique profile.
Storage uses strict parsing, bounded capacity, encoded profile identity and
atomic replacement. Failed writes leave both prior preferences and journal
visibility unchanged. Report operation/path/Windows error, not a generic save
failure. Do not put debug spam back into its stable 1.0.0 behavior.
