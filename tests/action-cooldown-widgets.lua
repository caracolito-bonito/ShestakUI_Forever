-- Run from the repository root: luajit tests/action-cooldown-widgets.lua
local module = "ShestakUI/Modules/ActionBars/ActionCooldownWidgets.lua"
local function forbidden() error("secret value inspection or action/grid state change") end
local secret = setmetatable({}, {__add = forbidden, __lt = forbidden, __le = forbidden, __tostring = forbidden, __index = forbidden})
function canaccessvalue(value) return not rawequal(value, secret) end
local nativeCalls, queries, durations, login
local function nativeSet(self, ...)
	local start, duration, rate = ...
	assert(canaccessvalue(start) and canaccessvalue(duration) and canaccessvalue(rate), "reproduced native secret-argument rejection")
	nativeCalls[#nativeCalls + 1] = {self = self, n = select("#", ...), ...}
	return "native-result"
end
local function clear(self) self.cleared = true; self.object = nil end
local widgetMethods = {
	SetCooldown = nativeSet, Clear = clear,
	SetCooldownFromDurationObject = function(self, object, clearIfZero)
		assert(clearIfZero == true)
		self.object, self.cleared = object, false
	end,
}
local function widget() return setmetatable({}, {__index = widgetMethods}) end
local function button()
	local b = {action = 62, showgrid = 1, cooldown = widget(), chargeCooldown = widget(), lossOfControlCooldown = widget()}
	for _, method in ipairs({"Show", "Hide", "SetShown", "SetAlpha", "SetAttribute", "SetScript"}) do b[method] = forbidden end
	return b
end
local sharedUpdater, applyCooldown = function() end, function() end
local registry, current
function hooksecurefunc(target, method, callback)
	assert(target == registry and method == "RegisterFrame")
	local original = target[method]
	target[method] = function(self, ...)
		original(self, ...)
		callback(self, ...)
	end
end
local function setup(enabled)
	nativeCalls, queries, durations, login = {}, {}, {}, nil
	ShestakUI = {{RegisterEvent = function(_, event, callback) assert(event == "PLAYER_LOGIN"); login = callback end}, {actionbar = {enable = enabled}}, {}}
	ActionButton_UpdateCooldown, ActionButton_ApplyCooldown = sharedUpdater, applyCooldown
	current = button()
	registry = {frames = {current}}
	function registry:ForEachFrame(callback) for _, frame in ipairs(self.frames) do callback(frame) end end
	function registry:RegisterFrame(frame) table.insert(self.frames, frame) end
	ActionBarButtonEventsFrame = registry
	C_ActionBar, C_Spell = {}, {}
	for _, kind in ipairs({"action", "spell"}) do
		local key = kind
		durations[key] = {normal = {}, charge = {}, loss = {}}
		local api = kind == "action" and C_ActionBar or C_Spell
		local names = kind == "action" and {GetActionCooldownDuration = "normal", GetActionChargeDuration = "charge", GetActionLossOfControlCooldownDuration = "loss"}
			or {GetSpellCooldownDuration = "normal", GetSpellChargeDuration = "charge", GetSpellLossOfControlCooldownDuration = "loss"}
		for method, mode in pairs(names) do
			local value = mode
			api[method] = function(id)
				queries[#queries + 1] = {kind = key, mode = value, id = id}
				return durations[key][value]
			end
		end
	end
	assert(loadfile(module))()
end
setup(false)
assert(current.cooldown.SetCooldown == nativeSet and not login)
-- Verify the test actually reproduces the native secret-value error.
assert(not pcall(current.cooldown.SetCooldown, current.cooldown, secret, secret, secret))
setup(true)
assert(current.cooldown.SetCooldown ~= nativeSet)
assert(widgetMethods.SetCooldown == nativeSet, "do not alter the shared widget metatable")
assert(ActionButton_UpdateCooldown == sharedUpdater and ActionButton_ApplyCooldown == applyCooldown)
assert(current.cooldown.Clear == clear)
-- Ordinary timings preserve native argument count, values and return value.
assert(current.cooldown:SetCooldown(10, 20) == "native-result")
assert(nativeCalls[1].n == 2 and nativeCalls[1][1] == 10 and nativeCalls[1][2] == 20)
current.cooldown:SetCooldown(0, 0, 1)
assert(nativeCalls[2].n == 3 and nativeCalls[2][1] == 0 and nativeCalls[2][3] == 1)
assert(#queries == 0, "readable timing calls must not be recomputed")
-- Secret timing payloads go straight to the matching duration-object API.
for _, pair in ipairs({{"cooldown", "normal"}, {"chargeCooldown", "charge"}, {"lossOfControlCooldown", "loss"}}) do
	current[pair[1]]:SetCooldown(secret, secret, secret)
	assert(current[pair[1]].object == durations.action[pair[2]])
end
assert(#nativeCalls == 2)
for _, query in ipairs(queries) do assert(query.kind == "action" and query.id == 62) end
current.spellID, queries = 12345, {}
current.cooldown:SetCooldown(10, 20, secret) -- secret modRate alone is sufficient
assert(current.cooldown.object == durations.spell.normal)
assert(queries[1].kind == "spell" and queries[1].id == 12345)
-- Actions change with pages; do not cache a slot or spell when wrapping.
current.spellID, current.action = nil, 74
current.cooldown:SetCooldown(secret, secret)
assert(queries[#queries].id == 74)
-- Empty slots use the unchanged native Clear path; no visibility/grid writes.
local empty = button()
empty.action = nil
registry:RegisterFrame(empty)
empty.cooldown:Clear()
assert(empty.cooldown.cleared and empty.showgrid == 1)
local before = #queries
empty.cooldown:SetCooldown(secret, secret)
assert(empty.cooldown.cleared and #queries == before)
-- Repeated login/registration must not install nested wrappers.
local wrapped = current.cooldown.SetCooldown
login()
registry:RegisterFrame(current)
assert(current.cooldown.SetCooldown == wrapped)
-- Missing duration clears stale rendering; other non-action cooldowns are untouched.
durations.action.normal = nil
current.cooldown:SetCooldown(secret, secret)
assert(current.cooldown.cleared)
assert(widget().SetCooldown == nativeSet)
local restricted = button()
restricted.cooldown.IsForbidden = function() return true end
registry:RegisterFrame(restricted)
assert(restricted.cooldown.SetCooldown == nativeSet)
-- Optional: verify against a locally supplied Forever ActionButton.lua,
-- without loading any of its frame initialization or requiring the network.
if arg and arg[1] then
	setup(true)
	local file = assert(io.open(arg[1]))
	local source = file:read("*a")
	file:close()
	local native = assert(source:match('(local function ActionButton_SetOrClearCooldown.-)\nfunction ClearActionButtonCooldowns'))
	assert(loadstring(native))()
	ActionButton_ApplyCooldown(current.cooldown,
		{startTime = secret, duration = secret, modRate = secret, isActive = true},
		current.chargeCooldown, {isActive = false},
		current.lossOfControlCooldown, {isActive = false, shouldReplaceNormalCooldown = false})
	assert(current.cooldown.object == durations.action.normal and #nativeCalls == 0)
	assert(current.chargeCooldown.cleared and current.lossOfControlCooldown.cleared)
	print("Native Forever ActionButton_ApplyCooldown secret-argument path passed")
end
print("Per-widget secret cooldown adapter and native public/grid behavior tests passed")
