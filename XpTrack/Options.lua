TimeToLevel = TimeToLevel or {}

TimeToLevel.Options = {}
local Options = TimeToLevel.Options
local DISPLAY = TimeToLevel.DISPLAY_NAME or "Xp Track"
local LOGO = TimeToLevel.LOGO_TEXTURE or "Interface\\AddOns\\XpTrack\\Textures\\Logo.png"

local PANEL_WIDTH = 360
local PANEL_HEIGHT = 340

local function SafeCreateFrame(frameType, name, parent, template)
	if template then
		local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
		if ok and frame then
			return frame
		end
	end
	return CreateFrame(frameType, name, parent)
end

function Options:Apply()
	if TimeToLevel.window then
		if TimeToLevel.window.frame then
			TimeToLevel.window.frame:SetHeight(TimeToLevel.window:GetFrameHeight())
		end
		if TimeToLevel.window.Layout then
			TimeToLevel.window:Layout()
		elseif TimeToLevel.window.LayoutChrome then
			TimeToLevel.window:LayoutChrome()
		end
	end
	TimeToLevel.SaveSettings()
end

function Options:RefreshScale()
	if not self.scaleSlider then
		return
	end
	local percent = math.floor((TimeToLevel.Settings.barScale or 1) * 100 + 0.5)
	self.scaleSlider:SetValue(percent)
	if self.scaleLabel then
		self.scaleLabel:SetText(string.format("Bar scale: %d%%", percent))
	end
end

function Options:RefreshOpacity()
	if not self.opacitySlider then
		return
	end
	local percent = math.floor((TimeToLevel.Settings.opacity or 1) * 100 + 0.5)
	self.opacitySlider:SetValue(percent)
	if self.opacityLabel then
		self.opacityLabel:SetText(string.format("Bar opacity: %d%%", percent))
	end
end

function Options:Refresh()
	if not self.frame then
		return
	end

	local settings = TimeToLevel.Settings
	if self.gryphonCheck then
		self.gryphonCheck:SetChecked(settings.gryphonCaps ~= false)
	end
	if self.borderCheck then
		self.borderCheck:SetChecked(settings.blizzardBorder ~= false)
	end
	if self.minimapCheck then
		self.minimapCheck:SetChecked(settings.minimapVisible ~= false)
	end
	self:RefreshOpacity()
	self:RefreshScale()
end

function Options:Toggle()
	if self.frame and self.frame:IsShown() then
		self:Hide()
	else
		self:Show()
	end
end

function Options:Show()
	TimeToLevel.LoadSettings()

	local ok, err = pcall(function()
		if not self.frame then
			self:Create()
		end
		if not self.frame then
			error("options frame missing after create")
		end
		self:Refresh()
		self.frame:Show()
	end)

	if not ok then
		print("|cffff0000" .. DISPLAY .. " options failed:|r " .. tostring(err))
	end
end

function Options:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

local function CreateCheckRow(panel, y, labelText, onClick)
	local check = SafeCreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	check:SetSize(24, 24)
	check:SetPoint("TOPLEFT", 20, y)
	check:SetScript("OnClick", onClick)

	local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	label:SetPoint("LEFT", check, "RIGHT", 6, 0)
	label:SetText(labelText)
	label:SetJustifyH("LEFT")

	return check
end

function Options:CreateOpacitySlider(panel)
	self.opacityLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.opacityLabel:SetPoint("TOPLEFT", 24, -52)
	self.opacityLabel:SetText("Bar opacity: 100%")

	local slider = SafeCreateFrame("Slider", "XpTrackOpacitySlider", panel, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", self.opacityLabel, "BOTTOMLEFT", 4, -12)
	slider:SetWidth(220)
	slider:SetHeight(20)
	slider:SetMinMaxValues(30, 100)
	slider:SetValueStep(5)
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end

	if not slider:GetThumbTexture() then
		local thumb = slider:CreateTexture(nil, "OVERLAY")
		thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		thumb:SetSize(16, 16)
		slider:SetThumbTexture(thumb)
	end

	local options = self
	slider:SetScript("OnValueChanged", function(_, value)
		value = math.floor((value or 100) + 0.5)
		if options.opacityLabel then
			options.opacityLabel:SetText(string.format("Bar opacity: %d%%", value))
		end
		if TimeToLevel.window then
			TimeToLevel.window:SetAlpha(value)
		else
			TimeToLevel.Settings.opacity = value / 100
			TimeToLevel.SaveSettings()
		end
	end)

	self.opacitySlider = slider
end

function Options:CreateScaleSlider(panel)
	self.scaleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.scaleLabel:SetPoint("TOPLEFT", 24, -98)
	self.scaleLabel:SetText("Bar scale: 100%")

	local slider = SafeCreateFrame("Slider", "XpTrackScaleSlider", panel, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", self.scaleLabel, "BOTTOMLEFT", 4, -12)
	slider:SetWidth(220)
	slider:SetHeight(20)
	slider:SetMinMaxValues(50, 150)
	slider:SetValueStep(5)
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end

	if not slider:GetThumbTexture() then
		local thumb = slider:CreateTexture(nil, "OVERLAY")
		thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		thumb:SetSize(16, 16)
		slider:SetThumbTexture(thumb)
	end

	local options = self
	slider:SetScript("OnValueChanged", function(_, value)
		value = math.floor((value or 100) + 0.5)
		if options.scaleLabel then
			options.scaleLabel:SetText(string.format("Bar scale: %d%%", value))
		end
		if TimeToLevel.window then
			TimeToLevel.window:SetBarScale(value)
		else
			TimeToLevel.Settings.barScale = value / 100
			TimeToLevel.SaveSettings()
		end
	end)

	self.scaleSlider = slider
end

function Options:Create()
	if self.frame then
		return self.frame
	end

	local panel = SafeCreateFrame("Frame", "XpTrackOptions", UIParent, "BackdropTemplate")
	panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
	panel:SetPoint("CENTER")
	panel:SetFrameStrata("FULLSCREEN_DIALOG")
	panel:SetFrameLevel(200)
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:SetClampedToScreen(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
	panel:Hide()

	if panel.SetBackdrop then
		panel:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		})
		panel:SetBackdropColor(0, 0, 0, 0.92)
	else
		local bg = panel:CreateTexture(nil, "BACKGROUND")
		bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
		bg:SetAllPoints()
	end

	local logo = panel:CreateTexture(nil, "ARTWORK")
	logo:SetSize(36, 36)
	logo:SetTexture(LOGO)
	logo:SetPoint("TOP", 0, -10)

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", logo, "BOTTOM", 0, -6)
	title:SetText(DISPLAY)

	local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
	subtitle:SetText("Options")

	local options = self
	self:CreateOpacitySlider(panel)
	self:CreateScaleSlider(panel)

	self.gryphonCheck = CreateCheckRow(panel, -164, "Show gryphon end caps", function(check)
		TimeToLevel.Settings.gryphonCaps = check:GetChecked() and true or false
		options:Apply()
	end)

	self.borderCheck = CreateCheckRow(panel, -196, "Show Blizzard XP bar border", function(check)
		TimeToLevel.Settings.blizzardBorder = check:GetChecked() and true or false
		options:Apply()
	end)

	self.minimapCheck = CreateCheckRow(panel, -228, "Show " .. DISPLAY .. " minimap button", function(check)
		local enabled = check:GetChecked() and true or false
		TimeToLevel.Settings.minimapVisible = enabled
		TimeToLevel.EnsureMinimapButton()
		if enabled then
			if TimeToLevel.minimap then
				TimeToLevel.minimap:Show()
			end
		elseif TimeToLevel.minimap then
			TimeToLevel.minimap:Hide()
		end
		options:Apply()
	end)

	local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("BOTTOM", 0, 44)
	hint:SetText("Esc > Edit Mode: move " .. DISPLAY)

	local close = SafeCreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	close:SetSize(100, 22)
	close:SetPoint("BOTTOM", 0, 16)
	close:SetText(CLOSE or "Close")
	close:SetScript("OnClick", function()
		panel:Hide()
	end)

	panel:SetScript("OnShow", function()
		options:Refresh()
	end)

	self.frame = panel
	self:TryRegisterInterfaceOptions()
	self:Refresh()

	return panel
end

function Options:ResetDefaults()
	TimeToLevel.Settings.gryphonCaps = true
	TimeToLevel.Settings.blizzardBorder = true
	TimeToLevel.Settings.minimapVisible = true
	TimeToLevel.Settings.opacity = 1
	TimeToLevel.Settings.barScale = 1
	if TimeToLevel.window then
		TimeToLevel.window:SetAlpha(100)
		TimeToLevel.window:SetBarScale(100)
	end
	self:Refresh()
	self:Apply()
	TimeToLevel.EnsureMinimapButton()
	if TimeToLevel.minimap then
		TimeToLevel.minimap:Show()
	end
end

function Options:TryRegisterInterfaceOptions()
	if self.registered then
		return
	end

	pcall(function()
		if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
			local launcher = CreateFrame("Frame", "XpTrackOptionsLauncher")
			launcher.name = DISPLAY
			launcher.icon = LOGO
			launcher.okay = function() end
			launcher.cancel = function() end
			launcher.default = function()
				Options:ResetDefaults()
			end
			launcher:SetScript("OnShow", function()
				Options:Show()
			end)
			local category = Settings.RegisterCanvasLayoutCategory(launcher, launcher.name)
			if Settings.AssignLayoutCategoryToAddon then
				Settings.AssignLayoutCategoryToAddon(category, "XpTrack")
			end
			Settings.RegisterAddOnCategory(category)
			self.settingsCategory = category
			self.registered = true
		elseif InterfaceOptions_AddCategory then
			local launcher = CreateFrame("Frame", "XpTrackOptionsLauncher")
			launcher.name = DISPLAY
			launcher.icon = LOGO
			launcher.okay = function() end
			launcher.cancel = function() end
			launcher.default = function()
				Options:ResetDefaults()
			end
			launcher:SetScript("OnShow", function()
				Options:Show()
			end)
			InterfaceOptions_AddCategory(launcher)
			self.registered = true
		end
	end)
end

function Options:Init()
	TimeToLevel.LoadSettings()
	self:TryRegisterInterfaceOptions()
end
