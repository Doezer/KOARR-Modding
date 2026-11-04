---
name: koarr-modding
description: Develop, debug, research, test, and package Kingdoms of Amalur Re-Reckoning mods using Mod Framework, Havok Lua, JSON patches, and Windows x86 helpers. Use for KOARR/Amalur mod work, game-log analysis, inventory or quest UI changes, native hooks, compatibility investigations, and Nexus release preparation in KOARR-Modding.
---

# KOARR modding

Work from verified game contracts. Implement the requested feature, preserve
native item/quest behavior, test the change, and provide a usable artifact when
requested. Do not equate an API name, a successful build, a mocked test, or a
READY log with a working game feature.

## Start here

1. Find the existing checkout with `git rev-parse --show-toplevel`; inspect status,
   remote, agent instructions, the affected mod's README, source and tests. Use
   this checkout; do not create a worktree unless requested. The canonical remote
   is `https://github.com/Doezer/KOARR-Modding`. Its local folder may retain the
   old name `KOARR-World-map-enhanced`.
2. Establish store, executable, framework and DLC before applying native code.
   The verified target is **Windows GOG Re-Reckoning + Fatesworn + Mod Framework
   v1.4**. Do not extend that claim to Steam, Epic, original Reckoning or other
   builds without evidence. Existing session answers remain valid.
3. Read [workflow](references/workflow.md) for tooling, evidence collection and
   delivery. For Lua/native changes read [runtime and native contracts](references/runtime-native.md).
   For inventory/quest UI work also read [UI contracts and failure history](references/ui.md).
4. Separate the requested feature from setup. Reuse existing tools and caches.
   In a managed cloud environment, follow the environment runtime skill for
   credentials/network policy. Never print credentials or bypass TLS checks.
5. Prefer the smallest supported implementation: a JSON patch for a verified
   byte change, a Lua adapter for exposed behavior, and a native helper only for
   a demonstrated gap. Do not replace or redistribute proprietary game scripts.

## Repository map

Paths below are relative to the repository root, not the skill directory.

| Folder | Purpose and first reads |
| --- | --- |
| `all-quest-markers/` | World-map marker visibility; `README.md`, `mods/all_quest_markers_native.json`, `docs/native-patches.md` |
| `quest-hider/` | Journal visibility, preferences, objective renderer filter; `README.md`, `mods/QuestHider/bootstrap.lua`, `src/quest_hider/` |
| `inventory-plus/` | Inventory view projection, navigation, input and probes; `README.md`, `mods/InventoryPlus/`, `docs/inventory/spec.md`, `docs/inventory/spike.md` |
| `common/` | `src/vm_bridge.h`, pinned toolchain, optional VM emulator and all-mod test runner |

Each mod is its own working directory for local tools/tests. Runtime `mods/...`
paths are relative to `koa.exe`, and must not gain the repository's mod folder
prefix. A shared source file does not imply a common runtime mod is needed.

## Current evidence baseline

Recorded **2 November 2026**; reread current source/docs and user feedback before
using this as release status. Historical notes contain superseded failures.

- All Quest Markers 1.0.1: user confirmed the world-map behavior. Its stable
  archive/tag must not be rebuilt to deliver unrelated work.
- Quest Hider 1.0.0: journal hide, hidden-list switching and restoration confirmed.
  Map filtering, full-restart persistence and broad compatibility need wider
  testing. F6 toggles hide/restore; F7 changes list. Keys are configurable.
- Inventory Plus: search, name sorting and clearing confirmed in 0.2.1/0.3.1.
  0.3.0 category navigation failed and was withdrawn. The user reported improved
  navigation in 0.4.0, followed by click-through. 0.4.1 addresses click ownership;
  0.5.0 replaces the native category menu and splits Primary/Secondary contexts;
  0.5.1 (Lua-only) restores the native menu if entry fails and releases the
  hidden tree on any exit. **Entry, Back and equipment-slot behavior are awaiting
  in-game validation.**
  0.6.0 adds damage/armor sorts from the native read-only tables (14 slots, raw/scaled);
  the card's slot is unverified, provisionally slot 0 scaled. Ctrl+D logs all slots.

## Non-negotiable implementation rules

- Preserve original quest progress, tracking, item ownership, stacks, equipment
  and saves unless the user explicitly requests a feature that changes them.
  Browsing, tabs, filtering and sorting are read-only operations.
- Keep native handles attached to rows. A displayed row index is not identity.
  Preserve exact duplicate-item identity and original action context.
- Do not call undocumented game APIs based on their names. Establish namespace,
  argument types/count, return shape, timing and side effects from original call
  sites or validated disassembly. Trace registration entries carefully: a nearby
  function pointer can belong to a previous entry.
- Use framework triggers to load dependencies in order. Avoid nested `loadfile`
  and `package.loadlib` in startup adapters. Defer game-dependent work until a
  valid window/character context exists.
- Expect placeholder module tables and repeated triggers. Attach idempotently,
  revisit late-populated functions, preserve multiple/nil return values, and
  restore temporary globals/state even after an error.
- Treat text editing and owned mouse clicks as exclusive input. Guard ledger
  dispatch as well as inventory handlers. Release/held keys must not activate
  items. Back must remain recoverable; never restore the failed navigation's
  blanket input lock.
- Verify build identity, rebase addresses, fingerprint exact code before a
  native patch, preserve displaced instructions and machine state, and fail
  without patching on mismatch. Never remove signature/hash checks to make a
  different build appear supported.
- Keep private executables, bytecode, disassemblies and large raw logs in ignored
  `build/` or an external private directory. Do not commit or package them.
- Preserve other mods and published archives. Change bridge version tokens
  together when the ABI changes; a Lua-only fix may retain the existing bridge
  token when documented and compatible.

## Execution and completion

Make the requested change rather than stopping at a plan. If a contract is
missing, finish independent work and create the smallest passive diagnostic
needed to resolve it. Ask for one focused game run, not repeated F2 commands or
another full export when the needed functions already exist locally.

Run appropriate builds/tests and inspect their actual exit status. Do not run
commit/push commands after a failed check simply because a shell continues to the
next line. Fix the failure and rerun first. Do not amend assumptions into tests
just to make an unverified engine route pass.

When delivering a preview, state what changed, what passed offline, what is
confirmed in-game, and the smallest remaining game check. Provide an actual
verified download if an artifact is requested. Commit/push only when authorized
by the task/session; invoking this skill does not itself authorize publishing.
Do not message Nexus staff or publish a Nexus listing without instruction.

Update the affected mod README/development notes when behavior or evidence
changes. Update this skill when new verified contracts supersede its baseline.
