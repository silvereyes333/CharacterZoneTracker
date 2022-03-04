--[[ 
    ===================================
          World Map Integration
    ===================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = true
local COLOR_NORMAL = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local getPinDetails, getToggleText, shouldPinShowCompletionMenu, toggleTrackedActivity

-- Singleton class
local WorldMap = ZO_Object:Subclass()

function WorldMap:New()
    return ZO_Object.New(self)
end

function WorldMap:Initialize()
  
    ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][MAP_PIN_TYPE_POI_SEEN] = 
    {
        {
            -- Show / hide logic for pin menu
            show = shouldPinShowCompletionMenu,
            GetDynamicHandlers = function(pin)
                local handlers = {
                    {
                        name = getToggleText,
                        gamepadName = getToggleText,
                        gamepadDialogEntryName = getToggleText,
                        gamepadDialogEntryColor = COLOR_NORMAL,
                        callback = toggleTrackedActivity,
                    },
                    {
                        name = function() return GetString(SI_DIALOG_CANCEL) end,
                        gamepadName = GetString(SI_DIALOG_CANCEL),
                        gamepadDialogEntryName = GetString(SI_DIALOG_CANCEL),
                        gamepadDialogEntryColor = COLOR_NORMAL,
                        callback = function(pin) --[[ noop ]] end,
                        czbRemove = true
                    },
                }

                return handlers
            end,
        }
    }
    
    ZO_PreHook("ZO_WorldMap_SetupGamepadChoiceDialog", function(...) self:PrehookSetupPinChoiceMenu(...) end)
    ZO_PreHook("ZO_WorldMap_SetupKeyboardChoiceMenu", function(...) self:PrehookSetupPinChoiceMenu(...) end)
end




---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function WorldMap:PrehookSetupPinChoiceMenu(pinDatas)
    for pinDataIndex = #pinDatas, 1, -1 do
        local pinData = pinDatas[pinDataIndex]
        local handler = pinData.handler
        if handler then
            if handler.czbRemove then
                table.remove(pinDatas, pinDataIndex)
            end
        end
    end
end


---------------------------------------
--
--          Private Methods
-- 
---------------------------------------

function getPinDetails(pin)
    local poiIndex = pin:GetPOIIndex()
    if poiIndex == -1 then
        return
    end
    local objective, completionType = addon.ZoneGuideTracker:GetPOIObjective(nil, poiIndex)
    local zoneId = GetZoneId(objective.zoneIndex)
    local complete = addon.Data:IsActivityComplete(zoneId, completionType, objective.activityIndex)
    return objective, completionType, zoneId, complete
end
function getToggleText(pin)
    local objective, completionType, zoneId, complete = getPinDetails(pin)
    if not objective then
        return
    end
    if complete then
        return zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString(SI_OPTIONS_RESET), objective.name)
    end
    local stringTemplate = GetString("SI_ZONECOMPLETIONTYPE_SHORTDESCRIPTION", completionType)
    return zo_strformat(stringTemplate, objective.name)
end
function shouldPinShowCompletionMenu(pin)
    local poiIndex = pin:GetPOIIndex()
    if poiIndex == -1 then
        return
    end
    local objective = addon.ZoneGuideTracker:GetPOIObjective(nil, poiIndex)
    return objective ~= nil
end
function toggleTrackedActivity(pin)
    local objective, completionType, zoneId, complete = getPinDetails(pin)
    if not objective then
        return
    end
    addon.Data:SetActivityComplete(zoneId, completionType, objective.activityIndex, not complete)
    -- Refresh pins
    ZO_WorldMap_RefreshAllPOIs()
    -- Refresh zone guide
    if IsInGamepadPreferredMode() then
        WORLD_MAP_ZONE_STORY_GAMEPAD:RefreshInfo()
        GAMEPAD_WORLD_MAP_INFO_ZONE_STORY:RefreshInfo()
    else
        WORLD_MAP_ZONE_STORY_KEYBOARD:RefreshInfo()
    end
    if complete then
        -- TODO: show reset message
    else
        addon.ZoneGuideTracker:AnnounceCompletion(objective)
    end
end



-- Create singleton
addon.WorldMap = WorldMap:New()