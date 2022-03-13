--[[ 
]]--

local addon = CharacterZoneTracker
local COMPLETION_TYPES = addon:GetCompletionTypes()
local ZONE_ACTIVITY_NAME_MAX_LEVENSHTEIN_DISTANCE = 5
local FIRST_ZONE_ID_WITH_DELVE_BOSS_UNIT_TAGS = 589
local ZoneGuideTracker = ZO_Object:Subclass()

local className = addon.name .. "ZoneGuideTracker"
local debug = false
local isPlayerNearObjective, matchObjectiveName, matchPoiIndex


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
    self.name = className
    self.pointsOfInterest = {}
    self.objectives = {}
    self.dangerousMonsterNames = {}
    self.delves = {}
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

function ZoneGuideTracker:ClearActiveWorldEventInstance()
    if not self.activeWorldEvent then
        return
    end
    ZO_ClearTable(self.activeWorldEvent)
    self.activeWorldEvent = nil
end

function ZoneGuideTracker:DeactivateWorldEventInstance()
    if not self.activeWorldEvent then
        addon.Utility.Debug("No active world event instance being tracked. Cannot mark it complete.", debug)
        return
    end
    addon.Utility.Debug("Deactivating active world event poiIndex " .. tostring(self.activeWorldEvent.poiIndex), debug)
    local activePoiIndex = self.activeWorldEvent.poiIndex
    local worldEventObjective = self:GetObjectivePlayerIsNearest(ZONE_COMPLETION_TYPE_WORLD_EVENTS)
    if not worldEventObjective then
        addon.Utility.Debug("Not completing world event, because none are nearby.", debug)
        return
    elseif worldEventObjective.poiIndex ~= activePoiIndex then
        addon.Utility.Debug("The nearest world event objective, " .. tostring(worldEventObjective.name) .. " has a poiIndex of " .. tostring(worldEventObjective.poiIndex) .. ". Exiting.", debug)
        return
    end
    -- Point of interest completed was the one the player is near.
    -- Save the progress
    ZO_ClearTable(self.activeWorldEvent)
    self.activeWorldEvent = nil
    local zoneId = GetZoneId(worldEventObjective.zoneIndex)
    
    local completedBefore = addon.Data:IsActivityCompletedOnAccount(zoneId, ZONE_COMPLETION_TYPE_WORLD_EVENTS, worldEventObjective.activityIndex)
    addon.Utility.Debug("Setting world event  "..tostring(worldEventObjective.name) .. ", zone id: " .. tostring(zoneId) .. ", activityIndex: " .. tostring(worldEventObjective.activityIndex) .. ", completedBefore: " .. tostring(completedBefore) .. " as complete.", debug)
    if addon.Data:SetActivityComplete(zoneId, ZONE_COMPLETION_TYPE_WORLD_EVENTS, worldEventObjective.activityIndex, true) then
        -- Refresh UI, and announce if not the first time
        if completedBefore then
            self:UpdateUIAndAnnounce(worldEventObjective, true)
        else
            self:UpdateUI()
        end
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

function ZoneGuideTracker:FindAllObjectives(matchFunction, completionType, ...)
    local zoneIndex = GetCurrentMapZoneIndex()
    local matches = {}
    if not zoneIndex or not self.objectives[zoneIndex] then
        return matches
    end
    local objectivesList
    if completionType then
        objectivesList = { [completionType] = self.objectives[zoneIndex][completionType] }
    else
        objectivesList = self.objectives[zoneIndex]
    end
    for completionType, objectives in pairs(objectivesList) do
        for activityIndex, objective in ipairs(objectives) do
            if matchFunction(objective, zoneIndex, ...) then
                table.insert(matches, { objective, completionType })
            end
        end
    end
    return matches
end

function ZoneGuideTracker:FindObjective(matchFunction, completionType, ...)
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
            if matchFunction(objective, zoneIndex, ...) then
                return objective, completionType
            end
        end
    end
end

function ZoneGuideTracker:GetObjectivePlayerIsNearest(completionType)
    local matches = self:FindAllObjectives(isPlayerNearObjective, completionType)
    local normalizedX, normalizedZ = GetMapPlayerPosition("player")
    local nearestObjective
    local nearestCompletionType
    local nearestDistance
    local _
    for _, match in ipairs(matches) do
        local objective = match[1]
        local objectiveCompletionType = match[2]
        local distance = addon.Utility.CartesianDistance2D(normalizedX, normalizedZ, objective.normalizedX, objective.normalizedZ)
        if not nearestDistance or distance < nearestDistance then
            nearestDistance = distance
            nearestObjective = objective
            nearestCompletionType = objectiveCompletionType
        end
    end
    return nearestObjective, nearestCompletionType
end

function ZoneGuideTracker:GetPOIObjective(completionType, poiIndex)
    return self:FindObjective(matchPoiIndex, completionType, poiIndex)
end

function ZoneGuideTracker:GetObjectiveByName(objectiveName, completionType, ...)
    return self:FindObjective(matchObjectiveName, completionType, objectiveName)
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
    
    if parentZoneId and parentZoneId > 0 and parentZoneId ~= zoneId then
        local parentZoneIndex = GetZoneIndex(parentZoneId)
        local delve = {
            zoneId          = zoneId,
            zoneIndex       = zoneIndex,
            name            = GetZoneNameById(zoneId),
            parentZoneIndex = parentZoneIndex
        }
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
                local objective = {
                    name          = GetZoneStoryActivityNameByActivityIndex(zoneId, completionType, activityIndex),
                    zoneIndex     = zoneIndex,
                    activityIndex = activityIndex,
                    poiId         = GetZoneActivityIdForZoneCompletionType(zoneId, completionType, activityIndex),
                }
                local _, poiIndex = GetPOIIndices(objective.poiId)
                objective.poiIndex = self.pointsOfInterest[zoneIndex][objective.name]
                objective.lookedUpPOIIndex = poiIndex
                local normalizedX, normalizedZ, mapPinType = GetPOIMapInfo(zoneIndex, objective.poiIndex)
                objective.normalizedX = normalizedX
                objective.normalizedZ = normalizedZ
                objective.mapPinType = mapPinType
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

function ZoneGuideTracker:LoadBaseGameCompletionForCurrentZone()
    local zoneIndex = GetCurrentMapZoneIndex()
    addon.Data:LoadBaseGameCompletionForZone(zoneIndex)
    self:UpdateUI()
end

function ZoneGuideTracker:RegisterDangerousMonsterName(name, difficulty)
    self.dangerousMonsterNames[name] = difficulty
end

function ZoneGuideTracker:ResetDangerousMonsterNames()
    ZO_ClearTable(self.dangerousMonsterNames)
end

function ZoneGuideTracker:ResetCurrentZone()
    local zoneIndex = GetCurrentMapZoneIndex()
    local zoneId = GetZoneId(zoneIndex)
    for completionType, _ in pairs(COMPLETION_TYPES) do
        for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
            addon.Data:SetActivityComplete(zoneId, completionType, activityIndex, nil)
        end
    end
    self:UpdateUI()
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

function ZoneGuideTracker:TryRegisterDelveBossKill(unitTag, targetName)
  
    local difficulty
    local unitReaction
    if unitTag and unitTag ~= "" then
        difficulty = GetUnitDifficulty(unitTag)
        unitReaction = GetUnitReaction(unitTag)
    else
        if not targetName or targetName == "" then
            return
        end
        targetName = zo_strformat("<<1>>", targetName)
        difficulty = self.dangerousMonsterNames[targetName]
        if not difficulty then
            addon.Utility.Debug("Target " .. tostring(targetName) .. " is not a known dangerous monster.", debug)
            return
        end
        unitReaction = UNIT_REACTION_HOSTILE
        unitTag = "reticleover"
    end
    
    -- Bosses are always at least "normal" (purple, winged unit frame) difficulty.
    if difficulty < MONSTER_DIFFICULTY_NORMAL then
        addon.Utility.Debug("Kill for target " .. tostring(unitTag) .. " ignored because monster difficulty is only " .. tostring(difficulty), debug)
        return
    end    
    
    -- Non-hostile units are not delve bosses
    if unitReaction ~= UNIT_REACTION_HOSTILE then
        return
    end
    
    -- Get current zone and confirm that it is valid
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex or zoneIndex == 0 then
        addon.Utility.Debug("Zone index " .. tostring(zoneIndex) .. " is not valid", debug)
        return
    end
    local zoneId = GetZoneId(zoneIndex)
    if not zoneId or zoneId == 0 then
        addon.Utility.Debug("Zone id " .. tostring(zoneId) .. " is not valid", debug)
        return
    end
    
    -- Ensure that the player is in a delve zone index.
    local delve = self.delves[zoneIndex]
    if not delve then 
        addon.Utility.Debug("Could not find delve for zone name " .. tostring(GetZoneNameById(zoneId)), debug)
        return
    end
    
    if not IsUnitInDungeon("player") then
        addon.Utility.Debug("Player is not in dungeon. Not registering delve kill.", debug)
        return
    end
    
     -- If zone is newer than Clockwork City, use BossFight to detect boss kills.
    local parentZoneId = GetZoneId(delve.parentZoneIndex)
    if parentZoneId >= FIRST_ZONE_ID_WITH_DELVE_BOSS_UNIT_TAGS then
    
        if not addon.BossFight:RegisterKill(unitTag) then
            addon.Utility.Debug("Boss " .. tostring(unitTag) .. " is not a known boss.", debug)
            return
        end
        
        if not addon.BossFight:AreAllBossesKilled() then
            addon.Utility.Debug("Kill for boss " .. tostring(unitTag) .. " registered, but there are more bosses waiting to be killed for this world boss fight.", debug)
            return
        end
    else
        if not targetName or targetName == "" then
            targetName = zo_strformat("<<1>>", GetUnitName(unitTag))
        end
        
        -- Exclude certain difficult monsters by name that are known to not be bosses.
        if addon.ExcludedMonsters:IsExcludedMonster(targetName) then
            addon.Utility.Debug(targetName .. " is specifically excluded. Not registering delve kill.", debug)
            return
        end
        
        -- Certain delves in Craglorn and Cyrodiil require killing several bosses to get credit.
        if addon.MultiBossDelves:IsZoneMultiBossDelve(zoneId) then
            addon.MultiBossDelves:RegisterBossKill(zoneId, targetName)
            if not addon.MultiBossDelves:AreAllBossesKilled(zoneId) then
                addon.Utility.Debug("Not all bosses in "..tostring(delve.name) .. ", zone id: " .. delve.zoneId .. " are killed yet.", debug)
                return
            end
        end
    end
    
    addon.Utility.Debug("Setting delve "..tostring(delve.name) .. ", zone id: " .. delve.zoneId .. " as complete.", debug)
    local completedBefore = addon.Data:IsActivityCompletedOnAccount(parentZoneId, ZONE_COMPLETION_TYPE_DELVES, delve.objective.activityIndex)
    if addon.Data:SetActivityComplete(parentZoneId, ZONE_COMPLETION_TYPE_DELVES, delve.objective.activityIndex, true) then
        -- Refresh UI, and announce if not first time
        if completedBefore then
            self:UpdateUIAndAnnounce(delve.objective, true)
        else
            self:UpdateUI()
        end
    end
    return true
end

function ZoneGuideTracker:TryRegisterWorldBossKill(unitTag)
    
    if IsUnitInDungeon("player") then
        addon.Utility.Debug("Not registering a world boss kill because the player is in a dungeon.", debug)
        return
    end
    
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex or zoneIndex == 0 then
        return
    end
    local zoneId = GetZoneId(zoneIndex)
    if not zoneId or zoneId == 0 then
        return
    end
    
    local worldBossObjective = self:GetObjectivePlayerIsNearest(ZONE_COMPLETION_TYPE_GROUP_BOSSES)
    if not worldBossObjective then
        addon.Utility.Debug("Not registering a world boss kill because none could be found near the player.", debug)
        return
    end
    
    if not addon.BossFight:RegisterKill(unitTag) then
        addon.Utility.Debug("Boss " .. tostring(unitTag) .. " is not a known boss.", debug)
        return
    end
    
    if not addon.BossFight:AreAllBossesKilled() then
        addon.Utility.Debug("Kill for boss " .. tostring(unitTag) .. " registered, but there are more bosses waiting to be killed for this world boss fight.", debug)
        return
    end
    
    addon.Utility.Debug("Setting world boss "..tostring(worldBossObjective.name) .. ", zone id: " .. tostring(zoneId) .. " as complete.", debug)
    
    local completedBefore = addon.Data:IsActivityCompletedOnAccount(zoneId, ZONE_COMPLETION_TYPE_GROUP_BOSSES, worldBossObjective.activityIndex)
    if addon.Data:SetActivityComplete(zoneId, ZONE_COMPLETION_TYPE_GROUP_BOSSES, worldBossObjective.activityIndex, true) then
        -- Refresh UI, and announce if not the first time
        if completedBefore then
            self:UpdateUIAndAnnounce(worldBossObjective, true)
        else
            self:UpdateUI()
        end
        
    else
        addon.Utility.Debug("Not announcing "..tostring(worldBossObjective.name) .. " as complete. Already completed on this character.", debug)
    end
    
    -- Reset boss fight
    addon.BossFight:Reset()
    
    return true
end

function ZoneGuideTracker:UpdateUI()
    -- Refresh world map pins
    ZO_WorldMap_RefreshAllPOIs()
    -- Refresh compass pins
    COMPASS:OnUpdate()
    -- Refresh zone guide progress bars
    if IsInGamepadPreferredMode() then
        WORLD_MAP_ZONE_STORY_GAMEPAD:RefreshInfo()
        GAMEPAD_WORLD_MAP_INFO_ZONE_STORY:RefreshInfo()
    else
        WORLD_MAP_ZONE_STORY_KEYBOARD:RefreshInfo()
    end
end

function ZoneGuideTracker:UpdateUIAndAnnounce(objective, complete)
    self:UpdateUI()
    if complete then
        addon.ZoneGuideTracker:AnnounceCompletion(objective)
    end
end



---------------------------------------
--
--          Private Members
-- 
---------------------------------------

function isPlayerNearObjective(objective, zoneIndex)
    local isNearby = select(8, GetPOIMapInfo(zoneIndex, objective.poiIndex))
    if isNearby then
        return true
    end
end

function matchObjectiveName(objective, zoneIndex, objectiveName)
    return objective.name == objectiveName
end

function matchPoiIndex(objective, zoneIndex, poiIndex)
    return objective.poiIndex == poiIndex
end


-- Create singleton instance
addon.ZoneGuideTracker = ZoneGuideTracker:New()