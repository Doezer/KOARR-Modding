# Inventory Plus stats probe 0.1.0 (diagnostic)

Read-only diagnostic. It settles which native damage/armor slot the item card
shows, so stat sorting can be built on a verified reader. It changes nothing: no
items, equipment, stacks or saves. Remove it when done. Same build as Inventory
Plus: GOG Re-Reckoning + Fatesworn + Mod Framework v1.4; other builds disable it.

Install: extract beside `koa.exe`, merging `mods`. It runs alongside Inventory Plus.
Restart the game fully.

## One game run

1. Open Inventory, select a **weapon**, and note the damage number the native
   card shows (and any comparison number).
2. Press **Ctrl+D**. Note the lines printed to the framework log.
3. Repeat with a second weapon of clearly different damage, then one **armor**
   piece (note its armor rating) and one **non-gear item** (e.g. a potion).
4. Send the framework log plus the numbers you saw on screen for each item.

Log shape: `damage raw` / `damage scaled` / `armor raw` / `armor scaled`, each 14
comma-separated values for slot indices 0..13. "raw" and "scaled" are the
function's own flag values. Values are truncated integers.

The helper fingerprints the two native readers (`0x00E42140`, `0x00E421D0`) and
the executable identity before registering; on any mismatch it does nothing.
