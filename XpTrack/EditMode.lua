TimeToLevel = TimeToLevel or {}

local STATUS_TRACKING_SYSTEM = 15
if Enum and Enum.EditModeSystem and Enum.EditModeSystem.StatusTrackingBar then
	STATUS_TRACKING_SYSTEM = Enum.EditModeSystem.StatusTrackingBar
end

function TimeToLevel.HasEditMode()
	return C_EditMode ~= nil
		and C_EditMode.GetLayouts ~= nil
		and EditModeManagerFrame ~= nil
end

local function GetXpBarDimensions()
	if MainMenuExpBar and MainMenuExpBar:GetWidth() and MainMenuExpBar:GetWidth() > 0 then
		return MainMenuExpBar:GetWidth(), MainMenuExpBar:GetHeight() or 13
	end

	if StatusTrackingBarManager then
		if StatusTrackingBarManager.bars then
			for _, bar in ipairs(StatusTrackingBarManager.bars) do
				if bar and bar.GetWidth and bar:GetWidth() > 0 then
					return bar:GetWidth(), bar:GetHeight() or 13
				end
			end
		end
		if StatusTrackingBarManager.GetWidth and StatusTrackingBarManager:GetWidth() > 0 then
			return StatusTrackingBarManager:GetWidth(), StatusTrackingBarManager:GetHeight() or 13
		end
	end

	return 512, 13
end

function TimeToLevel.GetEditModeXpBarGeometry()
	if not TimeToLevel.HasEditMode() then
		return nil
	end

	local layouts = C_EditMode.GetLayouts()
	if not layouts or not layouts.layouts or not layouts.activeLayout then
		return nil
	end

	local active = layouts.layouts[layouts.activeLayout]
	if not active or not active.systems then
		return nil
	end

	local width, height = GetXpBarDimensions()

	for _, systemInfo in ipairs(active.systems) do
		if systemInfo.system == STATUS_TRACKING_SYSTEM then
			local index = systemInfo.systemIndex or 1
			if index == 1 and systemInfo.anchorInfo then
				local anchor = systemInfo.anchorInfo
				return {
					point = anchor.point or "BOTTOM",
					relativeTo = anchor.relativeTo or "UIParent",
					relPoint = anchor.relativePoint or "BOTTOM",
					x = anchor.offsetX or 0,
					y = anchor.offsetY or 0,
					width = width,
					height = height,
					fromEditMode = true,
				}
			end
		end
	end

	return nil
end

function TimeToLevel.GetEditModeDefaultPosition()
	local anchor = TimeToLevel.GetDefaultBarAnchor(TimeToLevel.Settings.bottomOffset or 0)
	return {
		point = anchor.point,
		x = anchor.x,
		y = anchor.y,
		relativeTo = anchor.relativeTo,
		relPoint = anchor.relPoint,
	}
end

function TimeToLevel.RefreshBarGeometryFromEditMode(force)
	local settings = TimeToLevel.Settings
	if settings.anchor == "editmode" then
		return
	end
	if settings.anchor == "free" and not force then
		return
	end

	if TimeToLevel.HasEditMode() then
		local geo = TimeToLevel.GetEditModeXpBarGeometry()
		if geo then
			TimeToLevel.BlizzardBarGeometry = geo
			return
		end
	end
end

function TimeToLevel.RegisterEditModeFrame()
	if TimeToLevel.editModeRegistered then
		return true
	end
	if not TimeToLevel.HasEditMode() then
		return false
	end
	if not LibStub then
		return false
	end
	if not TimeToLevel.window or not TimeToLevel.window.frame then
		return false
	end

	local lib = LibStub:GetLibrary("LibEditMode", true)
	if not lib or not lib.AddFrame then
		return false
	end

	local frame = TimeToLevel.window.frame
	frame.editModeName = TimeToLevel.DISPLAY_NAME or "Xp Track"

	local default = TimeToLevel.GetEditModeDefaultPosition()
	local ok, err = pcall(function()
		lib:AddFrame(frame, function()
			local settings = TimeToLevel.Settings
			settings.anchor = "editmode"
			if TimeToLevel.window then
				TimeToLevel.window:Layout()
				TimeToLevel.window:SavePlacement()
			end
			TimeToLevel.SaveSettings()
		end, default, TimeToLevel.DISPLAY_NAME or "Xp Track")
	end)

	if not ok then
		print("|cffff0000Xp Track|r: Edit Mode registration failed: " .. tostring(err))
		return false
	end

	TimeToLevel.editModeLib = lib
	TimeToLevel.editModeRegistered = true

	if TimeToLevel.Settings.anchor ~= "free" then
		TimeToLevel.Settings.anchor = "editmode"
	end

	return true
end

function TimeToLevel.HookEditMode()
	if TimeToLevel.editModeHooked then
		return
	end
	TimeToLevel.editModeHooked = true

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
	frame:SetScript("OnEvent", function()
		local settings = TimeToLevel.Settings
		if settings.anchor == "free" or settings.anchor == "editmode" then
			TimeToLevel.HideBlizzardExpBar()
			if TimeToLevel.window then
				TimeToLevel.window:Layout()
				TimeToLevel.window:EnsureVisible()
			end
			return
		end

		TimeToLevel.RefreshBarGeometryFromEditMode(true)
		TimeToLevel.HideBlizzardExpBar()
		if TimeToLevel.window then
			TimeToLevel.window:SyncToBlizzardBar()
			TimeToLevel.window:SavePlacement()
		end
	end)
end
