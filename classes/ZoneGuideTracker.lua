--[[ 
]]--

local addon = CharacterZonesAndBosses
local COMPLETION_TYPES
local ZoneGuideTracker = ZO_Object:Subclass()

local name = addon.name .. "ZoneGuideTracker"

function ZoneGuideTracker:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end

function ZoneGuideTracker:Initialize()
    self.name = name
end

function ZoneGuideTracker:GetObjectivePlayerIsNear()
    if not self.zoneIndex or not self.objectives then
        return
    end
    for completionType, objectives in pairs(self.objectives) do
        for activityIndex, objective in ipairs(objectives) do
            local isNearby = select(8, GetPOIMapInfo(self.zoneIndex, objective.poiIndex))
            if isNearby then
                return objective
            end
        end
    end
end

function ZoneGuideTracker:SetActiveWorldEventInstanceId(worldEventInstanceId)
    local activePoiIndex
    if self.activeWorldEvent then
        activePoiIndex = self.activeWorldEvent.poiIndex
        ZO_ClearTable(self.activeWorldEvent)
    end
    if worldEventInstanceId then
        local zoneIndex, poiIndex = GetWorldEventPOIInfo(worldEventInstanceId)
        local objectiveName = GetPOIInfo(zoneIndex, poiIndex)
        self.activeWorldEvent = {
            instanceId = worldEventInstanceId,
            objectiveName = objectiveName,
            zoneIndex = zoneIndex,
            poiIndex = poiIndex,
        }
    elseif self.activeWorldEvent then
        self.activeWorldEvent = nil
        local objective = ZoneGuideTracker:GetObjectivePlayerIsNear()
        if not objective or objective.poiIndex ~= activePoiIndex then
            return
        end
        -- Point of interest completed was the one the player is near. Announce it was complete.
        local announce = ZO_CenterScreenAnnounce_GetEventHandler(EVENT_OBJECTIVE_COMPLETED)
        announce(self.zoneIndex, objective.poiIndex)
    end
end

--[[  ]]--
function ZoneGuideTracker:SetZoneIndex(zoneIndex)
    self.zoneIndex = zoneIndex
    self.zoneId = GetZoneId(zoneIndex)
    if self.pointsOfInterest then
        ZO_ClearTable(self.pointsOfInterest)
    end
    self.pointsOfInterest = {}
    if self.objectives then
        ZO_ClearTableWithCallback(self.objectives, ZO_ClearTable)
    end
    self.objectives = {}
    if self.achievements then
        ZO_ClearTableWithCallback(self.achievements, ZO_ClearTable)
    end
    self.achievements = {}
    if not self.zoneId then
        return
    end
    for poiIndex = 1, GetNumPOIs(zoneIndex) do
        self.pointsOfInterest[GetPOIInfo(zoneIndex, poiIndex)] = poiIndex
    end
    for completionType in pairs(COMPLETION_TYPES) do
        self.objectives[completionType] = {}
        for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(self.zoneId, completionType) do
            local objective = { name = GetZoneStoryActivityNameByActivityIndex(self.zoneId, completionType, activityIndex) }
            objective.poiIndex = self.pointsOfInterest[objective.name]
            if objective.poiIndex then
                local normalizedX, normalizedZ = GetPOIMapInfo(zoneIndex, objective.poiIndex)
                objective.mapPin = { x = normalizedX, z = normalizedZ }
                objective.worldEventInstanceId = GetPOIWorldEventInstanceId(zoneIndex, objective.poiIndex)
                if objective.worldEventInstanceId then
                    self:SetActiveWorldEventInstanceId(objective.worldEventInstanceId)
                end
            end
            self.objectives[completionType][activityIndex] = objective
        end
        self.achievements[completionType] = {}
        for achievementIndex = 1, GetNumAssociatedAchievementsForZoneCompletionType(self.zoneId, completionType) do
            self.achievements[completionType][achievementIndex] = GetAssociatedAchievementIdForZoneCompletionType(self.zoneId, completionType, achievementIndex)
        end
    end
end


COMPLETION_TYPES = {
    [ZONE_COMPLETION_TYPE_DELVES] = true,
    [ZONE_COMPLETION_TYPE_GROUP_BOSSES] = true,
    [ZONE_COMPLETION_TYPE_WORLD_EVENTS] = true,
}

addon.ZoneGuideTracker = ZoneGuideTracker:New()