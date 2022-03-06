--[[ 
]]--

local addon = CharacterZonesAndBosses
local COMPLETION_TYPES
local ZONE_ACTIVITY_NAME_MAX_LEVENSHTEIN_DISTANCE = 5
local ZoneGuideTracker = ZO_Object:Subclass()

local name = addon.name .. "ZoneGuideTracker"
local debug = true
local isPlayerNearObjective, matchPoiIndex


---------------------------------------
--
--       Constructors
-- 
---------------------------------------

function ZoneGuideTracker:New(...)
    local instance = ZO_Object.New(self)
    instance:Initialize(...)
    return instance
end

function ZoneGuideTracker:Initialize()
    self.name = name
    self.pointsOfInterest = {}
    self.objectives = {}
    self.achievements = {}
    self.delves = {}
    self.delveBossNames = {}
    --self.worldBossNames = {}
end



---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function ZoneGuideTracker:AnnounceCompletion(objective)
    local unitTag = "player"
    local level = GetUnitLevel(unitTag)
    local experience = GetUnitXP(unitTag)
    local championPoints = GetUnitChampionPoints(unitTag)
    local eventHandler = ZO_CenterScreenAnnounce_GetEventHandler(EVENT_OBJECTIVE_COMPLETED)
    local messageParams = eventHandler(objective.zoneIndex, objective.poiIndex, level, experience, experience, championPoints)
    CENTER_SCREEN_ANNOUNCE:DisplayMessage(messageParams)
end

function ZoneGuideTracker:DeactivateWorldEventInstance()
    if not self.activeWorldEvent then
        return
    end
    local activePoiIndex = self.activeWorldEvent.poiIndex
    local worldEventObjective = self:GetObjectivePlayerIsNear(ZONE_COMPLETION_TYPE_WORLD_EVENTS)
    if not worldEventObjective or worldEventObjective.poiIndex ~= activePoiIndex then
        return
    end
    -- Point of interest completed was the one the player is near.
    -- Save the progress
    ZO_ClearTable(self.activeWorldEvent)
    self.activeWorldEvent = nil
    local zoneId = GetZoneId(worldEventObjective.zoneIndex)
    addon.Utility.Debug("Setting world event  "..tostring(worldEventObjective.name) .. ", zone id: " .. tostring(zoneId) .. ", activityIndex: " .. tostring(worldEventObjective.activityIndex) .. " as complete.", debug)
    if addon.Data:SetActivityComplete(zoneId, ZONE_COMPLETION_TYPE_WORLD_EVENTS, worldEventObjective.activityIndex) then
        -- Announce it was complete and refresh UI
        self:UpdateUIAndAnnounce(worldEventObjective, true)
    end
end

function ZoneGuideTracker:FindBestZoneCompletionActivityNameMatch(zoneId, name, completionType, zoneIndex)
    local lowestLevenshteinDistance = ZONE_ACTIVITY_NAME_MAX_LEVENSHTEIN_DISTANCE + 1
    if not zoneIndex then
        zoneIndex = GetZoneIndex(zoneId)
    end
    local match
    for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
        local objective = self.objectives[zoneIndex][completionType][activityIndex]
        if objective then
            local levenshteinDistance = addon.Utility.Levenshtein(objective.name, name)
            if levenshteinDistance < lowestLevenshteinDistance then
                match = objective
                lowestLevenshteinDistance = levenshteinDistance
            end
        end
    end
    return match, lowestLevenshteinDistance
end

function ZoneGuideTracker:FindObjective(match, completionType, ...)
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex or not self.objectives[zoneIndex] then
        return
    end
    local objectivesList
    if completionType then
        objectivesList = { [completionType] = self.objectives[zoneIndex][completionType] }
    else
        objectivesList = self.objectives[zoneIndex]
    end
    for completionType, objectives in pairs(objectivesList) do
        for activityIndex, objective in ipairs(objectives) do
            if match(objective, zoneIndex, ...) then
                return objective, completionType
            end
        end
    end
end

function ZoneGuideTracker:GetObjectivePlayerIsNear(completionType)
    return self:FindObjective(isPlayerNearObjective, completionType)
end

function ZoneGuideTracker:GetPOIObjective(completionType, poiIndex)
    return self:FindObjective(matchPoiIndex, completionType, poiIndex)
end

function ZoneGuideTracker:InitializeAllZonesAsync(startZoneIndex)
    if self.allZonesInitialized then
        return
    end
    local timeout = 500
    local updateKey = addon.name .. ".ZoneGuideTracker.InitializeAllZones"
    EVENT_MANAGER:UnregisterForUpdate(updateKey)
    if not startZoneIndex then
        startZoneIndex = 1
    end
    for zoneIndex = startZoneIndex, startZoneIndex + 10 do
        if not self:InitializeZone(zoneIndex) then
            -- TODO: Raise callback for all zones initialized
            self.allZonesInitialized = true
            return
        end
    end
    EVENT_MANAGER:RegisterForUpdate(updateKey, timeout, function() self:InitializeAllZonesAsync(startZoneIndex + 11) end)
end

--[[  ]]--
function ZoneGuideTracker:InitializeZone(zoneIndex)
    if not zoneIndex or zoneIndex < 1 then
        return
    end
    
    local zoneId = GetZoneId(zoneIndex)
    if not zoneId or zoneId < 1 then
        return
    end
    local parentZoneId = GetParentZoneId(zoneId)
    
    local mapIndex = GetMapIndexByZoneId(zoneId)
    local _, mapType, mapContentType = GetMapInfo(mapIndex)
    
    if parentZoneId and parentZoneId > 0 and parentZoneId ~= zoneId then
        local parentZoneIndex = GetZoneIndex(parentZoneId)
        local delve = { zoneId = zoneId, zoneIndex = zoneIndex, name = GetZoneNameById(zoneId), parentZoneIndex = parentZoneIndex, mapType = mapType, mapContentType = mapContentType }
        self:InitializeZone(parentZoneIndex)
        if not self.objectives[parentZoneIndex] or not self.objectives[parentZoneIndex][ZONE_COMPLETION_TYPE_DELVES] then
            return true
        end
        local match, levenshteinDistance = self:FindBestZoneCompletionActivityNameMatch(parentZoneId, delve.name, ZONE_COMPLETION_TYPE_DELVES, parentZoneIndex)
        if match then
            if match.levenshteinDistance then
                if match.levenshteinDistance < levenshteinDistance then
                    return true
                end
                self.delves[match.delve.zoneIndex] = nil
                ZO_ClearTable(match.delve)
            end
            match.delve = delve
            match.levenshteinDistance = levenshteinDistance
            delve.objective = match
            self.delves[zoneIndex] = delve
        end
        return true
    end
    
    -- Zone is already initialized
    if self.pointsOfInterest[zoneIndex] then
        return true
    end
    local poiCount = GetNumPOIs(zoneIndex)
    if poiCount < 1 then
        return true
    end
    self.pointsOfInterest[zoneIndex] = {}
    for poiIndex = 1, poiCount do
        local poiName = GetPOIInfo(zoneIndex, poiIndex)
        if poiName and poiName ~= "" then
            self.pointsOfInterest[zoneIndex][poiName] = poiIndex
        end
    end
    self.objectives[zoneIndex] = {}
    local totalActivityCount = 0
    for completionType in pairs(COMPLETION_TYPES) do
        local activityCount = GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType)
        if activityCount > 0 then
            totalActivityCount = totalActivityCount + activityCount
            self.objectives[zoneIndex][completionType] = {}
            for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
                local objective = { name = GetZoneStoryActivityNameByActivityIndex(zoneId, completionType, activityIndex), zoneIndex = zoneIndex, activityIndex = activityIndex }
                objective.poiIndex = self.pointsOfInterest[zoneIndex][objective.name]
                objective.mapPinType = select(3, GetPOIMapInfo(zoneIndex, objective.poiIndex))
                if completionType == ZONE_COMPLETION_TYPE_WORLD_EVENTS then
                    if objective.poiIndex then
                        local worldEventInstanceId = GetPOIWorldEventInstanceId(zoneIndex, objective.poiIndex)
                        if worldEventInstanceId and worldEventInstanceId > 0 then
                            objective.worldEventInstanceId = worldEventInstanceId
                            self:SetActiveWorldEventInstanceId(worldEventInstanceId)
                        end
                    end
                end
                self.objectives[zoneIndex][completionType][activityIndex] = objective
            end
        end
    end
    -- Trim empty
    if totalActivityCount == 0 then
        self.objectives[zoneIndex] = nil
    end
    return true
end

function ZoneGuideTracker:GetObjectives(zoneIndex, completionType)
    self:InitializeZone(zoneIndex)
    return self.objectives[zoneIndex][completionType]
end

function ZoneGuideTracker:IsCompletionTypeTracked(completionType)
    return COMPLETION_TYPES[completionType]
end

function ZoneGuideTracker:UpdateUIAndAnnounce(objective, complete)
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
        addon.ZoneGuideTracker:AnnounceCompletion(objective)
    end
end

function ZoneGuideTracker:RegisterDelveKill(name)
    
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex then
        return
    end
    local delve = self.delves[zoneIndex]
    if not delve or not IsUnitInDungeon("player") then
        return
    end
    
    local zoneId = GetZoneId(zoneIndex)
    if addon.MultiBossDelves:IsZoneMultiBossDelve(zoneId) then
        addon.MultiBossDelves:RegisterBossKill(zoneId, name)
        if not addon.MultiBossDelves:AreAllBossesKilled(zoneId) then
            return
        end
        
    elseif not name or not self.delveBossNames[name] then
        addon.Utility.Debug("Not registering delve kill for "..tostring(delve.name) .. ", zone id: " .. delve.zoneId .. " because target name " .. tostring(name) .. " is not found in the known delve boss names list.", debug)
        return
    end
    
    local parentZoneId = GetZoneId(delve.parentZoneIndex)
    addon.Utility.Debug("Setting delve "..tostring(delve.name) .. ", zone id: " .. delve.zoneId .. " as complete.", debug)
    if addon.Data:SetActivityComplete(parentZoneId, ZONE_COMPLETION_TYPE_DELVES, delve.objective.activityIndex) then
        -- Announce it was complete and refresh UI
        self:UpdateUIAndAnnounce(delve.objective, true)
    end
    return true
end

function ZoneGuideTracker:RegisterWorldBossKill(experienceUpdateReason)
    
    -- Ignore non-delve boss XP increase kills
    if experienceUpdateReason ~= PROGRESS_REASON_OVERLAND_BOSS_KILL then
        return
    end
    
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex then
        return
    end
    -- Must be in overland
    if IsUnitInDungeon("player") then
        return
    end
    
    local worldBossObjective = self:GetObjectivePlayerIsNear(ZONE_COMPLETION_TYPE_GROUP_BOSSES)
    if not worldBossObjective then
        return
    end
    
    local zoneId = GetZoneId(zoneIndex)
    addon.Utility.Debug("Setting world boss "..tostring(worldBossObjective.name) .. ", zone id: " .. zoneId .. " as complete.", debug)
    if addon.Data:SetActivityComplete(zoneId, ZONE_COMPLETION_TYPE_GROUP_BOSSES, worldBossObjective.activityIndex) then
        -- Announce it was complete and refresh UI
        self:UpdateUIAndAnnounce(worldBossObjective, true)
    end
    return true
end

function ZoneGuideTracker:RegisterDelveBossName(name)
    self.delveBossNames[name] = true
end

--[[function ZoneGuideTracker:RegisterWorldBossName(name)
    self.worldBossNames[name] = true
end]]

function ZoneGuideTracker:SetActiveWorldEventInstanceId(worldEventInstanceId)
    if not worldEventInstanceId or worldEventInstanceId <= 0 then
        return
    end
    if self.activeWorldEvent then
        ZO_ClearTable(self.activeWorldEvent)
    end
    local zoneIndex, poiIndex = GetWorldEventPOIInfo(worldEventInstanceId)
    local objectiveName = GetPOIInfo(zoneIndex, poiIndex)
    self.activeWorldEvent = {
        instanceId = worldEventInstanceId,
        objectiveName = objectiveName,
        zoneIndex = zoneIndex,
        poiIndex = poiIndex,
    }
end



---------------------------------------
--
--          Private Members
-- 
---------------------------------------

COMPLETION_TYPES = {
    [ZONE_COMPLETION_TYPE_DELVES] = true, -- IsUnitInDungeon("player") == true
    [ZONE_COMPLETION_TYPE_GROUP_BOSSES] = true,
    [ZONE_COMPLETION_TYPE_WORLD_EVENTS] = true,
}

function isPlayerNearObjective(objective, zoneIndex)
    local isNearby = select(8, GetPOIMapInfo(zoneIndex, objective.poiIndex))
    if isNearby then
        return true
    end
end

function matchPoiIndex(objective, zoneIndex, poiIndex)
    return objective.poiIndex == poiIndex
end


-- Create singleton instance
addon.ZoneGuideTracker = ZoneGuideTracker:New()