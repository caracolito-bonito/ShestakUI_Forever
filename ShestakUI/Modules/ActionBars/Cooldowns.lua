local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true then return end

----------------------------------------------------------------------------------------
--	Style action-button cooldowns without hooking the shared Cooldown metatable.
--	Blizzard must retain its native execution path when applying secret values.
----------------------------------------------------------------------------------------
function T.StyleActionButtonCooldowns(button)
	local name = button:GetName()
	local cooldowns = {
		button.cooldown or button.Cooldown or (name and _G[name.."Cooldown"]),
		button.chargeCooldown,
		button.lossOfControlCooldown,
	}
	-- Optional entries can leave holes, so do not use ipairs here.
	for _, cooldown in pairs(cooldowns) do
		if not cooldown:IsForbidden() then
			T.SkinCooldown(cooldown, "actionbar")
		end
	end
end
