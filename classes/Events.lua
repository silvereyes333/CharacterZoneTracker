--[[ 
    ===================================
            GAME CLIENT EVENTS 
    ===================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = true

-- Singleton class
local Events = ZO_Object:Subclass()

function Events:New()
    return ZO_Object.New(self)
end

function Events:Initialize()
  
    if GetAPIVersion() >= 101033 then
        self.handlerNames = {
            [EVENT_CLIENT_INTERACT_RESULT]     = "ClientInteractResult",
            [EVENT_COMBAT_EVENT]               = "CombatEvent",
            [EVENT_OBJECTIVE_COMPLETED]        = "ObjectiveCompleted",
            [EVENT_POIS_INITIALIZED]           = "POIsInitialized",
            [EVENT_PLAYER_ACTIVATED]           = "PlayerActivated",
            [EVENT_WORLD_EVENT_UNIT_DESTROYED] = "WorldEventUnitDestroyed",
            [EVENT_WORLD_EVENT_ACTIVATED]      = "WorldEventActivated",
            [EVENT_WORLD_EVENT_ACTIVE_LOCATION_CHANGED] = "WorldEventActiveLocationChanged",
            [EVENT_WORLD_EVENT_DEACTIVATED]    = "WorldEventDeactivated",
            [EVENT_TRACKED_ZONE_STORY_ACTIVITY_COMPLETED] = "TrackedZoneStoryActivityCompleted",
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
        EVENT_MANAGER:RegisterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, self:Closure("CombatEvent"))
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED_XP)
        EVENT_MANAGER:AddFilterForEvent(addon.name .. "ZoneUpdate", EVENT_ZONE_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        -- We are only interested in ACTION_RESULT_DIED combat events
        --EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED)
        --EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")
        --EVENT_MANAGER:AddFilterForEvent(addon.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
    end
end
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
    if result == ACTION_RESULT_EFFECT_GAINED or result == ACTION_RESULT_EFFECT_FADED or result == ACTION_RESULT_BEGIN then
        return
    end
    if targetType ~= 0 then
        return
    end
    local sourceUnitDifficulty = GetUnitDifficulty(sourceUnitId)
    local targetUnitDifficulty = GetUnitDifficulty(targetUnitId)
    addon.Utility.Debug("EVENT_COMBAT_EVENT(" .. tostring(eventCode) .. ", result: "..tostring(result) .. ", isError: "..tostring(isError) 
        .. ", sourceName: "..tostring(sourceName) .. ", sourceType: " .. tostring(sourceType) .. ", targetName: "..tostring(targetName) .. ", targetType: "..tostring(targetType) 
        .. ", source: "..tostring(sourceUnitId) .. ", target: "..tostring(targetUnitId)
        .. ", sourceDifficulty: "..tostring(sourceUnitDifficulty) .. ", targetDifficulty: "..tostring(targetUnitDifficulty).. ")", debug)
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
    addon.Utility.Debug("EVENT_PLAYER_ACTIVATED(" .. tostring(eventCode) .. ", "..tostring(initial) .. ", zoneId: "..tostring(zoneId) .. ", zoneIndex: "..tostring(zoneIndex) .. ", addon: " .. tostring(addon) ..", addon.ZoneGuideTracker: " .. tostring(addon.ZoneGuideTracker) .. ")", debug)
    addon.ZoneGuideTracker:SetZoneIndex(zoneIndex)
end

--[[  ]]
function Events:POIsInitialized(eventCode)
    local zoneIndex = GetCurrentMapZoneIndex()
    local zoneId = GetZoneId(zoneIndex)
    local numPOIs = GetNumPOIs(zoneIndex)
    addon.Utility.Debug("EVENT_POIS_INITIALIZED(" .. tostring(eventCode) .. ", zoneId: "..tostring(zoneId) .. ", zoneIndex: "..tostring(zoneIndex) ", numPOIs: " .. tostring(numPOIs) .. ")", debug)
end

function Events:TrackedZoneStoryActivityCompleted(eventCode, zoneId, zoneCompletionType, activityId)
    addon.Utility.Debug("EVENT_TRACKED_ZONE_STORY_ACTIVITY_COMPLETED(" .. tostring(eventCode) .. ", "..tostring(zoneId) .. ", "..tostring(zoneCompletionType) .. ", "..tostring(activityId) .. ")", debug)
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
    addon.ZoneGuideTracker:SetActiveWorldEventInstanceId(worldEventInstanceId)
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
    addon.ZoneGuideTracker:SetZoneIndex(zoneIndex)
end

--[[  ]]
function Events:ZoneUpdate(eventCode, unitTag, newZoneName)
    local zoneIndex = GetCurrentMapZoneIndex()
    local zoneId = GetZoneId(zoneIndex)
    addon.Utility.Debug("EVENT_ZONE_UPDATE(" .. tostring(newZoneName) .. ", zoneId: "..tostring(zoneId) .. ", zoneIndex: "..tostring(zoneIndex) .. ")", debug)
    addon.ZoneGuideTracker:SetZoneIndex(zoneIndex)
end

-- Create singleton
addon.Events = Events:New()



--[[

* EVENT_ACHIEVEMENTS_COMPLETED_ON_UPGRADE_TO_ACCOUNT_WIDE (*integer* _numAchievementsCompleteOnUpgrade_)


 EVENT_UNIT_DESTROYED (number eventCode, string unitTag)

 GetUnitDifficulty(string unitTag)
Returns: number UIMonsterDifficulty difficult

UIMonsterDifficulty
MONSTER_DIFFICULTY_DEADLY
MONSTER_DIFFICULTY_EASY
MONSTER_DIFFICULTY_HARD
MONSTER_DIFFICULTY_NONE
MONSTER_DIFFICULTY_NORMAL

Search on ESOUI Source Code GetUnitType(string unitTag)
Returns: number type
Search on ESOUI Source Code GetUnitWorldPosition(string unitTag)
Returns: number zoneId, number worldX, number worldY, number worldZ
Search on ESOUI Source Code GetUnitZoneIndex(string unitTag)
Returns: number:nilable zoneIndex
Search on ESOUI Source Code GetZoneId(number zoneIndex)
Returns: number zoneId
Search on ESOUI Source Code GetZoneIndex(number zoneId)
Returns: number zoneIndex
Search on ESOUI Source Code GetZoneNameById(number zoneId)
Returns: string name


EVENT_WORLD_EVENT_UNIT_DESTROYED (number eventCode, number worldEventInstanceId, string unitTag)

Search on ESOUI Source Code GetWorldEventId(number worldEventInstanceId)
Returns: number worldEventId
Search on ESOUI Source Code GetWorldEventInstanceUnitPinType(number worldEventInstanceId, string unitTag)
Returns: number MapDisplayPinType pinType
Search on ESOUI Source Code GetWorldEventInstanceUnitTag(number worldEventInstanceId, number unitIndex)
Returns: string unitTag
Search on ESOUI Source Code GetWorldEventType(number worldEventId)
Returns: number WorldEventType worldEventType


* GetAchievementPersistenceLevel(*integer* _achievementId_)
** _Returns:_ *[AchievementPersistenceLevel|#AchievementPersistenceLevel]* _persistenceLevel_

* GetCharIdForCompletedAchievement(*integer* _achievementId_)
** _Returns:_ *id64* _charId_

* GetSkyshardAchievementZoneId(*integer* _achievementId_)
** _Returns:_ *integer* _zoneId_

 GetAssociatedAchievementIdForZoneCompletionType(number zoneId, number ZoneCompletionType zoneCompletionType, number associatedAchievementIndex)
Returns: number associatedAchievementId 
      GetNumAssociatedAchievementsForZoneCompletionType(number zoneId, number ZoneCompletionType zoneCompletionType)
Returns: number numAssociatedAchievements
    GetRecentlyCompletedAchievements(number numAchievementsToGet)
Uses variable returns...
Returns: number achievementId

Search on ESOUI Source Code GetMarketProductUnlockedByAchievementInfo(number marketProductId)
Returns: number achievementId, boolean hasCompletedAchievement, number:nilable helpCategoryIndex, number:nilable helpIndex

Search on ESOUI Source Code IsPlayerInsidePinArea(number MapDisplayPinType pinType, number param1, number param2, number param3)
Search on ESOUI Source Code GetMapLocationTooltipLineInfo(number locationIndex, number tooltipLineIndex)
Returns: textureName icon, string name, number grouping, string categoryName

Search on ESOUI Source Code GetNumMapLocationTooltipLines(number locationIndex)
 GetMapLocationTooltipHeader(number locationIndex)
 
 /script d(GetMapLocationTooltipHeader(1))
]]--