-- Run from the repository root: luajit tests/gamepad-class-flyout.lua [native ActionBarButton.lua]
local module = "ShestakUI/Modules/ActionBars/GamepadClassFlyout.lua"
local function forbidden() error("must not cast, change action/grid state, or inspect secret data") end
local secret = setmetatable({}, {__index = forbidden, __tostring = forbidden, __eq = forbidden})
function canaccessvalue(value) return not rawequal(value, secret) end
local original = function() return "original" end
local states, queries, onLoad, onLogin, onEnteringWorld, target, registry, timers
function hooksecurefunc(object, method, callback)
	assert(object == registry and method == "RegisterFrame")
	local originalMethod = object[method]
	object[method] = function(self, ...)
		originalMethod(self, ...)
		callback(self, ...)
	end
end
C_Flyout = {GetFlyoutTexture = function(id) assert(id == 262); return "generic-flyout" end}
local function NativeIconUpdate(self)
	if not self.isFlyoutAction then return end
	local id = self:GetSingleSpellID() or self:GetActiveSpellID()
	local texture = id and C_Spell.GetSpellTexture(id) or C_Flyout.GetFlyoutTexture(self.flyoutID)
	self.icon:SetTexture(texture)
end
if arg and arg[1] then
	local file = assert(io.open(arg[1]))
	local source = file:read("*a")
	file:close()
	local native = assert(source:match('(function GamepadActionBarButtonFlyoutMixin:UpdateFlyoutActionIcon%(%)%s*.-)\nfunction GamepadActionBarButtonFlyoutMixin:ReapplyStyle'))
	GamepadActionBarButtonFlyoutMixin = {}
	assert(loadstring(native))()
	NativeIconUpdate = GamepadActionBarButtonFlyoutMixin.UpdateFlyoutActionIcon
end
local function setup(enabled, late, restricted)
	states, queries, onLoad, onLogin, onEnteringWorld, timers = {}, {}, nil, nil, nil, {}
	SlashCmdList = {}
	C_Timer = {After = function(delay, callback) assert(delay == 0); timers[#timers + 1] = callback end}
	C_Spell = {
		IsActiveSpell = function(id) queries[#queries + 1] = id; if states[id] == nil then return false end; return states[id] end,
		GetSpellTexture = function(id) return "spell-"..id end,
	}
	ShestakUI = {{RegisterEvent = function(_, event, callback)
		if event == "PLAYER_LOGIN" then onLogin = callback
		elseif event == "PLAYER_ENTERING_WORLD" then onEnteringWorld = callback
		else error("unexpected event") end
	end}, {actionbar = {enable = enabled}}, {}}
	EventUtil = {ContinueOnAddOnLoaded = function(addon, callback)
		assert(addon == "Blizzard_GamepadActionBars")
		onLoad = callback
		if not late then callback() end
	end}
	target = {isFlyoutAction = true, flyoutID = 262, GetActiveSpellID = original, UpdateCooldown = original, OnEvent = original, showgrid = 1, icon = {SetTexture = function(self, texture) self.texture = texture end}}
	function target:GetName() return "GamepadMainActionBarFramePageUnitLeftClassAction" end
	function target:GetSingleSpellID() return self.singleSpellID end
	function target:EnumFlyoutSlotInfo(onlyKnown)
		assert(onlyKnown == true)
		local ids, i = {5487, 768}, 0
		return function() i = i + 1; if ids[i] then return i, ids[i] end end
	end
	if restricted then target.IsForbidden = function() return true end end
	for _, key in ipairs({"Hide", "Show", "SetAlpha", "SetAttribute", "SetScript", "HandleFlyoutClickOverride"}) do target[key] = forbidden end
	CastSpellByID = forbidden
	GamepadMainActionBarFrame, GamepadMainActionBarFramePageUnitLeftClassAction, GamepadMainActionBarFramePageUnitRightClassAction = nil, nil, nil
	-- Reproduce the XML parentKey layout with NO global root/child aliases.
	UIParent = {}
	if not late then UIParent.GamepadMainActionBarFrame = {PageUnit = {LeftClassAction = target}} end
	registry = {frames = {}}
	function registry:ForEachFrame(callback) for _, frame in ipairs(self.frames) do callback(frame) end end
	function registry:RegisterFrame(frame) self.frames[#self.frames + 1] = frame end
	ActionBarButtonEventsFrame = registry
	assert(loadfile(module))()
end
setup(false)
assert(target.GetActiveSpellID == original and not onLoad and not onLogin)
setup(true, false, true)
assert(target.GetActiveSpellID == original)
setup(true)
local patched, spellAPI = target.GetActiveSpellID, C_Spell.IsActiveSpell
assert(patched ~= original and target.UpdateCooldown == original and target.OnEvent == original and target.showgrid == 1)
states[5487], states[768] = false, true
assert(target:GetActiveSpellID() == 768)
NativeIconUpdate(target)
assert(target.icon.texture == "spell-768")
states[5487], states[768] = true, false
NativeIconUpdate(target)
assert(target.icon.texture == "spell-5487")
states[5487], states[768] = false, false
NativeIconUpdate(target)
assert(target.icon.texture == "generic-flyout")
-- Restricted active state is not treated as either true or false. Return nil
-- immediately so the unchanged Blizzard icon updater selects its fallback.
states[5487], states[768], queries = secret, true, {}
NativeIconUpdate(target)
assert(target.icon.texture == "generic-flyout" and #queries == 1)
states[5487], states[768], queries = false, secret, {}
NativeIconUpdate(target)
assert(target.icon.texture == "generic-flyout" and #queries == 2)
target.singleSpellID, queries = 123, {}
NativeIconUpdate(target)
assert(target.icon.texture == "spell-123" and #queries == 0)
target.singleSpellID, target.isFlyoutAction, queries = nil, false, {}
assert(target:GetActiveSpellID() == nil and #queries == 0)
onLogin()
assert(target.GetActiveSpellID == patched and C_Spell.IsActiveSpell == spellAPI)
-- Initialization after our login handler must not discard the guard.
target.GetActiveSpellID = original
for _, callback in ipairs(timers) do callback() end
assert(target.GetActiveSpellID == patched)
target.GetActiveSpellID = original
onEnteringWorld()
assert(target.GetActiveSpellID == patched)
local oldPrint, output, reads = print, {}, #queries
print = function(...) output[#output + 1] = {...} end
SlashCmdList.SUIFLYOUT()
print = oldPrint
assert(#output == 1 and output[1][3] == true and #queries == reads, "installation check must not read secret state")
-- The addon can be loaded after login; also support the explicit global name
-- used in the reported stack without patching the mixin or other instances.
setup(true, true)
onLogin() -- no frame yet
assert(target.GetActiveSpellID == original)
GamepadMainActionBarFramePageUnitLeftClassAction = target
onLoad()
assert(target.GetActiveSpellID ~= original)
states[5487] = secret
NativeIconUpdate(target)
assert(target.icon.texture == "generic-flyout")
assert(({GetActiveSpellID = original}).GetActiveSpellID == original)
-- Late registered class buttons are patched even without any root/global alias.
setup(true, true)
registry:RegisterFrame(target)
assert(target.GetActiveSpellID ~= original)
local other = {GetName = function() return "ActionButton1" end, GetActiveSpellID = original, EnumFlyoutSlotInfo = original}
registry:RegisterFrame(other)
assert(other.GetActiveSpellID == original)
-- Registry and parent-key paths must identify one physical button only once.
UIParent.GamepadMainActionBarFrame = {PageUnit = {LeftClassAction = target}}
oldPrint, output = print, {}
print = function(...) output[#output + 1] = {...} end
SlashCmdList.SUIFLYOUT()
print = oldPrint
assert(#output == 1 and output[1][3] == true)
print("Gamepad class flyout parent-key/late-installation and secret-state tests passed")
