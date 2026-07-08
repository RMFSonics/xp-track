TimeToLevel = TimeToLevel or {}

local MAX_LEVEL = 70

function TimeToLevel.GetMaxLevel()
	return MAX_LEVEL
end

function TimeToLevel.FormatNumber(value)
	value = math.floor(value or 0)
	local formatted = tostring(value)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

function TimeToLevel.FormatCompactNumber(value)
	value = math.floor(value or 0)
	local abs = math.abs(value)
	if abs >= 1000000 then
		return string.format("%.1fm", value / 1000000)
	end
	if abs >= 10000 then
		return string.format("%.0fk", value / 1000)
	end
	if abs >= 1000 then
		return string.format("%.1fk", value / 1000)
	end
	return tostring(value)
end

function TimeToLevel.FormatShortDuration(seconds)
	if seconds == nil then
		return "--"
	end

	seconds = math.max(0, math.floor(seconds))
	if seconds == 0 then
		return "0m"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if hours > 0 then
		return string.format("%dh%dm", hours, minutes)
	end
	if minutes > 0 then
		return string.format("%dm", minutes)
	end
	return string.format("%ds", seconds % 60)
end

function TimeToLevel.FormatDuration(seconds)
	if seconds == nil then
		return "--"
	end

	seconds = math.max(0, math.floor(seconds))
	if seconds == 0 then
		return "0m"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	end
	if minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	end
	return string.format("%ds", secs)
end

function TimeToLevel.GetPlayerLevel()
	return UnitLevel("player") or 1
end

function TimeToLevel.GetPlayerXP()
	return UnitXP("player") or 0
end

function TimeToLevel.GetPlayerXPMax()
	return UnitXPMax("player") or 0
end

function TimeToLevel.IsMaxLevel()
	return TimeToLevel.GetPlayerLevel() >= MAX_LEVEL
end

-- Negative values move the bar down toward the screen bottom.
TimeToLevel.BAR_ANCHOR_Y_NUDGE = -20

function TimeToLevel.GetDefaultBarAnchor(extraOffset)
	local y = (extraOffset or 0) + (TimeToLevel.BAR_ANCHOR_Y_NUDGE or 0)

	if MainMenuBar and MainMenuBar.IsShown and MainMenuBar:IsShown() then
		return {
			point = "BOTTOM",
			relativeTo = MainMenuBar,
			relPoint = "BOTTOM",
			x = 0,
			y = y,
		}
	end

	if MainActionBar and MainActionBar.IsShown and MainActionBar:IsShown() then
		return {
			point = "BOTTOM",
			relativeTo = MainActionBar,
			relPoint = "TOP",
			x = 0,
			y = y,
		}
	end

	return {
		point = "BOTTOM",
		relativeTo = UIParent,
		relPoint = "BOTTOM",
		x = 0,
		y = y,
	}
end

function TimeToLevel.HasRestedBonus()
	if not GetXPExhaustion then
		return false
	end
	local exhaustion = GetXPExhaustion()
	return exhaustion ~= nil and exhaustion ~= 0
end

function TimeToLevel.GetRestedBarPercent()
	if not TimeToLevel.HasRestedBonus() then
		return nil
	end

	local xpRequired = TimeToLevel.GetPlayerXPMax()
	if xpRequired <= 0 then
		return nil
	end

	local xp = TimeToLevel.GetPlayerXP()
	local rested = math.abs(GetXPExhaustion())
	return math.min(100, ((xp + rested) / xpRequired) * 100)
end

function TimeToLevel.GetRestedXpAmount()
	if not GetXPExhaustion then
		return 0
	end
	local exhaustion = GetXPExhaustion()
	if exhaustion == nil or exhaustion == 0 then
		return 0
	end
	return math.abs(exhaustion)
end

function TimeToLevel.GetBlizzardXpTexture()
	if MainMenuExpBar and MainMenuExpBar.GetStatusBarTexture then
		local tex = MainMenuExpBar:GetStatusBarTexture()
		if tex and tex.GetTexture then
			local path = tex:GetTexture()
			if path then
				return path
			end
		end
	end
	return "Interface\\TargetingFrame\\UI-StatusBar"
end

local XP_BAR_FILE = "Interface\\MainMenuBar\\UI-XP-Bar"
local GRYPHON_FILE = "Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf"

local XP_BORDER_FALLBACK = {
	{ width = 14, tex = XP_BAR_FILE, coord = { 0.00390625, 0.11328125, 0.015625, 0.984375 } },
	{ width = 0, tex = XP_BAR_FILE, coord = { 0.11328125, 0.59375, 0.015625, 0.984375 }, stretch = true },
	{ width = 0, tex = XP_BAR_FILE, coord = { 0.59375, 0.88671875, 0.015625, 0.984375 }, stretch = true },
	{ width = 14, tex = XP_BAR_FILE, coord = { 0.88671875, 0.99609375, 0.015625, 0.984375 } },
}

function TimeToLevel.CaptureXpBorderSpecs(force)
	if TimeToLevel.CachedXpBorderSpecs and not force then
		return
	end

	local specs = {}
	for index = 1, 4 do
		local blizz = _G["MainMenuXPBarTexture" .. (index - 1)]
		if blizz and blizz.GetTexture then
			local path = blizz:GetTexture()
			if path then
				specs[index] = {
					width = blizz:GetWidth() or XP_BORDER_FALLBACK[index].width,
					tex = path,
					coord = { blizz:GetTexCoord() },
					stretch = XP_BORDER_FALLBACK[index].stretch == true,
				}
			end
		end

		if not specs[index] and StatusTrackingBarManager and StatusTrackingBarManager.bars then
			for _, bar in ipairs(StatusTrackingBarManager.bars) do
				local sb = bar and bar.StatusBar
				local part = sb and sb["XPBarTexture" .. (index - 1)]
				if part and part.GetTexture then
					local path = part:GetTexture()
					if path then
						specs[index] = {
							width = part:GetWidth() or XP_BORDER_FALLBACK[index].width,
							tex = path,
							coord = { part:GetTexCoord() },
							stretch = XP_BORDER_FALLBACK[index].stretch == true,
						}
						break
					end
				end
			end
		end

		if not specs[index] then
			specs[index] = XP_BORDER_FALLBACK[index]
		end
	end
	TimeToLevel.CachedXpBorderSpecs = specs
end

function TimeToLevel.GetXpBorderPartSpec(index)
	if TimeToLevel.CachedXpBorderSpecs and TimeToLevel.CachedXpBorderSpecs[index] then
		return TimeToLevel.CachedXpBorderSpecs[index]
	end

	local blizz = _G["MainMenuXPBarTexture" .. (index - 1)]
	if blizz and blizz.GetTexture then
		local path = blizz:GetTexture()
		if path then
			return {
				width = blizz:GetWidth() or XP_BORDER_FALLBACK[index].width,
				tex = path,
				coord = { blizz:GetTexCoord() },
				stretch = XP_BORDER_FALLBACK[index].stretch == true,
			}
		end
	end

	if StatusTrackingBarManager then
		if StatusTrackingBarManager.bars then
			for _, bar in ipairs(StatusTrackingBarManager.bars) do
				local sb = bar and bar.StatusBar
				local part = sb and sb["XPBarTexture" .. (index - 1)]
				if part and part.GetTexture then
					local path = part:GetTexture()
					if path then
						return {
							width = part:GetWidth() or XP_BORDER_FALLBACK[index].width,
							tex = path,
							coord = { part:GetTexCoord() },
							stretch = XP_BORDER_FALLBACK[index].stretch == true,
						}
					end
				end
			end
		end

		for _, childName in ipairs({ "SingleBarLarge", "SingleBarSmall" }) do
			local bar = StatusTrackingBarManager[childName]
			if bar then
				local part = bar["XPBarTexture" .. (index - 1)]
					or bar["Border" .. (index - 1)]
				if part and part.GetTexture then
					local path = part:GetTexture()
					if path then
						return {
							width = part:GetWidth() or XP_BORDER_FALLBACK[index].width,
							tex = path,
							coord = { part:GetTexCoord() },
							stretch = XP_BORDER_FALLBACK[index].stretch == true,
						}
					end
				end
			end
		end
	end

	return XP_BORDER_FALLBACK[index]
end

function TimeToLevel.GetGryphonTexture(side)
	if MainMenuBarArtFrame then
		local cap = MainMenuBarArtFrame.LeftEndCap
		if side == "right" and MainMenuBarArtFrame.RightEndCap then
			cap = MainMenuBarArtFrame.RightEndCap
		end
		if cap and cap.GetTexture then
			local path = cap:GetTexture()
			if path then
				return path
			end
		end
	end

	if UnitFactionGroup and UnitFactionGroup("player") == "Horde" then
		return "Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Human"
	end
	return GRYPHON_FILE
end
