-- BabbleZone
local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()

-- defining list of paladin auras (for sanctified retribution, since any aura could give the buff)
local PALADIN_AURA_LIST = {}
PALADIN_AURA_LIST[GetSpellInfo(465)] = true
PALADIN_AURA_LIST[GetSpellInfo(7294)] = true
PALADIN_AURA_LIST[GetSpellInfo(19746)] = true
PALADIN_AURA_LIST[GetSpellInfo(19876)] = true
PALADIN_AURA_LIST[GetSpellInfo(19888)] = true
PALADIN_AURA_LIST[GetSpellInfo(19891)] = true
PALADIN_AURA_LIST[GetSpellInfo(32223)] = true

-- defining list of paladin auras (for sanctified retribution, since any aura could give the buff)
local ROGUE_POISON_LIST = {}
ROGUE_POISON_LIST[GetSpellInfo(57970)] = true -- deadly
ROGUE_POISON_LIST[GetSpellInfo(57965)] = true -- instant
ROGUE_POISON_LIST[GetSpellInfo(57978)] = true -- wound 
ROGUE_POISON_LIST[GetSpellInfo(57981)] = true -- anesthesic

-- define criteria functions used
local function isPriest()
   local _, class = UnitClass("player")
   return class == "PRIEST"
end

local function isHunter()
   local _, class = UnitClass("player")
   return class == "HUNTER"
end

local function hasItem(itemNumberChecked)
   for slotId=0, 19 do
      local itemLink = GetInventoryItemLink("player", slotId)
      if itemLink then
         local _, _, _, _, itemNumber = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
         if (itemNumber+0) == itemNumberChecked then
            return true
         end 
      end
   end

   -- Dalaran-WoW Nevermelting Ice Crystal behavior.
   if itemNumberChecked ~= 50259 then
      return false
	end
   
   for bag = 0,4 do
      for slot=1,GetContainerNumSlots(bag) do
         local sItemLink = GetContainerItemLink(bag, slot)
         if sItemLink then
            local _, _, _, _, sItemNumber = string.find(sItemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
            if (sItemNumber+0) == itemNumberChecked then
               return true
            end 
         end
      end
   end

   return false
end

local function hasSetBonus(setBonusNumber, completeSetItemNumbers)
   local setItemEquippedCount = 0
   for _, itemNumber in pairs(completeSetItemNumbers) do
      if hasItem(itemNumber) then
         setItemEquippedCount = setItemEquippedCount + 1
      end
   end
   return setItemEquippedCount >= setBonusNumber
end

function isInZone(zoneNameChecked)
   local zoneName = GetRealZoneText()
   return zoneNameChecked == zoneName
end

ShadowGreenLight.upgradeDb = {
	-------------------------------------
	-- ShadowWeave
	["ShadowWeave"] = {
		name = GetSpellInfo(15257),
		maxCount = 5,
		upgradePerStack = 2,
		type = "Shadow Weaving",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "dmg",
		isApplicable = isPriest,
		applicabilityArgs = {},
	},
	["Culling the Herd"] = {
		name = GetSpellInfo(52858),
		maxCount = 1,
		upgradePerStack = 3,
		type = "Culling the Herd",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "dmg",
		isApplicable = isHunter,
		applicabilityArgs = {},
	},
	["Aspect of the Viper"] = {
		name = GetSpellInfo(34074),
		maxCount = 1,
		upgradePerStack = -50,
		type = "Aspect of the Viper",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = false,
		upgradeType = "dmg",
		isApplicable = isHunter,
		applicabilityArgs = {},
	},
	-------------------------------------
	-- Talent-based upgrades
	["Improved Scorch"] = {
		name = GetSpellInfo(11095),
		talentName = GetSpellInfo(11095),
		maxCount = 1,
		upgradePerStack = 5,
		type = "Spell Critical Strike Chance Debuff",
		detectionUnit = "target",
		detectionType = "debuff",
		upgradeType = "crit",
		upgradeRestriction = "spell",
	},
	["Improved Shadow Bolt"] = {
		name = GetSpellInfo(18275),
		talentName = GetSpellInfo(17803),
		maxCount = 1,
		upgradePerTalentRank = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
		},
		type = "Spell Critical Strike Chance Debuff",
		detectionUnit = "target",
		detectionType = "debuff",
		upgradeType = "crit",
		upgradeRestriction = "spell",
	},
	["Winter's Chill"] = {
		name = GetSpellInfo(11180),
		talentName = GetSpellInfo(11180),
		maxCount = 5,
		upgradePerStack = 1,
		type = "Spell Critical Strike Chance Debuff",
		detectionUnit = "target",
		detectionType = "debuff",
		upgradeType = "crit",
		upgradeRestriction = "spell",
	},
	["Totem of Wrath"] = {
		name = GetSpellInfo(57722),
		talentName = GetSpellInfo(57722),
		maxCount = 1,
		upgradePerStack = 3,
		type = "Critical Strike Chance Taken Debuff",
		detectionUnit = "target",
		detectionType = "debuff",
		upgradeType = "crit",
	},
	["Heart of the Crusader"] = {
		name = GetSpellInfo(20337),
		talentName = GetSpellInfo(20337),
		maxCount = 1,
		upgradePerTalentRank = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
		},
		type = "Critical Strike Chance Taken Debuff",
		detectionUnit = "target",
		detectionType = "debuff",
		upgradeType = "crit",
	},
	["Master Poisoner"] = {
		name = GetSpellInfo(58410),
		affectingAuraNames = ROGUE_POISON_LIST,
		providerIsSignificant = true,
		talentName = GetSpellInfo(58410),
		maxCount = 1,
		upgradePerTalentRank = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
		},
		type = "Critical Strike Chance Taken Debuff",
		detectionUnit = "target",
		detectionType = "debuff",
		upgradeType = "crit",
	},
	["Moonkin Aura"] = {
		name = GetSpellInfo(24907),
		talentName = GetSpellInfo(24858),
		maxCount = 1,
		upgradePerStack = 5,
		type = "Spell Critical Strike Chance Buff",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "crit",
		upgradeRestriction = "spell",
	},
	["Elemental Oath"] = {
		name = GetSpellInfo(51470),
		talentName = GetSpellInfo(51470),
		maxCount = 1,
		upgradePerTalentRank = {
			[1] = 3,
			[2] = 5,
		},
		type = "Spell Critical Strike Chance Buff",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "crit",
		upgradeRestriction = "spell",
	},
	["Leader of the Pack"] = {
		name = GetSpellInfo(24932),
		talentName = GetSpellInfo(24932),
		maxCount = 1,
		upgradePerStack = 5,
		type = "Physical Critical Strike Chance Buff",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "crit",
		upgradeRestriction = "physical",
	},
	["Rampage"] = {
		name = GetSpellInfo(29801),
		talentName = GetSpellInfo(29801),
		maxCount = 1,
		upgradePerStack = 5,
		type = "Physical Critical Strike Chance Buff",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "crit",
		upgradeRestriction = "physical",
	},
	["Arcane Empowerment"] = {
		name = GetSpellInfo(31579),
		talentName = GetSpellInfo(31579),
		maxCount = 1,
		upgradePerTalentRank = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
		},
		type = "Percentage Damage Increase",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "dmg",
	},
	["Ferocious Inspiration"] = {
		name = GetSpellInfo(34455),
		talentName = GetSpellInfo(34455),
		maxCount = 1,
		upgradePerTalentRank = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
		},
		type = "Percentage Damage Increase",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "dmg",
	},
	["Sanctified Retribution"] = {
		name = GetSpellInfo(31869),
		affectingAuraNames = PALADIN_AURA_LIST,
		providerIsSignificant = true,
		talentName = GetSpellInfo(31869),
		maxCount = 1,
		upgradePerStack = 3,
		type = "Percentage Damage Increase",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "dmg",
	},
	-------------------------------------
	-- Player-based bonus
	["Tricks of the Trade"] = {
		name = GetSpellInfo(57934),
		maxCount = 1,
		upgradePerStack = 15,
		type = "Tricks of the Trade",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = true,
		upgradeType = "dmg",
	},
	["Wild Magic"] = {
		name = GetSpellInfo(53909),
		upgradePerStack = 200/45.91,
		maxCount = 1,
		type = "Wild Magic",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = true,
		upgradeType = "crit",
	},
	-------------------------------------
	-- Encounter specific bonus
	-- Malygos
	["Power Spark"] = {
		name = GetSpellInfo(56152),
		upgradePerStack = 50,
		maxCount = 10,
		type = "Encounter Specific - Malygos",
		detectionUnit = "player",
		detectionType = "debuff",
		multipleAuraInstanceStack = true,	-- Set to true only if there can be multiple auras with same name and effects stacks
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["The Eye of Eternity"]},
	},
	-- Naxxramas
	["Fungal Creep"] = {
		name = GetSpellInfo(29232),
		upgradePerStack = 50,
		maxCount = 1,
		type = "Encounter Specific - Loatheb",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = true,
		upgradeType = "crit",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Naxxramas"]},
	},
	["Negative Charge"] = {
		name = GetSpellInfo(39091),
		upgradePerStack = 10,
		maxCount = 25,
		type = "Encounter Specific - Thaddius",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = true,
		hasToBeStackable = true,	-- Only set this attribute to true if competing with another non-stackable aura with same name
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Naxxramas"]},
	},
	["Positive Charge"] = {
		name = GetSpellInfo(39089),
		upgradePerStack = 10,
		maxCount = 25,
		type = "Encounter Specific - Thaddius",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = true,
		hasToBeStackable = true,	-- Only set this attribute to true if competing with another non-stackable aura with same name
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Naxxramas"]},
	},
	-- Ulduar
	["Unstable Sun Beam"] = {
		name = GetSpellInfo(62243),
		upgradePerStack = 5,
		maxCount = 1,
		type = "Encounter Specific - Freya",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Ulduar"]},
	},
	["Shadow Crash"] = {
		name = GetSpellInfo(63277),
		upgradePerStack = 100,
		maxCount = 1,
		type = "Encounter Specific - Vezax",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Ulduar"]},
	},
	["Rune of Power"] = {
		name = GetSpellInfo(64320),
		upgradePerStack = 50,
		maxCount = 2,
		type = "Encounter Specific - Iron Council",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Ulduar"]},
	},
	["Sara's fervor"] = {
		name = GetSpellInfo(63138),
		upgradePerStack = 20,
		maxCount = 1,
		type = "Encounter Specific - Yogg Saron",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Ulduar"]},
	},
	-- Trial of the Crusader
	["Empowered Light"] = {
		name = GetSpellInfo(67218),
		upgradePerStack = 100,
		maxCount = 1,
		type = "Encounter Specific - Valkyr Twins",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Trial of the Crusader"]},
	},
	["Empowered Darkness"] = {
		name = GetSpellInfo(67215),
		upgradePerStack = 100,
		maxCount = 1,
		type = "Encounter Specific - Valkyr Twins",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Trial of the Crusader"]},
	},
	-- Icecrown citadel
	["Essence of the Blood Queen"] = {
		name = GetSpellInfo(71473),
		upgradePerStack = 100,
		maxCount = 1,
		type = "Encounter Specific - Blood Queen Lana'thel",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Icecrown Citadel"]},
	},
	["Gastric Bloat"] = {
		name = GetSpellInfo(72551),
		upgradePerStack = 10,
		maxCount = 9,
		type = "Encounter Specific - Festergut",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = true,
		upgradeType = "dmg",
		isApplicable = isInZone,
		applicabilityArgs = {BZ["Icecrown Citadel"]},
	},
	-------------------------------------
	-- Gear-specific upgrade
	["Nevermelting Ice Crystal"] = {
		name = GetSpellInfo(71563),
		upgradePerStack = 184/45.91,
		maxCount = 5, 
		type = "Trinket - Nevermelting Ice Crystal",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "crit",
		isApplicable = hasItem,
		applicabilityArgs = {50259},
	},
	["Devious Minds"] = {	-- 4T10 Warlock set bonus
		name = GetSpellInfo(70840),
		maxCount = 1,
		upgradePerStack = 10,
		type = "Warlock 4T10 set bonus",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "dmg",
		isApplicable = hasSetBonus,
		applicabilityArgs = {4, {51230, 51231, 51232, 51233, 51234, 51205, 51206, 51207, 51208, 51209, 50240, 50241, 50242, 50243, 50244}},
	},
	["Exploit Weakness"] = { -- Hunter t10 proc
		name = GetSpellInfo(70728),
		maxCount = 1,
		upgradePerStack = 15,
		type = "Hunter 2T10 set bonus",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "dmg",
		isApplicable = hasSetBonus,
		applicabilityArgs = {2, {50114, 50115, 50116, 50117, 50118, 51150, 51151, 51152, 51153, 51154, 51285, 51286, 51287, 51288, 51289}},
	},
	-----------------------------
	-- Test purposes
	--[[["Weakened Soul"] = {
		name = GetSpellInfo(6788),
		upgradePerStack = 10,
		maxCount = 1,
		type = "Encounter Specific - Test",
		detectionUnit = "player",
		detectionType = "debuff",
		isBonus = false,
		multipleAuraInstanceStack = false,	-- Set to true only if there can be multiple auras with same name and effects stacks
		upgradeType = "crit",
	},
	["Renew"] = {
		name = GetSpellInfo(139),
		upgradePerStack = 30,
		maxCount = 1,
		type = "Encounter Specific - Test2",
		detectionUnit = "player",
		detectionType = "buff",
		isBonus = false,
		multipleAuraInstanceStack = true,	-- Set to true only if there can be multiple auras with same name and effects stacks
		upgradeType = "crit",
	},	
	["Dummy Talent"] = {
		name = GetSpellInfo(15337),
		talentName = GetSpellInfo(15270),
		maxCount = 1,
		upgradePerTalentRank = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
		},
		type = "Dummy talent",
		detectionUnit = "player",
		detectionType = "buff",
		upgradeType = "crit",
	},]]--
}