--[[
	Note to display developpers :
		In order to play nice with ShadowGreenLight you have to provide through the registerDisplay call at the end of file:
			- One object with the following methods and attributes set :
				* CreateDisplay() 					>>> Creating UI objects that you need
				* SetIsShown(isShown) 				>>> Set the shown attribute to true or false
				* DisplayToIdleState()				>>> Get the display to its idle state
				* UpdateDisplay() 					>>> Update UI objects according to SGL state
				* UpdateDisplay_OnEnteringCombat()	>>> Update display when entering combat
				* UpdateDisplay_OnExitingCombat()	>>> Update UI objects when exiting combat
				* options							>>> attribute containing an Ace3 option table for the user to configure your display
				* 										note that handler option *must* be set to your plugin object											
			- One name (one word) that will identify your display
]]--

local Display = LibStub("AceAddon-3.0"):NewAddon("ShadowGreenLight_DefaultDisplay", "AceConsole-3.0")
local ShadowGreenLight = ShadowGreenLight 	-- speed up lookup
local LibQTip = LibStub('LibQTip-1.0')		-- tooltip management library
local LSM = LibStub("LibSharedMedia-3.0")

Display.options = {
    reset = {
        type = "execute",
        handler = Display,
        name = "Reset position",
        desc = "Reset display position",
        func = "ResetDisplayPosition",
        order = 10,
    },
	border = {
        type = "select",
		dialogControl = 'LSM30_Border',
        handler = Display,
        name = "Border style",
        desc = "Selects border style",
        get = function(info)
            return info.handler.db.profile.border
        end,
        set = function(info,v)
            info.handler.db.profile.border = v
            info.handler:UpdateDisplaySettings()
        end,
        values = AceGUIWidgetLSMlists.border,
        order = 11,
    },
	size = {
        type = "range",
        handler = Display,
        name = "Indicator size",
        desc = "Sets indicator display size",
        get = function(info)
            return info.handler.db.profile.indicatorSize
        end,
        set = function(info,v)
            info.handler.db.profile.indicatorSize = v
            info.handler:UpdateDisplaySettings()
        end,
        min = 4,
        max = 60,
        step = 1,
        order = 12,
    },
    toggleNumber = {
        type = "toggle",
        handler = Display,
        name = "Numeric display toggle",
        desc = "Toggles displaying of numbers",
        get = function(info)
            return Display.db.profile.displayNumericIndicator
        end,
        set = function(info,v)
            info.handler.db.profile.displayNumericIndicator = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 13,
    },
    toggleTtp = {
        type = "toggle",
        handler = Display,
        name = "Time to profit display toggle",
        desc = "Toggles displaying of time to profit indicator",
        get = function(info)
            return info.handler.db.profile.displayTtpIndicator
        end,
        set = function(info,v)
            info.handler.db.profile.displayTtpIndicator = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 14,
    },
    toggleRecastIndicator = {
        type = "toggle",
        handler = Display,
        name = "Recast indicator toggle",
        desc = "Toggles displaying of recast indicator",
        get = function(info)
            return info.handler.db.profile.displayRecastIndicator
        end,
        set = function(info,v)
            info.handler.db.profile.displayRecastIndicator = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 15,
    },
    showTooltip = {
        type = "toggle",
        handler = Display,
        name = "Tooltip toggle",
        desc = "Toggles showing tooltip",
        get = function(info)
            return info.handler.db.profile.showTooltip
        end,
        set = function(info,v)
            info.handler.db.profile.showTooltip = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 16,
    },
    toggleOOCHiding = {
        type = "toggle",
        handler = Display,
        name = "OoC hiding toggle",
        desc = "Toggles hiding indicator when out of combat",
        get = function(info)
            return Display.db.profile.oocHiding
        end,
        set = function(info,v)
            info.handler.db.profile.oocHiding = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 17,
    },
    toggleCurrentDotPower = {
        type = "toggle",
        handler = Display,
        name = "Current DoT power toggle",
        desc = "Toggles displaying current DoT power instead of maximum upgrade in the numeric display",
        get = function(info)
            return Display.db.profile.currentDotPower
        end,
        set = function(info,v)
            info.handler.db.profile.currentDotPower = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 18,
    },
    lock = {
        type = "toggle",
        handler = Display,
        name = "Lock frame",
        desc = "Toggles frame position lock",
        get = function(info)
            return Display.db.profile.lockFrame
        end,
        set = function(info,v)
            info.handler.db.profile.lockFrame = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 19,
    },
    titleDesc = {
    	type = "header",
    	name = "Indicators",
    	order = 30,
	},
    desc1 = {
    	type = "description",
    	name = "|cFFFFFF00Background color of the frame : |cFFFFFFFFfrom red (no available upgrades are up) to green (all available upgrades are up).",
    	order = 31,
	},
    desc2 = {
    	type = "description",
    	name = "|cFFFFFF00Numeric indicator (top of the frame) : |cFFFFFFFFsame information as background color, except displayed as numeric value in terms of DPS increase (current DPS increase / max available DPS increase).",
    	order = 32,
	},
    desc3 = {
    	type = "description",
    	name = "|cFFFFFF00Skull in the frame : |cFFFFFFFFrecasting SW:P/corruption now would result in an increase of its tick values, however keep in mind that you would be using a gcd to refresh dot and thus might actually lose DPS, next indicator might give you a better idea. [Warlock specific] if there is a Cross instead of the skull it means you will be unable to directly refresh your dot because of spellpower bug",
    	order = 33,
	},
    desc4 = {
    	type = "description",
    	name = "|cFFFFFF00Time to profit indicator (bottom of the frame) : |cFFFFFFFFaccording to your current DPS and the upgrades available, this indicator tells you how long it will take to be compensated from losing a gcd to refresh SW:P / Corruption.",
    	order = 34,
	},
    desc5 = {
    	type = "description",
    	name = "|cFFFFFF00Tooltip : |cFFFFFFFFhovering the frame in combat will display a recap of which upgrades are currently available, time to scream at your mage to have better scorch uptime !",
    	order = 35,
	},
}

function Display:OnInitialize()
  	-- Initialization of session db
  	self.db = LibStub("AceDB-3.0"):New("ShadowGreenLight_DefaultDisplayDB", {
  		profile = {
  			posX = 0,
  			posY = 0,
  			relativePoint = "CENTER",
  			point = "CENTER",
  			indicatorSize = 30,
  			displayNumericIndicator = true,
  			displayTtpIndicator = true,
  			displayRecastIndicator = true,
  			showTooltip = true,
  			oocHiding = false,
			currentDotPower = false,
  			border = "Blizzard Tooltip",
  			lockFrame = false,
		}
	}, "Default")
	
	self.isShown = false
end

function Display:OnEnable()
end

function Display:OnDisable()
end

--------------------------------------------------
-- Tooltip management

-- Font definition
local headerFont = CreateFont("ShadowGreenLight_HeaderFont")
headerFont:SetFont(GameTooltipText:GetFont(), 12)
headerFont:SetTextColor(0,1,1)

local whiteFont = CreateFont("ShadowGreenLight_WhiteFont")
whiteFont:SetFont(GameTooltipText:GetFont(), 10)
whiteFont:SetTextColor(1,1,1)

local redFont = CreateFont("ShadowGreenLight_RedFont")
redFont:SetFont(GameTooltipText:GetFont(), 10)
redFont:SetTextColor(1,0,0)

local orangeFont = CreateFont("ShadowGreenLight_OrangeFont")
orangeFont:SetFont(GameTooltipText:GetFont(), 10)
orangeFont:SetTextColor(1,0.5,0)

local greenFont = CreateFont("ShadowGreenLight_GreenFont")
greenFont:SetFont(GameTooltipText:GetFont(), 10)
greenFont:SetTextColor(0,1,0)

local yellowFont = CreateFont("ShadowGreenLight_YellowFont")
yellowFont:SetFont(GameTooltipText:GetFont(), 10)
yellowFont:SetTextColor(1,1,0)

local function showTooltip(self)
    if not Display.db.profile.showTooltip then return end
    -- Acquire tooltip
    local tooltip = LibQTip:Acquire("ShadowGreenLight_DefaultDisplay_Tooltip", 2, "LEFT", "RIGHT")
    Display.tooltip = tooltip 
    
    -- If we are in combat display tooltip with current debuffs
    if ShadowGreenLight.isInCombat then
        -- Add header
        tooltip:SetHeaderFont(headerFont)
        tooltip:AddHeader('Upgrade', 'Amount')
        
        -- Cycle the tooltip object
        for upgradeType, _ in pairs(ShadowGreenLight.currentTooltipUpgradeList) do
            tooltip:SetFont(whiteFont)
            tooltip:AddLine(upgradeType)
            for upgradeName, upgrade in pairs(ShadowGreenLight.currentTooltipUpgradeList[upgradeType]) do
                if upgrade.currentStack == 0 then
                    tooltip:SetFont(redFont)
                elseif upgrade.currentStack >= upgrade.maxStack then
                    tooltip:SetFont(greenFont)
                else
                    tooltip:SetFont(orangeFont)
                end
                tooltip:AddLine(string.format("  %s", upgradeName), string.format("%.0f/%.0f", (upgrade.currentStack>upgrade.maxStack and upgrade.maxStack) or upgrade.currentStack, upgrade.maxStack))
            end
        end
    -- If we are NOT in combat display tooltip with current raid upgrades available
    else
        -- Add header
        tooltip:SetHeaderFont(headerFont)
        tooltip:AddHeader('ShadowGreenLight')
        -- Add hint
        tooltip:SetFont(yellowFont)
        if not Display.db.profile.lockFrame then
        	tooltip:AddLine("Right click and drag to move")
        else
        	tooltip:AddLine("Frame locked")
        end
        tooltip:AddLine("Shift + left click to open config")
        tooltip:AddLine("")
        tooltip:SetFont(whiteFont)
        
        if ShadowGreenLight.raidUpgradeAvailable then
	        for name, _ in pairs(ShadowGreenLight.raidUpgradeAvailable) do
	        	for _, upgrade in pairs(ShadowGreenLight.raidUpgradeAvailable[name]) do
	        		local maxUpgradeAmount = upgrade.upgradePerStack * upgrade.maxCount
	        		tooltip:AddLine(string.format("%s : %s (%.0f%% %s)", name, upgrade.talentName, maxUpgradeAmount, upgrade.upgradeType))
	        	end
	        end
	    end
    end
    
    -- Use smart anchoring code to anchor the tooltip to our frame
    tooltip:SmartAnchorTo(self)
    
    -- Show it, et voilà !
    tooltip:Show()
end

local function hideTooltip(self)
	if not Display.db.profile.showTooltip then return end
	-- Release the tooltip
	LibQTip:Release(Display.tooltip)
	Display.tooltip = nil
end

--------------------------------------------------
-- Create all necessary UI objects
function Display:CreateDisplay()
    if self.frame then
		self:UpdateDisplaySettings() 
		return
	end
    -- Create fugly square
	self.frame = CreateFrame("Frame", "ShadowGreenLight_DefaultDisplay_Frame", UIParent)
	self.frame:SetPoint(self.db.profile.point,UIParent,self.db.profile.relativePoint,self.db.profile.posX,self.db.profile.posY)
	self.frame:EnableMouse()
	-- Mouse behaviour : drag and drop + clicking
	self.frame:SetScript("OnMouseDown", function() 
		if this:IsMovable() and arg1 == "RightButton" then
			this:StartMoving()
			this.isMoving = true
		elseif arg1 == "LeftButton" and IsShiftKeyDown() and not ShadowGreenLight.isInCombat then
			InterfaceOptionsFrame_OpenToCategory(ShadowGreenLight.optionsFrame)
		end
	end)
	self.frame:SetScript("OnMouseUp", function() 
		if ( this.isMoving ) then
			local point,relativeTo,relativePoint,xOfs,yOfs = this:GetPoint(1)
			Display.db.profile.point = point
			Display.db.profile.relativePoint = relativePoint
			Display.db.profile.posX = xOfs
			Display.db.profile.posY = yOfs
			this:StopMovingOrSizing()
			this.isMoving = false
		end
	end)	
	-- Mouse behaviour : tooltip
	self.frame:SetScript('OnEnter', showTooltip)
    self.frame:SetScript('OnLeave', hideTooltip)

	
	-- create recast indicator
	self.frame.recastIndicator = self.frame:CreateTexture()
	self.frame.recastIndicator:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
	self.frame.recastIndicator:SetPoint("CENTER", self.frame, "CENTER", 0,0)
	self.frame.recastIndicator:Hide()
	
	-- create numeric indicator
	self.frame.numericIndicator = self.frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
	self.frame.numericIndicator:SetPoint("BOTTOMLEFT", self.frame, "TOPLEFT", 0, 0)
	self.frame.numericIndicator:SetTextColor(1,1,1,1)
	self.frame.numericIndicator:SetTextHeight("12")
	self.frame.numericIndicator:Hide()
		
	-- create time to profit indicator
	self.frame.ttpIndicator = self.frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
	self.frame.ttpIndicator:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 0, 0)
	self.frame.ttpIndicator:SetTextColor(1,1,1,1)
	self.frame.ttpIndicator:SetTextHeight("12")
	self.frame.ttpIndicator:Hide()
	
	-- update configuration-dependant attributes
	self:UpdateDisplaySettings()
end

---------------------------------------------------
-- Update Display according to ShadowGreenLight state
function Display:UpdateDisplay()
	-- Compute current upgrade
    local currentUpgrade, isBonus = ShadowGreenLight:ComputeCurrentUpgrade()
	
	-- Change background color
	self.frame:SetBackdropColor(
		1-currentUpgrade / ShadowGreenLight.maxUpgrade,
		currentUpgrade / ShadowGreenLight.maxUpgrade,
		0,
		1
	)
	
	-- Change border color if bonus
	if isBonus then
   		self.frame:SetBackdropBorderColor(1,0,0,1)	
   	else
   		self.frame:SetBackdropBorderColor(1,1,1,1)
   	end
	
	local lastDotUpgrade = 0
	local unitGUID = UnitGUID("target")
	if ShadowGreenLight:GetLastDotUpgrade(unitGUID) then
		lastDotUpgrade = ShadowGreenLight:GetLastDotUpgrade(UnitGUID("target"))
	end
	local lastDotSpellPower = 0
	if ShadowGreenLight:GetLastDotSpellPower(unitGUID) then
		lastDotSpellPower = ShadowGreenLight:GetLastDotSpellPower(UnitGUID("target"))
	end
	-- Display/Hide recast indicator according to available upgrade versus last time SWP was applied
	if self.db.profile.displayRecastIndicator and currentUpgrade > lastDotUpgrade then
		local _, class = UnitClass("player")
		if class == "WARLOCK" then
			if lastDotSpellPower > GetSpellBonusDamage(6) then
				-- Don't change display based on spell power. Spell power isn't checked on Dalaran WoW.
				self.frame.recastIndicator:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
			else
				self.frame.recastIndicator:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
			end
		end
	   	self.frame.recastIndicator:Show()	
	else
	   	self.frame.recastIndicator:Hide()
	end
	
	-- Display/Hide time to profit indicator according to config and if available upgrade versus last time SWP was applied
	if self.db.profile.displayTtpIndicator and currentUpgrade > lastDotUpgrade then
		local ttp = ShadowGreenLight:GetTimeToProfit(currentUpgrade)
		self.frame.ttpIndicator:SetText(ttp)
		self.frame.ttpIndicator:Show()
	else
		self.frame.ttpIndicator:Hide()
	end	
	
	-- Display/Hide numeric indicator according to configuration
	if self.db.profile.displayNumericIndicator then
		if isBonus then
	   		self.frame.numericIndicator:SetTextColor(1,0,0,1)	
	   	else
	   		self.frame.numericIndicator:SetTextColor(1,1,1,1)
	   	end
		if self.db.profile.currentDotPower then
			self.frame.numericIndicator:SetFormattedText( "%.0f/%.0f" , currentUpgrade, lastDotUpgrade)
		else
			self.frame.numericIndicator:SetFormattedText( "%.0f/%.0f" , currentUpgrade, ShadowGreenLight.maxUpgrade)
		end
	   	self.frame.numericIndicator:Show()
	end
end

---------------------------------------------------
-- Update Display when entering combat 
function Display:UpdateDisplay_OnEnteringCombat()
	if self.isShown then
		self.frame:Show()
	end
end

---------------------------------------------------
-- Set isShown 
function Display:SetShown(isShown)
	self.isShown = isShown
	self:UpdateDisplaySettings()
end

--------------------------------------------------
-- Update display to idle state
function Display:DisplayToIdleState()
    if self.db.profile.oocHiding then
		self.frame:Hide()
	end	
	
	self.frame.recastIndicator:Hide()
	self.frame.numericIndicator:SetText("")
	self.frame.ttpIndicator:SetText("")
	
	self.frame:SetBackdropColor(0,0,0,1)
end

---------------------------------------------------
-- Update Display when exiting combat
function Display:UpdateDisplay_OnExitingCombat()
	self:DisplayToIdleState()
end


--------------------------------------------------
-- Update UI objects according to settings
function Display:UpdateDisplaySettings()
	-- Set movable or not according to config
	if self.db.profile.lockFrame then
		self.frame:SetMovable(false)
	else
		self.frame:SetMovable(true)
	end
   self.frame:SetHeight(self.db.profile.indicatorSize)
	self.frame:SetWidth(self.db.profile.indicatorSize)
	self.frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = LSM:Fetch("border", self.db.profile.border),
		tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	self.frame:SetBackdropColor(0,0,0,1)
		
	self.frame.recastIndicator:SetWidth(self.db.profile.indicatorSize/2)
	self.frame.recastIndicator:SetHeight(self.db.profile.indicatorSize/2)
	
	-- hide if configured
	if self.db.profile.oocHiding or not self.isShown then
		self.frame:Hide()
	else
		self.frame:Show()
	end
end

--------------------------------------------------
-- Reset UI objects position on the screen
function Display:ResetDisplayPosition()
	self.frame:ClearAllPoints()
	self.frame:SetPoint("CENTER",UIParent,"CENTER", 0, 0)
end

ShadowGreenLight:RegisterDisplay("Default", Display)