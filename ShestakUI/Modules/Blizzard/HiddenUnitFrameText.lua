local T, C, L = unpack(ShestakUI)
if C.unitframe.enable ~= true then return end

----------------------------------------------------------------------------------------
--	Disable text updates on Blizzard unit frames replaced by ShestakUI.
--	Forever's CharacterFrame explicitly calls Show/HideStatusBarText even on
--	these disabled frames. Their cached health/power values can be secret.
--	TextStatusBar supports a missing TextString and then skips numeric updates.
----------------------------------------------------------------------------------------
local function DisableText(bar)
	if not bar then return end
	for _, key in ipairs({"TextString", "LeftText", "RightText"}) do
		local text = bar[key]
		if text then
			text:SetText("")
			text:Hide()
		end
	end
	bar.TextString = nil
end

T:RegisterEvent("PLAYER_LOGIN", function()
	-- Check the actual replacements as well as the setting: never disable text
	-- on Blizzard frames still in use (e.g. when another unit-frame addon loads).
	if oUF_Player then
		DisableText(PlayerFrame_GetHealthBar())
		DisableText(PlayerFrame_GetManaBar())
		DisableText(PlayerFrame_GetAlternatePowerBar())
	end
	if oUF_Pet then
		DisableText(PetFrameHealthBar)
		DisableText(PetFrameManaBar)
	end
end)
