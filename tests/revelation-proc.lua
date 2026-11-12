-- Run from the repository root: luajit tests/revelation-proc.lua
local module = "ShestakUI/Config/Filters/FilgerSpells.lua"
function CreateFrame() return {} end
function UnitRace() return "Test", "Test" end
function GetInventoryItemLink() end
function GetSpellInfo(id) return "Spell"..id end
C_Spell = {GetSpellInfo = function(id) return {name = GetSpellInfo(id)} end}
C_SpellBook = {IsSpellKnown = function() return false end}
tinsert = table.insert
local function setup(class)
	local filger = setmetatable({enable = true}, {__index = function() return 24 end})
	for _, key in ipairs({"buff_spells_list", "proc_spells_list", "debuff_spells_list", "aura_bar_spells_list", "aura_bar_player_spells_list", "cd_spells_list", "ignore_spells_list"}) do filger[key] = {} end
	local T, C = {class = class}, {unitframe = {enable = true}, filger = filger}
	ShestakUI = {T, C, {}}
	assert(loadfile(module))()
	return T, C
end
local revelationIDs = {SHAMAN = 1323418, MAGE = 1248808}
for _, class in ipairs({"SHAMAN", "PRIEST", "MAGE"}) do
	local T, C = setup(class)
	local expected = revelationIDs[class]
	for _, id in pairs(revelationIDs) do
		assert(not not T.Filger_P_PROC[id] == (id == expected), "only register the class-specific Revelation aura")
		assert(not T.Filger_P_BUFF[id] and not T.Filger_T_DEBUFF[id])
	end
	if class == "SHAMAN" then assert(T.Filger_P_PROC[16246], "keep Clearcasting in the same proc block") end
	local matches = 0
	for _, group in ipairs(C.filger_spells[class]) do
		for _, spell in ipairs(group) do
			if spell.spellID == 1248808 or spell.spellID == 1323418 then
				assert(spell.spellID == expected)
				matches = matches + 1
				assert(group.Name == "P_PROC_ICON")
				assert(spell.unitID == "player" and spell.filter == "BUFF" and spell.absID)
				assert(spell.caster == "all", "enchant procs may not have a player source")
			end
		end
	end
	assert(matches == (expected and 1 or 0), "register exactly one confirmed proc for supported classes")
end
-- Execute the actual PProc AddGroup declaration, not a separate test filter.
local T = setup("SHAMAN")
local file = assert(io.open("ShestakUI/Modules/UnitFrames/Functions.lua"))
local source = file:read("*a")
file:close()
local declaration = assert(source:match('(self%.PProc:AddGroup%(".-\n\t\t\t}%))'))
local captured
local self = {PProc = {AddGroup = function(_, filter, options) captured = {filter, options} end}}
assert(loadstring("local self, T = ...\n"..declaration))(self, T)
assert(captured[1] == "HELPFUL", "must not reject source-less enchant procs with PLAYER")
assert(captured[2].maxFrameCount == 6)
local whitelist = captured[2].candidateFilters.includeSpellIDs
assert(whitelist == T.Filger_P_PROC and whitelist[1323418] and whitelist[16246])
assert(not whitelist[1248808], "do not use the Mage proc ID on a Shaman")
assert(not whitelist[999999], "do not allow unrelated buffs into the proc group")
print("Revelation proc filter and aura-source tests passed")
