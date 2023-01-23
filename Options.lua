function ShadowGreenLight:ResetOptions()
	self.options = { 
	    name = "ShadowGreenLight",
	    handler = ShadowGreenLight,
	    type = "group",
	    args = {
	    	config = {
	    		type = "execute",
			    handler = ShadowGreenLight,
			    guiHidden = true,
				name = "Config SGL",
				desc = "Open ShadowGreenLight configuration options",
	    		func = function()
	    			InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	    		end,
	    		order = 0,
			},
	    	desc = {
	    		type = "description",
	    		name = "ShadowGreenLight aims at helping shadow priests and affliction warlocks decide whether refreshing SWP / Corruption is profitable, based on which buffs / debuffs are available in your raid",
	    		order = 1,
			},
	        selectDisplay = {
	        	type = "select",
			    handler = ShadowGreenLight,
				name = "Display plugin selection",
				desc = "Select display plugin to use",
				get = function(info)
					return ShadowGreenLight.db.profile.selectedDisplay
				end,
				set = function(info, v)
					local SGL = ShadowGreenLight
					SGL:SelectedDisplaySetShown(false)
					SGL.db.profile.selectedDisplay = v
					SGL:BuildSelectedDisplayPluginShortcutOptions()
					SGL:CreateDisplay()
					SGL:SelectedDisplaySetShown(SGL.isDisplayed)
				end,
				values = function(info)
					local displays = {}
					for display, _ in pairs(ShadowGreenLight.registeredDisplays) do
						displays[display] = display
					end
					return displays
				end,
	    		order = 11,
			},
			toggleDebug = {
		        type = "toggle",
			    handler = ShadowGreenLight,
		        name = "Debug toggle",
		        desc = "Toggles debugging mode",
		        get = function(info)
		            return ShadowGreenLight.db.profile.debug
		        end,
		        set = function(info,v)
		            ShadowGreenLight.db.profile.debug = v
		            info.handler:Print("Debug mode " .. (v and "on" or "off"))
		        end,
	    		order = 12,
		    },	    
	    	soundAlert = {
	    		type = "group",
	    		inline = true,
	    		name = "Sound alert",
	    		order = 20,
	    		args = {
					soundAlertThreshold = {
				        type = "range",
				        handler = ShadowGreenLight,
				        name = "Sound alert threshold",
				        desc = "Sets the threshold (in sec) under which the time to profit indicator will trigger a sound alert",
				        get = function(info)
				            return info.handler.db.profile.soundAlertThreshold
				        end,
				        set = function(info,v)
				            info.handler.db.profile.soundAlertThreshold = v
				        end,
				        min = 20,
				        max = 500,
				        step = 5,
				        order = 1,
				    },
					soundAlertSound = {
				        type = "select",
						dialogControl = 'LSM30_Sound',
				        handler = ShadowGreenLight,
				        name = "Sound",
				        desc = "Selects the sound to play when under the time to profit threshold",
				        get = function(info)
				            return info.handler.db.profile.soundAlertSound
				        end,
				        set = function(info,v)
				            info.handler.db.profile.soundAlertSound = v
				        end,
				        values = AceGUIWidgetLSMlists.sound,
				        order = 2,
				    },
				},
			},	    
	    	displayPlugin = {
	    		type = "group",
	    		inline = true,
	    		name = "Display plugin",
	    		order = 30,
			},
	    },
	}
end