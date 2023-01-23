--[[

]]--

local _DEBUG = false
local _UPDATEDISPLAY_RATE = 0.2
local _CHECKSOUNDALERT_RATE = 5
local SPELL_SWP = GetSpellInfo(589)
local SPELL_CORRUPTION = GetSpellInfo(172)
local SPELL_SERPENT_STING = GetSpellInfo(1978)
local SPELL_GLYPH_QUICK_DECAY = GetSpellInfo(70947)
local TALENT_DEATH_EMBRACE = GetSpellInfo(47198)
local TALENT_PAIN_AND_SUFFERING = GetSpellInfo(47580)
local TALENT_EVERLASTING_AFFLICTION = GetSpellInfo(47201)
local TALENT_CHIMERA_SHOT = GetSpellInfo(53209)
local DEATH_EMBRACE_MULTIPLIER = 4
local CR_HASTE_SPELL = CR_HASTE_SPELL or 20
local DPS_COMPUTATION_WINDOW_LENGTH = 10
local MEAN_DPS_COMPUTATION_WINDOW_LENGTH = 10


local COMBATLOG_OBJECT_AFFILIATION_MINE		= COMBATLOG_OBJECT_AFFILIATION_MINE		or 0x00000001
local COMBATLOG_OBJECT_REACTION_HOSTILE		= COMBATLOG_OBJECT_REACTION_HOSTILE		or 0x00000040
local COMBATLOG_OBJECT_TYPE_NPC				= COMBATLOG_OBJECT_TYPE_NPC				or 0x00000800
local hostileNPCMask = COMBATLOG_OBJECT_REACTION_HOSTILE+COMBATLOG_OBJECT_TYPE_NPC

ShadowGreenLight = LibStub("AceAddon-3.0"):NewAddon("ShadowGreenLight", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local LGT = LibStub('LibGroupTalents-1.0')
local LSM = LibStub("LibSharedMedia-3.0")

function ShadowGreenLight:OnInitialize()
  	-- Initialization of attributes
  	self.maxUpgrade = 0
	self.currentUpgrade = 0
	self.lastDotUpgrade = {}
	self.LastDotBaseCritPct = {}
	self.lastDotSpellPower = {}
	self.critPctWithoutRaidBuffs = 0
	self.upgradeList = {}
	self.buffProviders = {}
	self.currentTooltipUpgradeList = {}
	self.raidUpgradeAvailable = {}
	self.isInCombat = false
	self.isDisplayed = false
	self.dpslog = {
		["first"] = 1,
		["last"] = 0,
	}
	self.hasteAffectsDotTicks = false
	self.deathEmbraceInvestment = 0
	self.lastDotTick = 0
	self.soundAlert = false
	self.class = ""
	
	self.lastSpellTarget = ""
  	
  	-- Initialization of session db
  	self.db = LibStub("AceDB-3.0"):New("ShadowGreenLightDB", {
  		profile = {
  			selectedDisplay = "Default",
  			debug = false,
  			soundAlertThreshold = 60,
  			soundAlertSound = "None",
		}
	}, "Default")
	
	-- Add standard options
	self:ResetOptions()
	-- Add selected plugin options
	self:BuildSelectedDisplayPluginShortcutOptions()
	
	-- Registering chat commands
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ShadowGreenLight", self.options, {"sgl", "ShadowGreenLight"})
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ShadowGreenLight", "ShadowGreenLight")
end

function ShadowGreenLight:OnEnable()
	-- Registering player entering world
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnteringWorld")
end

function ShadowGreenLight:OnDisable()
    -- Callback for talent query
    LGT.UnregisterCallback(self, "LibGroupTalents_Update")
end

local function getRealmedName(unit)
	local name, realm = UnitName(unit)

	if realm ~= nil and realm ~= "" then
		name = name .. "-" .. realm
	end

	return name
end

function ShadowGreenLight:Debug(...)
	if self.db.profile.debug then
		self:Print(...)
	end
end

function ShadowGreenLight:OnEnteringWorld()
	local _, class = UnitClass("player")
	self.class = class
	if class == "PRIEST" or class=="WARLOCK" or class=="HUNTER" then
		-- Registering events to enter/exit combat
		self:RegisterEvent("PLAYER_REGEN_DISABLED", "EnteringCombat")
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ExitingCombat")
		-- Registering callback for LibGroupTalents
		LGT.RegisterCallback(self, 'LibGroupTalents_Update')
		-- sets the spell to follow depending on class
		if class == "PRIEST" then
			self.affectedDot = SPELL_SWP
		elseif class == "HUNTER" then
			self.affectedDot = SPELL_SERPENT_STING
		else
			self.affectedDot = SPELL_CORRUPTION
		end
		-- Create display
		self:CreateDisplay()
		-- Go to idle state
		self:SelectedDisplayToIdleState()
	end
end

function ShadowGreenLight:BuildSelectedDisplayPluginShortcutOptions()
	local display = self.registeredDisplays[self.db.profile.selectedDisplay]
	--if not display then display = self.registeredDisplays["Default"] end
	
	self.options.args.displayPlugin.args = display.options
	self.options.args.displayPlugin.name = "Display plugin - " .. self.db.profile.selectedDisplay
end

--------------------------------------------------
-- Display registering methods
function ShadowGreenLight:RegisterDisplay(name, object)
	if not self.registeredDisplays then
		self.registeredDisplays = {}
	end
	self.registeredDisplays[name] = object
	object.name = name
end

--------------------------------------------------
-- Display methods
function ShadowGreenLight:CreateDisplay()
	local display = self.registeredDisplays[self.db.profile.selectedDisplay]
	--if not display then display = self.registeredDisplays["Default"] end
	display:CreateDisplay()
end

function ShadowGreenLight:UpdateSelectedDisplay()
	if not self.isDisplayed then
		return
	end
	local unitGUID = UnitGUID("target")
	if unitGUID and not self.lastDotUpgrade[unitGUID] then
		self.lastDotUpgrade[unitGUID] = 0
		self.lastDotSpellPower[unitGUID] = 0
	end
	
	local display = self.registeredDisplays[self.db.profile.selectedDisplay]
	display:UpdateDisplay()
end


function ShadowGreenLight:SelectedDisplaySetShown(isShown)
	local display = self.registeredDisplays[self.db.profile.selectedDisplay]
	
	display:SetShown(isShown)
end

function ShadowGreenLight:SelectedDisplayToIdleState()
	local display = self.registeredDisplays[self.db.profile.selectedDisplay]
	display:DisplayToIdleState()
end

--------------------------------------------------
-- Internal logic methods

function ShadowGreenLight:EnteringCombat()
	local display = self.registeredDisplays[self.db.profile.selectedDisplay]
	--if not display then display = self.registeredDisplays["Default"] end
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "handleSpellcast")
	self:RegisterEvent("UNIT_SPELLCAST_SENT", "handleSpellCastAttempt")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "handleCombatLogEvent")
	self.updateDisplayTimer = self:ScheduleRepeatingTimer("UpdateSelectedDisplay", _UPDATEDISPLAY_RATE)
	self.checkSoundAlertTimer = self:ScheduleRepeatingTimer("CheckSoundAlert", _CHECKSOUNDALERT_RATE)
	
	
	display:UpdateDisplay_OnEnteringCombat()
		
	self.soundAlert = false
	self.isInCombat = true
	
	-- Resetting dpslog
	local log = self.dpslog
	for i = log.first, log.last do
		log[i] = nil
	end
	log.first = 1
	log.last = 0
	self.lastDotTick = 0
	
	-- Detecting quick decay glyph
	self.hasteAffectsDotTicks = false
	for socketID = 1, GetNumGlyphSockets() do
		local _, _, glyphSpellID = GetGlyphSocketInfo(socketID, GetActiveTalentGroup(false, false))
		if glyphSpellID == SPELL_GLYPH_QUICK_DECAY then
			self.hasteAffectsDotTicks = true
		end
	end
	
	self:PopulateUpgradeList()
	self:ComputeCritPctWithoutRaidBuffs()
	self:ComputeMaxUpgrade()
end

function ShadowGreenLight:ExitingCombat()
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:CancelTimer(self.updateDisplayTimer)
	self.updateDisplayTimer = nil
	self:CancelTimer(self.checkSoundAlertTimer)
	self.checkSoundAlertTimer = nil
	--self.lastDotUpgrade = {}
	--self.lastDotSpellPower = {} Don't clear data as feign death can be used during fight
	
	local display = self.registeredDisplays[self.db.profile.selectedDisplay]
	display:UpdateDisplay_OnExitingCombat()
	
	self.soundAlert = false
	self.isInCombat = false
	self.dpslog.firstCombatEventTimeStamp = nil
end

function ShadowGreenLight:TargetChanged()
	self.soundAlert = false
	self.dpslog.firstCombatEventTimeStamp = nil
	
	-- Resetting dpslog
	local log = self.dpslog
	for i = log.first, log.last do
		log[i] = nil
	end
	log.first = 1
	log.last = 0
	self.lastDotTick = 0	
	
	self:UpdateSelectedDisplay()
end

--------------------------------------------------
-- Detecting SW:P application
function ShadowGreenLight:handleSpellcast(event, unit, spellName, ...)
    if unit == "player" and spellName == self.affectedDot and UnitName("target") == self.lastSpellTarget then
    	local unitGUID = UnitGUID("target")
		self.LastDotBaseCritPct[unitGUID] = self:ComputeCritPctWithoutRaidBuffs()
        self.lastDotUpgrade[unitGUID] = self:ComputeCurrentUpgrade()
        self.lastDotSpellPower[unitGUID] = GetSpellBonusDamage(6)
    end
end

--Detect what the last cast attempt's target was.
--Mouseover casts are still handled incorrectly when multiple units with the same name are involved.
--Upgrade is not computed correctly for mouseover targets, but this fixes fixes main target's corruption being overridden.
function ShadowGreenLight:handleSpellCastAttempt(event, unit, spellName, spellRank, target)
    if unit == "player" and spellName == self.affectedDot then
		self.lastSpellTarget = target
    end
end

--------------------------------------------------
-- Logging dmg events
function ShadowGreenLight:handleCombatLogEvent(event, timeStamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
    if srcName == UnitName("player") and dstName == UnitName("target") then
		local prefix, suffix, special = strsplit("_", eventType)
		if suffix == "DAMAGE" or special=="DAMAGE" then
			if not self.dpslog.firstCombatEventTimeStamp then self.dpslog.firstCombatEventTimeStamp = timeStamp end
			local _, spellName, _, dmg, _, _, resisted, blocked, absorbed, critical = ...
			resisted = resisted or 0
			blocked = blocked or 0
			absorbed = absorbed or 0
			
			local log = self.dpslog
	    	-- logging new entry
			local entry = {}
			entry.timeStamp = timeStamp
			entry.dmg = dmg or 0
			if log.last > 0 and log[log.last].totalWindowedDmg then
				entry.totalWindowedDmg = log[log.last].totalWindowedDmg + entry.dmg
			else
				entry.totalWindowedDmg = entry.dmg
			end
			log.last = log.last + 1
			log[log.last] = entry
			-- cleanup old entries
			for i = log.first, log.last do
				if log[i].timeStamp < timeStamp - DPS_COMPUTATION_WINDOW_LENGTH then
					entry.totalWindowedDmg = entry.totalWindowedDmg - log[i].dmg
					log[i] = nil
					log.first = log.first + 1
				else
					break
				end
			end
			-- Compute instant DPS
			if log.last == log.first then
				entry.instantDPS = 0
			else
				entry.instantDPS = entry.totalWindowedDmg / (log[log.last].timeStamp - log[log.first].timeStamp)
			end
			
			-- use last SWP tick value to compute instant SWP mean value
			if spellName == self.affectedDot then
				self.lastDotTick = dmg + resisted + blocked + absorbed
				if critical then
					self.lastDotTick = self.lastDotTick / 2
				end
				self.lastDotTick = self.lastDotTick * (1+self:GetCritChance()/100)
			end
	    end
		if suffix == "AURA" and special == "REMOVED" then
			local _, spellName, _, dmg, _, _ = ...
			if spellName == self.affectedDot then
				self.lastDotUpgrade[dstGUID] = None
				self.LastDotBaseCritPct[dstGUID] = None
			end
		end
	end
end

---------------------------------------------------
-- Talent scanning

-- Handle LibGroupTalents_Update event
function ShadowGreenLight:LibGroupTalents_Update(_, _, unit)
	local name = getRealmedName(unit)
	self:Debug("Talent info received for ", name)
	
	-- resetting talent info for this raidmember
	self.raidUpgradeAvailable[name] = {}
	
	-- Scan spells in upgrade database (except shadowweave)
	for upgradeName, upgrade in pairs(self.upgradeDb) do
		-- skip non talents
		if upgrade.talentName then
			-- Get talent related to upgrade
			local investment = LGT:UnitHasTalent(unit, upgrade.talentName)
			if investment and investment > 0 then
				if not self.raidUpgradeAvailable[name] then
					self.raidUpgradeAvailable[name] = {}
				end
				if not self.raidUpgradeAvailable[name][upgradeName] then
					self.raidUpgradeAvailable[name][upgradeName] = {}
					for attributeName, attributeValue in pairs(upgrade) do
						--self:Debug(name, upgradeName, attributeName)
						self.raidUpgradeAvailable[name][upgradeName][attributeName] = attributeValue
					end
					-- upgrade per stack can be dependant on talent point investment
					if upgrade.upgradePerTalentRank then
						self.raidUpgradeAvailable[name][upgradeName].upgradePerStack = upgrade.upgradePerTalentRank[investment]
					end
				end
				self:Debug(name .. " > " .. upgradeName .. " > " .. self.raidUpgradeAvailable[name][upgradeName].upgradePerStack)
			end 
		end
	end
	
	-- Handling the case where unit is player to show/hide based
	if UnitIsUnit(unit, "player") then
		if self.class == "WARLOCK" then
			-- detect death embrace
			self.deathEmbraceInvestment = LGT:UnitHasTalent(unit, TALENT_DEATH_EMBRACE) or 0
			-- detect if warlock currently affli specced
			local investment = LGT:UnitHasTalent(unit, TALENT_EVERLASTING_AFFLICTION) or 0
			self.isDisplayed = (investment > 0) 
		elseif self.class == "PRIEST" then
			-- detect if priest currently shadow specced
			local investment = LGT:UnitHasTalent(unit, TALENT_PAIN_AND_SUFFERING) or 0
			self.isDisplayed = (investment > 0)
		elseif self.class == "HUNTER" then
			local investment = LGT:UnitHasTalent(unit, TALENT_CHIMERA_SHOT) or 0
			self.isDisplayed = (investment > 0)
		end
		if self.isDisplayed then
			self:SelectedDisplaySetShown(true)
		else
			self:SelectedDisplaySetShown(false)
		end
	end
end

---------------------------------------------------
-- Upgrade computation

function ShadowGreenLight:ComputeCurrentUpgrade()
	local currentUpgradeList = {
		["crit"]={},
		["dmg"]={},
	}
	self:ComputeCritPctWithoutRaidBuffs()
	
	local isBonus = false
	
	-- Reset current stack count in upgrade list for tooltip
	for upgradeType in pairs(self.currentTooltipUpgradeList) do
	    for upgradeName in pairs(self.currentTooltipUpgradeList[upgradeType]) do
	       self.currentTooltipUpgradeList[upgradeType][upgradeName].currentStack = 0
	    end
	end
	
	-- processing the death's embrace for warlocks
	if self.deathEmbraceInvestment > 0 then
		if UnitExists("target") and UnitHealth("target")/UnitHealthMax("target")<=0.35 then
			currentUpgradeList["dmg"]["Death's Embrace"] = self.deathEmbraceInvestment * DEATH_EMBRACE_MULTIPLIER
			isBonus = true
		end
	end
	
	-- Scan upgrade list
	for _, upgradeBuff in pairs(self.upgradeList) do
		-- detection function is either UnitBuff or UnitDebuff according to detectionType
		local detectionFunction
		if upgradeBuff.detectionType == "buff" then
			detectionFunction = UnitBuff
		else
			detectionFunction = UnitDebuff
		end
		-- Cycle through every buffs or debuffs of detection unit
		local index = 1
		local auraName, _, _, auraCount, _, _, _, caster = detectionFunction(upgradeBuff.detectionUnit, index)
		while auraName do
			
			-- Cas : une seule aura peut donner l'upgrade => si le nom de l'aura courante correspond
			-- Cas : si plusieurs auras peuvent donner l'upgrade => si l'aura est dans la liste 
			if (upgradeBuff.name == auraName and not upgradeBuff.affectingAuraNames) or (upgradeBuff.affectingAuraNames and upgradeBuff.affectingAuraNames[auraName]) then
				-- Si la personne qui donne le buff n'est pas importante ou si le caster correspond à un provider potentiel
				if not upgradeBuff.providerIsSignificant or self.buffProviders[upgradeBuff.name][UnitName(caster)] then
					if not upgradeBuff.hasToBeStackable or (upgradeBuff.hasToBeStackable and auraCount ~= 0) then
						if self:UpgradeCanBeApplied(upgradeBuff) then
							if auraCount == 0 then
								auraCount = 1
							end -- apparently if buff does not stack UnitBuff returns 0
								-- Due to master poisoner we have to check if the stack number is significant
							local upgradeAmount = upgradeBuff.upgradePerStack * ((auraCount>upgradeBuff.maxCount and upgradeBuff.maxCount) or auraCount)
							if not currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] then
								currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] = 0
							end
							if upgradeBuff.multipleAuraInstanceStack then	-- If multiple aura instances stacks
								if upgradeBuff.upgradeType == "crit" then		-- crits stack additively
									currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] = currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] + upgradeAmount
								else	-- dmg stack multiplicatively
									-- (1+A/100)*(1+B/100) = (1+C/100) => C = A+B+AB/100
									currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] = currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] + upgradeAmount + currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] * upgradeAmount / 100
								end
							else
								-- Check if need updating (non stackable)
								if upgradeAmount > currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] or
										(upgradeAmount < 0 and upgradeAmount < currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type]) then
									currentUpgradeList[upgradeBuff.upgradeType][upgradeBuff.type] = upgradeAmount
								end
							end
							-- Update tooltip
							if not upgradeBuff.isBonus then
								self.currentTooltipUpgradeList[upgradeBuff.type][upgradeBuff.name].currentStack = auraCount
							end
							-- set the bonus flag
							if upgradeBuff.isBonus then
								isBonus = true
							end
						end
					end
				end
			end
			index = index + 1
			auraName, _, _, auraCount, _, _, _, caster = detectionFunction(upgradeBuff.detectionUnit, index)
		end
	end
	
	local currentCritFactor = 0
	targetGUID = UnitGUID("target") 
	-- A somewhat questionable way to show crit rating in currentUpgrade.
	-- Mainly for showing difference between a crit prewep cast and a fresh one.
	if self:GetLastDotBaseCritPct(targetGUID) then
		currentCritFactor = self.critPctWithoutRaidBuffs-self:GetLastDotBaseCritPct(targetGUID) 
	end
	
	for Type, upgradeAmount in pairs(currentUpgradeList["crit"]) do
	   currentCritFactor = currentCritFactor + upgradeAmount
	end
	
	local currentDmgFactor = 1
	for Type, upgradeAmount in pairs(currentUpgradeList["dmg"]) do
	   currentDmgFactor = currentDmgFactor * (1 + upgradeAmount/100)
	end

	if self.class == "HUNTER" and not self:HunterHasTier9() then
		currentCritFactor = 0
	end

	local currentUpgrade = ((1+currentCritFactor/100/(1+self.critPctWithoutRaidBuffs/100))*currentDmgFactor - 1)*100
	
	self.currentUpgrade = currentUpgrade
	return currentUpgrade, isBonus
end

---------------------------------------------------
-- Populate Upgrade List
function ShadowGreenLight:PopulateUpgradeList()
	-- reinitialize upgrade list
	for upgradeName, _ in pairs(self.upgradeList) do
		self.upgradeList[upgradeName] = nil
	end
	-- reinitialize names of raidmembers able to provide the upgrades where provider is significant debuff
	for buffName, _ in pairs(self.buffProviders) do
		for providerName, _ in pairs(self.buffProviders[buffName]) do
			self.buffProviders[buffName][providerName] = nil
		end
		self.buffProviders[buffName] = nil
	end

	-- Add upgrades that are not dependants on raid talents and are applicable
	for upgradeName, upgrade in pairs(self.upgradeDb) do
	   local applicable = true
	    if upgrade.isApplicable then
			applicable = upgrade.isApplicable(unpack(upgrade.applicabilityArgs))
	    end

		if (not upgrade.talentName) and applicable and self:UpgradeCanBeApplied(upgrade) then
		   self.upgradeList[upgradeName] = upgrade
		end
	end
	
	-- taking list of raid member and comparing it to available upgrade list
	-- skip afk / not visible / out of zone players
	if GetNumRaidMembers()>0 then
		for i = 1,40 do
			if UnitIsVisible("raid"..i) then
				self:PopulateUpgradeListForUnit("raid"..i)
			end
		end
	else
		for i = 1,4 do
			if UnitIsVisible("party"..i) then
				self:PopulateUpgradeListForUnit("party"..i)
			end
		end
		self:PopulateUpgradeListForUnit("player")
	end
    
    -- Reset current upgrade list for tooltip
	for upgradeType in pairs(self.currentTooltipUpgradeList) do
	    for upgradeName in pairs(self.currentTooltipUpgradeList[upgradeType]) do
	       self.currentTooltipUpgradeList[upgradeType][upgradeName].currentStack = nil
	       self.currentTooltipUpgradeList[upgradeType][upgradeName].maxStack = nil
	       self.currentTooltipUpgradeList[upgradeType][upgradeName] = nil
	    end
		self.currentTooltipUpgradeList[upgradeType] = nil
	end
    -- register upgrades for tooltip
	for _, upgradeBuff in pairs(self.upgradeList) do
		if not upgradeBuff.isBonus then -- do not register bonus upgrades for tooltip
	        if not self.currentTooltipUpgradeList[upgradeBuff.type] then
		        self.currentTooltipUpgradeList[upgradeBuff.type] = {}
	        end
	        -- register upgrade for tooltip
	        self.currentTooltipUpgradeList[upgradeBuff.type][upgradeBuff.name] = {
	    	     currentStack = 0,
	    	     maxStack = upgradeBuff.maxCount
	        }
		end 
    end
end

function ShadowGreenLight:PopulateUpgradeListForUnit(unit)
	local name = getRealmedName(unit)
	if self.raidUpgradeAvailable[name] then
		for upgradeName, upgrade in pairs(self.raidUpgradeAvailable[name]) do
			if self:UpgradeCanBeApplied(upgrade) then
				-- either buff was not available before
				if not self.upgradeList[upgradeName] then
					self.upgradeList[upgradeName] = upgrade
					-- or it was, in that case check if new upgrade is better
				else
					if self.upgradeList[upgradeName].upgradePerStack < upgrade.upgradePerStack then
						self.upgradeList[upgradeName] = upgrade
					end
				end
				-- populate the provider list if needed
				if upgrade.providerIsSignificant then
					if not self.buffProviders[upgrade.name] then
						self.buffProviders[upgrade.name] = {}
					end
					self.buffProviders[upgrade.name][name] = true
				end
			end
		end
	end
end

function ShadowGreenLight:ComputeMaxUpgrade()
	local maxUpgradeByUpgradeType = {
		["crit"]={},
		["dmg"]={},
	}

	self:ComputeCritPctWithoutRaidBuffs()

	self.maxUpgrade = 0
	for _, upgradeBuff in pairs(self.upgradeList) do
		if not upgradeBuff.isBonus then	-- skip bonus buffs for maxupgrade computation
		   
			if not maxUpgradeByUpgradeType[upgradeBuff.upgradeType][upgradeBuff.type] then
				maxUpgradeByUpgradeType[upgradeBuff.upgradeType][upgradeBuff.type] = 0
			end
			local maxUpgradeAmount = upgradeBuff.upgradePerStack * upgradeBuff.maxCount
			if maxUpgradeAmount > maxUpgradeByUpgradeType[upgradeBuff.upgradeType][upgradeBuff.type] then
				maxUpgradeByUpgradeType[upgradeBuff.upgradeType][upgradeBuff.type] = maxUpgradeAmount
			end
		end
	end
	
	local maxCritFactor = 0
	for Type, upgradeAmount in pairs(maxUpgradeByUpgradeType["crit"]) do
		maxCritFactor = maxCritFactor + upgradeAmount
	end
	
	local maxDmgFactor = 1
	for Type, upgradeAmount in pairs(maxUpgradeByUpgradeType["dmg"]) do
		maxDmgFactor = maxDmgFactor * (1 + upgradeAmount/100)
	end
	
	
	self.maxUpgrade = ((1+maxCritFactor/100/(1+self.critPctWithoutRaidBuffs/100))*maxDmgFactor - 1)*100
	return self.maxUpgrade
end

function ShadowGreenLight:ComputeCritPctWithoutRaidBuffs()
	local maxCritUpgradeByUpgradeType = {}
	self.critPctWithoutRaidBuffs = self:GetCritChance()

	if self.affectedDot == SPELL_SERPENT_STING and not self:HunterHasTier9() then
		return self.critPctWithoutRaidBuffs
	end

	-- Scan upgrade list
	for _, upgradeBuff in pairs(self.upgradeList) do
		-- only keep self crit buffs
		if upgradeBuff.detectionType == "buff" and upgradeBuff.detectionUnit == "player" and upgradeBuff.upgradeType == "crit" then
			-- Cycle through every buffs or debuffs of detection unit
			local index = 1
			local auraName, _, _, auraCount = UnitBuff("player", index)
			while auraName do
				if upgradeBuff.name == auraName then
					if auraCount == 0 then auraCount = 1 end -- apparently if buff does not stack UnitBuff returns 0
					if not maxCritUpgradeByUpgradeType[upgradeBuff.type] then
						maxCritUpgradeByUpgradeType[upgradeBuff.type] = 0
					end
					local upgradeAmount = upgradeBuff.upgradePerStack * auraCount
					-- Check if need updating
					if upgradeAmount > maxCritUpgradeByUpgradeType[upgradeBuff.type] then
						maxCritUpgradeByUpgradeType[upgradeBuff.type] = upgradeAmount
					end
				end
				index = index + 1
				auraName, _, _, auraCount = UnitBuff("player", index)
			end
		end
	end

	for _, upgradeAmount in pairs(maxCritUpgradeByUpgradeType) do
		self.critPctWithoutRaidBuffs = self.critPctWithoutRaidBuffs - upgradeAmount
	end

	return self.critPctWithoutRaidBuffs
end

function ShadowGreenLight:GetTimeToProfit(currentUpgrade)
	local dpslog = self.dpslog
	if dpslog.last == 0 then return "--" end

	-- If the data recorded is deemed sufficient (10 because it is the average time for all damages to kick in)
	local meanDPS = 0
	if dpslog[dpslog.last].timeStamp - self.dpslog.firstCombatEventTimeStamp >= MEAN_DPS_COMPUTATION_WINDOW_LENGTH then
		-- we find the first datapoint in the mean DPS window
		local firstDataPointIndex = dpslog.first
		for i = dpslog.first, dpslog.last do
			if dpslog[dpslog.last].timeStamp - dpslog[i].timeStamp <= MEAN_DPS_COMPUTATION_WINDOW_LENGTH then
				firstDataPointIndex = i
				break
			end
		end
		-- mean DPS on window is the weighted mean of instant DPS on the window
		local weightedSum = 0
		local weightSum = 0
		for i = firstDataPointIndex, dpslog.last do
			weight = (dpslog[dpslog.last].timeStamp - dpslog[i].timeStamp)/(dpslog[dpslog.last].timeStamp - dpslog[firstDataPointIndex].timeStamp)
			weightSum = weightSum + weight
			weightedSum = weightedSum + dpslog[i].instantDPS * weight
		end
		meanDPS = weightedSum/weightSum
	end

	-- Compute gcd value with haste
	local hasteRating = GetCombatRating(CR_HASTE_SPELL)
	local gcd = 1.5 / (1 + (hasteRating / 32.79 / 100))
	if gcd < 1 then gcd = 1 end

	-- Compute dot DPS
	local timeBetweenTicks = 3
	-- A properly glyphed warlock will have Quick Decay
	if self.hasteAffectsDotTicks then
		timeBetweenTicks = timeBetweenTicks/ (1 + (hasteRating / 32.79 / 100))
	end
	local dotDps = self.lastDotTick/timeBetweenTicks

	local lastDotUpgrade = self:GetLastDotUpgrade(UnitGUID("target"))
	if not lastDotUpgrade then
		lastDotUpgrade = 0
	end

	if meanDPS == 0 or dotDps == 0 or (currentUpgrade - lastDotUpgrade == 0) then
		self.soundAlert = false
		return "--"
	else
		local ttp = gcd * meanDPS / (dotDps * (currentUpgrade - lastDotUpgrade)/100)
		self.soundAlert = (ttp < self.db.profile.soundAlertThreshold)
		--return string.format("%.0f - %.0f - %.1f", meanDPS, log[log.last].instantDPS, log[log.last].timeStamp - log[log.first].timeStamp)
		return string.format("%.0f'%.0f\"", math.floor(ttp / 60), ttp % 60)
	end
end

function ShadowGreenLight:GetCritChance()
	if self:HunterHasTier9() then
		return GetRangedCritChance()
	elseif self.class == "HUNTER" then
		return 0
	else
		return GetSpellCritChance(6)
	end
end

function ShadowGreenLight:HunterHasTier9()
	if self.class ~= "HUNTER" then
		return false
	end
	slots = {" Handguards", " Headpiece", " Spaulders", " Tunic", " Legguards"}
	tiers = {" of Conquest", " of Triumph"}
	tier = 0
	for tier_ind=1,2,1 do
		for slot_ind=1,5,1 do
			if(IsEquippedItem("Windrunner's" .. slots[slot_ind] .. tiers[tier_ind])) then
				tier = tier + 1
			end
		end
	end
	return tier >= 2
end

function ShadowGreenLight:UpgradeCanBeApplied(upgrade)
	local targetCritBuffType = "spell"
	if self.affectedDot == SPELL_SERPENT_STING then
		targetCritBuffType = "physical"
	end

	if upgrade.upgradeType == "crit" then
		if upgrade.upgradeRestriction ~= nil and upgrade.upgradeRestriction ~= targetCritBuffType then
			return false
		end

		if self.affectedDot == SPELL_SERPENT_STING and not self:HunterHasTier9() then
			return false
		end
	end
	return true
end

function ShadowGreenLight:GetMaxUpgrade()
	return self.maxUpgrade
end

function ShadowGreenLight:GetCurrentUpgrade()
	return self.currentUpgrade
end

function ShadowGreenLight:GetLastDotUpgrade(unitGUID)
	return self.lastDotUpgrade[unitGUID]
end

function ShadowGreenLight:GetLastDotBaseCritPct(unitGUID)
	return self.LastDotBaseCritPct[unitGUID]
end

function ShadowGreenLight:GetLastDotSpellPower(unitGUID)
	return self.lastDotSpellPower[unitGUID]
end

---------------------------------------------------
-- Checking sound alert flag and playing selected file
function ShadowGreenLight:CheckSoundAlert()
	if self.soundAlert then
		PlaySoundFile(LSM:Fetch("sound", self.db.profile.soundAlertSound))
	end
end