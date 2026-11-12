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
for _, class in ipairs({"SHAMAN", "PRIEST", "MAGE"}) do
	local T, C = setup(class)
	assert(T.Filger_P_PROC[1248808], "Revelation must reach the active player's proc filter")
	assert(not T.Filger_P_BUFF[1248808] and not T.Filger_T_DEBUFF[1248808])
	if class == "SHAMAN" then assert(T.Filger_P_PROC[16246], "keep Clearcasting in the same proc block") end
	local matches = 0
	for _, group in ipairs(C.filger_spells[class]) do
		for _, spell in ipairs(group) do
			if spell.spellID == 1248808 then
				matches = matches + 1
				assert(group.Name == "P_PROC_ICON")
				assert(spell.unitID == "player" and spell.filter == "BUFF" and spell.absID)
			end
		end
	end
	assert(matches == 1, "do not duplicate the proc")
end
print("Revelation proc filter tests passed")
