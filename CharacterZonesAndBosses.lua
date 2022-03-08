-- Character Zone and Boss Completion Addon for Elder Scrolls Online
-- Author: silvereyes

CharacterZonesAndBosses = {
    name = "CharacterZonesAndBosses",
    title = "Character Zone and Boss Completion",
    version = "1.0.0",
    author = "silvereyes",
}

-- Local declarations
local addon = CharacterZonesAndBosses
local onAddonLoaded
local COMPLETION_TYPES



---------------------------------------
--
--          Public Members
-- 
---------------------------------------

addon.Chat = LibChatMessage(addon.name, "CZB")

function CharacterZonesAndBosses_OnKeyboardLoadAccountButtonClick(control)
    local worldMap = addon.WorldMap -- get singleton
    worldMap:OnKeyboardLoadAccountButtonClick(control)
end

function CharacterZonesAndBosses_OnKeyboardResetButtonClick(control)
    local worldMap = addon.WorldMap -- get singleton
    worldMap:OnKeyboardResetButtonClick(control)
end

function CharacterZonesAndBosses:GetCompletionTypes()
    return COMPLETION_TYPES
end

function CharacterZonesAndBosses:IsCompletionTypeTracked(completionType)
    return COMPLETION_TYPES[completionType]
end


---------------------------------------
--
--          Private Members
-- 
---------------------------------------

function onAddonLoaded(event, name)
    if name ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
    
    addon.Events:Initialize()
    
    -- Everything below this point should only run after Update 33 comes out
    if GetAPIVersion() < 101033 then
        return
    end
  
    addon.Compass:Initialize()
    addon.WorldMap:Initialize()
end

COMPLETION_TYPES = {
    [ZONE_COMPLETION_TYPE_DELVES] = true, -- IsUnitInDungeon("player") == true
    [ZONE_COMPLETION_TYPE_GROUP_BOSSES] = true,
    [ZONE_COMPLETION_TYPE_WORLD_EVENTS] = true,
}



-- Register addon
EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, onAddonLoaded)