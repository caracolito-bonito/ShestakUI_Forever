local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true then return end
if not C_ActionBar or not C_Spell or not ActionBarButtonEventsFrame then return end
if not ActionButton1Cooldown or not ActionButton1Cooldown.SetCooldownFromDurationObject then return end

----------------------------------------------------------------------------------------
--	Fix only the gamepad UpdateCooldown -> numeric ActionButton_UpdateCooldown
--	call path. Do not replace the shared updater, touch keyboard action buttons,
--	or change grid/empty-slot visibility, events, bindings or click casting.
----------------------------------------------------------------------------------------
local actionAPIs = {
	info = C_ActionBar.GetActionCooldown,
	charges = C_ActionBar.GetActionCharges,
	loss = C_ActionBar.GetActionLossOfControlCooldownInfo,
	duration = C_ActionBar.GetActionCooldownDuration,
	chargeDuration = C_ActionBar.GetActionChargeDuration,
	lossDuration = C_ActionBar.GetActionLossOfControlCooldownDuration,
}
local spellAPIs = {
	info = C_Spell.GetSpellCooldown,
	charges = C_Spell.GetSpellCharges,
	loss = C_Spell.GetSpellLossOfControlCooldownInfo,
	duration = C_Spell.GetSpellCooldownDuration,
	chargeDuration = C_Spell.GetSpellChargeDuration,
	lossDuration = C_Spell.GetSpellLossOfControlCooldownDuration,
}
for _, apis in ipairs({actionAPIs, spellAPIs}) do
	for _, key in ipairs({"info", "charges", "loss", "duration", "chargeDuration", "lossDuration"}) do
		if type(apis[key]) ~= "function" then return end
	end
end

local function SetOrClear(cooldown, getDuration, id, enabled)
	if not cooldown then return end
	if enabled then
		local duration = getDuration(id)
		if duration then
			cooldown:SetCooldownFromDurationObject(duration, true)
			return
		end
	end
	cooldown:Clear()
end

local function UpdateCooldown(button, eventSpellID)
	-- Preserve GamepadActionBarButtonFlyoutMixin's event matching semantics.
	local singleSpellID = button:GetSingleSpellID()
	if singleSpellID and singleSpellID ~= eventSpellID then return end

	local apis, id
	if button.spellID then
		apis, id = spellAPIs, button.spellID
	else
		apis, id = actionAPIs, button.action
	end
	if id == nil then
		for _, cooldown in pairs({button.cooldown, button.chargeCooldown, button.lossOfControlCooldown}) do
			cooldown:Clear()
		end
		return
	end

	local info = apis.info(id)
	local chargeInfo = apis.charges(id)
	local lossInfo = button.enableLOCCooldown and apis.loss(id) or nil
	-- Only NeverSecret boolean fields are inspected, never numeric timings.
	local replaceNormal = lossInfo and lossInfo.shouldReplaceNormalCooldown
	SetOrClear(button.lossOfControlCooldown, apis.lossDuration, id, lossInfo and lossInfo.isActive)
	SetOrClear(button.chargeCooldown, apis.chargeDuration, id, not replaceNormal and chargeInfo and chargeInfo.isActive)
	SetOrClear(button.cooldown, apis.duration, id, not replaceNormal and info and info.isActive)
end

local function PatchButton(button)
	if not button or (button.IsForbidden and button:IsForbidden()) then return end
	-- Both methods identify standard gamepad buttons, not regular action bars.
	if type(button.GetGamepadPageUnitSlotID) ~= "function" or type(button.GetSingleSpellID) ~= "function" then return end
	if type(button.UpdateCooldown) ~= "function" then return end
	button.UpdateCooldown = UpdateCooldown
end

ActionBarButtonEventsFrame:ForEachFrame(PatchButton)
hooksecurefunc(ActionBarButtonEventsFrame, "RegisterFrame", function(_, button)
	PatchButton(button)
end)
T:RegisterEvent("PLAYER_LOGIN", function()
	ActionBarButtonEventsFrame:ForEachFrame(PatchButton)
end)
