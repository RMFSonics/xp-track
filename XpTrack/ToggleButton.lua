TimeToLevel = TimeToLevel or {}

TimeToLevel.ToggleButton = {}
local ToggleButton = TimeToLevel.ToggleButton

ToggleButton.WIDTH = 44
ToggleButton.HEIGHT = 24
ToggleButton.DRAG_THRESHOLD = 4

function ToggleButton:Create(mainWindow)
	TimeToLevel.LoadSettings()
	local settings = TimeToLevel.Settings

	self.mainWindow = mainWindow
	self.frame = CreateFrame("Button", "XpTrackToggleButton", UIParent, "UIPanelButtonTemplate")
	self.frame:SetSize(ToggleButton.WIDTH, ToggleButton.HEIGHT)
	self.frame:SetText("XP")
	self.frame:SetFrameStrata("HIGH")
	self.frame:SetAlpha(settings.toggleOpacity or 0.85)

	local left = settings.toggleLeft
	local top = settings.toggleTop
	if left == nil then
		left = math.max(20, (UIParent:GetWidth() or 1024) - 60)
	end
	self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, -(top or 310))

	if settings.toggleVisible ~= false then
		self.frame:Show()
	else
		self.frame:Hide()
	end

	self.dragging = false
	self.dragged = false
	self.dragStartX = 0
	self.dragStartY = 0

	self.frame:SetScript("OnMouseDown", function(_, button)
		if button ~= "LeftButton" then
			return
		end
		self.dragging = true
		self.dragged = false
		local scale = self.frame:GetEffectiveScale()
		local x, y = GetCursorPosition()
		self.dragStartX = x / scale
		self.dragStartY = y / scale
		local _, _, _, px, py = self.frame:GetPoint()
		self.frameStartX = px
		self.frameStartY = py
	end)

	self.frame:SetScript("OnMouseUp", function(_, button)
		if button ~= "LeftButton" then
			return
		end

		if self.dragging and not self.dragged then
			if self.mainWindow then
				self.mainWindow:Toggle()
			end
		end

		self.dragging = false
	end)

	self.frame:SetScript("OnUpdate", nil)

	self.dragFrame = CreateFrame("Frame")
	self.dragFrame:SetScript("OnUpdate", function()
		if not self.dragging then
			return
		end

		local scale = self.frame:GetEffectiveScale()
		local x, y = GetCursorPosition()
		x = x / scale
		y = y / scale

		local dx = x - self.dragStartX
		local dy = y - self.dragStartY

		if not self.dragged and (math.abs(dx) > ToggleButton.DRAG_THRESHOLD or math.abs(dy) > ToggleButton.DRAG_THRESHOLD) then
			self.dragged = true
		end

		if self.dragged and self.frameStartX and self.frameStartY then
			self.frame:ClearAllPoints()
			self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.frameStartX + dx, self.frameStartY + dy)
			TimeToLevel.Settings.toggleLeft = self.frameStartX + dx
			TimeToLevel.Settings.toggleTop = -(self.frameStartY + dy)
		end
	end)

	self:UpdatePosition()
	return self
end

function ToggleButton:UpdatePosition()
	local settings = TimeToLevel.Settings
	local left = settings.toggleLeft
	local top = settings.toggleTop or 310
	if left == nil then
		left = math.max(20, (UIParent:GetWidth() or 1024) - 60)
	end
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, -top)
end

function ToggleButton:Show()
	self.frame:Show()
	TimeToLevel.Settings.toggleVisible = true
end

function ToggleButton:Hide()
	self.frame:Hide()
	TimeToLevel.Settings.toggleVisible = false
end

function ToggleButton:ToggleVisibility()
	if self.frame:IsShown() then
		self:Hide()
	else
		self:Show()
	end
end
