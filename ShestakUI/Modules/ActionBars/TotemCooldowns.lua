local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true or T.class ~= "SHAMAN" then return end
if not MultiCastSpellButton_UpdateCooldown or not C_Spell.GetSpellCooldownDuration then return end
if not MultiCastSummonSpellButtonCooldown or not MultiCastSummonSpellButtonCooldown.SetCooldownFromDurationObject then return end

----------------------------------------------------------------------------------------
--	Forever's summon/recall buttons still use GetSpellCooldown -> CooldownFrame_Set.
--	In restricted combat that helper compares secret start/duration numbers.
--	Use the duration-object API instead, without inspecting cooldown values or
--	changing the shared CooldownFrame_Set/SetCooldown paths for other frames.
----------------------------------------------------------------------------------------
function MultiCastSpellButton_UpdateCooldown(button)
	local cooldown = _G[button:GetName().."Cooldown"]
	local duration = C_Spell.GetSpellCooldownDuration(button.spellId)
	if duration then
		cooldown:SetDrawEdge(false)
		cooldown:SetCooldownFromDurationObject(duration, true)
	else
		cooldown:Clear()
	end
end
