local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true then return end
if type(ActionButton_UpdateCooldown) ~= "function" or not C_ActionBar or not C_Spell then return end
if not ActionButton1Cooldown or not ActionButton1Cooldown.SetCooldownFromDurationObject then return end

----------------------------------------------------------------------------------------
--	Forever's shared updater still sends secret start/duration/modRate numbers
--	to SetCooldown. Both keyboard and gamepad buttons use it. Draw cooldowns
--	from duration objects instead; do not alter click casting, event delivery,
--	button action IDs, or the shared Cooldown metatable.
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
-- Leave Blizzard's implementation intact on clients without the full API.
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

function ActionButton_UpdateCooldown(button)
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
	-- These booleans are documented NeverSecret. Never inspect or calculate
	-- with the numeric fields of the info tables or the duration objects.
	local replaceNormal = lossInfo and lossInfo.shouldReplaceNormalCooldown
	SetOrClear(button.lossOfControlCooldown, apis.lossDuration, id, lossInfo and lossInfo.isActive)
	SetOrClear(button.chargeCooldown, apis.chargeDuration, id, not replaceNormal and chargeInfo and chargeInfo.isActive)
	SetOrClear(button.cooldown, apis.duration, id, not replaceNormal and info and info.isActive)
end
