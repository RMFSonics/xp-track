TimeToLevel = TimeToLevel or {}

TimeToLevel.Tracker = {}
local Tracker = TimeToLevel.Tracker

Tracker.RATE_WINDOW_SECONDS = 300
Tracker.MIN_RATE_SECONDS = 30
Tracker.DISPLAY_TICK_SECONDS = 5

function Tracker:ResetXpSamples()
	self.xpSamples = {}
end

function Tracker:RecordXpGain(amount)
	if not amount or amount <= 0 then
		return
	end

	self.xpSamples = self.xpSamples or {}
	self.xpSamples[#self.xpSamples + 1] = {
		t = GetTime(),
		xp = amount,
	}

	local cutoff = GetTime() - Tracker.RATE_WINDOW_SECONDS
	local write = 1
	for i = 1, #self.xpSamples do
		local sample = self.xpSamples[i]
		if sample.t >= cutoff then
			self.xpSamples[write] = sample
			write = write + 1
		end
	end
	for i = write, #self.xpSamples do
		self.xpSamples[i] = nil
	end
end

function Tracker:GetRecentXpRate()
	local samples = self.xpSamples
	if not samples or #samples == 0 then
		return nil
	end

	local now = GetTime()
	local cutoff = now - Tracker.RATE_WINDOW_SECONDS
	local totalXp = 0
	local oldest = now

	for i = 1, #samples do
		local sample = samples[i]
		if sample.t >= cutoff then
			totalXp = totalXp + sample.xp
			if sample.t < oldest then
				oldest = sample.t
			end
		end
	end

	if totalXp <= 0 then
		return nil
	end

	local elapsed = math.max(Tracker.MIN_RATE_SECONDS, now - oldest)
	return totalXp / elapsed
end

function Tracker:Init(window)
	self.window = window
	self.level = TimeToLevel.GetPlayerLevel()
	self.lastXp = TimeToLevel.GetPlayerXP()
	self.sessionXpEarned = 0
	self.levelStartTime = GetTime()
	self.hasXpSample = false

	self:ResetXpSamples()

	TimeToLevel.XpGain:Init()
	TimeToLevel.QuestXp:Init()

	self:LoadState()
	self:RegisterEvents()
	self:Refresh(true)
end

function Tracker:RegisterEvents()
	self.frame = CreateFrame("Frame")
	self.frame:RegisterEvent("PLAYER_XP_UPDATE")
	self.frame:RegisterEvent("PLAYER_LEVEL_UP")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

	self.frame:SetScript("OnEvent", function(_, event, ...)
		if event == "PLAYER_XP_UPDATE" then
			self:OnXPUpdate(false)
		elseif event == "PLAYER_LEVEL_UP" then
			self:OnLevelUp(...)
		elseif event == "PLAYER_ENTERING_WORLD" then
			self:OnEnterWorld()
		end
	end)
end

function Tracker:LoadState()
	local saved = TimeToLevel.LoadCharState()
	local level = TimeToLevel.GetPlayerLevel()

	if saved.level == level then
		self.level = level
		self.sessionXpEarned = saved.sessionXpEarned or 0
		self.levelStartTime = saved.levelStartTime or GetTime()
		self.lastXp = TimeToLevel.GetPlayerXP()
		self.hasXpSample = (self.sessionXpEarned or 0) > 0
	else
		self:ResetLevelSession(level, true)
	end
end

function Tracker:SaveState()
	local saved = TimeToLevel.LoadCharState()
	saved.level = self.level
	saved.sessionXpEarned = self.sessionXpEarned
	saved.levelStartTime = self.levelStartTime
	TimeToLevel.SaveCharState()
end

function Tracker:ResetLevelSession(level, skipSave)
	self.level = level or TimeToLevel.GetPlayerLevel()
	self.lastXp = TimeToLevel.GetPlayerXP()
	self.sessionXpEarned = 0
	self.levelStartTime = GetTime()
	self.hasXpSample = false
	self:ResetXpSamples()
	if not skipSave then
		self:SaveState()
	end
	self:Refresh(true)
end

function Tracker:OnEnterWorld()
	local level = TimeToLevel.GetPlayerLevel()
	if level ~= self.level then
		self:ResetLevelSession(level, true)
	else
		self.lastXp = TimeToLevel.GetPlayerXP()
	end
	self:Refresh(true)
end

function Tracker:OnLevelUp(newLevel)
	self:ResetLevelSession(newLevel or TimeToLevel.GetPlayerLevel())
	if self.window then
		self.window:FlashLevelUp()
	end
end

function Tracker:OnXPUpdate(forceRefresh)
	if TimeToLevel.IsMaxLevel() then
		self:Refresh(forceRefresh)
		return
	end

	local level = TimeToLevel.GetPlayerLevel()
	local xp = TimeToLevel.GetPlayerXP()

	if level ~= self.level then
		self:ResetLevelSession(level, true)
		self.lastXp = xp
		self:Refresh(true)
		return
	end

	if self.lastXp ~= nil and xp > self.lastXp then
		local gained = xp - self.lastXp
		local xpRequired = TimeToLevel.GetPlayerXPMax()
		TimeToLevel.XpGain:OnXpApplied(self.lastXp, xp, xpRequired)
		self.sessionXpEarned = (self.sessionXpEarned or 0) + gained
		self:RecordXpGain(gained)
		self.hasXpSample = true
		self:SaveState()
	end

	self.lastXp = xp
	self:Refresh(forceRefresh)
end

function Tracker:GetStats()
	if TimeToLevel.IsMaxLevel() then
		return {
			level = TimeToLevel.GetPlayerLevel(),
			maxLevel = true,
			xpIntoLevel = 0,
			xpRequired = 0,
			xpRemaining = 0,
			percent = 100,
			elapsed = GetTime() - (self.levelStartTime or GetTime()),
			xpPerMinute = 0,
			xpPerHour = 0,
			etaSeconds = nil,
			sessionXpEarned = self.sessionXpEarned or 0,
		}
	end

	local xpIntoLevel = TimeToLevel.GetPlayerXP()
	local xpRequired = TimeToLevel.GetPlayerXPMax()
	local xpRemaining = math.max(0, xpRequired - xpIntoLevel)
	local elapsed = math.max(0, GetTime() - (self.levelStartTime or GetTime()))
	local percent = 0

	if xpRequired > 0 then
		percent = (xpIntoLevel / xpRequired) * 100
	end

	local xpPerSecond = 0
	local xpPerMinute = 0
	local xpPerHour = 0
	local etaSeconds = nil

	local recentXpPerSecond = self:GetRecentXpRate()
	if recentXpPerSecond and recentXpPerSecond > 0 then
		xpPerSecond = recentXpPerSecond
		xpPerMinute = xpPerSecond * 60
		xpPerHour = xpPerSecond * 3600
	elseif self.hasXpSample and elapsed >= Tracker.MIN_RATE_SECONDS and (self.sessionXpEarned or 0) > 0 then
		xpPerSecond = self.sessionXpEarned / elapsed
		xpPerMinute = xpPerSecond * 60
		xpPerHour = xpPerSecond * 3600
	end

	if xpPerSecond > 0 then
		if xpRemaining > 0 then
			etaSeconds = xpRemaining / xpPerSecond
		elseif xpRemaining == 0 then
			etaSeconds = 0
		end
	end

	local questStats = TimeToLevel.QuestXp:GetStats(xpRequired)
	local xpRemainingAfterQuests = xpRemaining
	if questStats.totalXp and questStats.totalXp > 0 then
		xpRemainingAfterQuests = math.max(0, xpRequired - xpIntoLevel - questStats.totalXp)
	end

	return {
		level = self.level,
		maxLevel = false,
		xpIntoLevel = xpIntoLevel,
		xpRequired = xpRequired,
		xpRemaining = xpRemaining,
		xpRemainingAfterQuests = xpRemainingAfterQuests,
		percent = percent,
		elapsed = elapsed,
		xpPerMinute = xpPerMinute,
		xpPerHour = xpPerHour,
		etaSeconds = etaSeconds,
		sessionXpEarned = self.sessionXpEarned or 0,
		barMode = TimeToLevel.XpGain:GetBarMode(),
		flash = TimeToLevel.XpGain:GetFlashState(),
		restedPercent = TimeToLevel.GetRestedBarPercent(),
		restedXp = TimeToLevel.GetRestedXpAmount(),
		questXpTotal = questStats.totalXp,
		questXpCount = questStats.count,
		questXpEntries = questStats.entries,
		questProjectedPercent = questStats.projectedPercent,
	}
end

function Tracker:Refresh(force)
	if self.window then
		self.window:UpdateDisplay(self:GetStats(), force)
	end
end

function Tracker:PrintStats()
	local stats = self:GetStats()
	if stats.maxLevel then
		print("|cff00ff00TimeToLevel|r: Max level (" .. stats.level .. ").")
		return
	end

	print(string.format(
		"|cff00ff00TimeToLevel|r L%d: %s / %s (%.1f%%) | %s XP/min | ETA %s",
		stats.level,
		TimeToLevel.FormatNumber(stats.xpIntoLevel),
		TimeToLevel.FormatNumber(stats.xpRequired),
		stats.percent,
		TimeToLevel.FormatNumber(stats.xpPerMinute),
		TimeToLevel.FormatDuration(stats.etaSeconds)
	))
	if stats.questXpTotal and stats.questXpTotal > 0 then
		print(string.format(
			"  |cffffd200+%s XP ready from %d quest(s)|r (hover bar for list)",
			TimeToLevel.FormatNumber(stats.questXpTotal),
			stats.questXpCount or 0
		))
	end
end

function Tracker:StartTicker()
	if self.tickerFrame then
		return
	end

	self.tickerFrame = CreateFrame("Frame")
	self.tickerFrame.elapsed = 0
	self.tickerFrame:SetScript("OnUpdate", function(frame, elapsed)
		frame.elapsed = frame.elapsed + elapsed
		if frame.elapsed >= Tracker.DISPLAY_TICK_SECONDS then
			frame.elapsed = 0
			self:Refresh(false)
		end
	end)
end
