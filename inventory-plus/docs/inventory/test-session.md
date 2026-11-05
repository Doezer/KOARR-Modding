# Inventory Plus 0.6.3: one test session

Everything below is unconfirmed in-game. Run it once, in order, and send the
full framework log plus the numbers marked **[card]**.

## Install (2 minutes)

1. Close the game. Remove the old Inventory Plus files: `mods/inventory_plus.json`,
   `mods/inventory_plus_native.dll`, `mods/InventoryPlus/`.
2. Remove the stats probe if installed (`mods/inventory_plus_stats_probe*`,
   `mods/InventoryPlusStatsProbe/`): both listen to Ctrl+D.
3. Extract `InventoryPlus-0.6.3-preview.zip` beside `koa.exe`, merging `mods`.
4. Start the game fully, load a character with several weapons and armor pieces.

## Checks

| # | Do | Expect |
| --- | --- | --- |
| 1 | Open the ledger, enter Inventory | Lands in Primary, seven buttons, no old category menu |
| 2 | Click Secondary, then Primary | Each shows its own native list and comparison; nothing equips |
| 3 | Select a weapon in each, use the native Equip action | Goes to the matching slot (note any wrong slot) |
| 4 | Click every button, then press Ctrl+1 to Ctrl+7 | Switches categories; nothing underneath activates |
| 5 | Ctrl+F, type part of a name, confirm | List filters; footer shows count; Esc clears |
| 6 | With a search active, switch category | Search stays applied |
| 7 | Press Back after clearing search | Leaves Inventory to the ledger, old menu not shown |
| 8 | Reopen Inventory | Returns to the last category |
| 9 | Open Quests/Map from the ledger, return | Their navigation is normal |
| 10 | Inside Inventory, close the ledger (not Back), reopen it | Ledger navigation is visible and usable |
| 11 | Ctrl+S in Primary until the footer says **Dmg** | Highest damage first |
| 12 | Select the top weapon, press **Ctrl+D** | Log lines `Stats: ...` appear |
| 13 | **[card]** Note that weapon's damage; repeat for 2 more weapons | Used to pick the right slot |
| 14 | In Armor, Ctrl+S until **Armor**; Ctrl+D on 2 pieces; **[card]** their ratings | Same purpose |
| 15 | Switch to Consumables with Dmg active | Falls back to A-Z |
| 16 | In Primary press Ctrl+1 then Ctrl+2, then click Primary and Secondary | Switches; if a click does nothing, send the `[nav]` log lines |
| 17 | Ctrl+S through Lvl and Value; Ctrl+D on 2 items; **[card]** required level and sell value | Compare with the logged `get_item_cost` / `get_level_requirement` |

If something looks wrong, stop and note the step number; do not retry repeatedly.

## What to send

- The full framework log from the session (it contains the Ctrl+D lines, the
  `Button event ...` lines and the `Names ACTOR/TYPE` candidate lists).
- The **[card]** numbers for each item, and any step that failed.
