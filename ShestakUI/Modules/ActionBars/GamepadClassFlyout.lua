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

local function PatchClassButton()
	local root = _G.GamepadMainActionBarFrame
	local button = root and root.PageUnit and root.PageUnit.LeftClassAction
	button = button or _G.GamepadMainActionBarFramePageUnitLeftClassAction
	if not button or (button.IsForbidden and button:IsForbidden()) then return end
	if type(button.GetActiveSpellID) ~= "function" or type(button.EnumFlyoutSlotInfo) ~= "function" then return end
	button.GetActiveSpellID = GetActiveSpellID
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_GamepadActionBars", PatchClassButton)
T:RegisterEvent("PLAYER_LOGIN", PatchClassButton)
