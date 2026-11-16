-- Run from the repository root: luajit tests/maelstrom-player-buff.lua
function CreateFrame() return {} end
function UnitRace() return "Test", "Test" end
function GetInventoryItemLink() end
function GetSpellInfo(id) return "Spell"..id end
C_Spell = {GetSpellInfo = function(id) return {name = GetSpellInfo(id)} end}
C_SpellBook = {IsSpellKnown = function() return false end}
AuraContainerSortDirection = {Reverse = 1}
tinsert = table.insert
local function setup(class)
	local filger = setmetatable({enable = true}, {__index = function() return 24 end})
	for _, key in ipairs({"buff_spells_list", "proc_spells_list", "debuff_spells_list", "aura_bar_spells_list", "aura_bar_player_spells_list", "cd_spells_list", "ignore_spells_list"}) do filger[key] = {} end
	local T, C = {class = class}, {unitframe = {enable = true}, filger = filger}
	ShestakUI = {T, C, {}}
	assert(loadfile("ShestakUI/Config/Filters/FilgerSpells.lua"))()
	return T, C
end
local T, C = setup("SHAMAN")
assert(T.Filger_P_BUFF[408505], "track the Forever stacking aura in P_BUFF_ICON")
assert(not T.Filger_P_PROC[408505] and not T.Filger_P_PROC[409946], "do not duplicate it in the proc block or track the talent")
assert(not T.Filger_P_BUFF[187881], "do not use the retail talent ID")
assert(T.Filger_P_PROC[16246], "keep Clearcasting unchanged")
local matches = 0
for _, group in ipairs(C.filger_spells.SHAMAN) do
	for _, spell in ipairs(group) do
		if spell.spellID == 408505 then
			matches = matches + 1
			assert(group.Name == "P_BUFF_ICON" and spell.unitID == "player")
			assert(spell.filter == "BUFF" and spell.caster == "player" and spell.absID)
		end
	end
end
assert(matches == 1)
-- Execute the real player-buff container setup to verify that stack display
-- and the same spell whitelist are used by the active raid-era aura system.
local file = assert(io.open("ShestakUI/Modules/UnitFrames/Functions.lua"))
local source = file:read("*a")
file:close()
local declaration = assert(source:match('(self%.PBuffs = self:CreateAuras%(%{.-)\n\t\tend\n\t\tif C%.filger%.show_proc'))
local container = {}
function container:SetPoint(...) self.point = {...} end
function container:AddGroup(filter, options) self.filter, self.options = filter, options end
local self = {CreateAuras = function() return container end}
T.PostCreateFilgerIcon = function() end
assert(loadstring("local self, T, C = ...\n"..declaration))(self, T, C)
assert(container.showCount == true, "show Maelstrom Weapon's stack count")
assert(container.point[2] == P_BUFF_ICON_Anchor)
assert(container.options.candidateFilters.includeSpellIDs[408505])
assert(container.filter == "HELPFUL|PLAYER|!BIG_DEFENSIVE")
local other = setup("MAGE")
assert(not other.Filger_P_BUFF[408505], "Shaman buff tracking must not affect other classes")
print("Maelstrom player buff and stack display tests passed")
