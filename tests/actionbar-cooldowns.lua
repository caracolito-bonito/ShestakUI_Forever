-- Run from the repository root: luajit tests/actionbar-cooldowns.lua
local module = "ShestakUI/Modules/ActionBars/Cooldowns.lua"
local styled = {}
ShestakUI = {{SkinCooldown = function(cooldown, kind)
	assert(kind == "actionbar")
	styled[cooldown] = true
end}, {actionbar = {enable = true}}, {}}
local T = ShestakUI[1]
-- Styling must not install any hook or call the native cooldown setters.
function hooksecurefunc() error("unexpected hook") end
local nativeSetCooldown = function() error("unexpected cooldown value update") end
local cooldownMethods = {IsForbidden = function(self) return self.forbidden end, SetCooldown = nativeSetCooldown}
local function cooldown(forbidden)
	return setmetatable({forbidden = forbidden}, {__index = cooldownMethods})
end
assert(loadfile(module))()
local main, charge, loss = cooldown(), cooldown(), cooldown()
local button = {GetName = function() return "TestActionButton" end, cooldown = main, chargeCooldown = charge, lossOfControlCooldown = loss}
T.StyleActionButtonCooldowns(button)
assert(styled[main] and styled[charge] and styled[loss])
assert(main.SetCooldown == nativeSetCooldown and cooldownMethods.SetCooldown == nativeSetCooldown)
styled = {}
button.cooldown = nil -- sparse list: charge/loss must still be styled
T.StyleActionButtonCooldowns(button)
assert(styled[charge] and styled[loss])
local forbidden = cooldown(true)
button.Cooldown = forbidden
T.StyleActionButtonCooldowns(button)
assert(not styled[forbidden])
button.Cooldown = nil
_G.TestActionButtonCooldown = main
T.StyleActionButtonCooldowns(button)
assert(styled[main])
T.StyleActionButtonCooldowns({GetName = function() end}) -- anonymous button without cooldown
local file = assert(io.open("ShestakUI/Modules/ActionBars/Style.lua"))
local source = file:read("*a")
file:close()
assert(not source:find('hooksecurefunc(Cooldown_MT', 1, true), "shared cooldown metatable hook must stay removed")
print("Action-bar cooldown tests passed")
