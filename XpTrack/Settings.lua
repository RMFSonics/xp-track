TimeToLevel = TimeToLevel or {}

TimeToLevel.DISPLAY_NAME = "Xp Track"
TimeToLevel.SLASH_CMD = "/xptrack"
TimeToLevel.LOGO_TEXTURE = "Interface\\AddOns\\XpTrack\\Textures\\Logo.png"
TimeToLevel.MINIMAP_ICON_TEXTURE = "Interface\\AddOns\\XpTrack\\Textures\\Logo-32.png"

TimeToLevelDB = TimeToLevelDB or {}
TimeToLevelCharDB = TimeToLevelCharDB or {}

local DEFAULTS = {
	width = 520,
	height = 20,
	anchor = "bottom",
	bottomOffset = 0,
	left = nil,
	top = nil,
	anchorPoint = nil,
	anchorRelPoint = nil,
	anchorRelativeTo = nil,
	anchorX = nil,
	anchorY = nil,
	opacity = 1,
	barScale = 1,
	visible = true,
	hideBlizzardBar = true,
	blizzardBorder = true,
	gryphonCaps = true,
	migratedBarV2 = false,
	minimapVisible = true,
	minimapAngle = 220,
	migratedEditModeV1 = false,
}

function TimeToLevel.LoadSettings()
	for key, value in pairs(DEFAULTS) do
		if TimeToLevelDB[key] == nil then
			TimeToLevelDB[key] = value
		end
	end
	TimeToLevel.Settings = TimeToLevelDB
end

function TimeToLevel.SaveSettings()
	if TimeToLevelDB then
		TimeToLevelDB._lastSave = time and time() or nil
	end
end

function TimeToLevel.GetCharKey()
	local name = UnitName("player")
	local realm = GetRealmName()
	if name and realm then
		return name .. "-" .. realm
	end
	return name or "Unknown"
end

function TimeToLevel.LoadCharState()
	local key = TimeToLevel.GetCharKey()
	TimeToLevel.Char = TimeToLevelCharDB[key] or {}
	TimeToLevelCharDB[key] = TimeToLevel.Char
	return TimeToLevel.Char
end

function TimeToLevel.SaveCharState()
end
