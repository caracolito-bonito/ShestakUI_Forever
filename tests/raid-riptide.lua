-- Run from the repository root: luajit tests/raid-riptide.lua
local methods = {}
local function object() return setmetatable({}, {__index = methods}) end
function methods:SetPoint(...) self.pointArgs = {...} end
function methods:AddGroup(filter, options) self.filter, self.options = filter, options end
function methods:SetCountdownMillisecondsThreshold(value) self.threshold = value end
function methods:SetHideCountdownNumbers(value) self.hideNumbers = value end
function methods:SetReverse(value) self.reverse = value end
function methods:CreateBorder() self.oborder = object() end
function methods:CreateTexture() self.square = object(); return self.square end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetSize() end
for _, name in ipairs({"SetOutside", "SetTexCoord", "SetFont", "SetShadowOffset", "SetAllPoints", "SetTexture", "SetJustifyH"}) do methods[name] = function() end end
local T = {class = "SHAMAN", SkinCooldown = function() end}
local C = {
	raidframe = {plugins_buffs = true, plugins_debuffs = false, icon_multiplier = 1, plugins_buffs_timer = false},
	aura = {show_timer = false, show_spiral = true},
	media = {blank = "blank"},
	font = {unit_frames_font_size = 8},
}
ShestakUI = {T, C, {}}
tinsert = table.insert
assert(loadfile("ShestakUI/Config/Filters/RaidAuraWatch.lua"))()
local file = assert(io.open("ShestakUI/Modules/UnitFrames/Functions.lua"))
local source = file:read("*a")
file:close()
local functions = assert(source:match("(local CountOffSets =.-)\nT.CreateHealthPrediction ="))
assert(loadstring("local T, C = ...\n"..functions))(T, C)
local function indicators(class)
	T.class = class
	local self = {created = {}}
	function self:CreateAuras()
		local auras = object()
		self.created[#self.created + 1] = auras
		return auras
	end
	T.CreateAuraWatch(self)
	return self.created
end
local function find(list, id)
	for _, auras in ipairs(list) do
		if auras.options.candidateFilters.includeSpellIDs[id] then return auras end
	end
end
local function render(auras)
	local button = object()
	button.Cooldown, button.Count, button.Icon = object(), object(), object()
	auras.PostCreateButton(auras, button)
	return button
end
local shaman = indicators("SHAMAN")
local riptide = assert(find(shaman, 408521))
assert(riptide.point == "TOPRIGHT" and riptide.pointArgs[1] == "TOPRIGHT")
assert(riptide.filter == "HELPFUL|PLAYER", "track only the player's Riptide")
assert(riptide.options.maxFrameCount == 1 and riptide.size == 7)
assert(riptide.showBuffTimer == true and not riptide.disableCooldown)
local button = render(riptide)
assert(button.square.color[1] == 0.2 and button.square.color[2] == 0.8 and button.square.color[3] == 0.2)
assert(button.Cooldown.hideNumbers == false and button.Cooldown.threshold == 0)
assert(button.Cooldown.reverse == true)
local fortitude = assert(find(shaman, 16177))
assert(fortitude.point == "TOPLEFT", "do not overlap the existing upper-left indicator")
assert(fortitude.disableCooldown and render(fortitude).Cooldown.hideNumbers, "other buffs keep existing timer settings")
local druid = indicators("DRUID")
local rejuvenation = assert(find(druid, 774))
assert(rejuvenation.point == "TOPRIGHT" and rejuvenation.filter == "HELPFUL|PLAYER")
assert(rejuvenation.options.candidateFilters.includeSpellIDs[25299], "keep druid HoT ranks")
assert(not find(druid, 408521), "do not add Riptide to another class's configuration")
C.aura.show_timer = true
C.raidframe.plugins_buffs_timer = true
local druidWithTimers = assert(find(indicators("DRUID"), 774))
assert(not druidWithTimers.disableCooldown and not render(druidWithTimers).Cooldown.hideNumbers)
print("Raid Riptide indicator tests passed")
