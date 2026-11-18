local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true then return end
if not C_Spell or type(C_Spell.IsActiveSpell) ~= "function" or type(canaccessvalue) ~= "function" then return end

----------------------------------------------------------------------------------------
--	The gamepad class flyout tests IsActiveSpell to choose its icon. In combat
--	that boolean can be secret (e.g. Druid forms). Do not branch on it: return
--	nil so Blizzard's unchanged icon updater uses the generic flyout texture.
--	Only the class-button instance is patched; do not alter cast/cancel logic,
--	global spell APIs, other buttons, cooldowns or action-bar visibility.
----------------------------------------------------------------------------------------
local function GetActiveSpellID(button)
	if not button.isFlyoutAction then return end
	local onlyKnown = true
	for _, overrideSpellID in button:EnumFlyoutSlotInfo(onlyKnown) do
		local active = C_Spell.IsActiveSpell(overrideSpellID)
		if not canaccessvalue(active) then return nil end
		if active then return overrideSpellID end
	end
end

local classButtonNames = {
	GamepadMainActionBarFramePageUnitLeftClassAction = true,
	GamepadMainActionBarFramePageUnitRightClassAction = true,
}

local function PatchButton(button)
	if not button or (button.IsForbidden and button:IsForbidden()) then return end
	if type(button.GetActiveSpellID) ~= "function" or type(button.EnumFlyoutSlotInfo) ~= "function" then return end
	button.GetActiveSpellID = GetActiveSpellID
end

local function IsNamedClassButton(button)
	if not button or (button.IsForbidden and button:IsForbidden()) then return false end
	local name = button.GetName and button:GetName()
	return name and classButtonNames[name]
end

local function ForEachClassButton(callback)
	local seen = {}
	local function Visit(button)
		if not button or seen[button] or (button.IsForbidden and button:IsForbidden()) then return end
		seen[button] = true
		callback(button)
	end
	-- The XML's parentKey stores the root on UIParent; do not rely on a
	-- global alias or on globally exported names for its child buttons.
	local root = UIParent and UIParent.GamepadMainActionBarFrame or _G.GamepadMainActionBarFrame
	if root and root.PageUnit then
		Visit(root.PageUnit.LeftClassAction)
		Visit(root.PageUnit.RightClassAction)
	end
	for name in pairs(classButtonNames) do Visit(_G[name]) end
	if ActionBarButtonEventsFrame then
		ActionBarButtonEventsFrame:ForEachFrame(function(button)
			if IsNamedClassButton(button) then Visit(button) end
		end)
	end
end

local function PatchExisting()
	ForEachClassButton(PatchButton)
end
local function PatchAfterInitialization()
	PatchExisting()
	-- Class flyout setup is also scheduled on login. Run once after the
	-- remaining initialization callbacks, without installing an OnUpdate poll.
	C_Timer.After(0, PatchExisting)
end

if ActionBarButtonEventsFrame then
	hooksecurefunc(ActionBarButtonEventsFrame, "RegisterFrame", function(_, button)
		if IsNamedClassButton(button) then PatchButton(button) end
	end)
end
EventUtil.ContinueOnAddOnLoaded("Blizzard_GamepadActionBars", PatchAfterInitialization)
T:RegisterEvent("PLAYER_LOGIN", PatchAfterInitialization)
T:RegisterEvent("PLAYER_ENTERING_WORLD", PatchAfterInitialization)

-- Read-only installation check: no aura or secret spell state is queried.
SlashCmdList.SUIFLYOUT = function()
	local count = 0
	ForEachClassButton(function(button)
		count = count + 1
		print(button:GetName() or "Class flyout", "guard:", button.GetActiveSpellID == GetActiveSpellID)
	end)
	if count == 0 then print("ShestakUI: class flyout buttons not found") end
end
SLASH_SUIFLYOUT1 = "/suiflyout"
