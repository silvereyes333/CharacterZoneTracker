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



---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function CharacterZonesAndBosses_OnKeyboardLoadAccountButtonClick(control)
    local worldMap = addon.WorldMap -- get singleton
    worldMap:OnKeyboardLoadAccountButtonClick(control)
end

function CharacterZonesAndBosses_OnKeyboardResetButtonClick(control)
    local worldMap = addon.WorldMap -- get singleton
    worldMap:OnKeyboardResetButtonClick(control)
end


---------------------------------------
--
--          Private Methods
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



-- Register addon
EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, onAddonLoaded)