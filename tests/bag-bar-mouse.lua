-- Run: luajit tests/bag-bar-mouse.lua
-- In game: reload, hover right of the action bars, open/close bags, swap a bag,
-- and check tooltips inside the actual inventory still work. No native scripts,
-- bag functions, frame geometry, visibility or alpha should change.
local module = "ShestakUI/Modules/ActionBars/BagBarMouse.lua"
local events, timers, loaded, combat, touched
local function forbidden() error("must not change scripts, events, visibility, layout or bag operations") end
local function node(children, blocked)
	local frame = {children = children or {}, click = true, motion = true, forbidden = blocked}
	function frame:IsForbidden() return self.forbidden end
	function frame:GetChildren() assert(not self.forbidden); return unpack(self.children) end
	function frame:SetMouseClickEnabled(value) assert(not combat and not self.forbidden); self.click = value; touched = touched + 1 end
	function frame:SetMouseMotionEnabled(value) assert(not combat and not self.forbidden); self.motion = value end
	frame.SetScript, frame.HookScript, frame.UnregisterAllEvents = forbidden, forbidden, forbidden
	frame.SetParent, frame.SetPoint, frame.SetAlpha, frame.Hide = forbidden, forbidden, forbidden, forbidden
	return frame
end
local function setup(enabled)
	events, timers, loaded, combat, touched = {}, {}, nil, false, 0
	ShestakUI = {{RegisterEvent = function(_, name, callback) assert(not events[name]); events[name] = callback end}, {actionbar = {enable = enabled}}, {}}
	C_Timer = {After = function(delay, callback) assert(delay == 0); timers[#timers + 1] = callback end}
	EventUtil = {ContinueOnAddOnLoaded = function(name, callback) assert(name == "Blizzard_MainMenuBarBagButtons"); loaded = callback end}
	function InCombatLockdown() return combat end
	GameTooltip = {hidden = false}
	function GameTooltip:IsOwned(frame) return self.owner == frame end
	function GameTooltip:Hide() self.hidden = true end
	local nested, blocked = node(), node(nil, true)
	MainMenuBarBackpackButton = node({nested})
	BagsBar = node({MainMenuBarBackpackButton, node(), blocked})
	ContainerFrameCombinedBags, GamepadBagBar, ActionButton1 = node(), node(), node()
	ToggleBackpack, OpenAllBags = forbidden, forbidden
	assert(loadfile(module))()
	return nested, blocked
end
local function flush()
	local queue = timers
	timers = {}
	for _, callback in ipairs(queue) do callback() end
end
local function checkUntouched(frame) assert(frame.click and frame.motion) end
setup(false)
assert(next(events) == nil and loaded == nil)
local nested, blocked = setup(true)
GameTooltip.owner = nested
loaded()
events.PLAYER_LOGIN()
events.PLAYER_ENTERING_WORLD()
assert(#timers == 1, "coalesce initialization requests")
flush()
assert(touched == 4 and GameTooltip.hidden)
for _, frame in ipairs({BagsBar, MainMenuBarBackpackButton, nested, BagsBar.children[2]}) do
	assert(not frame.click and not frame.motion)
end
for _, frame in ipairs({blocked, ContainerFrameCombinedBags, GamepadBagBar, ActionButton1}) do checkUntouched(frame) end
-- Do not hide another tooltip or repeatedly apply on every fight ending.
GameTooltip.owner, GameTooltip.hidden = ContainerFrameCombinedBags, false
events.PLAYER_ENTERING_WORLD()
flush()
assert(not GameTooltip.hidden)
events.PLAYER_REGEN_ENABLED()
assert(#timers == 0)
-- Protected UI input settings are not written while reloading in combat.
setup(true)
combat = true
events.PLAYER_LOGIN()
flush()
assert(touched == 0)
combat = false
events.PLAYER_REGEN_ENABLED()
flush()
assert(touched == 4)
-- Late addon loading and new toolbar descendants are discovered on the next pass.
setup(true)
local late = BagsBar
BagsBar = nil
events.PLAYER_LOGIN()
flush()
assert(touched == 0)
BagsBar = late
local extra = node()
BagsBar.children[#BagsBar.children + 1] = extra
loaded()
flush()
assert(not extra.click and not extra.motion)
print("Hidden bag toolbar mouse suppression and scope/combat tests passed")
