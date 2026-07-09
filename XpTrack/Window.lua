TimeToLevel = TimeToLevel or {}

TimeToLevel.Window = {}
local Window = TimeToLevel.Window

Window.MIN_WIDTH = 280
Window.MIN_HEIGHT = 14
Window.DEFAULT_WIDTH = 520
Window.DEFAULT_HEIGHT = 20
Window.TRACK_HEIGHT = 14
Window.END_CAP_WIDTH = 14
Window.BORDER_HEIGHT = 13
Window.GRYPHON_WIDTH = 56
Window.XP_BORDER_FILE = "Interface\\MainMenuBar\\UI-XP-Bar"

local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

local COLORS = {
	track = { 0.04, 0.02, 0.06, 1 },
	current = { 0.78, 0.48, 0.92, 1 },
	rested = { 0.25, 0.52, 1.0, 1 },
	quest = { 1.0, 0.82, 0.0, 1 },
	questZone = { 1.0, 0.82, 0.0, 1 },
	text = { 1, 1, 1, 1 },
}

local function GetModeColor(mode)
	if mode == TimeToLevel.XpGain.MODE_QUEST then
		return COLORS.quest
	end
	if mode == TimeToLevel.XpGain.MODE_RESTED then
		return COLORS.rested
	end
	return COLORS.current
end

function Window:IsReady()
	return self.uiReady and self.frame and self.track and self.currentFill
end

function Window:DestroyFrame()
	if self.frame then
		self.frame:Hide()
		self.frame:SetScript("OnMouseDown", nil)
		self.frame:SetScript("OnMouseUp", nil)
		self.frame:SetScript("OnDragStart", nil)
		self.frame:SetScript("OnDragStop", nil)
		self.frame:SetParent(nil)
		self.frame = nil
	end
	self.uiReady = false
end

function Window:StopAllMovement()
	if self.frame then
		self.frame:StopMovingOrSizing()
	end
	self.isMoving = false
	self.isResizing = false
end

function Window:GetDefaultWidth()
	if MainMenuExpBar and MainMenuExpBar:GetWidth() > 0 then
		return MainMenuExpBar:GetWidth()
	end
	return Window.DEFAULT_WIDTH
end

local function ResolveAnchorFrame(name)
	if type(name) == "string" and name ~= "" then
		local frame = _G[name]
		if frame then
			return frame
		end
	end
	return UIParent
end

function Window:HasSavedAnchor()
	local settings = TimeToLevel.Settings
	return settings.anchorPoint ~= nil and settings.anchorX ~= nil and settings.anchorY ~= nil
end

function Window:SaveAnchorSettings()
	local settings = TimeToLevel.Settings
	if not self.frame or not settings then
		return
	end

	local point, relativeTo, relPoint, x, y = self.frame:GetPoint(1)
	if not point then
		return
	end

	settings.anchorPoint = point
	settings.anchorRelPoint = relPoint or point
	settings.anchorX = x or 0
	settings.anchorY = y or 0
	if relativeTo and relativeTo.GetName then
		settings.anchorRelativeTo = relativeTo:GetName() or "UIParent"
	else
		settings.anchorRelativeTo = "UIParent"
	end

	if settings.anchor == "free" then
		local left = self.frame:GetLeft()
		local top = self.frame:GetTop()
		if left and top and UIParent then
			settings.left = left
			settings.top = UIParent:GetHeight() - top
		end
	end
end

function Window:ApplySavedAnchor()
	local settings = TimeToLevel.Settings
	if not self.frame or not settings then
		return false
	end

	self:ApplyFrameLayer()
	self.frame:ClearAllPoints()
	self.frame:SetSize(
		math.max(Window.MIN_WIDTH, settings.width or self:GetDefaultWidth()),
		self:GetFrameHeight()
	)

	if self:HasSavedAnchor() then
		local relativeTo = ResolveAnchorFrame(settings.anchorRelativeTo)
		self.frame:SetPoint(
			settings.anchorPoint,
			relativeTo,
			settings.anchorRelPoint or settings.anchorPoint,
			settings.anchorX,
			settings.anchorY
		)
		return true
	end

	if settings.anchor == "free" and settings.left and settings.top then
		self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.left, -settings.top)
		return true
	end

	return false
end

function Window:ClearSavedAnchor()
	local settings = TimeToLevel.Settings
	if not settings then
		return
	end

	settings.anchorPoint = nil
	settings.anchorRelPoint = nil
	settings.anchorRelativeTo = nil
	settings.anchorX = nil
	settings.anchorY = nil
	settings.left = nil
	settings.top = nil
end

function Window:SavePlacement()
	if not self.frame then
		return
	end

	local settings = TimeToLevel.Settings
	settings.width = self.frame:GetWidth()
	local scale = self:GetBarScale()
	if scale > 0 then
		settings.height = math.max(Window.MIN_HEIGHT, math.floor(self.frame:GetHeight() / scale + 0.5))
	else
		settings.height = self.frame:GetHeight()
	end

	if settings.anchor == "free" or settings.anchor == "editmode" then
		self:SaveAnchorSettings()
	end

	TimeToLevel.SaveSettings()
end

function Window:GetBarScale()
	local scale = TimeToLevel.Settings.barScale or 1
	return math.max(0.5, math.min(1.5, scale))
end

function Window:GetBaseHeight()
	local settings = TimeToLevel.Settings
	return math.max(Window.MIN_HEIGHT, settings.height or Window.DEFAULT_HEIGHT)
end

function Window:GetFrameHeight()
	return math.max(Window.MIN_HEIGHT, math.floor(self:GetBaseHeight() * self:GetBarScale() + 0.5))
end

function Window:ApplyDefaultAnchor()
	if not self.frame then
		return
	end

	local settings = TimeToLevel.Settings
	local anchor = TimeToLevel.GetDefaultBarAnchor(settings.bottomOffset or 0)
	self.frame:ClearAllPoints()
	self.frame:SetPoint(anchor.point, anchor.relativeTo, anchor.relPoint, anchor.x, anchor.y)
end

function Window:ApplyFrameLayer()
	if not self.frame then
		return
	end

	if self.frame:GetParent() ~= UIParent then
		self.frame:SetParent(UIParent)
	end

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetFrameLevel(1)
end

function Window:GetBlizzardGeometry()
	if TimeToLevel.Settings.anchor == "editmode" then
		return TimeToLevel.BlizzardBarGeometry
	end
	if TimeToLevel.Settings.anchor ~= "free" and TimeToLevel.RefreshBarGeometryFromEditMode then
		TimeToLevel.RefreshBarGeometryFromEditMode()
	end

	local geo = TimeToLevel.BlizzardBarGeometry
	if geo then
		return geo
	end

	TimeToLevel.HideBlizzardExpBar()
	return TimeToLevel.BlizzardBarGeometry
end

function Window:ApplyAnchor()
	local settings = TimeToLevel.Settings
	if not self.frame then
		return
	end

	if settings.anchor == "editmode" then
		if not self:ApplySavedAnchor() then
			self:ApplyFrameLayer()
			self:ApplyDefaultAnchor()
		end
		return
	end

	self:ApplyFrameLayer()
	self.frame:ClearAllPoints()

	if settings.anchor == "free" then
		if not self:ApplySavedAnchor() then
			self:ApplyDefaultAnchor()
		end
		return
	end

	if settings.anchor == "bottom" then
		self.frame:SetSize(
			math.max(Window.MIN_WIDTH, settings.width or self:GetDefaultWidth()),
			self:GetFrameHeight()
		)
		self:ApplyDefaultAnchor()
	else
		local y = settings.bottomOffset or 0
		local geo = self:GetBlizzardGeometry()
		if geo then
			local relativeTo = _G[geo.relativeTo] or UIParent
			if TimeToLevel.IsNeuteredBlizzardFrame and TimeToLevel.IsNeuteredBlizzardFrame(relativeTo) then
				relativeTo = UIParent
			end
			self.frame:SetSize(
				math.max(Window.MIN_WIDTH, geo.width or settings.width or self:GetDefaultWidth()),
				self:GetFrameHeight()
			)
			self.frame:SetPoint(geo.point, relativeTo, geo.relPoint, geo.x, geo.y + y)
		else
			self.frame:SetSize(self:GetDefaultWidth(), self:GetFrameHeight())
			self:ApplyDefaultAnchor()
		end
	end
end

function Window:SyncToBlizzardBar()
	if not self.frame then
		return
	end
	local settings = TimeToLevel.Settings
	if settings.anchor == "bottom" then
		settings.width = math.max(Window.MIN_WIDTH, self:GetDefaultWidth())
		if (settings.height or 0) < Window.MIN_HEIGHT then
			settings.height = Window.DEFAULT_HEIGHT
		end
		if TimeToLevel.CaptureBlizzardBarGeometry then
			TimeToLevel.CaptureBlizzardBarGeometry(true)
		end
		self:ApplyAnchor()
	end
	self:EnsureVisible()
end

function Window:EnsureVisible()
	if not self.frame then
		return
	end

	local settings = TimeToLevel.Settings
	if settings.visible == false then
		return
	end

	if not self.frame:GetPoint(1) then
		self:ApplyAnchor()
	end

	local width = self.frame:GetWidth()
	local height = self.frame:GetHeight()
	if not width or width < Window.MIN_WIDTH or not height or height < Window.MIN_HEIGHT then
		self.frame:SetSize(
			math.max(Window.MIN_WIDTH, settings.width or self:GetDefaultWidth()),
			self:GetFrameHeight()
		)
		self:Layout()
	end

	self.frame:SetAlpha(settings.opacity or 1)
	self.frame:Show()
	self:ApplyFrameLayer()

	if self.lastStats then
		self:UpdateBarVisuals(self.lastStats)
	end
	self:Layout()
end

function Window:GetTrackInsets()
	local settings = TimeToLevel.Settings
	local scale = self:GetBarScale()
	if settings.blizzardBorder == false then
		local pad = math.max(1, math.floor(2 * scale))
		return { left = pad, right = pad, top = pad, bottom = pad }
	end
	return {
		left = math.max(8, math.floor(Window.END_CAP_WIDTH * scale)),
		right = math.max(8, math.floor(Window.END_CAP_WIDTH * scale)),
		top = math.max(1, math.floor(2 * scale)),
		bottom = 0,
	}
end

function Window:ApplyBorderSpec(tex, spec)
	if not tex or not spec then
		return
	end

	tex:SetTexture(spec.tex or Window.XP_BORDER_FILE)
	tex:SetVertexColor(1, 1, 1, 1)
	local coord = spec.coord
	if coord and #coord >= 4 then
		tex:SetTexCoord(coord[1], coord[2], coord[3], coord[4])
	end
	if tex.SetHorizTile then
		tex:SetHorizTile(spec.stretch == true)
	end
	if tex.SetVertTile then
		tex:SetVertTile(false)
	end
end

function Window:CreateChrome()
	local settings = TimeToLevel.Settings
	self.chrome = CreateFrame("Frame", nil, self.frame)
	self.chrome:SetAllPoints()
	self.chrome:SetFrameLevel(self.frame:GetFrameLevel() + 8)

	self.borderParts = {}
	for i = 1, 4 do
		local tex = self.chrome:CreateTexture(nil, "ARTWORK", nil, i)
		self:ApplyBorderSpec(tex, TimeToLevel.GetXpBorderPartSpec(i))
		tex:Hide()
		self.borderParts[i] = tex
	end
	self.borderLeft = self.borderParts[1]
	self.borderMidLeft = self.borderParts[2]
	self.borderMidRight = self.borderParts[3]
	self.borderRight = self.borderParts[4]

	self.gryphonLeft = self.chrome:CreateTexture(nil, "OVERLAY", nil, 5)
	self.gryphonLeft:SetTexture(TimeToLevel.GetGryphonTexture("left"))
	self.gryphonLeft:SetSize(Window.GRYPHON_WIDTH, Window.GRYPHON_WIDTH)

	self.gryphonRight = self.chrome:CreateTexture(nil, "OVERLAY", nil, 6)
	self.gryphonRight:SetTexture(TimeToLevel.GetGryphonTexture("right"))
	if MainMenuBarArtFrame and MainMenuBarArtFrame.RightEndCap then
		self.gryphonRight:SetTexCoord(0, 1, 0, 1)
	else
		self.gryphonRight:SetTexCoord(1, 0, 0, 1)
	end
	self.gryphonRight:SetSize(Window.GRYPHON_WIDTH, Window.GRYPHON_WIDTH)

	if settings.blizzardBorder == false then
		for _, tex in ipairs(self.borderParts) do
			tex:Hide()
		end
	end
	if settings.gryphonCaps == false then
		self.gryphonLeft:Hide()
		self.gryphonRight:Hide()
	end
end

function Window:LayoutChrome()
	if not self.chrome or not self.borderParts or not self.track then
		return
	end

	local settings = TimeToLevel.Settings
	local scale = self:GetBarScale()
	local borderH = math.max(8, math.floor(Window.BORDER_HEIGHT * scale))

	if settings.blizzardBorder ~= false then
		local leftSpec = TimeToLevel.GetXpBorderPartSpec(1)
		local midLeftSpec = TimeToLevel.GetXpBorderPartSpec(2)
		local midRightSpec = TimeToLevel.GetXpBorderPartSpec(3)
		local rightSpec = TimeToLevel.GetXpBorderPartSpec(4)

		self:ApplyBorderSpec(self.borderLeft, leftSpec)
		self:ApplyBorderSpec(self.borderMidLeft, midLeftSpec)
		self:ApplyBorderSpec(self.borderMidRight, midRightSpec)
		self:ApplyBorderSpec(self.borderRight, rightSpec)

		local leftW = leftSpec.width or Window.END_CAP_WIDTH
		local rightW = rightSpec.width or Window.END_CAP_WIDTH
		local trackWidth = self.track:GetWidth()
		local midWidth = math.max(0, trackWidth)
		local midLeftW = math.floor(midWidth / 2)

		self.borderLeft:Show()
		self.borderLeft:ClearAllPoints()
		self.borderLeft:SetPoint("BOTTOMRIGHT", self.track, "BOTTOMLEFT", 0, 0)
		self.borderLeft:SetSize(leftW, borderH)

		self.borderRight:Show()
		self.borderRight:ClearAllPoints()
		self.borderRight:SetPoint("BOTTOMLEFT", self.track, "BOTTOMRIGHT", 0, 0)
		self.borderRight:SetSize(rightW, borderH)

		self.borderMidLeft:Show()
		self.borderMidLeft:ClearAllPoints()
		self.borderMidLeft:SetPoint("BOTTOMLEFT", self.borderLeft, "BOTTOMRIGHT", 0, 0)
		self.borderMidLeft:SetSize(math.max(1, midLeftW), borderH)

		self.borderMidRight:Show()
		self.borderMidRight:ClearAllPoints()
		self.borderMidRight:SetPoint("BOTTOMLEFT", self.borderMidLeft, "BOTTOMRIGHT", 0, 0)
		self.borderMidRight:SetSize(math.max(1, midWidth - midLeftW), borderH)
	else
		for _, tex in ipairs(self.borderParts) do
			tex:Hide()
		end
	end

	if settings.gryphonCaps ~= false then
		local gryphonSize = math.max(28, math.floor(Window.GRYPHON_WIDTH * scale))
		self.gryphonLeft:SetSize(gryphonSize, gryphonSize)
		self.gryphonRight:SetSize(gryphonSize, gryphonSize)
		self.gryphonLeft:Show()
		self.gryphonRight:Show()
		self.gryphonLeft:ClearAllPoints()
		self.gryphonLeft:SetPoint("BOTTOMRIGHT", self.track, "BOTTOMLEFT", 4, 0)
		self.gryphonRight:ClearAllPoints()
		self.gryphonRight:SetPoint("BOTTOMLEFT", self.track, "BOTTOMRIGHT", -4, 0)
	else
		self.gryphonLeft:Hide()
		self.gryphonRight:Hide()
	end
end

function Window:BeginMove()
	if not self.frame then
		return
	end

	local scale = UIParent:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	self.dragCX = cx / scale
	self.dragCY = cy / scale
	self.dragLeft = self.frame:GetLeft()
	local top = self.frame:GetTop()
	self.dragTop = (top and UIParent) and (UIParent:GetHeight() - top) or 0
	self.isMoving = true
	self.frame:SetMovable(true)
	TimeToLevel.Settings.anchor = "free"
	self.mouseCatcher:EnableMouse(true)
end

function Window:BindBarMouseHandlers()
	local window = self

	local function OnBarMouseUp(_, button)
		if button == "RightButton" and IsShiftKeyDown() and not window.isMoving and not window.isResizing then
			window:CycleAlpha()
			return
		end
		window:OnMouseUp(button)
	end

	local function OnBarMouseDown(_, button)
		if button == "LeftButton" and IsShiftKeyDown() then
			window:BeginMove()
		end
	end

	self.chrome:EnableMouse(true)
	self.chrome:SetScript("OnMouseDown", OnBarMouseDown)
	self.chrome:SetScript("OnMouseUp", OnBarMouseUp)

	self.frame:SetScript("OnMouseDown", OnBarMouseDown)
end

function Window:UpdateMouseCatcher()
	if not self.mouseCatcher then
		return
	end

	local window = self
	self.mouseCatcher:SetScript("OnUpdate", function()
		if window.isMoving then
			if not IsMouseButtonDown("LeftButton") then
				window:OnMouseUp("LeftButton")
				return
			end
			local scale = UIParent:GetEffectiveScale()
			local cx, cy = GetCursorPosition()
			cx = cx / scale
			cy = cy / scale
			local dx = cx - window.dragCX
			local dy = cy - window.dragCY
			window.frame:ClearAllPoints()
			window.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", window.dragLeft + dx, -(window.dragTop - dy))
			return
		end

		if not window.manualResize then
			return
		end
		local scale = window.frame:GetEffectiveScale()
		local x = select(1, GetCursorPosition()) / scale
		local dx = x - window.resizeStartX
		local width = math.max(Window.MIN_WIDTH, window.resizeStartW + dx)
		window.frame:SetWidth(width)
		TimeToLevel.Settings.width = width
		window:Layout()
		if window.lastStats then
			window:UpdateDisplay(window.lastStats)
		end
	end)
end

function Window:Create()
	TimeToLevel.LoadSettings()
	local settings = TimeToLevel.Settings
	local window = self

	self:DestroyFrame()

	if not settings.migratedBarV2 then
		settings.width = self:GetDefaultWidth()
		settings.height = Window.DEFAULT_HEIGHT
		settings.anchor = "bottom"
		settings.bottomOffset = 0
		settings.left = nil
		settings.top = nil
		settings.migratedBarV2 = true
	end

	if not settings.migratedEditModeV1 and TimeToLevel.HasEditMode and TimeToLevel.HasEditMode() then
		settings.migratedEditModeV1 = true
	end

	if not settings.migratedBarV4 then
		if (settings.height or 0) < Window.MIN_HEIGHT then
			settings.height = Window.DEFAULT_HEIGHT
		end
		settings.migratedBarV4 = true
	end

	settings.width = math.max(Window.MIN_WIDTH, settings.width or self:GetDefaultWidth())
	settings.height = math.max(Window.MIN_HEIGHT, settings.height or Window.DEFAULT_HEIGHT)
	if settings.barScale == nil then
		settings.barScale = 1
	end

	self.frame = CreateFrame("Frame", "XpTrackBar", UIParent)
	self.frame:SetSize(settings.width, self:GetFrameHeight())
	self:ApplyFrameLayer()
	self:ApplyAnchor()
	self.frame:SetMovable(true)
	self.frame:SetClampedToScreen(true)
	self.frame:EnableMouse(true)
	self.frame:SetAlpha(settings.opacity or 1)

	self:CreateChrome()
	self:BindBarMouseHandlers()

	local ins = self:GetTrackInsets()
	self.track = CreateFrame("Frame", nil, self.frame)
	self.track:SetPoint("TOPLEFT", ins.left, -ins.top)
	self.track:SetPoint("BOTTOMRIGHT", -ins.right, ins.bottom)
	self.track:SetFrameLevel(self.frame:GetFrameLevel() + 3)
	self.track:EnableMouse(true)
	self.track:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" and IsShiftKeyDown() then
			window:BeginMove()
		end
	end)
	self.track:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" and IsShiftKeyDown() and not window.isMoving and not window.isResizing then
			window:CycleAlpha()
			return
		end
		window:OnMouseUp(button)
	end)

	self.trackBg = self.track:CreateTexture(nil, "BACKGROUND")
	self.trackBg:SetAllPoints()
	self.trackBg:SetColorTexture(COLORS.track[1], COLORS.track[2], COLORS.track[3], COLORS.track[4])

	self.remainingZone = self.track:CreateTexture(nil, "ARTWORK", nil, 1)
	self.remainingZone:SetTexture(BAR_TEXTURE)
	self.remainingZone:SetVertexColor(COLORS.track[1], COLORS.track[2], COLORS.track[3], COLORS.track[4])
	self.remainingZone:Hide()

	self.questPreview = self.track:CreateTexture(nil, "ARTWORK", nil, 2)
	self.questPreview:SetTexture(BAR_TEXTURE)
	self.questPreview:SetVertexColor(COLORS.questZone[1], COLORS.questZone[2], COLORS.questZone[3], COLORS.questZone[4])
	self.questPreview:Hide()

	self.currentFill = self.track:CreateTexture(nil, "ARTWORK", nil, 3)
	self.currentFill:SetTexture(BAR_TEXTURE)
	self.currentFill:SetVertexColor(COLORS.current[1], COLORS.current[2], COLORS.current[3], 1)
	self.currentFill:Hide()

	self.gainHighlight = self.track:CreateTexture(nil, "ARTWORK", nil, 4)
	self.gainHighlight:SetTexture(BAR_TEXTURE)
	self.gainHighlight:Hide()

	self.textLayer = CreateFrame("Frame", nil, self.track)
	self.textLayer:SetAllPoints()
	self.textLayer:SetFrameLevel(self.track:GetFrameLevel() + 10)
	self.textLayer:EnableMouse(false)

	self.text = self.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.text:SetPoint("CENTER", self.textLayer, "CENTER", 0, 0)
	self.text:SetJustifyH("CENTER")
	self.text:SetText(TimeToLevel.DISPLAY_NAME or "Xp Track")

	self.track:SetScript("OnEnter", function()
		window:ShowQuestTooltip()
	end)
	self.track:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	self.grip = CreateFrame("Frame", nil, self.frame)
	self.grip:SetSize(6, self.frame:GetHeight())
	self.grip:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
	self.grip:EnableMouse(true)
	self.grip:SetScript("OnEnter", function()
		GameTooltip:SetOwner(window.grip, "ANCHOR_ABOVE")
		GameTooltip:SetText("Shift+drag: move bar", 1, 1, 1)
		GameTooltip:AddLine("Shift+right-click: cycle opacity", 0.9, 0.9, 0.9, true)
		GameTooltip:AddLine("Right-drag left edge: resize width", 0.9, 0.9, 0.9, true)
		GameTooltip:Show()
	end)
	self.grip:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	self.grip:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" and IsShiftKeyDown() then
			window:BeginMove()
		elseif button == "RightButton" then
			window.isResizing = true
			window.mouseCatcher:EnableMouse(true)
			window.frame:SetResizable(true)
			local ok = pcall(window.frame.StartSizing, window.frame, "RIGHT")
			if not ok then
				window.manualResize = true
				window.resizeStartX = select(1, GetCursorPosition()) / window.frame:GetEffectiveScale()
				window.resizeStartW = window.frame:GetWidth()
			end
		end
	end)

	self.grip:SetScript("OnMouseUp", function(_, button)
		window:OnMouseUp(button)
	end)

	self.frame:SetScript("OnMouseUp", function(_, button)
		window:OnMouseUp(button)
	end)

	if not self.mouseCatcher then
		self.mouseCatcher = CreateFrame("Frame", nil, UIParent)
		self.mouseCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
		self.mouseCatcher:SetAllPoints(UIParent)
		self.mouseCatcher:EnableMouse(false)
		self.mouseCatcher:SetScript("OnMouseUp", function(_, button)
			window:OnMouseUp(button)
		end)
	end

	self:UpdateMouseCatcher()

	self.uiReady = true
	self:Layout()
	self:RefreshFromGame()

	if settings.visible ~= false then
		self.frame:Show()
	else
		self.frame:Hide()
	end

	if settings.hideBlizzardBar ~= false then
		TimeToLevel.HideBlizzardExpBar()
		TimeToLevel.StartBlizzardBarWatch()
	end

	if settings.anchor == "bottom" then
		self:SyncToBlizzardBar()
	else
		self:ApplyAnchor()
	end

	if TimeToLevel.RegisterEditModeFrame then
		TimeToLevel.RegisterEditModeFrame()
	end

	return self
end

function Window:OnMouseUp(button)
	local wasMoving = self.isMoving
	local wasResizing = self.isResizing

	self:StopAllMovement()
	self.manualResize = false
	if self.mouseCatcher then
		self.mouseCatcher:EnableMouse(false)
	end

	if not self:IsReady() then
		return
	end

	if wasMoving then
		TimeToLevel.Settings.anchor = "free"
		self:SavePlacement()
	elseif wasResizing then
		self:SavePlacement()
	end
end

function Window:Layout()
	if not self:IsReady() then
		return
	end

	local settings = TimeToLevel.Settings
	local height = self.frame:GetHeight()
	local trackWidth = math.max(1, self.track:GetWidth())
	local ins = self:GetTrackInsets()
	local fontSize = math.max(7, math.min(11, math.floor(math.min(height, trackWidth / 42))))

	self.text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
	self.text:SetWidth(math.max(1, trackWidth - 6))
	if self.text.SetWordWrap then
		self.text:SetWordWrap(false)
	end
	self.grip:SetHeight(height)
	self.track:ClearAllPoints()
	self.track:SetPoint("TOPLEFT", ins.left, -ins.top)
	self.track:SetPoint("BOTTOMRIGHT", -ins.right, ins.bottom)
	self:LayoutChrome()
end

function Window:GetBarSegmentPixels(stats, trackWidth)
	local xpRequired = stats.xpRequired or 0
	local xpInto = stats.xpIntoLevel or 0
	local questXp = stats.questXpTotal or 0

	if xpRequired <= 0 or trackWidth <= 0 then
		return 0, 0, trackWidth
	end

	local currentEnd = trackWidth * (xpInto / xpRequired)
	local questEnd = currentEnd

	if questXp > 0 then
		questEnd = math.min(trackWidth, trackWidth * ((xpInto + questXp) / xpRequired))
	end

	return currentEnd, questEnd, trackWidth
end

function Window:PositionBarSegment(texture, leftPx, rightPx, track)
	if not texture or not track then
		return
	end

	local width = rightPx - leftPx
	if width <= 0.5 then
		texture:Hide()
		return
	end

	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", track, "TOPLEFT", leftPx, 0)
	texture:SetPoint("BOTTOMRIGHT", track, "BOTTOMLEFT", rightPx, 0)
	texture:Show()
end

function Window:ShowQuestTooltip()
	local stats = self.lastStats
	if not stats or not stats.questXpCount or stats.questXpCount <= 0 then
		return
	end

	GameTooltip:SetOwner(self.track, "ANCHOR_ABOVE")
	GameTooltip:SetText("Ready to turn in", 1, 0.82, 0)
	for _, entry in ipairs(stats.questXpEntries or {}) do
		GameTooltip:AddLine(
			string.format("%s  |cff00ccff+%s XP|r", entry.title, TimeToLevel.FormatNumber(entry.xp)),
			1, 1, 1,
			true
		)
	end
	if stats.questProjectedPercent then
		GameTooltip:AddLine(" ")
		local remaining = math.max(0, (stats.xpRequired or 0) - (stats.xpIntoLevel or 0) - (stats.questXpTotal or 0))
		GameTooltip:AddLine(string.format(
			"Total +%s XP  |  %s left after turn-in",
			TimeToLevel.FormatNumber(stats.questXpTotal or 0),
			TimeToLevel.FormatNumber(remaining)
		), 0.9, 0.9, 0.9, true)
	end
	GameTooltip:Show()
end

function Window:UpdateBarVisuals(stats)
	if not self:IsReady() or not stats then
		return
	end

	local trackWidth = math.max(1, self.track:GetWidth())
	local currentEnd, questEnd = self:GetBarSegmentPixels(stats, trackWidth)

	self:PositionBarSegment(self.remainingZone, questEnd, trackWidth, self.track)
	self:PositionBarSegment(self.questPreview, currentEnd, questEnd, self.track)
	self:PositionBarSegment(self.currentFill, 0, currentEnd, self.track)

	if stats.flash and stats.flash.endPct and stats.flash.startPct then
		local startPx = trackWidth * (stats.flash.startPct / 100)
		local endPx = trackWidth * (stats.flash.endPct / 100)
		self:PositionBarSegment(self.gainHighlight, startPx, endPx, self.track)
		local flashColor = GetModeColor(stats.flash.mode)
		self.gainHighlight:SetVertexColor(flashColor[1], flashColor[2], flashColor[3], 0.95)
	else
		self.gainHighlight:Hide()
	end
end

function Window:RefreshFromGame()
	local xpRequired = TimeToLevel.GetPlayerXPMax()
	local xpInto = TimeToLevel.GetPlayerXP()
	self:UpdateDisplay({
		level = TimeToLevel.GetPlayerLevel(),
		maxLevel = TimeToLevel.IsMaxLevel(),
		xpIntoLevel = xpInto,
		xpRequired = xpRequired,
		xpRemaining = math.max(0, xpRequired - xpInto),
		percent = xpRequired > 0 and (xpInto / xpRequired) * 100 or 0,
		elapsed = 0,
		xpPerMinute = 0,
		xpPerHour = 0,
		etaSeconds = nil,
		sessionXpEarned = 0,
		barMode = TimeToLevel.XpGain:GetBarMode(),
		flash = TimeToLevel.XpGain:GetFlashState(),
		restedPercent = TimeToLevel.GetRestedBarPercent(),
		restedXp = TimeToLevel.GetRestedXpAmount(),
	})
end

function Window:BuildBarText(stats)
	if stats.maxLevel then
		return string.format("Lv %d  MAX", stats.level)
	end

	local displayRemaining = stats.xpRemaining or 0
	if stats.questXpTotal and stats.questXpTotal > 0 and stats.xpRemainingAfterQuests ~= nil then
		displayRemaining = stats.xpRemainingAfterQuests
	end

	local parts = {
		string.format("Lv%d %.1f%%", stats.level, stats.percent or 0),
	}

	if (stats.xpPerMinute or 0) > 0 then
		parts[#parts + 1] = TimeToLevel.FormatCompactNumber(stats.xpPerMinute) .. "/m"
	end

	if stats.etaSeconds ~= nil and (stats.xpPerMinute or 0) > 0 then
		parts[#parts + 1] = "~" .. TimeToLevel.FormatShortDuration(stats.etaSeconds)
	end

	parts[#parts + 1] = TimeToLevel.FormatCompactNumber(displayRemaining) .. " left"

	local line = table.concat(parts, " | ")

	if stats.questXpTotal and stats.questXpTotal > 0 then
		local questMark = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12:0:0|t"
		line = line .. string.format(
			" | %s +%s (%d)",
			questMark,
			TimeToLevel.FormatCompactNumber(stats.questXpTotal),
			stats.questXpCount or 0
		)
	end

	if stats.restedXp and stats.restedXp > 0 then
		line = line .. string.format(
			" | |cff66aaff+%s RXP|r",
			TimeToLevel.FormatCompactNumber(stats.restedXp)
		)
	elseif stats.flash and stats.flash.mode == TimeToLevel.XpGain.MODE_QUEST then
		line = line .. " | |cffffd200Quest|r"
	elseif stats.flash and stats.flash.mode == TimeToLevel.XpGain.MODE_RESTED then
		line = line .. " | |cff66aaffRXP|r"
	elseif stats.barMode == TimeToLevel.XpGain.MODE_RESTED then
		line = line .. " | |cff66aaffRXP|r"
	end

	return line
end

function Window:UpdateDisplay(stats)
	if not stats or not self:IsReady() then
		return
	end

	self.lastStats = stats

	if stats.xpRequired and stats.xpRequired > 0 then
		stats.percent = (stats.xpIntoLevel / stats.xpRequired) * 100
	end

	self.text:SetText(self:BuildBarText(stats))
	self.text:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3])

	self:UpdateBarVisuals(stats)
end

function Window:CycleAlpha()
	local settings = TimeToLevel.Settings
	local steps = { 0.5, 0.7, 0.85, 1.0 }
	local current = settings.opacity or 1
	local nextAlpha = steps[1]
	for i, value in ipairs(steps) do
		if current < value - 0.01 then
			nextAlpha = value
			break
		elseif i == #steps then
			nextAlpha = steps[1]
		end
	end
	settings.opacity = nextAlpha
	self.frame:SetAlpha(nextAlpha)
	TimeToLevel.SaveSettings()
	if TimeToLevel.Options and TimeToLevel.Options.RefreshOpacity then
		TimeToLevel.Options:RefreshOpacity()
	end
end

function Window:SetBarScale(percent)
	local scale = math.max(50, math.min(150, percent or 100)) / 100
	TimeToLevel.Settings.barScale = scale
	if self.frame then
		self.frame:SetHeight(self:GetFrameHeight())
		self:Layout()
		if self.lastStats then
			self:UpdateDisplay(self.lastStats)
		end
	end
	TimeToLevel.SaveSettings()
	if TimeToLevel.Options and TimeToLevel.Options.RefreshScale then
		TimeToLevel.Options:RefreshScale()
	end
end

function Window:SetAlpha(value)
	local alpha = math.max(0.3, math.min(1, value / 100))
	TimeToLevel.Settings.opacity = alpha
	self.frame:SetAlpha(alpha)
	TimeToLevel.SaveSettings()
	if TimeToLevel.Options and TimeToLevel.Options.RefreshOpacity then
		TimeToLevel.Options:RefreshOpacity()
	end
end

function Window:FlashLevelUp()
	if not self.currentFill then
		return
	end
	self.currentFill:SetVertexColor(0.3, 0.9, 0.4, 1)
	if self.flashFrame then
		self.flashFrame:SetScript("OnUpdate", nil)
	end
	self.flashFrame = CreateFrame("Frame")
	self.flashFrame.elapsed = 0
	self.flashFrame:SetScript("OnUpdate", function(frame, elapsed)
		frame.elapsed = frame.elapsed + elapsed
		if frame.elapsed >= 1.2 then
			if self.currentFill then
				self.currentFill:SetVertexColor(COLORS.current[1], COLORS.current[2], COLORS.current[3], 1)
			end
			if self.lastStats then
				self:UpdateBarVisuals(self.lastStats)
			end
			frame:SetScript("OnUpdate", nil)
		end
	end)
end

function Window:Show()
	if self.frame then
		self.frame:Show()
		TimeToLevel.Settings.visible = true
		if TimeToLevel.Settings.hideBlizzardBar ~= false then
			TimeToLevel.HideBlizzardExpBar()
		end
	end
end

function Window:Hide()
	if self.frame then
		self.frame:Hide()
		TimeToLevel.Settings.visible = false
		if TimeToLevel.Settings.hideBlizzardBar ~= false then
			TimeToLevel.RestoreBlizzardExpBar()
		end
	end
end

function Window:Toggle()
	if self.frame and self.frame:IsShown() then
		self:Hide()
	else
		self:Show()
	end
end

function Window:IsShown()
	return self.frame and self.frame:IsShown()
end
