--[[ 
    ===================================
            GAME CLIENT EVENTS 
    ===================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = false
local DELVE_BOSS_MAX_HP = 133844
local BOSS_KILL_REASONS = { [PROGRESS_REASON_BOSS_KILL] = true, [PROGRESS_REASON_OVERLAND_BOSS_KILL] = true }

-- Singleton class
local Events = ZO_Object:Subclass()

function Events:New()
    return ZO_Object.New(self)
end

function Events:Initialize()
  
    if GetAPIVersion() >= 101033 then
        self.handlerNames = {
            --[EVENT_CLIENT_INTERACT_RESULT]     = "ClientInteractResult",
            [EVENT_COMBAT_EVENT]               = "CombatEvent",
            [EVENT_EXPERIENCE_UPDATE]          = "ExperienceUpdate",
            [EVENT_OBJECTIVE_COMPLETED]        = "ObjectiveCompleted",
            [EVENT_POIS_INITIALIZED]           = "POIsInitialized",
            [EVENT_PLAYER_ACTIVATED]           = "PlayerActivated",
            [EVENT_POWER_UPDATE]               = "PowerUpdate",
            [EVENT_TRACKED_ZONE_STORY_ACTIVITY_COMPLETED] = "TrackedZoneStoryActivityCompleted",
            --[EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED] = "UnitAttributeVisualAdded",
            --[EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED] = "UnitAttributeVisualRemoved",
            --[EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED] = "UnitAttributeVisualUpdated",
            [EVENT_WORLD_EVENT_UNIT_DESTROYED] = "WorldEventUnitDestroyed",
            [EVENT_WORLD_EVENT_ACTIVATED]      = "WorldEventActivated",
            [EVENT_WORLD_EVENT_ACTIVE_LOCATION_CHANGED] = "WorldEventActiveLocationChanged",
            [EVENT_WORLD_EVENT_DEACTIVATED]    = "WorldEventDeactivated",
            [EVENT_ZONE_CHANGED]               = "ZoneChanged",
            [EVENT_ZONE_UPDATE]                = "ZoneUpdate",
        }
    else
        self.handlerNames = {
            [EVENT_ACHIEVEMENT_AWARDED]        = "AchievementAwarded",
            [EVENT_TRACKED_ZONE_STORY_ACTIVITY_COMPLETED] = "TrackedZoneStoryActivityCompleted"
        }
    end
    
    for event, handlerName in pairs(self.handlerNames) do
        EVENT_MANAGER:RegisterForEvent(addon.name .. handlerName, event, self:Closure(handlerName))
    end
    
    if GetAPIVersion() >= 101033 then
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_TARGET_DEAD)
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
        EVENT_MANAGER:RegisterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, self:Closure("CombatEvent"))
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED_XP)
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "ExperienceUpdate", EVENT_ZONE_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "PowerUpdate", EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG, "reticleover")
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "PowerUpdate", EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH)
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "ZoneUpdate", EVENT_ZONE_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        -- We are only interested in ACTION_RESULT_DIED combat events
        --EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED)
        --EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")
        --EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
    end
end



---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function Events:AchievementAwarded(eventCode, name, points, id, link)
    addon.Utility.Debug("EVENT_ACHIEVEMENT_AWARDED(" .. tostring(eventCode) .. ", "..tostring(name) .. ", "..tostring(points) .. ", "..tostring(id) .. ", "..tostring(link) .. ")", debug)
end

function Events:ClientInteractResult(eventCode, result, interactTargetName)
    addon.Utility.Debug("EVENT_CLIENT_INTERACT_RESULT(" .. tostring(eventCode) .. ", "..tostring(result) .. ", "..tostring(interactTargetName), debug)
end

function Events:Closure(functionName)
    return function(...)
        self[functionName](self, ...)
    end
end

--[[  ]]
function Events:CombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId, overflow)
    if addon.ZoneGuideTracker:RegisterKill(targetName) then
        addon.Utility.Debug("EVENT_COMBAT_EVENT(" .. tostring(eventCode) .. ", result: "..tostring(result) .. ", isError: "..tostring(isError) 
            .. ", sourceName: "..tostring(sourceName) .. ", sourceType: " .. tostring(sourceType) .. ", targetName: "..tostring(targetName) .. ", targetType: "..tostring(targetType) 
            .. ", source: "..tostring(sourceUnitId) .. ", target: "..tostring(targetUnitId)
            .. ", sourceDifficulty: "..tostring(sourceUnitDifficulty) .. ", targetDifficulty: "..tostring(targetUnitDifficulty).. ")", debug)
    end
end

--[[  ]]
function Events:ExperienceUpdate(eventCode, unitTag, currentExp, maxExp, reason)
    if not BOSS_KILL_REASONS[reason] then
        return
    end
    local unitName = GetUnitName(unitTag)
    if addon.ZoneGuideTracker:RegisterKill(nil, reason) then
        addon.Utility.Debug("EVENT_EXPERIENCE_UPDATE(" .. tostring(eventCode) .. ", unitTag: "..tostring(unitTag) .. ", unitName: "..tostring(unitName) .. ", currentExp: "..tostring(currentExp) .. ", maxExp: " .. tostring(maxExp) .. ", reason: " .. tostring(reason) .. ")", debug)
    end
end

--[[  ]]
function Events:ObjectiveCompleted (eventCode, zoneIndex, poiIndex, level, previousExperience, currentExperience, championPoints)
    local zoneId = GetZoneId(zoneIndex)
    addon.Utility.Debug("EVENT_OBJECTIVE_COMPLETED(" .. tostring(eventCode) .. ", zoneIndex: "..tostring(zoneIndex) .. ", zoneId: "..tostring(zoneId) .. ", poiIndex: "..tostring(poiIndex) .. ", level: " .. tostring(level) ..", previousExperience: " .. tostring(previousExperience) ..", currentExperience: " .. tostring(currentExperience) ..", championPoints: " .. tostring(championPoints)  .. ")", debug)
end

--[[  ]]
function Events:PlayerActivated(eventCode, initial)
    local zoneIndex = GetCurrentMapZoneIndex()
    local zoneId = GetZoneId(zoneIndex)
    addon.Utility.Debug("EVENT_PLAYER_ACTIVATED(" .. tostring(eventCode) .. ", "..tostring(initial) .. ", zoneId: "..tostring(zoneId) .. ", zoneIndex: "..tostring(zoneIndex) .. ")", debug)
    addon.ZoneGuideTracker:InitializeZone(zoneIndex)
end

--[[  ]]
function Events:PowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
    if powerMax < DELVE_BOSS_MAX_HP then
        return
    end
    local unitName = GetUnitName(unitTag)
    if powerMax == DELVE_BOSS_MAX_HP then
        addon.ZoneGuideTracker:RegisterDelveBossName(unitName)
    elseif IsUnitInDungeon("player") then
        return
    else
        addon.ZoneGuideTracker:RegisterWorldBossName(unitName)
    end
    addon.Utility.Debug("EVENT_POWER_UPDATE(" .. tostring(eventCode) .. ", unitTag: "..tostring(unitTag) .. ", unitName: "..tostring(unitName) .. ", powerIndex: "..tostring(powerIndex) .. ", powerType: " .. tostring(powerType) .. ", powerValue: " .. tostring(powerValue) .. ", powerMax: " .. tostring(powerMax) .. ", powerEffectiveMax: " .. tostring(powerEffectiveMax) .. ")", debug)
end

function Events:TrackedZoneStoryActivityCompleted(eventCode, zoneId, zoneCompletionType, activityId)
    addon.Utility.Debug("EVENT_TRACKED_ZONE_STORY_ACTIVITY_COMPLETED(" .. tostring(eventCode) .. ", "..tostring(zoneId) .. ", "..tostring(zoneCompletionType) .. ", "..tostring(activityId) .. ")", debug)
end

function Events:UnitAttributeVisualAdded(eventCode, unitTag, unitAttributeVisual, statType, attributeType, powerType, value, maxValue, sequenceId)
    addon.Utility.Debug("EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED(" .. tostring(eventCode) .. ", unitTag: "..tostring(unitTag) .. ", unitAttributeVisual: "..tostring(unitAttributeVisual) .. ", statType: "..tostring(statType) .. ", attributeType: "..tostring(attributeType) .. ", powerType: "..tostring(powerType) .. ", value: "..tostring(value) .. ", maxValue: "..tostring(maxValue) .. ", sequenceId: "..tostring(sequenceId) .. ")", debug)
end

function Events:UnitAttributeVisualRemoved(eventCode, unitTag, unitAttributeVisual, statType, attributeType, powerType, value, maxValue, sequenceId)
    addon.Utility.Debug("EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED("  .. tostring(eventCode) .. ", unitTag: "..tostring(unitTag) .. ", unitAttributeVisual: "..tostring(unitAttributeVisual) .. ", statType: "..tostring(statType) .. ", attributeType: "..tostring(attributeType) .. ", powerType: "..tostring(powerType) .. ", value: "..tostring(value) .. ", maxValue: "..tostring(maxValue) .. ", sequenceId: "..tostring(sequenceId) .. ")", debug)
end

function Events:UnitAttributeVisualUpdated(eventCode, unitTag, unitAttributeVisual, statType, attributeType, powerType, oldValue, newValue, oldMaxValue, newMaxValue, sequenceId)
    addon.Utility.Debug("EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED(" .. tostring(eventCode) .. ", unitTag: "..tostring(unitTag) .. ", unitAttributeVisual: "..tostring(unitAttributeVisual) .. ", statType: "..tostring(statType) .. ", attributeType: "..tostring(attributeType) .. ", powerType: "..tostring(powerType) .. ", oldValue: "..tostring(oldValue) .. ", newValue: "..tostring(newValue) .. ", oldMaxValue: "..tostring(oldMaxValue) .. ", newMaxValue: "..tostring(newMaxValue) .. ", sequenceId: "..tostring(sequenceId) .. ")", debug)
end

--[[  ]]
function Events:WorldEventActivated(eventCode, worldEventInstanceId)
    addon.Utility.Debug("EVENT_WORLD_EVENT_ACTIVATED(" .. tostring(eventCode) .. ", "..tostring(worldEventInstanceId) .. ")", debug)
    addon.ZoneGuideTracker:SetActiveWorldEventInstanceId(worldEventInstanceId)
end

--[[  ]]
function Events:WorldEventActiveLocationChanged(eventCode, worldEventInstanceId, oldWorldEventLocationId, newWorldEventLocationId)
    addon.Utility.Debug("EVENT_WORLD_EVENT_ACTIVE_LOCATION_CHANGED(" .. tostring(eventCode) .. ", "..tostring(worldEventInstanceId) .. ", "..tostring(oldWorldEventLocationId) .. ", "..tostring(newWorldEventLocationId) .. ")", debug)
    addon.ZoneGuideTracker:SetActiveWorldEventInstanceId(worldEventInstanceId)
end

--[[  ]]
function Events:WorldEventDeactivated(eventCode, worldEventInstanceId)
    -- Say the character is standing near another dolmen when one across the world completes.
    addon.Utility.Debug("EVENT_WORLD_EVENT_DEACTIVATED(" .. tostring(eventCode) .. ", "..tostring(worldEventInstanceId) .. ")", debug)
    addon.ZoneGuideTracker:DeactivateWorldEventInstance()
end

--[[  ]]
function Events:WorldEventUnitDestroyed(eventCode, worldEventInstanceId, unitTag)
    local zoneIndex, poiIndex = GetWorldEventPOIInfo(worldEventInstanceId)
    local xLoc, zLoc, poiPinType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
    local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
    addon.Utility.Debug("EVENT_WORLD_EVENT_UNIT_DESTROYED(" .. tostring(eventCode) .. ", "..tostring(worldEventInstanceId) .. ", "..tostring(unitTag) .. ", poiPinType: "..tostring(poiPinType) .. ", icon: "..tostring(icon) .. ", isShownInCurrentMap: "..tostring(isShownInCurrentMap) .. ", isNearby: "..tostring(isNearby) .. ", objectiveName: "..tostring(objectiveName) .. ")", debug)
end

--[[  ]]
function Events:ZoneChanged(eventCode, zoneName, subZoneName, newSubzone, zoneId, subZoneId)
    if newSubzone or zoneId == 0 then
        return
    end
    local zoneIndex = GetZoneIndex(zoneId)
    addon.Utility.Debug("EVENT_ZONE_CHANGED(" .. tostring(zoneName) .. ", "..tostring(subZoneName) .. ", "..tostring(newSubzone) .. ", zoneId: "..tostring(zoneId) .. ", subZoneId: "..tostring(subZoneId) .. ")", debug)
    addon.ZoneGuideTracker:InitializeZone(zoneIndex)
end

--[[  ]]
function Events:ZoneUpdate(eventCode, unitTag, newZoneName)
    local zoneIndex = GetCurrentMapZoneIndex()
    local zoneId = GetZoneId(zoneIndex)
    addon.Utility.Debug("EVENT_ZONE_UPDATE(" .. tostring(newZoneName) .. ", zoneId: "..tostring(zoneId) .. ", zoneIndex: "..tostring(zoneIndex) .. ")", debug)
    addon.ZoneGuideTracker:InitializeZone(zoneIndex)
end

-- Create singleton
addon.Events = Events:New()