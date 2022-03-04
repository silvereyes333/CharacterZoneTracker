--[[ 
    ===================================
          World Map Integration
    ===================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = true
local COLOR_NORMAL = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local getPinDetails, getCompleteText, getResetText, markPinComplete, markPinIncomplete, shouldPinShowCompletionMenu

-- Singleton class
local WorldMap = ZO_Object:Subclass()

function WorldMap:New()
    return ZO_Object.New(self)
end

function WorldMap:Initialize()
  
    -- Placeholder handler to make the total number of handlers returned by GetDynamicHandlers be greater than 1, to trigger the context menu.
    local dummyHandler =
    {
        name = function() return GetString(SI_DIALOG_CANCEL) end,
        gamepadName = GetString(SI_DIALOG_CANCEL),
        gamepadDialogEntryName = GetString(SI_DIALOG_CANCEL),
        gamepadDialogEntryColor = COLOR_NORMAL,
        callback = function(pin) --[[ noop ]] end,
        czbRemove = true
    }
    
    -- Menu action to force-complete a zone activity
    ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][MAP_PIN_TYPE_POI_SEEN] = 
    {
        {
            -- Show / hide logic for pin menu
            show = shouldPinShowCompletionMenu,
            GetDynamicHandlers = function(pin)
                local handlers = {
                    {
                        name = getCompleteText,
                        gamepadName = getCompleteText,
                        gamepadDialogEntryName = getCompleteText,
                        gamepadDialogEntryColor = COLOR_NORMAL,
                        callback = markPinComplete,
                    },
                    dummyHandler,
                }

                return handlers
            end,
        }
    }
  
    -- Menu action to force-reset a zone activity
    ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][MAP_PIN_TYPE_POI_COMPLETE] = 
    {
        {
            -- Show / hide logic for pin menu
            show = shouldPinShowCompletionMenu,
            GetDynamicHandlers = function(pin)
                local handlers = {
                    {
                        name = getResetText,
                        gamepadName = getResetText,
                        gamepadDialogEntryName = getResetText,
                        gamepadDialogEntryColor = COLOR_NORMAL,
                        callback = markPinIncomplete,
                    },
                    dummyHandler,
                }

                return handlers
            end,
        }
    }
    
    -- Hook pin click menu creation events to remove the dummy handler menu entry before display.
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
    return objective, completionType, zoneId
end
function getCompleteText(pin)
    local objective, completionType, zoneId = getPinDetails(pin)
    if not objective then
        return
    end
    local stringTemplate = GetString("SI_ZONECOMPLETIONTYPE_SHORTDESCRIPTION", completionType)
    return zo_strformat(stringTemplate, objective.name)
end
function getResetText(pin)
    local objective, completionType, zoneId, complete = getPinDetails(pin)
    if not objective then
        return
    end
    return zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString(SI_OPTIONS_RESET), objective.name)
end
function markPinComplete(pin)
    local objective, completionType, zoneId = getPinDetails(pin)
    if not objective then
        return
    end
    addon.Data:SetActivityComplete(zoneId, completionType, objective.activityIndex, true)
    addon.ZoneGuideTracker:UpdateUIAndAnnounce(objective, true)
end
function markPinIncomplete(pin)
    local objective, completionType, zoneId = getPinDetails(pin)
    if not objective then
        return
    end
    addon.Data:SetActivityComplete(zoneId, completionType, objective.activityIndex, false)
    addon.ZoneGuideTracker:UpdateUIAndAnnounce(objective, false)
    -- TODO: show reset message
end
function shouldPinShowCompletionMenu(pin)
    local poiIndex = pin:GetPOIIndex()
    if poiIndex == -1 then
        return
    end
    local objective = addon.ZoneGuideTracker:GetPOIObjective(nil, poiIndex)
    return objective ~= nil
end



-- Create singleton
addon.WorldMap = WorldMap:New()