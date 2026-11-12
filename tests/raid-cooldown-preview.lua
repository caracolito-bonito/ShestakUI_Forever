-- Run from the repository root: luajit tests/raid-cooldown-preview.lua
local module = "ShestakUI/Modules/Cooldowns/RaidCD.lua"
local frames = {}
local methods = {}
local function object() return setmetatable({scripts = {}}, {__index = methods}) end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function methods:CreateBackdrop() self.backdrop = object() end
function methods:SetNormalTexture() self.normal = object() end
function methods:GetNormalTexture() return self.normal end
function methods:SetText(value) self.text = value end
function methods:Show() self.hidden = false end
function methods:Hide() self.hidden = true end
for _, name in ipairs({"SetPoint", "ClearAllPoints", "SetFrameStrata", "SetStatusBarTexture", "SetMinMaxValues", "SetAllPoints", "SetTexture", "SetFont", "SetShadowOffset", "SetJustifyH", "SetTexCoord", "SetStatusBarColor", "SetVertexColor", "EnableMouse", "RegisterEvent", "UnregisterEvent"}) do methods[name] = function() end end
function CreateFrame(_, name)
	local frame = object()
	frames[#frames + 1] = frame
	if name then _G[name] = frame end
	return frame
end
Enum = {CombatLogObject = {AffiliationRaid = 1, AffiliationParty = 2, AffiliationMine = 4}}
bit = require("bit")
format, tinsert, tremove = string.format, table.insert, table.remove
function GetTime() return 1000 end
function UnitName() return "TestPlayer" end
function UnitClass() return nil end -- reproduce an unresolved class color too
function GetSpellInfo(id)
	if id == 20484 or id == 871 or id == 29166 then return "Spell"..id, nil, 123 end
end
RAID_CLASS_COLORS = {}
local function setup(spells)
	frames = {}
	SlashCmdList = {}
	ShestakUI = {{RaidSpells = spells}, {raidcooldown = {enable = true, width = 200, height = 16, show_icon = true}, position = {raid_cooldown = {}}, media = {}, font = {raid_cooldowns_font_size = 8}}, {}}
	assert(loadfile(module))()
end
local function bars()
	local result = {}
	for _, frame in ipairs(frames) do if frame.spellId and not frame.hidden then result[frame.spellId] = frame end end
	return result
end
for _, config in ipairs({{}, {[20484] = 600}, {[871] = 99}}) do
	setup(config)
	SlashCmdList.RaidCD()
	local active = bars()
	for id, fallback in pairs({[20484] = 600, [871] = 180, [29166] = 180}) do
		local bar = assert(active[id], "missing preview bar")
		assert(bar.startTime == 1000 and bar.endTime == 1000 + (config[id] or fallback))
		assert(bar.right.text)
	end
	SlashCmdList.RaidCD() -- replace old previews without duplicating bars
	local count = 0
	for _ in pairs(bars()) do count = count + 1 end
	assert(count == 3)
end
-- Exercise StartTimer without preview fallback: missing/invalid durations
-- must be rejected before constructing a bar, not fail halfway through.
setup({})
local StartTimer
for i = 1, 10 do
	local name, value = debug.getupvalue(SlashCmdList.RaidCD, i)
	if name == "StartTimer" then StartTimer = value; break end
end
assert(StartTimer)
local before = #frames
StartTimer("TestPlayer", 871)
StartTimer("TestPlayer", 999999, 180)
assert(#frames == before)
ShestakUI[1].RaidSpells[871] = 0
StartTimer("TestPlayer", 871)
assert(#frames == before)
print("Raid cooldown preview tests passed")
