TimeToLevel = TimeToLevel or {}

TimeToLevel.QuestXp = {}
local QuestXp = TimeToLevel.QuestXp

local function IsQuestComplete(isComplete)
	return isComplete == 1 or isComplete == true
end

function QuestXp:GetRewardXP(questIndex, questID)
	if type(GetQuestLogRewardXP) ~= "function" then
		return 0
	end

	if questID and questID > 0 then
		local ok, xp = pcall(GetQuestLogRewardXP, questID)
		if ok and type(xp) == "number" and xp > 0 then
			return xp
		end
	end

	if SelectQuestLogEntry and questIndex then
		SelectQuestLogEntry(questIndex)
		local ok, xp = pcall(GetQuestLogRewardXP)
		if ok and type(xp) == "number" and xp > 0 then
			return xp
		end
	end

	return 0
end

function QuestXp:Reset()
	self.entries = {}
	self.byQuestID = {}
	self.totalXp = 0
	self.loginScanned = false
end

function QuestXp:AddEntry(questID, title, xp)
	if not questID or questID <= 0 or self.byQuestID[questID] then
		return
	end

	xp = xp or 0
	if xp <= 0 then
		return
	end

	local entry = {
		questID = questID,
		title = title or ("Quest " .. questID),
		xp = xp,
	}
	self.byQuestID[questID] = entry
	self.entries[#self.entries + 1] = entry
	self.totalXp = (self.totalXp or 0) + xp
end

function QuestXp:RemoveEntry(questID)
	local entry = self.byQuestID[questID]
	if not entry then
		return
	end

	self.byQuestID[questID] = nil
	self.totalXp = math.max(0, (self.totalXp or 0) - entry.xp)

	for i = #self.entries, 1, -1 do
		if self.entries[i].questID == questID then
			table.remove(self.entries, i)
			break
		end
	end
end

function QuestXp:ScanQuestLog()
	self.entries = {}
	self.byQuestID = {}
	self.totalXp = 0

	local numEntries = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
	for i = 1, numEntries do
		local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
		if title and not isHeader and questID and questID > 0 and IsQuestComplete(isComplete) then
			local xp = self:GetRewardXP(i, questID)
			if xp > 0 then
				self:AddEntry(questID, title, xp)
			end
		end
	end
end

function QuestXp:TrackNewCompletions()
	local numEntries = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
	local added = false

	for i = 1, numEntries do
		local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
		if title and not isHeader and questID and questID > 0 and IsQuestComplete(isComplete) and not self.byQuestID[questID] then
			local xp = self:GetRewardXP(i, questID)
			if xp > 0 then
				self:AddEntry(questID, title, xp)
				added = true
			end
		end
	end

	return added
end

function QuestXp:PruneTurnedIn()
	local stillComplete = {}
	local numEntries = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0

	for i = 1, numEntries do
		local _, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
		if not isHeader and questID and questID > 0 and IsQuestComplete(isComplete) then
			stillComplete[questID] = true
		end
	end

	local removed = false
	for questID in pairs(self.byQuestID) do
		if not stillComplete[questID] then
			self:RemoveEntry(questID)
			removed = true
		end
	end

	return removed
end

function QuestXp:RefreshBar()
	if TimeToLevel.Tracker then
		TimeToLevel.Tracker:Refresh(false)
	end
end

function QuestXp:OnLoginScan()
	if self.loginScanned then
		return
	end

	self.loginScanned = true
	self:ScanQuestLog()
	self:RefreshBar()
end

function QuestXp:OnQuestLogUpdate()
	if not self.loginScanned then
		return
	end

	local changed = self:TrackNewCompletions()
	if self:PruneTurnedIn() then
		changed = true
	end

	if changed then
		self:RefreshBar()
	end
end

function QuestXp:OnQuestTurnedIn(_, questID)
	if questID and questID > 0 then
		if self.byQuestID[questID] then
			self:RemoveEntry(questID)
			self:RefreshBar()
		end
	end
end

function QuestXp:GetStats(xpRequired)
	local totalXp = self.totalXp or 0
	local projectedPercent = nil

	if xpRequired and xpRequired > 0 and totalXp > 0 then
		local xpInto = TimeToLevel.GetPlayerXP()
		projectedPercent = math.min(100, ((xpInto + totalXp) / xpRequired) * 100)
	end

	return {
		totalXp = totalXp,
		count = #self.entries,
		entries = self.entries,
		projectedPercent = projectedPercent,
	}
end

function QuestXp:Init()
	self:Reset()

	self.frame = CreateFrame("Frame")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:RegisterEvent("QUEST_LOG_UPDATE")
	self.frame:RegisterEvent("QUEST_TURNED_IN")

	self.frame:SetScript("OnEvent", function(_, event, ...)
		if event == "PLAYER_ENTERING_WORLD" then
			self:OnLoginScan()
		elseif event == "QUEST_LOG_UPDATE" then
			self:OnQuestLogUpdate()
		elseif event == "QUEST_TURNED_IN" then
			self:OnQuestTurnedIn(event, ...)
		end
	end)
end
