-- Run from the repository root: luajit tests/hidden-unit-frame-text.lua
local module = "ShestakUI/Modules/Blizzard/HiddenUnitFrameText.lua"
local callback
local function text()
	return {SetText = function(self, value) self.value = value end, Hide = function(self) self.hidden = true end}
end
local function bar()
	return {TextString = text(), LeftText = text(), RightText = text()}
end
local health, mana, alternate
function PlayerFrame_GetHealthBar() return health end
function PlayerFrame_GetManaBar() return mana end
function PlayerFrame_GetAlternatePowerBar() return alternate end
local function setup(enabled, player, pet)
	callback = nil
	ShestakUI = {{RegisterEvent = function(_, event, handler)
		assert(event == "PLAYER_LOGIN")
		callback = handler
	end}, {unitframe = {enable = enabled}}, {}}
	oUF_Player, oUF_Pet = player and {} or nil, pet and {} or nil
	health, mana, alternate = bar(), bar(), bar()
	PetFrameHealthBar, PetFrameManaBar = bar(), bar()
	assert(loadfile(module))()
end
setup(false, true, true)
assert(not callback and health.TextString)
setup(true, false, false)
callback()
assert(health.TextString and mana.TextString and PetFrameHealthBar.TextString)
setup(true, true, false)
local oldText = health.TextString
callback()
assert(not health.TextString and not mana.TextString and not alternate.TextString)
assert(oldText.hidden and oldText.value == "")
assert(health.LeftText.hidden and health.RightText.hidden)
assert(PetFrameHealthBar.TextString, "do not change an unreplaced pet frame")
-- Model Blizzard's Show/HideStatusBarText -> UpdateTextString path. Any access
-- to cached secret values is an error, not just comparisons against them.
local secretReads = 0
health.GetValue = function() secretReads = secretReads + 1; error("secret read") end
local function UpdateTextString(self)
	if self.TextString then self:GetValue() end
end
local function ShowStatusBarText(self)
	if self.TextString then
		self.lockShow = (self.lockShow or 0) + 1
		UpdateTextString(self)
	end
end
ShowStatusBarText(health)
UpdateTextString(health)
assert(secretReads == 0)
setup(true, true, true)
alternate = nil
callback()
assert(not PetFrameHealthBar.TextString and not PetFrameManaBar.TextString)
callback() -- cleanup is idempotent
print("Hidden unit-frame text tests passed")
