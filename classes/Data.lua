local addon = CharacterZonesAndBosses
local debug = false
local trueCount, containsAnyUntrue

local Data = ZO_Object:Subclass()

function Data:New(...)
    local instance = ZO_Object.New(self)
    self.Initialize(instance, ...)
    return instance
end

function Data:Initialize()
    
    self.initialized = true
    self.save = LibSavedVars:NewCharacterSettings(addon.name .. "Data", {})
    self.esoui = {}
    
    self.esouiNames = {
        AreAllActivitiesComplete = "AreAllZoneStoryActivitiesCompleteForZoneCompletionType",
        CanActivitiesContinue = "CanZoneStoryContinueTrackingActivitiesForCompletionType",
        GetNumCompletedActivities = "GetNumCompletedZoneActivitiesForZoneCompletionType",
        IsActivityComplete = "IsZoneStoryActivityComplete",
        GetPOIMapInfo = "GetPOIMapInfo",
    }
    
    --[[
      GetPOIPinIcon(number poiId, boolean checkNearby)
      Returns: textureName icon, number MapDisplayPinType poiPinType
         Note: use Search on ESOUI Source Code GetPOIIndices(number poiId) Returns: number zoneIndex, number poiIndex
    ]]
    
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
    if addon.ZoneGuideTracker:IsCompletionTypeTracked(completionType) then
        return not containsAnyUntrue(self, zoneId, completionType)
    end
    return self.esoui.AreAllZoneStoryActivitiesCompleteForZoneCompletionType(zoneId, completionType)
end

--[[  ]]
function Data:CanActivitiesContinue(zoneId, completionType)
    if addon.ZoneGuideTracker:IsCompletionTypeTracked(completionType) then
        return containsAnyUntrue(self, zoneId, completionType)
    end
    return self.esoui.CanZoneStoryContinueTrackingActivitiesForCompletionType(zoneId, completionType)
end

--[[  ]]
function Data:GetNumCompletedActivities(zoneId, completionType)
    if addon.ZoneGuideTracker:IsCompletionTypeTracked(completionType) then
        return trueCount(self, zoneId, completionType)
    end
    return self.esoui.GetNumCompletedZoneActivitiesForZoneCompletionType(zoneId, completionType)
end

function Data:GetPOIMapInfo(zoneIndex, poiIndex)
    addon.ZoneGuideTracker:InitializeZone(zoneIndex)
    local poiObjective, completionType = addon.ZoneGuideTracker:GetPOIObjective(nil, poiIndex)
    local xLoc, zLoc, poiPinType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = self.esoui.GetPOIMapInfo(zoneIndex, poiIndex)
    if addon.ZoneGuideTracker:IsCompletionTypeTracked(completionType) then
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
function Data:IsActivityComplete(zoneId, completionType, activityIndex)
    addon.Utility.Debug("IsActivityComplete(zoneId: " .. tostring(zoneId) .. ", completionType: " .. tostring(completionType) .. ", activityIndex: " .. tostring(activityIndex) .. ")", debug)
    if addon.ZoneGuideTracker:IsCompletionTypeTracked(completionType) then
        addon.Utility.Debug("Returning " .. tostring(self.save[zoneId] and self.save[zoneId][completionType] and self.save[zoneId][completionType][activityIndex]), debug)
        return self.save[zoneId] and self.save[zoneId][completionType] and self.save[zoneId][completionType][activityIndex]
    end
    return self.esoui.IsZoneStoryActivityComplete(zoneId, completionType)
end

--[[  ]]
function Data:SetActivityComplete(zoneId, completionType, activityIndex, complete)
    if complete == nil then
        complete = true
    end
    addon.Utility.Debug("SetActivityComplete(zoneId: " .. tostring(zoneId) .. ", completionType: " .. tostring(completionType) .. ", activityIndex: " .. tostring(activityIndex) .. ", complete: " .. tostring(complete) .. ")", debug)
    if not addon.ZoneGuideTracker:IsCompletionTypeTracked(completionType) then
        return
    end
    if not self.save[zoneId] then
        self.save[zoneId] = {}
    end
    if not self.save[zoneId][completionType] then
        self.save[zoneId][completionType] = {}
    end
    self.save[zoneId][completionType][activityIndex] = complete
end

---------------------------------------
--
--          Private Members
-- 
---------------------------------------

function containsAnyUntrue(self, zoneId, completionType)
    if self.save[zoneId] and self.save[zoneId][completionType] then
        for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
            if not self.save[zoneId][completionType][activityIndex] then
                return true
            end
        end
    end  
end

function trueCount(self, zoneId, completionType)
    local count = 0
    for activityIndex = 1, GetNumZoneActivitiesForZoneCompletionType(zoneId, completionType) do
        if self.save[zoneId][completionType][activityIndex] then
            count = count + 1
        end
    end
    return count
end

-- Create singleton
addon.Data = Data:New()
