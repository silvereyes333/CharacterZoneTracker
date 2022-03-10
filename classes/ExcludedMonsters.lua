--[[ 
    ===============================================================
      Helps identify difficult monster names that are not bosses.
    ===============================================================
  ]]
  
local addon = CharacterZonesAndBosses
local debug = true
local EXCLUDED_MONSTER_NAMES

-- Singleton class
local ExcludedMonsters = ZO_Object:Subclass()

function ExcludedMonsters:New(...)
    local instance = ZO_Object.New(self)
    self.Initialize(instance, ...)
    return instance
end

function ExcludedMonsters:Initialize()
end




---------------------------------------
--
--          Public Methods
-- 
---------------------------------------

function ExcludedMonsters:IsExcludedMonster(targetName)
    local lang = string.lower(GetCVar("Language.2"))
    local monsterNames = EXCLUDED_MONSTER_NAMES[lang]
    return monsterNames[targetName] == true
end


---------------------------------------
--
--          Private Members
-- 
---------------------------------------

EXCLUDED_MONSTER_NAMES = {
    ["de"] = {
      
    },
    ["en"] = {
        ["Argonian Behemoth"] = true, --"8290981","0","87364"
        ["Bone Colossus"] = true, --"8290981","0","12911"
        ["Bull Netch"] = true, --"8290981","0","21303"
        ["Celestial Bat"] = true, --"8290981","0","73466"
        ["Celestial Scorpion"] = true, --"8290981","0","73467"
        ["Craghammer Giant"] = true,--"8290981","0","17024"
        ["Daedric Titan"] = true,--"8290981","0","50146"
        ["Daedroth"] = true,--"198758357","0","39557"
        ["Draugr Corpse"] = true,--"87370069","0","26983"
        ["Draugr Stormlord"] = true, --"8290981","0","54101"
        ["Dremora Kynreeve"] = true, --"191999749","0","2732"
        ["Drublog Mammoth"] = true, --"8290981","0","31254"
        ["Dwarven Centurion"] = true, --"168675493","0","4091"
        ["Dwarven Sphere"] = true, --"8290981","0","95940"
        ["Fetcherfly Hive Golem"] = true, --"8290981","0","74370"
        ["Frost Atronach"] = true,
        ["Frost Troll"] = true,
        ["Frostbite Spider"] = true,
        ["Gargoyle"] = true,
        ["Giant"] = true,
        ["Giant Scorpion"] = true,
        ["Grievous Twilight"] = true,
        ["Haj Mota"] = true,
        ["Harvester"] = true,
        ["Haunted Centurion"] = true,
        ["Hive Golem"] = true,
        ["Hunger"] = true,
        ["Iron Atronach"] = true,
        ["Mammoth"] = true,
        ["Mantikora"] = true,
        ["Miregaunt"] = true,
        ["Minotaur"] = true,
        ["Minotaur Shaman"] = true,
        ["Monstrous Troll"] = true,
        ["Nereid"] = true,
        ["Nereid Empress"] = true,
        ["River Troll"] = true,
        ["Shadow Bloodfiend"] = true,
        ["Spider Daedra"] = true,
        ["Spirit Giant"] = true,
        ["Storm Atronach"] = true,
        ["Timber Mammoth"] = true,
        ["Titan"] = true,
        ["Troll"] = true,
        ["Troll Brute"] = true,
        ["Tundra Mammoth"] = true,
        ["Veiled Colossus"] = true,
        ["Wamasu"] = true,
        ["Watcher"] = true,
        ["White Fall Giant"] = true,
        ["Wispmother"] = true,
        ["Wraith-of-Crows"] = true,
    },
    ["es"] = {
      
    },
    ["fr"] = {
      
    },
    ["jp"] = {
      
    },
    ["ru"] = {
      
    },
}




-- Create singleton
addon.ExcludedMonsters = ExcludedMonsters:New()