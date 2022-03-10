local addon = CharacterZoneTracker
local debug = false
local ASYNC_TIMEOUT = 100
local ASYNC_BACKUP_ALL_SCOPE = addon.name .. ".Data.BackupAllZonesAsync"
local ASYNC_BACKUP_BATCH_SIZE = 500
local COMPLETION_TYPES = addon:GetCompletionTypes()
local save, trueCount, containsAnyUntrue

local Data = ZO_Object:Subclass()

function Data:New(...)
    local instance = ZO_Object.New(self)
    self.Initialize(instance, ...)
    return instance
end

function Data:Initialize()
    
    self.initialized = true
    self.save = LibSavedVars:NewCharacterSettings(addon.name .. "Data", {})
                            :EnableDefaultsTrimming()
    self.esoui = {}
    
    self.esouiNames = {
        AreAllActivitiesComplete = "AreAllZoneStoryActivitiesCompleteForZoneCompletionType",
        CanActivitiesContinue = "CanZoneStoryContinueTrackingActivitiesForCompletionType",
        GetNumCompletedActivities = "GetNumCompletedZoneActivitiesForZoneCompletionType",
        IsActivityComplete = "IsZoneStoryActivityComplete",
        GetPOIMapInfo = "GetPOIMapInfo",
        GetPOIPinIcon = "GetPOIPinIcon",
    }
    
    for handlerName, methodName in pairs(self.esouiNames) do
        local method = _G[methodName]
        if method then
            self.esoui[methodName] = method
            _G[methodName] = self:Closure(handlerName)
        end
    end
end



---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

--[[  ]]
function Data:Closure(functionName)
    return function(...)
        return self[functionName](self, ...)
    end
end

--[[  ]]
function Data:AreAllActivitiesComplete(zoneId, completionType)
    if addon:IsCompletionTypeTracked(completionType) then
        return not containsAnyUntrue(self, zoneId, completionType)
    end
    return self.esoui.AreAllZoneStoryActivitiesCompleteForZoneCompletionType(zoneId, completionType)
end

function Data:BackupAllZonesAsync(startZoneIndex)
    if self:GetIsBackedUp() then
        return
    end
    EVENT_MANAGER:UnregisterForUpdate(ASYNC_BACKUP_ALL_SCOPE)
    if not startZoneIndex then
        startZoneIndex = 1
    end
    for zoneIndex = startZoneIndex, startZoneIndex + ASYNC_BACKUP_BATCH_SIZE do
        local zoneId = GetZoneId(zoneIndex)
        if not zoneId or zoneId < 1 then
            -- Print backup success message to chat
            addon.Utility.Print(zo_strformat(GetString(SI_CZB_BACKUP_FINISHED), GetUnitName("player")))
            self:SetIsBackedUp()
            return
        end
        self:LoadBaseGameCompletionForZone(zoneIndex)
    end
    EVENT_MANAGER:RegisterForUpdate(ASYNC_BACKUP_ALL_SCOPE, ASYNC_TIMEOUT, self:GenerateBackupAllZonesAsyncCallback(startZoneIndex + ASYNC_BACKUP_BATCH_SIZE + 1))
end

--[[  ]]
function Data:CanActivitiesContinue(zoneId, completionType)
    if addon:IsCompletionTypeTracked(completionType) then
        return containsAnyUntrue(self, zoneId, completionType)
    end
    return self.esoui.CanZoneStoryContinueTrackingActivitiesForCompletionType(zoneId, completionType)
end

--[[  ]]
function Data:GenerateBackupAllZonesAsyncCallback(startZoneIndex)
    return function()
        self:BackupAllZonesAsync(startZoneIndex)
    end
end

--[[  ]]
function Data:GetIsBackedUp()
    return self.save.backedUp
end

function Data:GetIsMultiBossDelveBossKilled(zoneId, bossIndex)
    return self.save.delveBossKills
           and self.save.delveBossKills[zoneId]
           and self.save.delveBossKills[zoneId][bossIndex]
           or false
end

--[[  ]]
function Data:GetNumCompletedActivities(zoneId, completionType)
    if addon:IsCompletionTypeTracked(completionType) then
        return trueCount(self, zoneId, completionType)
    end
    return self.esoui.GetNumCompletedZoneActivitiesForZoneCompletionType(zoneId, completionType)
end

function Data:GetPOIMapInfo(zoneIndex, poiIndex)
  
    addon.ZoneGuideTracker:InitializeZone(zoneIndex)
    local poiObjective, completionType = addon.ZoneGuideTracker:GetPOIObjective(nil, poiIndex)
    local xLoc, zLoc, poiPinType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = self.esoui.GetPOIMapInfo(zoneIndex, poiIndex)
    if addon:IsCompletionTypeTracked(completionType) then
        local zoneId = GetZoneId(zoneIndex)
        local priorIcon = icon
        if self:IsActivityComplete(zoneId, completionType, poiObjective.activityIndex) then
            poiPinType = MAP_PIN_TYPE_POI_COMPLETE
            icon = icon:gsub("_incomplete", "_complete")
        else
            poiPinType = MAP_PIN_TYPE_POI_SEEN
            icon = icon:gsub("_complete", "_incomplete")
        end
    end
    return xLoc, zLoc, poiPinType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby 
end

--[[  ]]
function Data:GetPOIPinIcon(poiId, checkNearby)
    local zoneIndex, poiIndex = GetPOIIndices(poiId)
    local _, _, poiPinType, icon = self:GetPOIMapInfo(zoneIndex, poiIndex)
    return icon, poiPinType
end

--[[  ]]
function Data:IsActivityComplete(zoneId, completionType, activityIndex)
    addon.Utility.Debug("IsActivityComplete(zoneId: " .. tostring(zoneId) .. ", completionType: " .. tostring(completionType) .. ", activityIndex: " .. tostring(activityIndex) .. ")", debug)
    if addon:IsCompletionTypeTracked(completionType) then
        addon.Utility.Debug("Returning " .. tostring(self.save[zoneId] and self.save[zoneId][completionType] and self.save[zoneId][completionType][activityIndex]), debug)
        return self.save[zoneId] and self.save[zoneId][completionType] and self.save[zoneId][completionType][activityIndex] or false
    end
    return self.esoui.IsZoneStoryActivityComplete(zoneId, completionType, activityIndex)
end

--[[  ]]
function Data:IsActivityCompletedOnAccount(zoneId, completionType, activityIndex)
    return self.esoui.IsZoneStoryActivityComplete(zoneId, completionType, activityIndex)
end

--[[  ]]
function Data:LoadBaseGameCompletion(zoneId, completionType, activityIndex)
    local baseGameActivityComplete = self.esoui.IsZoneStoryActivityComplete(zoneId, completionType, activityIndex)
    save(self, zoneId, completionType, activityIndex, baseGameActivityComplete)
end

function Data:LoadBaseGameCompletionForZone(zoneIndex)
    local zoneId = GetZoneId(zoneIndex)
    local _
    for completionType, _ in pairs(COMPLETION_TYPES) do
        for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
            addon.Data:LoadBaseGameCompletion(zoneId, completionType, activityIndex)
        end
    end
end

--[[  ]]
function Data:SetActivityComplete(zoneId, completionType, activityIndex, complete)
    addon.Utility.Debug("SetActivityComplete(zoneId: " .. tostring(zoneId) .. ", completionType: " .. tostring(completionType) .. ", activityIndex: " .. tostring(activityIndex) .. ", complete: " .. tostring(complete) .. ")", debug)
    if not addon:IsCompletionTypeTracked(completionType) then
        return
    end
    
    return save(self, zoneId, completionType, activityIndex, complete)
end

--[[  ]]
function Data:SetIsBackedUp()
    self.save.backedUp = true
end

function Data:SetMultiBossDelveBossKilled(zoneId, bossIndex)
    if not self.save.delveBossKills then
        self.save.delveBossKills = {}
    end
    if not self.save.delveBossKills[zoneId] then
        self.save.delveBossKills[zoneId] = {}
    end
    self.save.delveBossKills[zoneId][bossIndex] = true
end

---------------------------------------
--
--          Private Members
-- 
---------------------------------------

function containsAnyUntrue(self, zoneId, completionType)
    if self.save[zoneId] and self.save[zoneId][completionType] then
        for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
            if not self.save[zoneId] or not self.save[zoneId][completionType] or not self.save[zoneId][completionType][activityIndex] then
                return true
            end
        end
    end
    return false
end

function save(self, zoneId, completionType, activityIndex, complete)
    if not self.save[zoneId] then
        if complete then
            self.save[zoneId] = {}
        else
            return false
        end
    end
    if not self.save[zoneId][completionType] then
        if complete then
            self.save[zoneId][completionType] = {}
        else
            return false
        end
    end
    local success = (self.save[zoneId][completionType][activityIndex] == true and not complete)
                    or (not self.save[zoneId][completionType][activityIndex] and complete)
    self.save[zoneId][completionType][activityIndex] = complete or nil
    return success
end

function trueCount(self, zoneId, completionType)
    local count = 0
    for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
        if self.save[zoneId] and self.save[zoneId][completionType] and self.save[zoneId][completionType][activityIndex] then
            count = count + 1
        end
    end
    return count
end

-- Create singleton
addon.Data = Data:New()
