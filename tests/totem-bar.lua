-- Run from the repository root: luajit tests/totem-bar.lua
local module = "ShestakUI/Modules/ActionBars/BarTotem.lua"
local combat, frames, hooks, timers
C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
local methods = {}
local function object(name)
	return setmetatable({name = name, shown = true, scripts = {}, events = {}}, {__index = methods})
end
function methods:GetName() return self.name end
function methods:SetSize(w, h) assert(not combat); self.width, self.height = w, h end
function methods:SetPoint(...) assert(not combat); self.point = {...}; if self.pointHook then self.pointHook(self, ...) end end
function methods:ClearAllPoints() assert(not combat); self.point = nil end
function methods:SetScale(value) assert(not combat); self.scale = value end
function methods:SetParent(parent) assert(not combat); self.parent = parent end
function methods:SetFrameStrata() end
function methods:SetNormalTexture() end
function methods:SetTemplate() self.styled = true end
function methods:SetBackdropBorderColor() end
function methods:StyleButton() end
function methods:IsShown() return self.shown end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:HookScript(event, callback) self.scripts[event] = callback end
function CreateFrame(_, name, parent)
	local frame = object(name)
	frame.parent = parent
	_G[name] = frame
	frames[#frames + 1] = frame
	return frame
end
function InCombatLockdown() return combat end
function hooksecurefunc(target, method, callback)
	if type(target) == "string" then
		hooks[target] = method
	else
		local original = target[method]
		target[method] = function(self, ...)
			original(self, ...)
			callback(self, ...)
		end
	end
end
local function setup(class, enabled, hasBar)
	combat, frames, hooks, timers = false, {}, {}, {}
	ShestakUI = {{class = class}, {actionbar = {enable = enabled, button_size = 30, button_space = 4}}, {}}
	NUM_MULTI_CAST_PAGES, NUM_MULTI_CAST_BUTTONS_PER_PAGE = 3, 4
	TotemBarAnchor = nil
	MultiCastActionBarFrame = hasBar and object("MultiCastActionBarFrame") or nil
	if MultiCastActionBarFrame then
		local bar = MultiCastActionBarFrame
		bar.SetPointBase, bar.ClearAllPointsBase, bar.SetScaleBase = methods.SetPoint, methods.ClearAllPoints, methods.SetScale
		bar.SetPoint = function(self, ...)
			self:SetPointBase(...)
			self.editModeNotifications = (self.editModeNotifications or 0) + 1
		end
		bar.ApplySystemAnchor = function(self)
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", ActionBarAnchor, "TOPLEFT", 0, 0)
			-- Simulate layout work performed after SetPointOverride returns.
			self.point = {"TOPLEFT", ActionBarAnchor, "TOPLEFT", 0, 0}
		end
	end
	ActionBarAnchor, T_PetBattleFrameHider = object("ActionBarAnchor"), object("Hider")
	for _, name in ipairs({"MultiCastSummonSpellButton", "MultiCastRecallSpellButton", "MultiCastFlyoutFrame"}) do _G[name] = object(name) end
	for i = 1, 4 do _G["MultiCastSlotButton"..i] = object("MultiCastSlotButton"..i) end
	for i = 1, 12 do _G["MultiCastActionButton"..i] = object("MultiCastActionButton"..i) end
	for i = 1, 3 do _G["MultiCastActionPage"..i] = object("MultiCastActionPage"..i) end
	assert(loadfile(module))()
end
local function fire(event) TotemBarAnchor.scripts.OnEvent(TotemBarAnchor, event) end
for _, args in ipairs({{"MAGE", true, true}, {"SHAMAN", false, true}, {"SHAMAN", true, false}}) do
	setup(unpack(args))
	assert(#frames == 0, "unsupported configurations must not be changed")
end
setup("SHAMAN", true, true)
MultiCastActionBarFrame.numActiveSlots = 4
fire("PLAYER_LOGIN")
assert(MultiCastActionBarFrame.parent == TotemBarAnchor)
assert(TotemBarAnchor.parent == T_PetBattleFrameHider)
assert(TotemBarAnchor.width == 200)
assert(MultiCastSlotButton1.point[4] == 34)
assert(MultiCastRecallSpellButton.point[4] == 170)
for i = 1, 12 do
	local button = _G["MultiCastActionButton"..i]
	assert(button.styled and button.width == 30)
	assert(button.point[4] == ((i - 1) % 4) * 34)
end
-- Learning/unlearning summon and recall spells, with fewer available slots.
MultiCastSummonSpellButton.shown, MultiCastRecallSpellButton.shown = false, false
MultiCastActionBarFrame.numActiveSlots = 2
hooks.MultiCastActionBarFrame_Update()
assert(TotemBarAnchor.width == 64 and MultiCastSlotButton1.point[4] == 0)
-- Edit Mode must not steal the ShestakUI anchor.
MultiCastActionBarFrame:SetPoint("BOTTOM", ActionBarAnchor, "BOTTOM", 50, 50)
assert(MultiCastActionBarFrame.point[2] == TotemBarAnchor)
-- Reload: Edit Mode applies its saved layout after PLAYER_LOGIN.
assert(not MultiCastActionBarFrame.editModeNotifications or MultiCastActionBarFrame.editModeNotifications == 1)
MultiCastActionBarFrame:ApplySystemAnchor()
assert(MultiCastActionBarFrame.point[2] == TotemBarAnchor)
-- Native SetPointBase calls bypass the SetPoint override but are still caught.
MultiCastActionBarFrame:SetPointBase("TOPLEFT", ActionBarAnchor, "TOPLEFT", 0, 0)
assert(MultiCastActionBarFrame.point[2] == TotemBarAnchor)
local savedAnchor = TotemBarAnchor.point
fire("PLAYER_ENTERING_WORLD")
MultiCastActionBarFrame.point = {"TOPLEFT", ActionBarAnchor}
for _, callback in ipairs(timers) do callback() end
assert(MultiCastActionBarFrame.point[2] == TotemBarAnchor)
assert(TotemBarAnchor.point == savedAnchor, "do not reset the user's mover position")
-- Combat updates defer every geometry change until combat ends.
combat = true
MultiCastActionBarFrame.numActiveSlots = 4
hooks.MultiCastActionBarFrame_Update()
assert(TotemBarAnchor.width == 64 and TotemBarAnchor.events.PLAYER_REGEN_ENABLED)
combat = false
fire("PLAYER_REGEN_ENABLED")
assert(TotemBarAnchor.width == 132 and not TotemBarAnchor.events.PLAYER_REGEN_ENABLED)
-- Reloading in combat must also defer initialization and parenting.
setup("SHAMAN", true, true)
combat = true
fire("PLAYER_LOGIN")
assert(not MultiCastActionBarFrame.parent)
combat = false
fire("PLAYER_REGEN_ENABLED")
assert(MultiCastActionBarFrame.parent == TotemBarAnchor)
print("Totem bar tests passed")
