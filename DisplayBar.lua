--[[
	Note to display developpers :
		See default display documentation for more details on what your plugin should provide
]]--

local Display = LibStub("AceAddon-3.0"):NewAddon("ShadowGreenLight_DisplayBar", "AceConsole-3.0")
local ShadowGreenLight = ShadowGreenLight 	-- speed up lookup
local LibQTip = LibStub('LibQTip-1.0')		-- tooltip management library
local LSM = LibStub("LibSharedMedia-3.0")

Display.options = {
	titleGeneral = {
		type = "header",
		name = "General",
		order = 10,
	},
	reset = {
	    type = "execute",
	    handler = Display,
	    name = "Reset position",
	    desc = "Reset display position",
	    func = "ResetDisplayPosition",
	    order = 11,
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
        order = 12,
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
        order = 13,
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
        order = 14,
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
        order = 15,
    },
	titleAspect = {
		type = "header",
		name = "Visual aspect",
		order = 20,
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
        order = 21,
    },
	backgroundColor = {
        type = "color",
        handler = Display,
        name = "Background Color",
        desc = "Sets background color",
        hasAlpha = true,
        get = function(info)
            return unpack(info.handler.db.profile.bgColor)
        end,
        set = function(info,r,g,b,a)
            info.handler.db.profile.bgColor = {r,g,b,a}
            info.handler:UpdateDisplaySettings()
        end,
        order = 22,
    },
	borderColor = {
        type = "color",
        handler = Display,
        name = "Border Color",
        desc = "Sets border color",
        hasAlpha = true,
        get = function(info)
            return unpack(info.handler.db.profile.borderColor)
        end,
        set = function(info,r,g,b,a)
            info.handler.db.profile.borderColor = {r,g,b,a}
            info.handler:UpdateDisplaySettings()
        end,
        order = 23,
    },
	barTexture = {
        type = "select",
		dialogControl = 'LSM30_Statusbar',
        handler = Display,
        name = "Bar texture",
        desc = "Selects bar texture",
        get = function(info)
            return info.handler.db.profile.barTexture
        end,
        set = function(info,v)
            info.handler.db.profile.barTexture = v
            info.handler:UpdateDisplaySettings()
        end,
        values = AceGUIWidgetLSMlists.statusbar,
        order = 24,
    },
	height = {
        type = "range",
        handler = Display,
        name = "Indicator height",
        desc = "Sets indicator display height",
        get = function(info)
            return info.handler.db.profile.frameHeight
        end,
        set = function(info,v)
            info.handler.db.profile.frameHeight = v
            info.handler:UpdateDisplaySettings()
        end,
        min = 30,
        max = 100,
        step = 1,
        order = 25,
    },    
	width = {
        type = "range",
        handler = Display,
        name = "Indicator width",
        desc = "Sets indicator display width",
        get = function(info)
            return info.handler.db.profile.frameWidth
        end,
        set = function(info,v)
            info.handler.db.profile.frameWidth = v
            info.handler:UpdateDisplaySettings()
        end,
        min = 30,
        max = 100,
        step = 1,
        order = 26,
    },        
	bonusWidth = {
        type = "range",
        handler = Display,
        name = "Indicator bonus width",
        desc = "Sets indicator display bonus width",
        get = function(info)
            return info.handler.db.profile.bonusFrameWidth
        end,
        set = function(info,v)
            info.handler.db.profile.bonusFrameWidth = v
            info.handler:UpdateDisplaySettings()
        end,
        min = 50,
        max = 120,
        step = 1,
        order = 27,
    },        
	fontSize = {
		type = "range",
		handler = Display,
		name = "Indicator font size",
		desc = "Sets indicator display bonus width",
		get = function(info)
			return info.handler.db.profile.fontSize
		end,
		set = function(info,v)
			info.handler.db.profile.fontSize = v
			info.handler:UpdateDisplaySettings()
		end,
		min = 6,
		max = 20,
		step = 1,
		order = 28,
    },
    titleIndicators = {
		type = "header",
		name = "Indicators",
		order = 30,
	 },
    toggleTopNumeric = {
        type = "toggle",
        handler = Display,
        name = "Top numeric",
        desc = "Toggles displaying the top numeric indicator (max available upgrade)",
        get = function(info)
            return info.handler.db.profile.displayTopNumericIndicator
        end,
        set = function(info,v)
            info.handler.db.profile.displayTopNumericIndicator = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 31,
    },
    toggleUpperBarNumeric = {
        type = "toggle",
        handler = Display,
        name = "Upper bar numeric",
        desc = "Toggles displaying the upper bar numeric indicator (current available upgrade)",
        get = function(info)
            return info.handler.db.profile.displayUpperBarNumericIndicator
        end,
        set = function(info,v)
            info.handler.db.profile.displayUpperBarNumericIndicator = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 32,
    },
    toggleLowerBarNumeric = {
        type = "toggle",
        handler = Display,
        name = "Lower bar numeric",
        desc = "Toggles displaying the lower bar numeric indicator (available upgrade when last you applied SW:P/Corruption)",
        get = function(info)
            return info.handler.db.profile.displayLowerBarNumericIndicator
        end,
        set = function(info,v)
            info.handler.db.profile.displayLowerBarNumericIndicator = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 33,
    },
    toggleTtp = {
        type = "toggle",
        handler = Display,
        name = "Time to profit",
        desc = "Toggles displaying of time to profit indicator",
        get = function(info)
            return info.handler.db.profile.displayTtpIndicator
        end,
        set = function(info,v)
            info.handler.db.profile.displayTtpIndicator = v
            info.handler:UpdateDisplaySettings()
        end,
        order = 34,
    },
    titleDesc = {
    	type = "header",
    	name = "Indicators",
    	order = 40,
	},
    desc1 = {
    	type = "description",
    	name = "|cFFFFFF00Top bar : |cFFFFFFFFindicates the upgrade available currently if you recast SWP / Corruption.",
    	order = 41,
	},
    desc2 = {
    	type = "description",
    	name = "|cFFFFFF00Bottom bar : |cFFFFFFFFindicates the upgrade available when you last casted SWP / Corruption.",
    	order = 42,
	},
    desc3 = {
    	type = "description",
    	name = "|cFFFFFF00Numeric indicator (top of the frame) : |cFFFFFFFFmax upgrade available taken your raid comp into account.",
    	order = 43,
	},
    desc4 = {
    	type = "description",
    	name = "|cFFFFFF00Time to profit indicator (bottom of the frame) : |cFFFFFFFFaccording to your current DPS and the upgrades available, this indicator tells you how long it will take to be compensated from losing a gcd to refresh SWP / Corruption.",
    	order = 44,
	},
    desc5 = {
    	type = "description",
    	name = "|cFFFFFF00Tooltip : |cFFFFFFFFhovering the frame in combat will display a recap of which upgrades are currently available, time to scream at your mage to have better scorch uptime !",
    	order = 45,
	},
}

function Display:OnInitialize()
  	-- Initialization of session db
  	self.db = LibStub("AceDB-3.0"):New("ShadowGreenLight_DisplayBarDB", {
  		profile = {
  			posX = 0,
  			posY = 0,
  			relativePoint = "CENTER",
  			point = "CENTER",
  			frameWidth = 60,
  			frameHeight = 40,
  			bonusFrameWidth = 90,
  			fontSize = 12,
  			displayTtpIndicator = true,
  			displayTopNumericIndicator = true,
  			displayUpperBarNumericIndicator = true,
  			displayLowerBarNumericIndicator = true,
  			showTooltip = true,
  			oocHiding = false,
			currentDotPower = false,
  			border = "Blizzard Tooltip",
  			bgColor = {0,0,0,1},
  			borderColor = {1,1,1,1},
  			barTexture = "Blizzard",
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
	self.frame = CreateFrame("Frame", "ShadowGreenLight_DisplayBar_MainFrame", UIParent)
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
	
	-- create raid current upgrade bar
	self.frameCurrentUpgrade = CreateFrame("Frame", "ShadowGreenLight_DisplayBar_CurrentUpgradeFrame", self.frame)
	self.frameCurrentUpgrade:SetPoint("TOPLEFT",self.frame,"TOPLEFT",0,0)
	
	-- create raid last upgrade bar
	self.frameLastUpgrade = CreateFrame("Frame", "ShadowGreenLight_DisplayBar_LastUpgradeFrame", self.frame)
	self.frameLastUpgrade:SetPoint("BOTTOMLEFT",self.frame,"BOTTOMLEFT",0,0)
		
	-- create raid max upgrade numeric indicator
	self.raidMaxUpgradeIndicator = self.frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
	self.raidMaxUpgradeIndicator:SetPoint("BOTTOMRIGHT", self.frame, "TOPRIGHT", 0, 0)
	self.raidMaxUpgradeIndicator:SetTextColor(1,1,1,1)
	
    -- create raid current upgrade numeric indicator
	self.raidCurrentUpgradeIndicator = self.frameCurrentUpgrade:CreateFontString(nil,"OVERLAY","GameFontNormal")
	self.raidCurrentUpgradeIndicator:SetPoint("BOTTOMRIGHT", self.frameCurrentUpgrade, "BOTTOMRIGHT", -5, 3)
	self.raidCurrentUpgradeIndicator:SetTextColor(1,1,1,1)
	
	-- create raid last upgrade numeric indicator
	self.raidLastUpgradeIndicator = self.frameLastUpgrade:CreateFontString(nil,"OVERLAY","GameFontNormal")
	self.raidLastUpgradeIndicator:SetPoint("TOPRIGHT", self.frameLastUpgrade, "TOPRIGHT", -5, -3)
	self.raidLastUpgradeIndicator:SetTextColor(1,1,1,1)
		
	-- create time to profit indicator
	self.ttpIndicator = self.frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
	self.ttpIndicator:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 0, 0)
	self.ttpIndicator:SetTextColor(1,1,1,1)
	
	-- update configuration-dependant attributes
	self:UpdateDisplaySettings()
	self:DisplayToIdleState()
end

---------------------------------------------------
-- Update Display according to ShadowGreenLight state
function Display:UpdateDisplay()
	-- Get current / max and last upgrade
    local currentUpgrade, isBonus = ShadowGreenLight:ComputeCurrentUpgrade()
    local maxUpgrade = ShadowGreenLight.maxUpgrade
    local lastUpgrade = 0
	if ShadowGreenLight:GetLastDotUpgrade(UnitGUID("target")) then
		lastUpgrade = ShadowGreenLight:GetLastDotUpgrade(UnitGUID("target"))
	end
	
	-- Change background color and length of current upgrade bar
	self.frameCurrentUpgrade:SetBackdropColor(
		1-currentUpgrade / maxUpgrade,
		currentUpgrade / maxUpgrade,
		0,
		1
	)
	if currentUpgrade > maxUpgrade then
	    if lastUpgrade > currentUpgrade then
	       self.frameCurrentUpgrade:SetWidth(self.db.profile.frameWidth+(self.db.profile.bonusFrameWidth-self.db.profile.frameWidth)*(currentUpgrade-maxUpgrade)/(lastUpgrade-maxUpgrade))
	    else
	       self.frameCurrentUpgrade:SetWidth(self.db.profile.bonusFrameWidth)
	    end
    else
        self.frameCurrentUpgrade:SetWidth(self.db.profile.frameWidth*(currentUpgrade/maxUpgrade))
    end
    self.frameCurrentUpgrade:Show()
    
    -- Change background color and length of last upgrade bar
	self.frameLastUpgrade:SetBackdropColor(
		1-lastUpgrade / maxUpgrade,
		lastUpgrade / maxUpgrade,
		0,
		1
	)
    if lastUpgrade > maxUpgrade then
	    if currentUpgrade > lastUpgrade then
	       self.frameLastUpgrade:SetWidth(self.db.profile.frameWidth+(self.db.profile.bonusFrameWidth-self.db.profile.frameWidth)*(lastUpgrade-maxUpgrade)/(currentUpgrade-maxUpgrade))
	    else
	       self.frameLastUpgrade:SetWidth(self.db.profile.bonusFrameWidth)
	    end
    else
    	if lastUpgrade == 0 then
    		self.frameLastUpgrade:SetWidth(1)
    	else
        	self.frameLastUpgrade:SetWidth(self.db.profile.frameWidth*(lastUpgrade/maxUpgrade))
        end
    end
	self.frameLastUpgrade:Show()
	
	-- Display/Hide time to profit indicator according to config and if available upgrade versus last time dot was applied
	if currentUpgrade > lastUpgrade then
		local ttp = ShadowGreenLight:GetTimeToProfit(currentUpgrade)
		self.ttpIndicator:SetText(ttp)
	else
		self.ttpIndicator:SetText("")
	end	
	
	-- Display top numeric indicators
	self.raidMaxUpgradeIndicator:SetFormattedText( "%.0f%%" , maxUpgrade)
	-- Display upper bar numeric indicators
	self.raidCurrentUpgradeIndicator:SetFormattedText( "%.0f%%" , currentUpgrade)
	-- Display lower bar numeric indicators
	self.raidLastUpgradeIndicator:SetFormattedText( "%.0f%%" , lastUpgrade)
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
	
	self.raidMaxUpgradeIndicator:SetText("")
	self.raidCurrentUpgradeIndicator:SetText("")
	self.raidLastUpgradeIndicator:SetText("")
	self.ttpIndicator:SetText("")
	self.frameLastUpgrade:Hide()
	self.frameCurrentUpgrade:Hide()
end

---------------------------------------------------
-- Update Display when entering combat 
function Display:UpdateDisplay_OnEnteringCombat()
	if self.isShown then
		self.frame:Show()
		self:UpdateDisplaySettings()
	end
end
---------------------------------------------------
-- Update Display when exiting combat (go to idle state)
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
	
    self.frame:SetHeight(self.db.profile.frameHeight)
	self.frame:SetWidth(self.db.profile.frameWidth)
	self.frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = LSM:Fetch("border", self.db.profile.border),
		tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	self.frame:SetBackdropColor(unpack(self.db.profile.bgColor))
	self.frame:SetBackdropBorderColor(unpack(self.db.profile.borderColor))
		
	self.frameCurrentUpgrade:SetHeight(self.db.profile.frameHeight/2)
	self.frameCurrentUpgrade:SetBackdrop({
		bgFile = LSM:Fetch("statusbar", self.db.profile.barTexture),
		edgeFile = "",
		tile = false, tileSize = 0, edgeSize = 100,
		insets = { left = 4, right = 4, top = 4, bottom = 0 }
	})
	
    self.frameLastUpgrade:SetHeight(self.db.profile.frameHeight/2)
    self.frameLastUpgrade:SetBackdrop({
		bgFile = LSM:Fetch("statusbar", self.db.profile.barTexture),
		edgeFile = "",
		tile = false, tileSize = 0, edgeSize = 16,
		insets = { left = 4, right = 4, top = 0, bottom = 4 }
	})
	
	-- Mouse behaviour : tooltip
	if self.db.profile.showTooltip then
	  	self.frame:SetScript('OnEnter', showTooltip)
	    self.frame:SetScript('OnLeave', hideTooltip)
	else
		self.frame:SetScript('OnEnter', nil)
	    self.frame:SetScript('OnLeave', nil)
	end
			
	-- hide if configured
	if self.db.profile.oocHiding or not self.isShown then
		self.frame:Hide()
	else
		self.frame:Show()
	end
	
	-- font sizes
	local fontSize = self.db.profile.fontSize
	self.raidMaxUpgradeIndicator:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
	self.raidCurrentUpgradeIndicator:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
	self.raidLastUpgradeIndicator:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
	self.ttpIndicator:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
	
	-- Display/Hide time to profit indicator according to config
	if self.db.profile.displayTtpIndicator then
		self.ttpIndicator:Show()
	else
		self.ttpIndicator:Hide()
	end
	
	-- Display top numeric indicators
	if self.db.profile.displayTopNumericIndicator then
		self.raidMaxUpgradeIndicator:Show()
	else
		self.raidMaxUpgradeIndicator:Hide()
	end
	
	-- Display upper bar numeric indicators
	if self.db.profile.displayUpperBarNumericIndicator then
		self.raidCurrentUpgradeIndicator:Show()
	else
		self.raidCurrentUpgradeIndicator:Hide()
	end
	
	-- Display lower bar numeric indicators
	if self.db.profile.displayLowerBarNumericIndicator then
		self.raidLastUpgradeIndicator:Show()
	else
		self.raidLastUpgradeIndicator:Hide()
	end
end

--------------------------------------------------
-- Reset UI objects position on the screen
function Display:ResetDisplayPosition()
	self.frame:ClearAllPoints()
	self.frame:SetPoint("CENTER",UIParent,"CENTER", 0, 0)
end

ShadowGreenLight:RegisterDisplay("Bars", Display)