-- Run from the repository root: luajit tests/gamepad-cooldowns.lua
local module = "ShestakUI/Modules/ActionBars/GamepadCooldowns.lua"
local function forbidden() error("must not use numeric cooldowns or change action/grid/binding state") end
local originalShared = function() error("legacy shared numeric updater") end
local originalGamepad = function(self) ActionButton_UpdateCooldown(self) end
local originalKeyboard = function() end
local function cooldown()
	return {SetCooldown = forbidden, SetCooldownFromDurationObject = function(self, duration, clearIfZero)
		assert(clearIfZero == true)
		self.duration, self.cleared = duration, false
	end, Clear = function(self) self.duration, self.cleared = nil, true end}
end
local function button(isGamepad)
	local b = {action = 13, showgrid = 1, enableLOCCooldown = true, cooldown = cooldown(), chargeCooldown = cooldown(), lossOfControlCooldown = cooldown(), OnEvent = originalKeyboard, UpdateCooldown = originalKeyboard}
	for _, method in ipairs({"Show", "Hide", "SetShown", "SetAlpha", "SetAttribute", "SetScript", "RegisterForClicks"}) do b[method] = forbidden end
	if isGamepad then
		b.GetGamepadPageUnitSlotID = function() return 1 end
		b.GetSingleSpellID = function(self) return self.singleSpellID end
		b.UpdateCooldown = originalGamepad
	end
	return b
end
local state, queries, onLogin, keyboard, gamepad, registry
function hooksecurefunc(target, method, callback)
	assert(target == registry and method == "RegisterFrame", "only hook registration of future buttons")
	local original = target[method]
	target[method] = function(self, ...)
		original(self, ...)
		callback(self, ...)
	end
end
local function setup(enabled, unsupported)
	state, queries, onLogin = {}, {}, nil
	ShestakUI = {{RegisterEvent = function(_, event, callback) assert(event == "PLAYER_LOGIN"); onLogin = callback end}, {actionbar = {enable = enabled}}, {}}
	ActionButton_UpdateCooldown = originalShared
	ActionButton_ApplyCooldown, CooldownFrame_Set = forbidden, forbidden
	ActionButton1Cooldown = cooldown()
	keyboard, gamepad = button(false), button(true)
	registry = {frames = {keyboard, gamepad}}
	function registry:ForEachFrame(callback) for _, frame in ipairs(self.frames) do callback(frame) end end
	function registry:RegisterFrame(frame) table.insert(self.frames, frame) end
	ActionBarButtonEventsFrame = registry
	for _, kind in ipairs({"action", "spell"}) do
		local key = kind
		state[key] = {
			info = setmetatable({isActive = true}, {__index = forbidden}),
			charges = setmetatable({isActive = false}, {__index = forbidden}),
			loss = setmetatable({isActive = false, shouldReplaceNormalCooldown = false}, {__index = forbidden}),
			duration = {}, chargeDuration = {}, lossDuration = {},
		}
		local names = kind == "action" and {GetActionCooldown = "info", GetActionCharges = "charges", GetActionLossOfControlCooldownInfo = "loss", GetActionCooldownDuration = "duration", GetActionChargeDuration = "chargeDuration", GetActionLossOfControlCooldownDuration = "lossDuration"}
			or {GetSpellCooldown = "info", GetSpellCharges = "charges", GetSpellLossOfControlCooldownInfo = "loss", GetSpellCooldownDuration = "duration", GetSpellChargeDuration = "chargeDuration", GetSpellLossOfControlCooldownDuration = "lossDuration"}
		local apis = {}
		for method, field in pairs(names) do
			local value = field
			apis[method] = function(id) queries[#queries + 1] = {kind = key, field = value, id = id}; return state[key][value] end
		end
		if kind == "action" then C_ActionBar = apis else C_Spell = apis end
	end
	if unsupported then C_ActionBar.GetActionChargeDuration = nil end
	assert(loadfile(module))()
end
setup(false)
assert(gamepad.UpdateCooldown == originalGamepad and not onLogin)
setup(true, true)
assert(gamepad.UpdateCooldown == originalGamepad and not onLogin)
setup(true)
local patched = gamepad.UpdateCooldown
assert(patched ~= originalGamepad and keyboard.UpdateCooldown == originalKeyboard)
assert(ActionButton_UpdateCooldown == originalShared and ActionButton_ApplyCooldown == forbidden and CooldownFrame_Set == forbidden)
assert(gamepad.OnEvent == originalKeyboard and keyboard.OnEvent == originalKeyboard)
gamepad:UpdateCooldown(99)
assert(gamepad.cooldown.duration == state.action.duration)
assert(gamepad.chargeCooldown.cleared and gamepad.lossOfControlCooldown.cleared)
for _, query in ipairs(queries) do assert(query.kind == "action" and query.id == 13) end
state.action.charges.isActive = true
gamepad:UpdateCooldown()
assert(gamepad.chargeCooldown.duration == state.action.chargeDuration)
state.action.loss.isActive, state.action.loss.shouldReplaceNormalCooldown = true, true
gamepad:UpdateCooldown()
assert(gamepad.lossOfControlCooldown.duration == state.action.lossDuration)
assert(gamepad.cooldown.cleared and gamepad.chargeCooldown.cleared)
state.action.loss.shouldReplaceNormalCooldown = false
gamepad:UpdateCooldown()
assert(gamepad.cooldown.duration == state.action.duration)
gamepad.enableLOCCooldown, queries = false, {}
gamepad:UpdateCooldown()
assert(gamepad.lossOfControlCooldown.cleared)
for _, query in ipairs(queries) do assert(query.field ~= "loss" and query.field ~= "lossDuration") end
-- Preserve native flyout matching: unrelated spell updates must do nothing.
gamepad.singleSpellID, gamepad.spellID, queries = 123456, 123456, {}
gamepad:UpdateCooldown(999)
assert(#queries == 0)
gamepad:UpdateCooldown(123456)
assert(gamepad.cooldown.duration == state.spell.duration)
for _, query in ipairs(queries) do assert(query.kind == "spell" and query.id == 123456) end
-- Late-created gamepad buttons get the narrow fix; ordinary empty slots do not.
local late, empty = button(true), button(false)
empty.action = nil
registry:RegisterFrame(late)
registry:RegisterFrame(empty)
assert(late.UpdateCooldown == patched and empty.UpdateCooldown == originalKeyboard)
onLogin()
assert(gamepad.UpdateCooldown == patched and late.UpdateCooldown == patched)
assert(keyboard.UpdateCooldown == originalKeyboard and empty.showgrid == 1)
assert(ActionButton_UpdateCooldown == originalShared)
for _ = 1, 72 do late:UpdateCooldown() end
state.action.info.isActive, state.action.charges.isActive = false, false
late:UpdateCooldown()
assert(late.cooldown.cleared and late.chargeCooldown.cleared)
late.action, queries = nil, {}
late:UpdateCooldown()
assert(#queries == 0)
local restricted = button(true)
restricted.IsForbidden = function() return true end
registry:RegisterFrame(restricted)
assert(restricted.UpdateCooldown == originalGamepad)
print("Narrow gamepad cooldown and untouched keyboard/grid regression tests passed")
