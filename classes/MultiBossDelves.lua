--[[ 
    ============================================
      Tracking for Delves with Multiple Bosses 
    ============================================
  ]]
  
local addon = CharacterZoneTracker
local debug = false
local MULTIBOSS_DELVE_DATA

-- Singleton class
local MultiBossDelves = ZO_Object:Subclass()

function MultiBossDelves:New(...)
    local instance = ZO_Object.New(self)
    self.Initialize(instance, ...)
    return instance
end

function MultiBossDelves:Initialize()
  
end




---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function MultiBossDelves:AreAllBossesKilled(zoneId)
    local bossNames = self:GetBossList(zoneId)
    if not bossNames then
        return false
    end
    for bossIndex = 1, #bossNames do
        if not addon.Data:GetIsMultiBossDelveBossKilled(zoneId, bossIndex) then
            return false
        end
    end
    return true
end

function MultiBossDelves:IsZoneMultiBossDelve(zoneId)
    return MULTIBOSS_DELVE_DATA[zoneId] ~= nil
end

function MultiBossDelves:GetBossList(zoneId)
    local lang = string.lower(GetCVar("Language.2"))
    local delveData = MULTIBOSS_DELVE_DATA[zoneId]
    if not delveData then
        return
    end
    return delveData.bossNames[lang]
end

function MultiBossDelves:RegisterBossKill(zoneId, targetName)
    local bossNames = self:GetBossList(zoneId)
    if not bossNames then
        return
    end
    local bossIndex = ZO_IndexOfElementInNumericallyIndexedTable(bossNames, targetName)
    if not bossIndex then
        return
    end
    addon.Data:SetMultiBossDelveBossKilled(zoneId, bossIndex)
end



---------------------------------------
--
--          Private Members
-- 
---------------------------------------

MULTIBOSS_DELVE_DATA = {
  
    [497] = {
        ["zoneId"] = 497,
        ["parentZoneId"] = 181,
        ["activityIndex"] = 1,
        ["name"] = "Haynote Cave",
        ["poiId"] = 505,
        ["bossNames"] = {
            ["en"] = {
                "Theurgist Thelas",
                "Diabolist Volcatia"
            }
        }
    },
    
    [503] = {
        ["zoneId"] = 503,
        ["parentZoneId"] = 181,
        ["activityIndex"] = 2,
        ["name"] = "Pothole Caverns",
        ["poiId"] = 507,
        ["bossNames"] = {
            ["en"] = {
                "Serrin Vol",
                "Diabolist Vethisa",
                "Blighttooth"
            }
        }
    },
    
    [501] = {
        ["zoneId"] = 501,
        ["parentZoneId"] = 181,
        ["activityIndex"] = 3,
        ["name"] = "Newt Cave",
        ["poiId"] = 512,
        ["bossNames"] = {
            ["en"] = {
                "Graveltooth",
                "Rock Wing"
            }
        }
    },
    
    [505] = 
    {
        ["zoneId"] = 505,
        ["parentZoneId"] = 181,
        ["activityIndex"] = 6,
        ["name"] = "Red Ruby Cave",
        ["poiId"] = 630,
        ["bossNames"] = {
            ["en"] = {
                "Endare",
                "Zandur"
            }
        }
    },
    
    [502] = {
        ["zoneId"] = 502,
        ["parentZoneId"] = 181,
        ["activityIndex"] = 4,
        ["name"] = "Nisin Cave",
        ["poiId"] = 534,
        ["bossNames"] = {
            ["en"] = {
                "Barasatii",
                "Volgo the Harrower"
            }
        }
    },
    
    -- Underpall Cave, Cyrodiil
    [533] = {
        ["zoneId"] = 533,
        ["parentZoneId"] = 181,
        ["activityIndex"] = 17,
        ["name"] = "Underpall Cave",
        ["poiId"] = 510,
        ["bossNames"] = {
            ["en"] = {
                "Raelynne Ashham",
                "Emelin the Returned"
            }
        }
    }
}


-- Create singleton
addon.MultiBossDelves = MultiBossDelves:New()