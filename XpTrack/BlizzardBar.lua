TimeToLevel = TimeToLevel or {}

TimeToLevel.UIHider = TimeToLevel.UIHider or CreateFrame("Frame")
TimeToLevel.UIHider:Hide()
TimeToLevel.UIHider:SetAllPoints(UIParent)

local hooked = {}

function TimeToLevel.IsNeuteredBlizzardFrame(frame)
	if not frame then
		return false
	end
	if hooked[frame] then
		return true
	end
	if TimeToLevel.UIHider and frame.GetParent and frame:GetParent() == TimeToLevel.UIHider then
		return true
	end
	if frame.GetAlpha and frame:GetAlpha() == 0 then
		return true
	end
	return false
end

local function IsValidGeometry(geo)
	if not geo then
		return false
	end
	if not geo.width or geo.width < 100 then
		return false
	end
	if not geo.height or geo.height < 8 then
		return false
	end
	local relativeTo = geo.relativeTo and _G[geo.relativeTo]
	if TimeToLevel.IsNeuteredBlizzardFrame(relativeTo) then
		return false
	end
	return true
end

local function GetXpBarDimensions()
	if MainMenuExpBar and MainMenuExpBar:GetWidth() and MainMenuExpBar:GetWidth() > 0 then
		return MainMenuExpBar:GetWidth(), MainMenuExpBar:GetHeight() or 13
	end

	if StatusTrackingBarManager and StatusTrackingBarManager.bars then
		for _, bar in ipairs(StatusTrackingBarManager.bars) do
			if bar and bar.GetWidth and bar:GetWidth() > 0 then
				return bar:GetWidth(), bar:GetHeight() or 13
			end
		end
	end

	return 512, 13
end

local function CaptureBlizzardBarGeometry(force)
	if TimeToLevel.Settings and TimeToLevel.Settings.anchor == "free" and not force then
		return
	end

	if TimeToLevel.HasEditMode and TimeToLevel.HasEditMode() then
		TimeToLevel.RefreshBarGeometryFromEditMode(force)
		if TimeToLevel.BlizzardBarGeometry then
			return
		end
	end

	if TimeToLevel.BlizzardBarGeometry and not force then
		return
	end

	local width, height = GetXpBarDimensions()
	local point, relativeTo, relPoint, x, y

	if StatusTrackingBarManager and StatusTrackingBarManager.GetPoint then
		point, relativeTo, relPoint, x, y = StatusTrackingBarManager:GetPoint(1)
	end

	if not point and MainMenuExpBar then
		point, relativeTo, relPoint, x, y = MainMenuExpBar:GetPoint(1)
	end

	TimeToLevel.BlizzardBarGeometry = {
		point = point or "BOTTOM",
		relativeTo = (relativeTo and relativeTo.GetName and relativeTo:GetName()) or "UIParent",
		relPoint = relPoint or "BOTTOM",
		x = x or 0,
		y = y or 55,
		width = width,
		height = height,
	}

	if IsValidGeometry(TimeToLevel.BlizzardBarGeometry) then
		TimeToLevel.LastGoodBarGeometry = TimeToLevel.BlizzardBarGeometry
	elseif TimeToLevel.LastGoodBarGeometry then
		TimeToLevel.BlizzardBarGeometry = TimeToLevel.LastGoodBarGeometry
	end
end

local function HideFrameRegions(frame)
	if not frame then
		return
	end

	if frame.GetRegions then
		for i = 1, select("#", frame:GetRegions()) do
			local region = select(i, frame:GetRegions())
			if region and region.Hide then
				region:Hide()
				if region.SetAlpha then
					region:SetAlpha(0)
				end
			end
		end
	end

	if frame.GetChildren then
		for _, child in ipairs({ frame:GetChildren() }) do
			HideFrameRegions(child)
			child:Hide()
			if child.SetAlpha then
				child:SetAlpha(0)
			end
		end
	end
end

local function NeuterBlizzardFrame(frame)
	if not frame or hooked[frame] then
		return
	end

	frame:UnregisterAllEvents()
	frame:EnableMouse(false)
	frame:SetAlpha(0)
	frame:Hide()
	frame:SetParent(TimeToLevel.UIHider)

	if not frame._ttlOriginalShow then
		frame._ttlOriginalShow = frame.Show
		frame.Show = function(self)
			self:SetAlpha(0)
			self:Hide()
			HideFrameRegions(self)
		end
	end

	hooksecurefunc(frame, "Show", function(self)
		self:SetAlpha(0)
		self:Hide()
		HideFrameRegions(self)
	end)

	HideFrameRegions(frame)
	hooked[frame] = true
end

local function HideStatusTrackingManager()
	if not StatusTrackingBarManager then
		return
	end

	NeuterBlizzardFrame(StatusTrackingBarManager)

	if StatusTrackingBarManager.bars then
		for _, bar in ipairs(StatusTrackingBarManager.bars) do
			NeuterBlizzardFrame(bar)
			if bar.StatusBar then
				NeuterBlizzardFrame(bar.StatusBar)
			end
			if bar.OverlayFrame then
				NeuterBlizzardFrame(bar.OverlayFrame)
			end
		end
	end

	if StatusTrackingBarManager.SingleBarLarge then
		NeuterBlizzardFrame(StatusTrackingBarManager.SingleBarLarge)
	end
	if StatusTrackingBarManager.SingleBarSmall then
		NeuterBlizzardFrame(StatusTrackingBarManager.SingleBarSmall)
	end
end

function TimeToLevel.CaptureBlizzardBarGeometry(force)
	CaptureBlizzardBarGeometry(force)
end

function TimeToLevel.HideBlizzardExpBar()
	CaptureBlizzardBarGeometry()
	HideStatusTrackingManager()

	if MainMenuExpBar then
		NeuterBlizzardFrame(MainMenuExpBar)
	end
	if ExhaustionTick then
		NeuterBlizzardFrame(ExhaustionTick)
	end
	if ExhaustionLevelFillBar then
		NeuterBlizzardFrame(ExhaustionLevelFillBar)
	end
	if MainMenuBarArtFrame then
		if MainMenuBarArtFrame.ExhaustionTick then
			NeuterBlizzardFrame(MainMenuBarArtFrame.ExhaustionTick)
		end
		if MainMenuBarArtFrame.ExhaustionLevelFillBar then
			NeuterBlizzardFrame(MainMenuBarArtFrame.ExhaustionLevelFillBar)
		end
	end
end

function TimeToLevel.RestoreBlizzardExpBar()
	if MainMenuExpBar and hooked[MainMenuExpBar] then
		if MainMenuExpBar._ttlOriginalShow then
			MainMenuExpBar.Show = MainMenuExpBar._ttlOriginalShow
			MainMenuExpBar._ttlOriginalShow = nil
		end
		MainMenuExpBar:SetParent(MainMenuBar or UIParent)
		MainMenuExpBar:SetAlpha(1)
		MainMenuExpBar:Show()
		MainMenuExpBar:EnableMouse(true)
		hooked[MainMenuExpBar] = nil
	end
end

function TimeToLevel.HookBlizzardBarLayout()
	if TimeToLevel.blizzardLayoutHooked then
		return
	end
	TimeToLevel.blizzardLayoutHooked = true

	if StatusTrackingBarManager then
		if StatusTrackingBarManager.UpdateBarsShown then
			hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", function()
				CaptureBlizzardBarGeometry(true)
				TimeToLevel.HideBlizzardExpBar()
				if TimeToLevel.window then
					TimeToLevel.window:SyncToBlizzardBar()
					TimeToLevel.window:EnsureVisible()
				end
			end)
		end
		if StatusTrackingBarManager.LayoutBars then
			hooksecurefunc(StatusTrackingBarManager, "LayoutBars", function()
				CaptureBlizzardBarGeometry(true)
				TimeToLevel.HideBlizzardExpBar()
				if TimeToLevel.window then
					TimeToLevel.window:SyncToBlizzardBar()
					TimeToLevel.window:EnsureVisible()
				end
			end)
		end
	end

	if MainMenuBar and MainMenuBar.SetPositionForStatusBars then
		hooksecurefunc(MainMenuBar, "SetPositionForStatusBars", function()
			CaptureBlizzardBarGeometry(true)
			TimeToLevel.HideBlizzardExpBar()
			if TimeToLevel.window then
				local settings = TimeToLevel.Settings
				if settings.anchor == "bottom" then
					TimeToLevel.CaptureBlizzardBarGeometry(true)
					TimeToLevel.window:ApplyDefaultAnchor()
				else
					TimeToLevel.window:SyncToBlizzardBar()
				end
				TimeToLevel.window:EnsureVisible()
			end
		end)
	end

	if MainMenuExpBar then
		MainMenuExpBar:HookScript("OnShow", function()
			TimeToLevel.HideBlizzardExpBar()
		end)
	end
end

function TimeToLevel.StartBlizzardBarWatch()
	if TimeToLevel.blizzardWatchFrame then
		return
	end

	TimeToLevel.HookBlizzardBarLayout()
	if TimeToLevel.HookEditMode then
		TimeToLevel.HookEditMode()
	end

	TimeToLevel.blizzardWatchFrame = CreateFrame("Frame")
	TimeToLevel.blizzardWatchFrame.elapsed = 0
	TimeToLevel.blizzardWatchFrame:SetScript("OnUpdate", function(frame, elapsed)
		if TimeToLevel.Settings and TimeToLevel.Settings.hideBlizzardBar == false then
			return
		end
		frame.elapsed = frame.elapsed + elapsed
		if frame.elapsed < 0.2 then
			return
		end
		frame.elapsed = 0
		TimeToLevel.HideBlizzardExpBar()
		if TimeToLevel.window and TimeToLevel.Settings.anchor ~= "free" and TimeToLevel.Settings.anchor ~= "editmode" then
			if TimeToLevel.Settings.anchor == "bottom" then
				TimeToLevel.CaptureBlizzardBarGeometry(true)
				TimeToLevel.window:ApplyDefaultAnchor()
			else
				TimeToLevel.window:SyncToBlizzardBar()
			end
			TimeToLevel.window:EnsureVisible()
		end
	end)
end
