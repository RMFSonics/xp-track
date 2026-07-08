TimeToLevel = TimeToLevel or {}

TimeToLevel.MinimapButton = {}
local MinimapButton = TimeToLevel.MinimapButton
local DISPLAY = TimeToLevel.DISPLAY_NAME or "Xp Track"
local SLASH = TimeToLevel.SLASH_CMD or "/xptrack"
local MINIMAP_ICON = TimeToLevel.MINIMAP_ICON_TEXTURE or TimeToLevel.LOGO_TEXTURE or "Interface\\AddOns\\XpTrack\\Textures\\Logo-32.png"

MinimapButton.DRAG_THRESHOLD = 4
MinimapButton.RADIUS_OFFSET = 5

local MINIMAP_SHAPES = {
	ROUND = { true, true, true, true },
	SQUARE = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
}

local function GetMinimapShapeTable()
	local shape = "ROUND"
	if GetMinimapShape then
		shape = GetMinimapShape() or shape
	end
	return MINIMAP_SHAPES[shape] or MINIMAP_SHAPES.ROUND
end

function MinimapButton:UpdatePosition()
	if not self.frame or not Minimap then
		return
	end

	local settings = TimeToLevel.Settings
	local angle = math.rad(settings.minimapAngle or 220)
	local x = math.cos(angle)
	local y = math.sin(angle)
	local quad = 1
	if x < 0 then
		quad = quad + 1
	end
	if y > 0 then
		quad = quad + 2
	end

	local quadTable = GetMinimapShapeTable()
	local halfW = (Minimap:GetWidth() / 2) + MinimapButton.RADIUS_OFFSET
	local halfH = (Minimap:GetHeight() / 2) + MinimapButton.RADIUS_OFFSET

	if quadTable[quad] then
		x = x * halfW
		y = y * halfH
	else
		local diagW = math.sqrt(2 * halfW * halfW) - 10
		local diagH = math.sqrt(2 * halfH * halfH) - 10
		x = math.max(-halfW, math.min(x * diagW, halfW))
		y = math.max(-halfH, math.min(y * diagH, halfH))
	end

	self.frame:ClearAllPoints()
	self.frame:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:Destroy()
	if self.frame then
		self.frame:Hide()
		self.frame:SetParent(nil)
		self.frame = nil
	end
end

function MinimapButton:HandleClick(mouseButton)
	if self.dragged then
		self.dragged = false
		return
	end

	if mouseButton == "RightButton" then
		if TimeToLevel.Options then
			TimeToLevel.Options:Show()
		end
		return
	end

	if mouseButton == "LeftButton" then
		if IsShiftKeyDown() then
			self:Hide()
			TimeToLevel.SaveSettings()
			print("|cff00ff00" .. DISPLAY .. "|r: Minimap button hidden. Re-enable in " .. SLASH .. " options.")
		elseif self.mainWindow then
			self.mainWindow:Toggle()
		end
	end
end

function MinimapButton:Create(mainWindow)
	if not Minimap then
		return nil
	end

	TimeToLevel.LoadSettings()
	local settings = TimeToLevel.Settings
	local button = self
	button.mainWindow = mainWindow

	button:Destroy()

	button.frame = CreateFrame("Button", "XpTrackMinimapButton", Minimap)
	button.frame:SetSize(31, 31)
	button.frame:SetFrameStrata("MEDIUM")
	button.frame:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	button.frame:RegisterForClicks("anyUp")
	button.frame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	button.border = button.frame:CreateTexture(nil, "OVERLAY")
	button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	button.border:SetSize(53, 53)
	button.border:SetPoint("TOPLEFT", button.frame, "TOPLEFT", 0, 0)

	button.icon = button.frame:CreateTexture(nil, "ARTWORK")
	button.icon:SetSize(17, 17)
	button.icon:SetTexture(MINIMAP_ICON)
	button.icon:SetPoint("TOPLEFT", button.frame, "TOPLEFT", 7, -6)

	button.isMouseDown = false
	button.dragged = false

	button.frame:SetScript("OnEnter", function()
		GameTooltip:SetOwner(button.frame, "ANCHOR_LEFT")
		GameTooltip:SetText(DISPLAY, 1, 1, 1)
		GameTooltip:AddLine("Left-click: toggle XP bar", 0.9, 0.9, 0.9, true)
		GameTooltip:AddLine("Right-click: " .. DISPLAY .. " options", 0.9, 0.9, 0.9, true)
		GameTooltip:AddLine("Shift+left-click: hide " .. DISPLAY .. " minimap button", 0.9, 0.9, 0.9, true)
		GameTooltip:AddLine("Drag: move around minimap edge", 0.9, 0.9, 0.9, true)
		GameTooltip:Show()
	end)

	button.frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button.frame:SetScript("OnClick", function(_, mouseButton)
		button:HandleClick(mouseButton)
	end)

	button.frame:SetScript("OnMouseDown", function(_, mouseButton)
		if mouseButton == "RightButton" then
			return
		end
		if mouseButton ~= "LeftButton" then
			return
		end
		button.isMouseDown = true
		button.dragged = false
		local scale = Minimap:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		button.dragStartX = cx / scale
		button.dragStartY = cy / scale
	end)

	button.frame:SetScript("OnMouseUp", function(_, mouseButton)
		if mouseButton == "RightButton" and not button.dragged then
			button:HandleClick("RightButton")
		end
		button.isMouseDown = false
	end)

	button.frame:SetScript("OnUpdate", function()
		if not button.isMouseDown then
			return
		end

		local scale = Minimap:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		local x = cx / scale
		local y = cy / scale

		local dx = x - button.dragStartX
		local dy = y - button.dragStartY

		if not button.dragged and (math.abs(dx) > MinimapButton.DRAG_THRESHOLD or math.abs(dy) > MinimapButton.DRAG_THRESHOLD) then
			button.dragged = true
		end

		if button.dragged then
			local mx, my = Minimap:GetCenter()
			if mx and my then
				settings.minimapAngle = math.deg(math.atan2(y - my, x - mx))
				button:UpdatePosition()
			end
		end
	end)

	button:UpdatePosition()

	if settings.minimapVisible ~= false then
		button.frame:Show()
	else
		button.frame:Hide()
	end

	return button
end

function MinimapButton:Show()
	if self.frame then
		self.frame:Show()
		TimeToLevel.Settings.minimapVisible = true
	end
end

function MinimapButton:Hide()
	if self.frame then
		self.frame:Hide()
		TimeToLevel.Settings.minimapVisible = false
	end
end

function MinimapButton:ToggleVisibility()
	if self.frame and self.frame:IsShown() then
		self:Hide()
	else
		self:Show()
	end
end
