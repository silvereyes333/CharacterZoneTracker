--[[ 
]]--

local addon = CharacterZonesAndBosses
local COMPLETION_TYPES
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
    self.worldBossNames = {}
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

--[[  ]]--
function ZoneGuideTracker:InitializeZone(zoneIndex, isParentZone)
    if not zoneIndex then
        return
    end
    
    local zoneId = GetZoneId(zoneIndex)
    local parentZoneId = GetParentZoneId(zoneId)
    
    if not isParentZone and parentZoneId and parentZoneId > 0 and IsUnitInDungeon("player") then
        local parentZoneIndex = GetZoneIndex(parentZoneId)
        local delve = { zoneId = zoneId, zoneIndex = zoneIndex, name = GetZoneNameById(zoneId), parentZoneIndex = parentZoneIndex }
        self:InitializeZone(parentZoneIndex, true)
        for activityIndex = 1, #self.objectives[parentZoneIndex][ZONE_COMPLETION_TYPE_DELVES] do
            local objective = self.objectives[parentZoneIndex][ZONE_COMPLETION_TYPE_DELVES][activityIndex]
            if objective.name == delve.name then
                objective.delve = delve
                delve.objective = objective
                break
            end
        end
        self.delves[zoneIndex] = delve
        return
    end
    
    -- Zone is already initialized
    if self.pointsOfInterest[zoneIndex] then
        return
    end
    self.pointsOfInterest[zoneIndex] = {}
    self.objectives[zoneIndex] = {}
    self.achievements[zoneIndex] = {}
    for poiIndex = 1, GetNumPOIs(zoneIndex) do
        self.pointsOfInterest[zoneIndex][GetPOIInfo(zoneIndex, poiIndex)] = poiIndex
    end
    for completionType in pairs(COMPLETION_TYPES) do
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
        self.achievements[zoneIndex][completionType] = {}
        for achievementIndex = 1, GetNumAssociatedAchievementsForZoneCompletionType(zoneId, completionType) do
            self.achievements[zoneIndex][completionType][achievementIndex] = GetAssociatedAchievementIdForZoneCompletionType(zoneId, completionType, achievementIndex)
        end
    end
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

function ZoneGuideTracker:RegisterKill(name, experienceUpdateReason)
    
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex then
        return
    end
    local delve = self.delves[zoneIndex]
    if delve then
        -- Ignore non-overland boss XP increase kills
        if experienceUpdateReason and experienceUpdateReason ~= PROGRESS_REASON_OVERLAND_BOSS_KILL then
            addon.Utility.Debug("Not registering XP increase for "..tostring(delve.name) .. ", zone id: " .. delve.zoneId .. " because XP reason " .. tostring(experienceUpdateReason) .. " ~= " .. tostring(PROGRESS_REASON_OVERLAND_BOSS_KILL) .. ".", debug)
            return
        -- Ignore non-worldbosses
        elseif name and not self.delveBossNames[name] then
            addon.Utility.Debug("Not registering XP increase for "..tostring(delve.name) .. ", zone id: " .. delve.zoneId .. " because target name " .. tostring(name) .. " is not found in the known delve boss names list.", debug)
            return
        end
        local zoneId = GetZoneId(delve.parentZoneIndex)
        addon.Utility.Debug("Setting delve "..tostring(delve.name) .. ", zone id: " .. delve.zoneId .. " as complete.", debug)
        if addon.Data:SetActivityComplete(zoneId, ZONE_COMPLETION_TYPE_DELVES, delve.objective.activityIndex) then
            -- Announce it was complete and refresh UI
            self:UpdateUIAndAnnounce(delve.objective, true)
        end
        return true
    end
    
    if IsUnitInDungeon("player") then
        -- TODO: add dungeon boss tracking
        return
    end
    
    local worldBossObjective = self:GetObjectivePlayerIsNear(ZONE_COMPLETION_TYPE_GROUP_BOSSES)
    if worldBossObjective then
        -- Ignore non-delve boss XP increase kills
        if experienceUpdateReason and experienceUpdateReason ~= PROGRESS_REASON_OVERLAND_BOSS_KILL then
            return
        -- Ignore non-delve boss kills
        elseif not self.worldBossNames[name] then
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
end

function ZoneGuideTracker:RegisterDelveBossName(name)
    self.delveBossNames[name] = true
end

function ZoneGuideTracker:RegisterWorldBossName(name)
    self.worldBossNames[name] = true
end

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