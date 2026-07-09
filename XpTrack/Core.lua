TimeToLevel = TimeToLevel or {}

local ADDON_NAME = "XpTrack"
local DISPLAY = TimeToLevel.DISPLAY_NAME or "Xp Track"
local SLASH = TimeToLevel.SLASH_CMD or "/xptrack"
local LABEL = "|cff00ff00" .. DISPLAY .. "|r"
local ERR_LABEL = "|cffff0000" .. DISPLAY .. "|r"

local function PrintHelp()
	print(LABEL .. " - TBC Classic")
	print(SLASH .. " — print stats")
	print(SLASH .. " show | hide | toggle — XP bar")
	print(SLASH .. " reset — reset session stats for this level")
	print(SLASH .. " sync — refresh from your XP bar")
	print(SLASH .. " alpha <30-100> — set bar opacity")
	print(SLASH .. " anchor editmode — enable Edit Mode placement")
	print(SLASH .. " anchor bottom — reset to bottom center")
	print(SLASH .. " minimap show | hide | toggle — minimap button")
	print(SLASH .. " options — open options menu")
	print("Legacy aliases: /ttl, /timetolevel")
	print("Shift+drag the XP bar to move. Shift+right-click bar for opacity.")
	if TimeToLevel.HasEditMode and TimeToLevel.HasEditMode() then
		print("Edit Mode: Esc > Edit Mode > move " .. LABEL .. ".")
	end
end

local function Trim(msg)
	if msg == nil then
		return ""
	end
	return (msg:match("^%s*(.-)%s*$"))
end

local function HandleSlash(msg)
	msg = string.lower(Trim(msg or ""))

	if msg == "" then
		if not TimeToLevel.initialized then
			print(ERR_LABEL .. " is not loaded. Try /reload")
			return
		end
		if TimeToLevel.tracker then
			TimeToLevel.tracker:PrintStats()
		end
		return
	end

	if msg == "show" then
		if TimeToLevel.window then TimeToLevel.window:Show() end
		return
	end

	if msg == "hide" then
		if TimeToLevel.window then TimeToLevel.window:Hide() end
		return
	end

	if msg == "toggle" then
		if TimeToLevel.window then TimeToLevel.window:Toggle() end
		return
	end

	if msg == "reset" then
		if TimeToLevel.tracker then
			TimeToLevel.tracker:ResetLevelSession()
			print(LABEL .. ": Session reset for this level.")
		end
		return
	end

	if msg == "sync" then
		if TimeToLevel.tracker then
			TimeToLevel.tracker.lastXp = TimeToLevel.GetPlayerXP()
			TimeToLevel.tracker:Refresh(true)
			print(LABEL .. ": Synced to current XP bar.")
		end
		return
	end

	if msg == "anchor bottom" or msg == "resetpos" then
		TimeToLevel.Settings.anchor = "bottom"
		TimeToLevel.Settings.left = nil
		TimeToLevel.Settings.top = nil
		TimeToLevel.Settings.bottomOffset = 0
		TimeToLevel.Settings.anchorPoint = nil
		TimeToLevel.Settings.anchorRelPoint = nil
		TimeToLevel.Settings.anchorRelativeTo = nil
		TimeToLevel.Settings.anchorX = nil
		TimeToLevel.Settings.anchorY = nil
		TimeToLevel.BlizzardBarGeometry = nil
		if TimeToLevel.RefreshBarGeometryFromEditMode then
			TimeToLevel.RefreshBarGeometryFromEditMode(true)
		end
		if TimeToLevel.window then
			TimeToLevel.window:ApplyAnchor()
			TimeToLevel.window:SavePlacement()
			print(LABEL .. ": Bar reset to bottom center.")
		end
		return
	end

	if msg == "anchor editmode" or msg == "editmode" then
		TimeToLevel.Settings.anchor = "editmode"
		TimeToLevel.Settings.left = nil
		TimeToLevel.Settings.top = nil
		if TimeToLevel.RegisterEditModeFrame then
			TimeToLevel.RegisterEditModeFrame()
		end
		print(LABEL .. ": Open Esc > Edit Mode and select " .. LABEL .. " to move.")
		return
	end

	local alphaValue = string.match(msg, "^alpha%s+(%d+)$")
	if alphaValue then
		local value = tonumber(alphaValue)
		if value and TimeToLevel.window then
			TimeToLevel.window:SetAlpha(value)
			print(string.format(LABEL .. " opacity: %d%%", value))
		end
		return
	end

	if msg == "help" or msg == "?" then
		PrintHelp()
		return
	end

	if msg == "options" or msg == "config" or msg == "settings" then
		if not TimeToLevel.initialized then
			print(ERR_LABEL .. " is not loaded. Try /reload")
			return
		end
		if TimeToLevel.Options then
			TimeToLevel.Options:Show()
		end
		return
	end

	local minimapCmd = string.match(msg, "^minimap%s+(.+)$")
	if minimapCmd then
		if minimapCmd == "show" then
			TimeToLevel.EnsureMinimapButton()
			if TimeToLevel.minimap then TimeToLevel.minimap:Show() end
		elseif minimapCmd == "hide" and TimeToLevel.minimap then
			TimeToLevel.minimap:Hide()
		elseif minimapCmd == "toggle" then
			TimeToLevel.EnsureMinimapButton()
			if TimeToLevel.minimap then TimeToLevel.minimap:ToggleVisibility() end
		else
			print(LABEL .. ": Unknown minimap command.")
		end
		return
	end

	print(LABEL .. ": Unknown command. Type " .. SLASH .. " help")
end

function TimeToLevel.EnsureMinimapButton()
	if TimeToLevel.minimap and TimeToLevel.minimap.frame then
		return
	end
	if Minimap and TimeToLevel.window then
		TimeToLevel.minimap = TimeToLevel.MinimapButton:Create(TimeToLevel.window)
	end
end

local function InitAddon()
	if TimeToLevel.initialized then
		return
	end

	TimeToLevel.LoadSettings()

	TimeToLevel.window = TimeToLevel.Window:Create()
	TimeToLevel.tracker = TimeToLevel.Tracker
	TimeToLevel.tracker:Init(TimeToLevel.window)
	TimeToLevel.tracker:StartTicker()

	TimeToLevel.EnsureMinimapButton()
	TimeToLevel.Options:Init()

	TimeToLevel.CaptureXpBorderSpecs()
	TimeToLevel.HideBlizzardExpBar()
	TimeToLevel.HookBlizzardBarLayout()
	if TimeToLevel.HookEditMode then
		TimeToLevel.HookEditMode()
	end
	TimeToLevel.StartBlizzardBarWatch()
	if TimeToLevel.RegisterEditModeFrame then
		TimeToLevel.RegisterEditModeFrame()
	end

	SLASH_XPTRACK1 = "/xptrack"
	SLASH_XPTRACK2 = "/xp"
	SlashCmdList["XPTRACK"] = HandleSlash

	SLASH_TIMETOLEVEL1 = "/ttl"
	SLASH_TIMETOLEVEL2 = "/timetolevel"
	SlashCmdList["TIMETOLEVEL"] = HandleSlash

	TimeToLevel.initialized = true
	print(LABEL .. " v1.9.25 loaded. " .. SLASH .. " options | minimap right-click")
end

local function SafeInit()
	local ok, err = pcall(InitAddon)
	if not ok then
		print(ERR_LABEL .. " failed to load:|r " .. tostring(err))
	end
end

local function ShouldInitNow()
	local name = UnitName("player")
	return name ~= nil and name ~= "" and name ~= "Unknown"
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("PLAYER_LEAVING_WORLD")
loader:RegisterEvent("PLAYER_LOGOUT")
loader:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		if ShouldInitNow() then
			SafeInit()
		end
	elseif event == "PLAYER_LOGIN" then
		SafeInit()
	elseif event == "PLAYER_ENTERING_WORLD" then
		TimeToLevel.EnsureMinimapButton()
		if TimeToLevel.Settings and TimeToLevel.Settings.anchor ~= "free" and TimeToLevel.RefreshBarGeometryFromEditMode then
			TimeToLevel.RefreshBarGeometryFromEditMode(false)
		end
		TimeToLevel.HookBlizzardBarLayout()
		if TimeToLevel.HookEditMode then
			TimeToLevel.HookEditMode()
		end
		TimeToLevel.CaptureXpBorderSpecs()
		TimeToLevel.HideBlizzardExpBar()
		TimeToLevel.StartBlizzardBarWatch()
		if TimeToLevel.RegisterEditModeFrame then
			TimeToLevel.RegisterEditModeFrame()
		end
		if TimeToLevel.window then
			local ok, err = pcall(function()
				if TimeToLevel.Settings.anchor == "bottom" then
					TimeToLevel.CaptureBlizzardBarGeometry(true)
					TimeToLevel.window:ApplyDefaultAnchor()
				else
					TimeToLevel.window:ApplyAnchor()
					if TimeToLevel.Settings.anchor ~= "free" and TimeToLevel.Settings.anchor ~= "editmode" then
						TimeToLevel.window:SyncToBlizzardBar()
					end
				end
				TimeToLevel.window:EnsureVisible()
			end)
			if not ok then
				print(ERR_LABEL .. " bar refresh failed:|r " .. tostring(err))
			end
		end
		if TimeToLevel.minimap then
			TimeToLevel.minimap:UpdatePosition()
		end
		if TimeToLevel.tracker then
			TimeToLevel.tracker:OnEnterWorld()
		end
	elseif event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_LOGOUT" then
		if TimeToLevel.window then
			TimeToLevel.window:SavePlacement()
		end
		if event == "PLAYER_LOGOUT" and TimeToLevel.tracker then
			TimeToLevel.tracker:SaveState()
		end
	end
end)
