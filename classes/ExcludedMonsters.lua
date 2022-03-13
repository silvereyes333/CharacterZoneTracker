--[[ 
    ===============================================================
      Helps identify difficult monster names that are not bosses.
    ===============================================================
  ]]
  
local addon = CharacterZoneTracker
local debug = false
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
    targetName = zo_strlower(targetName)
    return monsterNames[targetName] == true
end


---------------------------------------
--
--          Private Members
-- 
---------------------------------------

EXCLUDED_MONSTER_NAMES = {
    ["de"] = {
        ["argonischer behemoth"] = true,
        ["beobachter"] = true,
        ["daedrischer titan"] = true,
        ["daedroth"] = true,
        ["der beobachter"] = true,
        ["draugr-leichnam"] = true,
        ["draugr-sturmfürstin"] = true,
        ["dremora-kynvogt"] = true,
        ["drublog-mammut"] = true,
        ["dwemersphäre"] = true,
        ["dwemerzenturio"] = true,
        ["eisenatronach"] = true,
        ["ernterin"] = true,
        ["flusstroll"] = true,
        ["frostatronach"] = true,
        ["frostbissspinne"] = true,
        ["frosttroll"] = true,
        ["gargyl"] = true,
        ["geisterriese"] = true,
        ["haj-mota"] = true,
        ["heimgesuchter zenturio"] = true,
        ["himmlischen-fledermaus"] = true,
        ["himmlischen-skorpion"] = true,
        ["hunger"] = true,
        ["irrlichtmutter"] = true,
        ["klippenhammerriese"] = true,
        ["knochenkoloss"] = true,
        ["krähenschrecken"] = true,
        ["mammut"] = true,
        ["mantikor"] = true,
        ["minotauren"] = true,
        ["minotaurenschamane"] = true,
        ["monströser troll"] = true,
        ["morastmergler"] = true,
        ["nereïde"] = true,
        ["nereïdenkaiserin"] = true,
        ["netchbulle"] = true,
        ["riese"] = true,
        ["riesenskorpion"] = true,
        ["schatten-blutunholdin"] = true,
        ["schleiererbe-koloss"] = true,
        ["spinnendaedra"] = true,
        ["sturmatronach"] = true,
        ["titan"] = true,
        ["troll"] = true,
        ["tundramammut"] = true,
        ["waldmammut"] = true,
        ["wamasu"] = true,
        ["weißsturzriese"] = true,
        ["zunderfliegenstock-golem"] = true,
        ["zwielichtschrecken"] = true,
    },
    ["en"] = {
        ["argonian behemoth"] = true,
        ["bone colossus"] = true,
        ["bull netch"] = true,
        ["celestial bat"] = true,
        ["celestial scorpion"] = true,
        ["craghammer giant"] = true,
        ["daedric titan"] = true,
        ["daedroth"] = true,
        ["draugr corpse"] = true,
        ["draugr stormlord"] = true,
        ["dremora kynreeve"] = true,
        ["drublog mammoth"] = true,
        ["dwarven centurion"] = true,
        ["dwarven sphere"] = true,
        ["fetcherfly hive golem"] = true,
        ["frost atronach"] = true,
        ["frost troll"] = true,
        ["frostbite spider"] = true,
        ["gargoyle"] = true,
        ["giant scorpion"] = true,
        ["giant"] = true,
        ["grievous twilight"] = true,
        ["haj mota"] = true,
        ["harvester"] = true,
        ["haunted centurion"] = true,
        ["hive golem"] = true,
        ["hunger"] = true,
        ["iron atronach"] = true,
        ["mammoth"] = true,
        ["mantikora"] = true,
        ["minotaur shaman"] = true,
        ["minotaur"] = true,
        ["miregaunt"] = true,
        ["monstrous troll"] = true,
        ["nereid empress"] = true,
        ["nereid"] = true,
        ["river troll"] = true,
        ["shadow bloodfiend"] = true,
        ["spider daedra"] = true,
        ["spirit giant"] = true,
        ["storm atronach"] = true,
        ["timber mammoth"] = true,
        ["titan"] = true,
        ["troll"] = true,
        ["tundra mammoth"] = true,
        ["veiled colossus"] = true,
        ["wamasu"] = true,
        ["watcher"] = true,
        ["white fall giant"] = true,
        ["wispmother"] = true,
        ["wraith-of-crows"] = true,
    },
    ["es"] = {
        ["argonian behemoth"] = true, --"81344020","0","830"
        ["bone colossus"] = true, --"8290981","0","12911"
        ["bull netch"] = true, --"8290981","0","21303"
        ["celestial bat"] = true, --"8290981","0","73466"
        ["celestial scorpion"] = true, --"8290981","0","73467"
        ["craghammer giant"] = true,--"8290981","0","17024"
        ["daedric titan"] = true,--"8290981","0","50146"
        ["daedroth"] = true,--"8290981","0","106454"
        ["draugr corpse"] = true,--"87370069","0","26983"
        ["draugr stormlord"] = true, --"8290981","0","54101"
        ["dremora kynreeve"] = true, --"191999749","0","2732"
        ["drublog mammoth"] = true, --"8290981","0","31254"
        ["dwarven centurion"] = true, --"168675493","0","4091"
        ["dwarven sphere"] = true, --"8290981","0","95940"
        ["fetcherfly hive golem"] = true, --"8290981","0","74370"
        ["frost atronach"] = true, --"168675493","0","3173"
        ["frost troll"] = true, --"8290981","0","96938"
        ["frostbite spider"] = true, --"18173141","0","7534"
        ["gargoyle"] = true, --"168675493","0","5576"
        ["giant"] = true, --"168675493","0","3268"
        ["giant scorpion"] = true, --"8290981","0","55181"
        ["grievous twilight"] = true, --"8290981","0","98921","1734544","grievous twilight^n"
        ["haj mota"] = true, --"8290981","0","70388"
        ["harvester"] = true, --"198758357","0","153912"
        ["haunted centurion"] = true, --"8290981","0","75399"
        ["hive golem"] = true, --"8290981","0","75754"
        ["hunger"] = true, --"8290981","0","81174"
        ["iron atronach"] = true, --"168675493","0","4709"
        ["mammoth"] = true, --"168675493","0","1889"
        ["mantikora"] = true, --"8290981","0","73119"
        ["miregaunt"] = true, --"168675493","0","5581"
        ["minotaur"] = true, --"98383029","0","39"
        ["minotaur shaman"] = true, --"8290981","0","76820"
        ["monstrous troll"] = true, --"8290981","0","58806"
        ["nereid"] = true, --"168675493","0","3827"
        ["nereid empress"] = true, --"8290981","0","48189"
        ["river troll"] = true, --"168675493","0","4024"
        ["shadow bloodfiend"] = true, --"8290981","0","71684"
        ["spider daedra"] = true, --"162946485","0","12653"
        ["spirit giant"] = true, --"8290981","0","73430"
        ["storm atronach"] = true, --"198758357","0","147943"
        ["timber mammoth"] = true, --"8290981","0","50389"
        ["titan"] = true, --"198758357","0","65742"
        ["troll"] = true, --"168675493","0","3620"
        ["tundra mammoth"] = true, --"8290981","0","17025"
        ["veiled colossus"] = true, --"8290981","0","39563"
        ["wamasu"] = true, --"8290981","0","88102"
        ["watcher"] = true, --"198758357","0","160530"
        ["white fall giant"] = true, --"8290981","0","49364"
        ["wispmother"] = true, --"168675493","0","3176"
        ["wraith-of-crows"] = true, --"168675493","0","4271"      
    },
    ["fr"] = {
        ["béhémoth argonien^m"] = true, --"81344020","0","830"
        ["colosse squelette^m"] = true, --"8290981","0","12911"
        ["netch mâle^m"] = true, --"8290981","0","21303"
        ["chauve-souris céleste^f"] = true, --"8290981","0","73466"
        ["scorpion céleste^m"] = true, --"8290981","0","73467"
        ["géant de pierremartel^m"] = true,--"8290981","0","17024"
        ["titan daedrique^m"] = true,--"8290981","0","45743"
        ["daedroth^n"] = true,--"8290981","0","106454"
        ["daedroth^m"] = true,--"8290981","0","106454"
        ["cadavre de draugr^m"] = true,--"87370069","0","26983"
        ["dame des tempêtes draugr^f"] = true, --"8290981","0","54101"
        ["kynreeve drémora^m"] = true, --"191999749","0","2732"
        ["kynreeve drémora^f"] = true, --"191999749","0","2732"
        ["mammouth drublog^m"] = true, --"8290981","0","31254"
        ["centurion dwemer^m"] = true, --"191999749","0","30699"
        ["dwarven sphere"] = true, --"8290981","0","95940"
        ["fetcherfly hive golem"] = true, --"8290981","0","74370"
        ["frost atronach"] = true, --"168675493","0","3173"
        ["frost troll"] = true, --"8290981","0","96938"
        ["frostbite spider"] = true, --"18173141","0","7534"
        ["gargoyle"] = true, --"168675493","0","5576"
        ["giant"] = true, --"168675493","0","3268"
        ["giant scorpion"] = true, --"8290981","0","55181"
        ["grievous twilight"] = true, --"8290981","0","98921","1734544","grievous twilight^n"
        ["haj mota"] = true, --"8290981","0","70388"
        ["harvester"] = true, --"198758357","0","153912"
        ["haunted centurion"] = true, --"8290981","0","75399"
        ["hive golem"] = true, --"8290981","0","75754"
        ["hunger"] = true, --"8290981","0","81174"
        ["iron atronach"] = true, --"168675493","0","4709"
        ["mammoth"] = true, --"168675493","0","1889"
        ["mantikora"] = true, --"8290981","0","73119"
        ["miregaunt"] = true, --"168675493","0","5581"
        ["minotaur"] = true, --"98383029","0","39"
        ["minotaur shaman"] = true, --"8290981","0","76820"
        ["monstrous troll"] = true, --"8290981","0","58806"
        ["nereid"] = true, --"168675493","0","3827"
        ["nereid empress"] = true, --"8290981","0","48189"
        ["river troll"] = true, --"168675493","0","4024"
        ["shadow bloodfiend"] = true, --"8290981","0","71684"
        ["spider daedra"] = true, --"162946485","0","12653"
        ["spirit giant"] = true, --"8290981","0","73430"
        ["storm atronach"] = true, --"198758357","0","147943"
        ["timber mammoth"] = true, --"8290981","0","50389"
        ["titan"] = true, --"198758357","0","65742"
        ["troll"] = true, --"168675493","0","3620"
        ["tundra mammoth"] = true, --"8290981","0","17025"
        ["veiled colossus"] = true, --"8290981","0","39563"
        ["wamasu"] = true, --"8290981","0","88102"
        ["watcher"] = true, --"198758357","0","160530"
        ["white fall giant"] = true, --"8290981","0","49364"
        ["wispmother"] = true, --"168675493","0","3176"
        ["wraith-of-crows"] = true, --"168675493","0","4271"
    },
    ["jp"] = {
        ["argonian behemoth"] = true, --"81344020","0","830"
        ["bone colossus"] = true, --"8290981","0","12911"
        ["bull netch"] = true, --"8290981","0","21303"
        ["celestial bat"] = true, --"8290981","0","73466"
        ["celestial scorpion"] = true, --"8290981","0","73467"
        ["craghammer giant"] = true,--"8290981","0","17024"
        ["daedric titan"] = true,--"8290981","0","45743"
        ["daedroth"] = true,--"8290981","0","106454"
        ["draugr corpse"] = true,--"87370069","0","26983"
        ["draugr stormlord"] = true, --"8290981","0","54101"
        ["dremora kynreeve"] = true, --"191999749","0","2732"
        ["drublog mammoth"] = true, --"8290981","0","31254"
        ["dwarven centurion"] = true, --"191999749","0","30699"
        ["dwarven sphere"] = true, --"8290981","0","95940"
        ["fetcherfly hive golem"] = true, --"8290981","0","74370"
        ["frost atronach"] = true, --"168675493","0","3173"
        ["frost troll"] = true, --"8290981","0","96938"
        ["frostbite spider"] = true, --"18173141","0","7534"
        ["gargoyle"] = true, --"168675493","0","5576"
        ["giant"] = true, --"168675493","0","3268"
        ["giant scorpion"] = true, --"8290981","0","55181"
        ["grievous twilight"] = true, --"8290981","0","98921","1734544","grievous twilight^n"
        ["haj mota"] = true, --"8290981","0","70388"
        ["harvester"] = true, --"198758357","0","153912"
        ["haunted centurion"] = true, --"8290981","0","75399"
        ["hive golem"] = true, --"8290981","0","75754"
        ["hunger"] = true, --"8290981","0","81174"
        ["iron atronach"] = true, --"168675493","0","4709"
        ["mammoth"] = true, --"168675493","0","1889"
        ["mantikora"] = true, --"8290981","0","73119"
        ["miregaunt"] = true, --"168675493","0","5581"
        ["minotaur"] = true, --"98383029","0","39"
        ["minotaur shaman"] = true, --"8290981","0","76820"
        ["monstrous troll"] = true, --"8290981","0","58806"
        ["nereid"] = true, --"168675493","0","3827"
        ["nereid empress"] = true, --"8290981","0","48189"
        ["river troll"] = true, --"168675493","0","4024"
        ["shadow bloodfiend"] = true, --"8290981","0","71684"
        ["spider daedra"] = true, --"162946485","0","12653"
        ["spirit giant"] = true, --"8290981","0","73430"
        ["storm atronach"] = true, --"198758357","0","147943"
        ["timber mammoth"] = true, --"8290981","0","50389"
        ["titan"] = true, --"198758357","0","65742"
        ["troll"] = true, --"168675493","0","3620"
        ["tundra mammoth"] = true, --"8290981","0","17025"
        ["veiled colossus"] = true, --"8290981","0","39563"
        ["wamasu"] = true, --"8290981","0","88102"
        ["watcher"] = true, --"198758357","0","160530"
        ["white fall giant"] = true, --"8290981","0","49364"
        ["wispmother"] = true, --"168675493","0","3176"
        ["wraith-of-crows"] = true, --"168675493","0","4271"
    },
    ["ru"] = {
        ["argonian behemoth"] = true, --"81344020","0","830"
        ["bone colossus"] = true, --"8290981","0","12911"
        ["bull netch"] = true, --"8290981","0","21303"
        ["celestial bat"] = true, --"8290981","0","73466"
        ["celestial scorpion"] = true, --"8290981","0","73467"
        ["craghammer giant"] = true,--"8290981","0","17024"
        ["daedric titan"] = true,--"8290981","0","45743"
        ["daedroth"] = true,--"8290981","0","106454"
        ["draugr corpse"] = true,--"87370069","0","26983"
        ["draugr stormlord"] = true, --"8290981","0","54101"
        ["dremora kynreeve"] = true, --"191999749","0","2732"
        ["drublog mammoth"] = true, --"8290981","0","31254"
        ["dwarven centurion"] = true, --"191999749","0","30699"
        ["dwarven sphere"] = true, --"8290981","0","95940"
        ["fetcherfly hive golem"] = true, --"8290981","0","74370"
        ["frost atronach"] = true, --"168675493","0","3173"
        ["frost troll"] = true, --"8290981","0","96938"
        ["frostbite spider"] = true, --"18173141","0","7534"
        ["gargoyle"] = true, --"168675493","0","5576"
        ["giant"] = true, --"168675493","0","3268"
        ["giant scorpion"] = true, --"8290981","0","55181"
        ["grievous twilight"] = true, --"8290981","0","98921","1734544","grievous twilight^n"
        ["haj mota"] = true, --"8290981","0","70388"
        ["harvester"] = true, --"198758357","0","153912"
        ["haunted centurion"] = true, --"8290981","0","75399"
        ["hive golem"] = true, --"8290981","0","75754"
        ["hunger"] = true, --"8290981","0","81174"
        ["iron atronach"] = true, --"168675493","0","4709"
        ["mammoth"] = true, --"168675493","0","1889"
        ["mantikora"] = true, --"8290981","0","73119"
        ["miregaunt"] = true, --"168675493","0","5581"
        ["minotaur"] = true, --"98383029","0","39"
        ["minotaur shaman"] = true, --"8290981","0","76820"
        ["monstrous troll"] = true, --"8290981","0","58806"
        ["nereid"] = true, --"168675493","0","3827"
        ["nereid empress"] = true, --"8290981","0","48189"
        ["river troll"] = true, --"168675493","0","4024"
        ["shadow bloodfiend"] = true, --"8290981","0","71684"
        ["spider daedra"] = true, --"162946485","0","12653"
        ["spirit giant"] = true, --"8290981","0","73430"
        ["storm atronach"] = true, --"198758357","0","147943"
        ["timber mammoth"] = true, --"8290981","0","50389"
        ["titan"] = true, --"198758357","0","65742"
        ["troll"] = true, --"168675493","0","3620"
        ["tundra mammoth"] = true, --"8290981","0","17025"
        ["veiled colossus"] = true, --"8290981","0","39563"
        ["wamasu"] = true, --"8290981","0","88102"
        ["watcher"] = true, --"198758357","0","160530"
        ["white fall giant"] = true, --"8290981","0","49364"
        ["wispmother"] = true, --"168675493","0","3176"
        ["wraith-of-crows"] = true, --"168675493","0","4271"
    },
}




-- Create singleton
addon.ExcludedMonsters = ExcludedMonsters:New()