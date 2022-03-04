-- Character Zone and Boss Achievements Addon for Elder Scrolls Online
-- Author: silvereyes

CharacterZonesAndBosses = {
    name = "CharacterZonesAndBosses",
    title = "Character Zone and Boss Achievements",
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


---------------------------------------
--
--          Private Methods
-- 
---------------------------------------

function onAddonLoaded(event, name)
    if name ~= addon.name then return end
    EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
    
    addon.Events:Initialize()
    addon.WorldMap:Initialize()
end



-- Register addon
EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, onAddonLoaded)