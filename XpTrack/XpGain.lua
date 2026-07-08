TimeToLevel = TimeToLevel or {}

TimeToLevel.XpGain = {}
local XpGain = TimeToLevel.XpGain

XpGain.MODE_NORMAL = "normal"
XpGain.MODE_RESTED = "rested"
XpGain.MODE_QUEST = "quest"

XpGain.FLASH_DURATION = 2.5

local QUEST_PATTERNS = {
	"are awarded (%d+) experience points",
	"awarded (%d+) experience points",
	"are awarded (%d+) experience",
	"awarded (%d+) experience",
	"quest.*(%d+) experience",
}

local RESTED_PATTERNS = {
	"rested",
	"bonus",
}

function XpGain:Init()
	self.pendingMode = nil
	self.pendingAmount = nil
	self.flashMode = nil
	self.flashUntil = 0
	self.gainStartPct = nil
	self.gainEndPct = nil

	if self.frame then
		return
	end

	self.frame = CreateFrame("Frame")
	self.frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
	self.frame:RegisterEvent("CHAT_MSG_SYSTEM")
	self.frame:SetScript("OnEvent", function(_, event, msg)
		self:OnChatMessage(msg, event)
	end)
end

function XpGain:OnChatMessage(msg, event)
	if not msg then
		return
	end

	local lower = string.lower(msg)

	if event == "CHAT_MSG_SYSTEM" then
		for _, pattern in ipairs(QUEST_PATTERNS) do
			local amount = string.match(lower, pattern)
			if amount then
				self.pendingMode = XpGain.MODE_QUEST
				self.pendingAmount = tonumber(amount)
				return
			end
		end
	end

	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
		if self.pendingMode == XpGain.MODE_QUEST then
			return
		end

		local amount = string.match(lower, "gain (%d+) experience points")
			or string.match(lower, "gain (%d+) experience")
		if amount then
			self.pendingAmount = tonumber(amount)
			self.pendingMode = XpGain.MODE_NORMAL

			for _, pattern in ipairs(RESTED_PATTERNS) do
				if string.find(lower, pattern, 1, true) then
					self.pendingMode = XpGain.MODE_RESTED
					break
				end
			end
		end
	end
end

function XpGain:OnXpApplied(oldXp, newXp, xpRequired)
	if xpRequired <= 0 or not newXp or not oldXp or newXp <= oldXp then
		return
	end

	local mode = self.pendingMode or XpGain.MODE_NORMAL

	if mode == XpGain.MODE_NORMAL and TimeToLevel.HasRestedBonus() then
		local exhaustion = GetXPExhaustion and GetXPExhaustion()
		if exhaustion and exhaustion ~= 0 then
			mode = XpGain.MODE_RESTED
		end
	end

	self.flashMode = mode
	self.flashUntil = GetTime() + XpGain.FLASH_DURATION
	self.gainStartPct = (oldXp / xpRequired) * 100
	self.gainEndPct = (newXp / xpRequired) * 100

	self.pendingMode = nil
	self.pendingAmount = nil
end

function XpGain:GetFlashState()
	if not self.flashUntil or GetTime() > self.flashUntil then
		return nil
	end
	return {
		mode = self.flashMode or XpGain.MODE_NORMAL,
		startPct = self.gainStartPct or 0,
		endPct = self.gainEndPct or 0,
		remaining = self.flashUntil - GetTime(),
	}
end

function XpGain:GetBarMode()
	local flash = self:GetFlashState()
	if flash then
		return flash.mode
	end

	if TimeToLevel.HasRestedBonus() then
		return XpGain.MODE_RESTED
	end

	return XpGain.MODE_NORMAL
end
