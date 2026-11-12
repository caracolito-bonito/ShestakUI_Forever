-- Run from the repository root: luajit tests/totem-cooldowns.lua
local module = "ShestakUI/Modules/ActionBars/TotemCooldowns.lua"
local original = function() error("legacy numeric cooldown path") end
local function forbidden() error("must not access secret cooldown numbers") end
local duration, queries
local function cooldown()
	return {
		SetCooldown = forbidden,
		SetDrawEdge = function(self, value) self.drawEdge = value end,
		SetCooldownFromDurationObject = function(self, object, clearIfZero)
			assert(object == duration and clearIfZero == true)
			self.duration = object
		end,
		Clear = function(self) self.duration = nil; self.cleared = true end,
	}
end
local function setup(class, enabled, supported)
	ShestakUI = {{class = class}, {actionbar = {enable = enabled}}, {}}
	MultiCastSpellButton_UpdateCooldown = original
	MultiCastSummonSpellButtonCooldown = cooldown()
	MultiCastRecallSpellButtonCooldown = cooldown()
	queries = {}
	C_Spell = {GetSpellCooldown = forbidden}
	if supported then
		C_Spell.GetSpellCooldownDuration = function(spellId)
			queries[#queries + 1] = spellId
			return duration
		end
	end
	CooldownFrame_Set = forbidden
	assert(loadfile(module))()
end
setup("MAGE", true, true)
assert(MultiCastSpellButton_UpdateCooldown == original)
setup("SHAMAN", false, true)
assert(MultiCastSpellButton_UpdateCooldown == original)
setup("SHAMAN", true, false)
assert(MultiCastSpellButton_UpdateCooldown == original)
setup("SHAMAN", true, true)
-- Opaque duration object: no indexing, arithmetic, numeric conversion or
-- comparisons of the protected numeric payload are permitted by this test.
duration = setmetatable({}, {__index = forbidden, __add = forbidden, __lt = forbidden, __le = forbidden, __tostring = forbidden})
local summon = {spellId = 66842, GetName = function() return "MultiCastSummonSpellButton" end}
local recall = {spellId = 36936, GetName = function() return "MultiCastRecallSpellButton" end}
MultiCastSpellButton_UpdateCooldown(summon)
MultiCastSpellButton_UpdateCooldown(recall)
assert(queries[1] == summon.spellId and queries[2] == recall.spellId)
assert(MultiCastSummonSpellButtonCooldown.duration == duration)
assert(MultiCastRecallSpellButtonCooldown.duration == duration)
assert(MultiCastSummonSpellButtonCooldown.drawEdge == false)
-- A missing cooldown clears the visual; zero/GCD handling is delegated to
-- the native duration-object API via clearIfZero, never implemented in Lua.
duration = nil
MultiCastSpellButton_UpdateCooldown(summon)
assert(MultiCastSummonSpellButtonCooldown.cleared)
assert(not MultiCastSummonSpellButtonCooldown.duration)
assert(CooldownFrame_Set == forbidden, "do not replace the shared helper")
print("Totem duration-object cooldown tests passed")
