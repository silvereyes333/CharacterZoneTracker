--[[ 
    ===================================
            UTILITY FUNCTIONS
    ===================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = false
local logger = LibDebugLogger(addon.name)

-- STATIC CLASS
addon.Utility = ZO_Object:Subclass()

--[[ Outputs formatted message to chat window if debugging is turned on ]]
function addon.Utility.Debug(input, force)
    --logger:Debug(input)
    if not force and not addon.debugMode then
        return
    end
    d("[CZB] " .. input)
end