--[[ 
    ===================================
            GAME CLIENT EVENTS 
    ===================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = true
local HANDLER_CONFIG

-- Singleton class
local Events = ZO_Object:Subclass()

function Events:New()
    return ZO_Object.New(self)
end

function Events:Initialize()    
    for handlerIndex = 1, #HANDLER_CONFIG do
        local handler = HANDLER_CONFIG[handlerIndex]
        EVENT_MANAGER:RegisterForEvent(addon.name .. handler.name, handler.event, self:Closure(handler.name))
        if handler.filters then
            for filterIndex = 1, #handler.filters do
                local filterType = handler.filters[filterIndex][1]
                local filterValue = handler.filters[filterIndex][2]
                EVENT_MANAGER:AddFilterForEvent(addon.name .. handler.name, handler.event, filterType, filterValue)
            end
        end
    end
end



---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function Events:BossesChanged(eventCode, forceReset)
    if addon.BossFight:UpdateBossList() then
        addon.Utility.Debug("EVENT_BOSSES_CHANGED(" .. tostring(eventCode) .. ", forceReset: "..tostring(forceReset) .. ")", debug)
    end
end

--[[  ]]
function Events:BossUnitDeathStateChanged (eventCode, unitTag, isDead)
    if not isDead then
        return
    end
    
    addon.Utility.Debug("EVENT_UNIT_DEATH_STATE_CHANGED(" .. tostring(eventCode) .. ", "..tostring(unitTag) .. ", "..tostring(isDead) .. ")", debug)
    
    if IsUnitInDungeon("player") then
        addon.ZoneGuideTracker:TryRegisterDelveBossKill(unitTag)
    else
        addon.ZoneGuideTracker:TryRegisterWorldBossKill(unitTag)
    end
end

function Events:Closure(functionName)
    return function(...)
        self[functionName](self, ...)
    end
end

function Events:CombatEventDiedXP(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId, overflow)
      addon.Utility.Debug("EVENT_COMBAT_EVENT(" .. tostring(eventCode) .. ", result: "..tostring(result) .. ", isError: "..tostring(isError) 
        .. ", sourceName: "..tostring(sourceName) .. ", sourceType: " .. tostring(sourceType) .. ", targetName: "..tostring(targetName) .. ", targetType: "..tostring(targetType) 
        .. ", source: "..tostring(sourceUnitId) .. ", target: "..tostring(targetUnitId) .. ")", debug)
      addon.ZoneGuideTracker:TryRegisterDelveBossKill(nil, targetName)
end

--[[  ]]
function Events:PlayerActivated(eventCode, initial)
    local zoneIndex = GetCurrentMapZoneIndex()
    local zoneId = GetZoneId(zoneIndex)
    addon.Utility.Debug("EVENT_PLAYER_ACTIVATED(" .. tostring(eventCode) .. ", "..tostring(initial) .. ", zoneId: "..tostring(zoneId) .. ", zoneIndex: "..tostring(zoneIndex) .. ")", debug)
    addon.ZoneGuideTracker:ClearActiveWorldEventInstance()
    addon.ZoneGuideTracker:ResetDangerousMonsterNames()
    addon.BossFight:UpdateBossList()
    addon.ZoneGuideTracker:InitializeZone(zoneIndex)
    
    -- If running before Update 33 comes out, then back up all current progress when you first log in.
    if GetAPIVersion() < 101033 then
        addon.Data:BackupAllZonesAsync()
    end
end

--[[  ]]
function Events:ReticleoverUnitDeathStateChanged(eventCode, unitTag, isDead)
    if not isDead then
        return
    end
    
    addon.Utility.Debug("EVENT_UNIT_DEATH_STATE_CHANGED(" .. tostring(eventCode) .. ", unitTag: "..tostring(unitTag) .. ", unitName: "..tostring(GetUnitName(unitTag)) .. ", isDead: "..tostring(isDead) .. ")", debug)
    addon.ZoneGuideTracker:TryRegisterDelveBossKill(unitTag)
end

function Events:ReticleTargetChanged(eventCode)
    -- If in the overland, we're obviously not in a delve.
    if not IsUnitInDungeon("player") then
        return
    end
    
    local unitTag = "reticleover"
    local unitName = GetUnitName(unitTag)
    if not unitName or unitName == "" then
        return
    end
    
    -- Ignore trash mobs
    local difficulty = GetUnitDifficulty(unitTag)
    if difficulty < MONSTER_DIFFICULTY_NORMAL then
        return
    end
    
    -- Non-hostile units are not delve bosses
    local unitReaction = GetUnitReaction(unitTag)
    addon.Utility.Debug("EVENT_RETICLE_TARGET_CHANGED(" .. tostring(eventCode) .. ", unitName: "..tostring(unitName) .. ", difficulty: " .. tostring(difficulty)  .. ", unitReaction: " .. tostring(unitReaction) .. ")", debug)
    if unitReaction ~= UNIT_REACTION_HOSTILE then
        return
    end
    
    addon.ZoneGuideTracker:RegisterDangerousMonsterName(unitName, difficulty)
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


---------------------------------------
--
--          Private Members
-- 
---------------------------------------

HANDLER_CONFIG = {
    {
        name = "BossesChanged",
        event = EVENT_BOSSES_CHANGED,
    },
    {
        name = "BossUnitDeathStateChanged",
        event = EVENT_UNIT_DEATH_STATE_CHANGED,
        filters = {
            { REGISTER_FILTER_UNIT_TAG_PREFIX, "boss" }
        },
    },
    {
        name = "CombatEventDiedXP",
        event = EVENT_COMBAT_EVENT,
        filters = {
            { REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED_XP }
        },
    },
    {
        name = "PlayerActivated",
        event = EVENT_PLAYER_ACTIVATED,
    },
    {
        name = "ReticleoverUnitDeathStateChanged",
        event = EVENT_UNIT_DEATH_STATE_CHANGED,
        filters = {
            { REGISTER_FILTER_UNIT_TAG, "reticleover" }
        },
    },
    {
        name = "ReticleTargetChanged",
        event = EVENT_RETICLE_TARGET_CHANGED,
    },
    {
        name = "WorldEventActivated",
        event = EVENT_WORLD_EVENT_ACTIVATED,
    },
    {
        name = "WorldEventActiveLocationChanged",
        event = EVENT_WORLD_EVENT_ACTIVE_LOCATION_CHANGED,
    },
    {
        name = "WorldEventDeactivated",
        event = EVENT_WORLD_EVENT_DEACTIVATED,
    },
    {
        name = "ZoneChanged",
        event = EVENT_ZONE_CHANGED,
    },
    {
        name = "ZoneUpdate",
        event = EVENT_ZONE_UPDATE,
        filters = {
            { REGISTER_FILTER_UNIT_TAG, "player" }
        },
    },
}



-- Create singleton
addon.Events = Events:New()