-- Run: luajit tests/action-grid.lua [path/to/native/ActionButton.lua]
local module = "ShestakUI/Modules/ActionBars/ActionGrid.lua"
local reason = 1048576
bit = require("bit")
local frames, timers, combat, secure, buttons
local prefixes = {"ActionButton", "MultiBarBottomLeftButton", "MultiBarLeftButton", "MultiBarRightButton", "MultiBarBottomRightButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button"}
UIParent = {}
function InCombatLockdown() return combat end
function issecure() return secure end
BaseActionButtonMixin = {}
if arg[1] then
	local file = assert(io.open(arg[1]))
	local source = file:read("*a")
	file:close()
	for _, name in ipairs({"GetShowGrid", "SetShowGrid"}) do
		assert(loadstring(assert(source:match("function BaseActionButtonMixin:"..name..".-\nend"))))()
	end
else
	function BaseActionButtonMixin:GetShowGrid() return (self:GetAttribute("showgrid") or 0) > 0 end
	function BaseActionButtonMixin:SetShowGrid(show, flag)
		if issecure() and self:GetShowGrid() ~= show then
			local grid = self:GetAttribute("showgrid") or 0
			self:SetAttribute("showgrid", show and bit.bor(grid, flag) or bit.band(grid, bit.bnot(flag)))
		end
	end
end
local nativeGet, nativeSet = BaseActionButtonMixin.GetShowGrid, BaseActionButtonMixin.SetShowGrid
local function forbidden() error("must not alter layout, alpha, parent, cooldowns or inspect actions") end
function CreateFrame(_, _, _, template)
	local frame = {attrs = {}, refs = {}, events = {}, template = template}
	function frame:RegisterEvent(event) self.events[event] = true end
	function frame:UnregisterEvent(event) self.events[event] = nil end
	function frame:SetScript(script, callback) assert(script == "OnEvent"); self.onEvent = callback end
	function frame:SetFrameRef(key, value) assert(not combat); self.refs[key] = value end
	function frame:GetFrameRef(key) return self.refs[key] end
	function frame:SetAttribute(key, value) assert(not combat); self.attrs[key] = value end
	function frame:GetAttribute(key) return self.attrs[key] end
	function frame:Execute(code)
		assert(not combat and self.template == "SecureHandlerBaseTemplate")
		secure = true
		local fn = assert(loadstring(code))
		setfenv(fn, {self = self}) -- no addon/global functions in the restricted snippet
		fn()
		secure = false
	end
	frames[#frames + 1] = frame
	return frame
end
local function setup(enabled, grid, editor)
	frames, timers, buttons, combat, secure = {}, {}, {}, false, false
	C_Timer = {After = function(delay, callback) assert(delay == 0); timers[#timers + 1] = callback end}
	ShestakUI = {{}, {actionbar = {enable = enabled, show_grid = grid, editor = editor, bar7_enable = true, bar8_enable = true, bar2_num = 6}}, {}}
	for _, prefix in ipairs(prefixes) do
		for i = 1, 12 do
			local button = {attrs = {showgrid = i % 5}, shown = false, parent = {shown = false}}
			function button:IsForbidden() return self.forbidden end
			function button:GetAttribute(key) return self.attrs[key] end
			function button:SetAttribute(key, value) assert(secure and not combat); self.attrs[key] = value end
			function button:Show(skipAttr)
				assert(secure and not combat and skipAttr == true, "do not rewrite statehidden")
				self.shown = true
			end
			button.GetShowGrid, button.SetShowGrid = nativeGet, nativeSet
			button.SetAlpha, button.SetScale, button.SetPoint, button.SetParent = forbidden, forbidden, forbidden, forbidden
			button.HasAction, button.UpdateCooldown = forbidden, forbidden
			_G[prefix..i] = button
			buttons[#buttons + 1] = button
		end
	end
	assert(loadfile(module))()
end
local function fire(event)
	for _, frame in ipairs(frames) do if frame.events[event] then frame.onEvent(frame, event) end end
end
local function flush()
	local queued = timers
	timers = {}
	for _, callback in ipairs(queued) do callback() end
end
setup(false, true)
assert(#frames == 0)
setup(true, false)
assert(#frames == 0)
setup(true, true)
local hidden, blocked = buttons[2], buttons[3]
hidden.attrs.statehidden, blocked.forbidden = true, true
local pet, gamepad = {attrs = {}}, {attrs = {}}
PetActionButton1, GamepadMainActionBarFramePageUnitLeftClassAction = pet, gamepad
fire("PLAYER_LOGIN")
fire("PLAYER_ENTERING_WORLD")
assert(#timers == 1, "coalesce startup events")
flush()
for index, button in ipairs(buttons) do
	if button ~= blocked then
		assert(button.attrs.showgrid == reason + ((index - 1) % 12 + 1) % 5, "preserve existing reason bits")
		assert(button:GetShowGrid())
		assert(button.shown == (button ~= hidden))
		assert(not button.parent.shown, "must not unhide a whole bar")
	end
	assert(button.GetShowGrid == nativeGet and button.SetShowGrid == nativeSet)
end
assert(not blocked.shown and blocked.attrs.showgrid == 3)
assert(pet.attrs.showgrid == nil and gamepad.attrs.showgrid == nil)
-- Native Edit Mode/drag/spellbook cleanup must leave our preference intact.
secure = true
local first = buttons[1]
for _, flag in ipairs({1, 2, 4}) do first:SetShowGrid(false, flag) end
secure = false
assert(first:GetShowGrid() and first.attrs.showgrid == reason)
-- Repeated world entry is idempotent, including unknown native reason bits.
first.attrs.showgrid = bit.bor(reason, 16)
fire("PLAYER_ENTERING_WORLD")
flush()
assert(first.attrs.showgrid == reason + 16)
-- Reload/login while fighting must not write protected references or attributes.
setup(true, true)
combat = true
fire("PLAYER_LOGIN")
flush()
assert(frames[2].events.PLAYER_REGEN_ENABLED)
for _, button in ipairs(buttons) do assert(not button.shown and button.attrs.showgrid < reason) end
combat = false
fire("PLAYER_REGEN_ENABLED")
flush()
assert(not frames[2].events.PLAYER_REGEN_ENABLED and buttons[1]:GetShowGrid())
-- A missing button can be discovered on the later world-entry pass.
setup(true, true)
local late = MultiBarLeftButton1
MultiBarLeftButton1 = nil
fire("PLAYER_LOGIN")
flush()
assert(not late.shown)
MultiBarLeftButton1 = late
fire("PLAYER_ENTERING_WORLD")
flush()
assert(late.shown and bit.band(late.attrs.showgrid, reason) == reason)
-- Editor-hidden extra buttons and disabled optional bars remain untouched.
setup(true, true, true)
ShestakUI[2].actionbar.bar7_enable = false
fire("PLAYER_ENTERING_WORLD")
flush()
assert(MultiBarBottomLeftButton6:GetShowGrid())
assert(not MultiBarBottomLeftButton7.shown and MultiBarBottomLeftButton7.attrs.showgrid < reason)
assert(not MultiBar6Button1.shown and MultiBar6Button1.attrs.showgrid < reason)
assert(BaseActionButtonMixin.GetShowGrid == nativeGet and BaseActionButtonMixin.SetShowGrid == nativeSet)
print("Persistent empty-slot grid, native cleanup and combat/editor safety tests passed")
