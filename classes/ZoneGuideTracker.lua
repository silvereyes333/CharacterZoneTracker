--[[ 
]]--

local addon = CharacterZoneTracker
local COMPLETION_TYPES = addon:GetCompletionTypes()
local ZONE_ACTIVITY_NAME_MAX_EDIT_DISTANCE = 5
local FIRST_ZONE_ID_WITH_DELVE_BOSS_UNIT_TAGS = 589
local WORLD_EVENT_MAX_DISTANCE = 0.02
local ZoneGuideTracker = ZO_Object:Subclass()

local className = addon.name .. "ZoneGuideTracker"
local debug = false
local isPlayerNearObjective, matchObjectiveName, matchPoiIndex
local _


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
    self.initializedZoneIndexes = {}
    self.objectives = {}
    self.dangerousMonsterNames = {}
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
    if not eventHandler then
        return
    end
    local messageParams = eventHandler(objective.zoneIndex, objective.poiIndex, level, experience, experience, championPoints)
    if not messageParams then
        return
    end
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
    local worldEventObjective, _, objectiveDistance = self:GetObjectivePlayerIsNearest(ZONE_COMPLETION_TYPE_WORLD_EVENTS)
    if not worldEventObjective or objectiveDistance > WORLD_EVENT_MAX_DISTANCE then
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
    if zoneId == 0 then
        return
    end
    
    local completionZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
    if completionZoneId == 0 then
        return
    end
    
    local completedBefore = addon.Data:IsActivityCompletedOnAccount(completionZoneId, ZONE_COMPLETION_TYPE_WORLD_EVENTS, worldEventObjective.activityIndex)
    addon.Utility.Debug("Setting world event  "..tostring(worldEventObjective.name) .. ", zone id: " .. tostring(zoneId) .. ", activityIndex: " .. tostring(worldEventObjective.activityIndex) .. ", completedBefore: " .. tostring(completedBefore) .. " as complete.", debug)
    if addon.Data:SetActivityComplete(completionZoneId, ZONE_COMPLETION_TYPE_WORLD_EVENTS, worldEventObjective.activityIndex, true) then
        -- Refresh UI, and announce if not the first time
        if completedBefore then
            self:UpdateUIAndAnnounce(worldEventObjective, true)
        else
            self:UpdateUI()
        end
    end
end

function ZoneGuideTracker:FindBestZoneCompletionActivityNameMatch(completionZoneId, name, completionType, completionZoneIndex)
  
    local halfSearchStringLength = math.ceil(ZoUTF8StringLength(name)/2)
    local maxEditDistance = math.min(ZONE_ACTIVITY_NAME_MAX_EDIT_DISTANCE, halfSearchStringLength)
    local lowestEditDistance = maxEditDistance + 1
    if not completionZoneIndex then
        completionZoneIndex = GetZoneIndex(completionZoneId)
    end
    local match
    for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(completionZoneId, completionType) do
        local objective = self.objectives[completionZoneIndex][completionType][activityIndex]
        if objective then
            local editDistance = addon.Utility.EditDistance(objective.name, name, lowestEditDistance)
            if editDistance < lowestEditDistance then
                match = objective
                lowestEditDistance = editDistance
            end
        end
    end
    return match, lowestEditDistance
end

function ZoneGuideTracker:FindAllObjectives(matchFunction, completionType, ...)
  
    local matches = {}
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex then
        return matches
    end
    
    local zoneId = GetZoneId(zoneIndex)
    if zoneId == 0 then
        return matches
    end
    
    local completionZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
    if completionZoneId == 0 then
        return matches
    end
    
    local completionZoneIndex = GetZoneIndex(completionZoneId)
    if completionZoneIndex == 0 then
        return matches
    end
    
    if not self.objectives[completionZoneIndex] then
        return matches
    end
    local objectivesList
    if completionType then
        objectivesList = { [completionType] = self.objectives[completionZoneIndex][completionType] }
    else
        objectivesList = self.objectives[completionZoneIndex]
    end
    for completionType, objectives in pairs(objectivesList) do
        for activityIndex, objective in ipairs(objectives) do
            if matchFunction(objective, ...) then
                table.insert(matches, { objective, completionType })
            end
        end
    end
    return matches
end

function ZoneGuideTracker:FindObjective(matchFunction, completionZoneIndex, completionType, ...)
    if not self.objectives[completionZoneIndex] then
        return
    end
    local objectivesList
    if completionType then
        objectivesList = { [completionType] = self.objectives[completionZoneIndex][completionType] }
    else
        objectivesList = self.objectives[completionZoneIndex]
    end
    for completionType, objectives in pairs(objectivesList) do
        for activityIndex, objective in ipairs(objectives) do
            if matchFunction(objective, ...) then
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
    return nearestObjective, nearestCompletionType, nearestDistance
end

function ZoneGuideTracker:GetPOIObjective(completionZoneIndex, completionType, poiZoneIndex, poiIndex)
    return self:FindObjective(matchPoiIndex, completionZoneIndex, completionType, poiZoneIndex, poiIndex)
end

function ZoneGuideTracker:GetObjectiveByName(completionZoneIndex, completionType, objectiveName)
    return self:FindObjective(matchObjectiveName, completionZoneIndex, completionType, objectiveName)
end

--[[  ]]--
function ZoneGuideTracker:InitializeZone(zoneIndex)
    
    addon.Utility.Debug("InitializeZone(zoneIndex: " .. tostring(zoneIndex) .. ")", debug)
  
    if zoneIndex == 0 then
        return
    end
    
    -- Zone is already initialized
    if self.initializedZoneIndexes[zoneIndex] then
        return true
    end
    
    self.initializedZoneIndexes[zoneIndex] = true
    
    local zoneId = GetZoneId(zoneIndex)
    if zoneId == 0 then
        return
    end
    
    local totalActivityCount = 0
    
    local completionZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
    if completionZoneId == 0 then
        return true
    end
    
    local completionZoneIndex = GetZoneIndex(completionZoneId)
    
    if not self.objectives[completionZoneIndex] then
        self.objectives[completionZoneIndex] = {}
    end
    
    for completionType in pairs(COMPLETION_TYPES) do
        local activityCount = GetNumZoneActivitiesForZoneCompletionType(completionZoneId, completionType)
        if activityCount > 0 then
            totalActivityCount = totalActivityCount + activityCount
            if not self.objectives[completionZoneIndex][completionType] then
                self.objectives[completionZoneIndex][completionType] = {}
            end
            for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(completionZoneId, completionType) do
                local activityName = GetZoneStoryActivityNameByActivityIndex(completionZoneId, completionType, activityIndex)
                local poiId = GetZoneActivityIdForZoneCompletionType(completionZoneId, completionType, activityIndex)
                local poiZoneIndex, poiIndex = GetPOIIndices(poiId)
                local normalizedX, normalizedZ = addon.Data:GetPOIMapInfoOnAccount(poiZoneIndex, poiIndex)
                
                local objective = {
                    name          = activityName,
                    zoneIndex     = poiZoneIndex,
                    activityIndex = activityIndex,
                    poiId         = poiId,
                    poiIndex      = poiIndex,
                    normalizedX   = normalizedX,
                    normalizedZ   = normalizedZ,
                }
                if completionType == ZONE_COMPLETION_TYPE_WORLD_EVENTS then
                    if objective.poiIndex then
                        local worldEventInstanceId = GetPOIWorldEventInstanceId(zoneIndex, objective.poiIndex)
                        if worldEventInstanceId and worldEventInstanceId > 0 then
                            objective.worldEventInstanceId = worldEventInstanceId
                            self:SetActiveWorldEventInstanceId(worldEventInstanceId)
                        end
                    end
                end
                self.objectives[completionZoneIndex][completionType][activityIndex] = objective
            end
        end
    end
    -- Trim empty
    if totalActivityCount == 0 then
        self.objectives[completionZoneIndex] = nil
    end
    return true
end

function ZoneGuideTracker:GetObjectives(zoneIndex, completionType)
    self:InitializeZone(zoneIndex)
    return self.objectives[zoneIndex][completionType]
end

function ZoneGuideTracker:LoadBaseGameCompletionForCurrentZone()
    local zoneIndex = GetCurrentMapZoneIndex()
    if zoneIndex == 0 then
        return
    end
    
    local zoneId = GetZoneId(zoneIndex)
    if zoneId == 0 then
        return
    end
    
    local completionZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
    if completionZoneId == 0 then
        return
    end
    
    local completionZoneIndex = GetZoneIndex(completionZoneId)
    if completionZoneIndex == 0 then
        return
    end

    
    addon.Data:LoadBaseGameCompletionForZone(completionZoneIndex)
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
    if zoneIndex == 0 then
        return
    end
    local zoneId = GetZoneId(zoneIndex)
    if zoneId == 0 then
        return
    end
    
    local completionZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
    if completionZoneId == 0 then
        return
    end
    
    local completionZoneIndex = GetZoneIndex(completionZoneId)
    if completionZoneIndex == 0 then
        return
    end
    
    for completionType, _ in pairs(COMPLETION_TYPES) do
        for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(completionZoneIndex, completionType) do
            addon.Data:SetActivityComplete(completionZoneId, completionType, activityIndex, nil)
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
        addon.Utility.Debug("Target " .. tostring(targetName) .. " is a known dangerous monster of difficulty " .. tostring(difficulty) .. ".", debug)
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
    local zoneIndex = GetUnitZoneIndex("player")
    if not zoneIndex or zoneIndex == 0 then
        addon.Utility.Debug("Zone index " .. tostring(zoneIndex) .. " is not valid", debug)
        return
    end
    local zoneId = GetZoneId(zoneIndex)
    if zoneId == 0 then
        addon.Utility.Debug("Zone id " .. tostring(zoneId) .. " is not valid", debug)
        return
    end
    
    local completionZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
    if completionZoneId == 0 then
        addon.Utility.Debug("Zone id " .. tostring(zoneId) .. " has no zone tracker.", debug)
        return
    end
    
    local zoneName = GetZoneNameById(zoneId)
    
    -- Try to find a map completion / zone guide activity that matches the current zone name
    local completionType = ZONE_COMPLETION_TYPE_DELVES
    local objective, editDistance = self:FindBestZoneCompletionActivityNameMatch(completionZoneId, zoneName, completionType)
    
    -- No matches found. Probably not a delve.
    if not objective then
        
        -- For the hardest monster kills that have no "boss" unit tag,
        -- try a fallback to see if this was actually a world boss.
        -- This can sometimes be necessary if a world boss lacks a "boss" unit tag.
        -- E.g. Walks-Like-Thunder at Echoing Hollow in Murkmire
        if difficulty >= MONSTER_DIFFICULTY_DEADLY
           and not addon.Utility.StartsWith(unitTag, "boss")
           and not addon.BossFight:IsActive()
           and not IsUnitInDungeon("player")
        then
            
            completionType = ZONE_COMPLETION_TYPE_GROUP_BOSSES
            objective = self:GetObjectivePlayerIsNearest(completionType)
            if not objective then
                addon.Utility.Debug("Not registering a world boss kill because none could be found near the player.", debug)
                return
            else
                addon.Utility.Debug("World boss kill detected for target " .. tostring(targetName) .. ".", debug)
            end
        else
            addon.Utility.Debug("Could not find delve for zone name " .. tostring(zoneName), debug)
            return
        end
    end
    
    if completionType == ZONE_COMPLETION_TYPE_DELVES and not IsUnitInDungeon("player") then
        addon.Utility.Debug("Player is not in dungeon. Not registering delve kill.", debug)
        return
    end
    
     -- Delves in zones newer than Clockwork City use BossFight to detect boss kills.
    if addon.BossFight:IsActive() and completionType == ZONE_COMPLETION_TYPE_DELVES then
    
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
            addon.Utility.Debug(targetName .. " is specifically excluded. Not registering boss kill.", debug)
            return
        end
        
        -- Certain delves in Craglorn and Cyrodiil require killing several bosses to get credit.
        if addon.MultiBossDelves:IsZoneMultiBossDelve(zoneId) then
            addon.MultiBossDelves:RegisterBossKill(zoneId, targetName)
            if not addon.MultiBossDelves:AreAllBossesKilled(zoneId) then
                addon.Utility.Debug("Not all bosses in "..tostring(zoneName) .. ", zone id: " .. tostring(zoneId) .. " are killed yet.", debug)
                return
            end
        end
    end
    
    addon.Utility.Debug("Setting activity "..tostring(objective.name) .. ", zone id: " .. tostring(zoneId) .. " as complete.", debug)
    local completedBefore = addon.Data:IsActivityCompletedOnAccount(completionZoneId, completionType, objective.activityIndex)
    if addon.Data:SetActivityComplete(completionZoneId, completionType, objective.activityIndex, true) then
        -- Refresh UI, and announce if not first time
        if completedBefore then
            self:UpdateUIAndAnnounce(objective, true)
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
    
    local zoneIndex = GetUnitZoneIndex("player")
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
    
    local completionZoneId = GetZoneStoryZoneIdForZoneId(zoneId)
    if completionZoneId == 0 then
        return
    end
    
    addon.Utility.Debug("Setting world boss "..tostring(worldBossObjective.name) .. ", zone id: " .. tostring(zoneId) .. " as complete.", debug)
    
    local completedBefore = addon.Data:IsActivityCompletedOnAccount(completionZoneId, ZONE_COMPLETION_TYPE_GROUP_BOSSES, worldBossObjective.activityIndex)
    if addon.Data:SetActivityComplete(completionZoneId, ZONE_COMPLETION_TYPE_GROUP_BOSSES, worldBossObjective.activityIndex, true) then
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

function isPlayerNearObjective(objective)
    local isNearby = select(8, GetPOIMapInfo(objective.zoneIndex, objective.poiIndex))
    if isNearby then
        return true
    end
end

function matchObjectiveName(objective, objectiveName)
    return objective.name == objectiveName
end

function matchPoiIndex(objective, zoneIndex, poiIndex)
    return objective.zoneIndex == zoneIndex and objective.poiIndex == poiIndex
end


-- Create singleton instance
addon.ZoneGuideTracker = ZoneGuideTracker:New()