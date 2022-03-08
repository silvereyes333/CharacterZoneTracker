--[[ 
    ============================================
      Tracking for boss fights
    ============================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = true

-- Singleton class
local BossFight = ZO_Object:Subclass()

function BossFight:New(...)
    local instance = ZO_Object.New(self)
    self.Initialize(instance, ...)
    return instance
end

function BossFight:Initialize()
    self.bossesKilled = {}
    self.bossNames = {}
end




---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function BossFight:AreAllBossesKilled()
    local bossName = next(self.bossNames)
    if not bossName then
        return false
    end
    repeat
        if not self.bossesKilled[bossName] then
            return false
        end
        bossName = next(self.bossNames, bossName)
    until not bossName 
    addon.Utility.Debug("All bosses in fight are killed!", debug)
    return true
end

function BossFight:RegisterKill(targetName)
    if not self.bossNames[targetName] then
        return
    end
    self.bossesKilled[targetName] = true
    return true
end

function BossFight:Reset()
    ZO_ClearTable(self.bossesKilled)
    ZO_ClearTable(self.bossNames)
    addon.Utility.Debug("Reset boss fight.", debug)
end

function BossFight:UpdateBossNames()
    local newBossnames = {}
    local reset
    local bossNameArray = {}
    for bossIndex = 1, MAX_BOSSES do
        local bossName = GetUnitName("boss" .. tostring(bossIndex))
        bossNameArray[bossIndex] = bossName
        if bossName ~= "" then
            newBossnames[bossName] = true
            if not self.bossNames[bossName] then
                addon.Utility.Debug("Did not find boss name " .. tostring(bossName) .. " in boss names list.", debug)
                reset = true
            end
        end
    end
    if reset then
        self:Reset()
        addon.Utility.Debug("New bosses set: " .. table.concat(bossNameArray, ", "), debug)
        self.bossNames = newBossnames
    end
    return reset
end


---------------------------------------
--
--          Private Members
-- 
---------------------------------------



-- Create singleton
addon.BossFight = BossFight:New()