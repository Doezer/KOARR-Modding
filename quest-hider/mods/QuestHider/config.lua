-- Executed by Mod Framework before bootstrap.lua for each matching trigger.
_G.QuestHiderConfig = {
    -- Windows virtual-key codes: F6 = 117, F7 = 118.
    toggle_key = 117,
    hidden_list_key = 118,
    -- Empty uses PLAYER.get_player_name(). Same-named characters share preferences.
    -- Set a unique name here if you play different characters with the same name.
    profile = "",
}
return _G.QuestHiderConfig
