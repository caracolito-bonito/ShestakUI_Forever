local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true then return end
if not C_ActionBar or not C_Spell or type(canaccessvalue) ~= "function" then return end
if not ActionBarButtonEventsFrame then return end

----------------------------------------------------------------------------------------
--	Adapt only the numeric setter on registered action-button cooldown widgets.
--	Readable arguments are forwarded verbatim to the original native setter.
--	Only inaccessible timings use duration objects for the owning action/spell.
--	Leave global updaters, the Cooldown metatable, Clear, events and grid alone.
----------------------------------------------------------------------------------------
local wrapped = setmetatable({}, {__mode = "k"})

local function Wrap(button, cooldown, actionDuration, spellDuration)
	if not cooldown or wrapped[cooldown] then return end
	if cooldown.IsForbidden and cooldown:IsForbidden() then return end
	if type(cooldown.SetCooldown) ~= "function" or not cooldown.SetCooldownFromDurationObject then return end
	if type(actionDuration) ~= "function" or type(spellDuration) ~= "function" then return end

	local original = cooldown.SetCooldown
	cooldown.SetCooldown = function(self, ...)
		local start, duration, modRate = ...
		if canaccessvalue(start) and canaccessvalue(duration) and canaccessvalue(modRate) then
			return original(self, ...)
		end

		local id, getDuration
		if button.spellID then
			id, getDuration = button.spellID, spellDuration
		else
			id, getDuration = button.action, actionDuration
		end
		local object = id ~= nil and getDuration(id) or nil
		if object then
			self:SetCooldownFromDurationObject(object, true)
		else
			self:Clear()
		end
	end
	wrapped[cooldown] = true
end

local function PatchButton(button)
	if not button or (button.IsForbidden and button:IsForbidden()) then return end
	Wrap(button, button.cooldown, C_ActionBar.GetActionCooldownDuration, C_Spell.GetSpellCooldownDuration)
	Wrap(button, button.chargeCooldown, C_ActionBar.GetActionChargeDuration, C_Spell.GetSpellChargeDuration)
	Wrap(button, button.lossOfControlCooldown, C_ActionBar.GetActionLossOfControlCooldownDuration, C_Spell.GetSpellLossOfControlCooldownDuration)
end

ActionBarButtonEventsFrame:ForEachFrame(PatchButton)
hooksecurefunc(ActionBarButtonEventsFrame, "RegisterFrame", function(_, button)
	PatchButton(button)
end)
T:RegisterEvent("PLAYER_LOGIN", function()
	ActionBarButtonEventsFrame:ForEachFrame(PatchButton)
end)
