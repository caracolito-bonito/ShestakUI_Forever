-- Run from the repository root: luajit tests/action-button-duration-cooldowns.lua
local module = "ShestakUI/Modules/ActionBars/DurationCooldowns.lua"
local function forbidden() error("numeric/secret cooldown path must not be used") end
local original = function() error("legacy ActionButton_UpdateCooldown") end
local state, queries
local function opaque()
	return setmetatable({}, {__index = forbidden, __add = forbidden, __lt = forbidden, __le = forbidden, __tostring = forbidden})
end
local function info(fields)
	return setmetatable(fields, {__index = forbidden}) -- only documented public fields may be read
end
local function cooldown()
	return {
		SetCooldown = forbidden,
		SetCooldownFromDurationObject = function(self, duration, clearIfZero)
			assert(clearIfZero == true)
			self.duration, self.cleared = duration, false
		end,
		Clear = function(self) self.duration, self.cleared = nil, true end,
	}
end
local function setup(enabled, unsupported)
	state, queries = {}, {}
	ShestakUI = {{}, {actionbar = {enable = enabled}}, {}}
	ActionButton_UpdateCooldown = original
	ActionButton_ApplyCooldown, CooldownFrame_Set = forbidden, forbidden
	ActionButton1Cooldown = cooldown()
	for _, kind in ipairs({"action", "spell"}) do
		local key = kind
		state[key] = {
			info = info({isActive = true}), charges = info({isActive = false}),
			loss = info({isActive = false, shouldReplaceNormalCooldown = false}),
			duration = opaque(), chargeDuration = opaque(), lossDuration = opaque(),
		}
		local api = {}
		local names = kind == "action" and {
			GetActionCooldown = "info", GetActionCharges = "charges", GetActionLossOfControlCooldownInfo = "loss",
			GetActionCooldownDuration = "duration", GetActionChargeDuration = "chargeDuration", GetActionLossOfControlCooldownDuration = "lossDuration",
		} or {
			GetSpellCooldown = "info", GetSpellCharges = "charges", GetSpellLossOfControlCooldownInfo = "loss",
			GetSpellCooldownDuration = "duration", GetSpellChargeDuration = "chargeDuration", GetSpellLossOfControlCooldownDuration = "lossDuration",
		}
		for method, field in pairs(names) do
			local value = field
			api[method] = function(id)
				queries[#queries + 1] = {kind = key, field = value, id = id}
				return state[key][value]
			end
		end
		if kind == "action" then C_ActionBar = api else C_Spell = api end
	end
	if unsupported then C_ActionBar.GetActionChargeDuration = nil end
	assert(loadfile(module))()
end
local function button()
	return {action = 13, enableLOCCooldown = true, cooldown = cooldown(), chargeCooldown = cooldown(), lossOfControlCooldown = cooldown()}
end
setup(false)
assert(ActionButton_UpdateCooldown == original)
setup(true, true)
assert(ActionButton_UpdateCooldown == original, "unsupported clients must keep Blizzard implementation")
setup(true)
local b = button()
ActionButton_UpdateCooldown(b)
assert(b.cooldown.duration == state.action.duration)
assert(b.chargeCooldown.cleared and b.lossOfControlCooldown.cleared)
for _, query in ipairs(queries) do assert(query.kind == "action" and query.id == 13) end
assert(b.cooldown.SetCooldown == forbidden and ActionButton_ApplyCooldown == forbidden and CooldownFrame_Set == forbidden)
-- Charge recovery and normal/GCD cooldowns can be active together.
state.action.charges.isActive = true
ActionButton_UpdateCooldown(b)
assert(b.chargeCooldown.duration == state.action.chargeDuration and b.cooldown.duration == state.action.duration)
-- A dominant loss-of-control cooldown replaces both other spirals.
state.action.loss.isActive, state.action.loss.shouldReplaceNormalCooldown = true, true
ActionButton_UpdateCooldown(b)
assert(b.lossOfControlCooldown.duration == state.action.lossDuration)
assert(b.cooldown.cleared and b.chargeCooldown.cleared)
state.action.loss.shouldReplaceNormalCooldown = false
ActionButton_UpdateCooldown(b)
assert(b.cooldown.duration == state.action.duration and b.lossOfControlCooldown.duration == state.action.lossDuration)
-- Disabling LoC must clear stale visuals and never query its APIs.
b.enableLOCCooldown, queries = false, {}
ActionButton_UpdateCooldown(b)
assert(b.lossOfControlCooldown.cleared)
for _, query in ipairs(queries) do assert(query.field ~= "loss" and query.field ~= "lossDuration") end
-- Spell-based flyouts (including gamepad flyouts) use spell duration APIs.
b.spellID, queries = 123456, {}
ActionButton_UpdateCooldown(b)
assert(b.cooldown.duration == state.spell.duration)
for _, query in ipairs(queries) do assert(query.kind == "spell" and query.id == 123456) end
-- Simulate repeated Gamepad UpdateCooldown delegation after a group rebuild.
b.spellID, b.action = nil, 14
for _ = 1, 72 do ActionButton_UpdateCooldown(b) end
assert(b.cooldown.duration == state.action.duration)
-- Inactive, missing info, and unavailable duration objects clear old cooldowns.
state.action.info.isActive, state.action.charges.isActive = false, false
ActionButton_UpdateCooldown(b)
assert(b.cooldown.cleared and b.chargeCooldown.cleared)
state.action.info.isActive, state.action.duration = true, nil
ActionButton_UpdateCooldown(b)
assert(b.cooldown.cleared)
state.action.info, state.action.charges = nil, nil
ActionButton_UpdateCooldown(b)
assert(b.cooldown.cleared and b.chargeCooldown.cleared)
-- Empty/transitional buttons: no invalid-slot queries, even with optional frames absent.
b.action, b.cooldown, queries = nil, nil, {}
ActionButton_UpdateCooldown(b)
assert(#queries == 0 and b.chargeCooldown.cleared and b.lossOfControlCooldown.cleared)
print("Shared action/gamepad duration cooldown tests passed")
