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
  
    self.handlerNames = {
        [EVENT_COMBAT_EVENT]                        = "CombatEvent",
        [EVENT_EXPERIENCE_UPDATE]                   = "ExperienceUpdate",
        [EVENT_PLAYER_ACTIVATED]                    = "PlayerActivated",
        [EVENT_RETICLE_TARGET_CHANGED]              = "ReticleTargetChanged",
        [EVENT_WORLD_EVENT_ACTIVATED]               = "WorldEventActivated",
        [EVENT_WORLD_EVENT_ACTIVE_LOCATION_CHANGED] = "WorldEventActiveLocationChanged",
        [EVENT_WORLD_EVENT_DEACTIVATED]             = "WorldEventDeactivated",
        [EVENT_ZONE_CHANGED]                        = "ZoneChanged",
        [EVENT_ZONE_UPDATE]                         = "ZoneUpdate",
    }
    
    for event, handlerName in pairs(self.handlerNames) do
        EVENT_MANAGER:RegisterForEvent(addon.name .. handlerName, event, self:Closure(handlerName))
    end
    
    EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_TARGET_DEAD)
    EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
    EVENT_MANAGER:RegisterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, self:Closure("CombatEvent"))
    EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED_XP)
    EVENT_MANAGER:AddFilterForEvent(addon.name .. "CombatEvent2", EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
    EVENT_MANAGER:AddFilterForEvent(addon.name .. "ExperienceUpdate", EVENT_ZONE_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
    EVENT_MANAGER:AddFilterForEvent(addon.name .. "ZoneUpdate", EVENT_ZONE_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
end



---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function Events:Closure(functionName)
    return function(...)
        self[functionName](self, ...)
    end
end

--[[  ]]
function Events:CombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId, overflow)
    if addon.ZoneGuideTracker:RegisterDelveKill(targetName) then
        addon.Utility.Debug("EVENT_COMBAT_EVENT(" .. tostring(eventCode) .. ", result: "..tostring(result) .. ", isError: "..tostring(isError) 
            .. ", sourceName: "..tostring(sourceName) .. ", sourceType: " .. tostring(sourceType) .. ", targetName: "..tostring(targetName) .. ", targetType: "..tostring(targetType) 
            .. ", source: "..tostring(sourceUnitId) .. ", target: "..tostring(targetUnitId)
            .. ", sourceDifficulty: "..tostring(sourceUnitDifficulty) .. ", targetDifficulty: "..tostring(targetUnitDifficulty).. ")", debug)
    end
end

--[[  ]]
function Events:ExperienceUpdate(eventCode, unitTag, currentExp, maxExp, reason)
    if reason ~= PROGRESS_REASON_OVERLAND_BOSS_KILL then
        return
    end
    if addon.ZoneGuideTracker:RegisterWorldBossKill(reason) then
        addon.Utility.Debug("EVENT_EXPERIENCE_UPDATE(" .. tostring(eventCode) .. ", unitTag: "..tostring(unitTag) .. ", unitName: "..tostring(unitName) .. ", currentExp: "..tostring(currentExp) .. ", maxExp: " .. tostring(maxExp) .. ", reason: " .. tostring(reason) .. ")", debug)
    end
end

--[[  ]]
function Events:PlayerActivated(eventCode, initial)
    local zoneIndex = GetCurrentMapZoneIndex()
    local zoneId = GetZoneId(zoneIndex)
    addon.Utility.Debug("EVENT_PLAYER_ACTIVATED(" .. tostring(eventCode) .. ", "..tostring(initial) .. ", zoneId: "..tostring(zoneId) .. ", zoneIndex: "..tostring(zoneIndex) .. ")", debug)
    addon.ZoneGuideTracker:ClearActiveWorldEventInstance()
    addon.ZoneGuideTracker:InitializeZone(zoneIndex)
    addon.ZoneGuideTracker:InitializeAllZonesAsync()
end

function Events:ReticleTargetChanged(eventCode)
    -- If in the overland, we're obviously not in a delve.
    if not IsUnitInDungeon("player") then
        return
    end
    local unitTag = "reticleover"
    
    -- Ignore trash mobs
    local difficulty = GetUnitDifficulty(unitTag)
    if difficulty < MONSTER_DIFFICULTY_NORMAL then
        return
    end
    
    -- Non-hostile units are not delve bosses
    local unitReaction = GetUnitReaction(unitTag)
    if unitReaction ~= UNIT_REACTION_HOSTILE then
        return
    end
    
    local unitName = GetUnitName(unitTag) 
    addon.ZoneGuideTracker:RegisterDelveBossName(unitName)
    addon.Utility.Debug("EVENT_RETICLE_TARGET_CHANGED(" .. tostring(eventCode) .. ", unitName: "..tostring(unitName) .. ")", debug)
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
function Events:ZoneChanged(eventCode, zoneName, subZoneName, newSubzone, zoneId, subZoneId)
    if newSubzone or zoneId == 0 then
        return
    end
    local zoneIndex = GetZoneIndex(zoneId)
    addon.Utility.Debug("EVENT_ZONE_CHANGED(" .. tostring(zoneName) .. ", "..tostring(subZoneName) .. ", "..tostring(newSubzone) .. ", zoneId: "..tostring(zoneId) .. ", subZoneId: "..tostring(subZoneId) .. ")", debug)
    addon.ZoneGuideTracker:ClearActiveWorldEventInstance()
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