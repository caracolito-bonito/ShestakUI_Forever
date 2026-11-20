local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true then return end

----------------------------------------------------------------------------------------
-- Core makes BagsBar transparent, but transparent children still receive mouse input.
-- Only suppress the hidden toolbar, not bag windows or the separate gamepad bag bar.
----------------------------------------------------------------------------------------
local queued, pending = false, false
local function DisableMouse(frame)
	if frame:IsForbidden() then return end
	frame:SetMouseClickEnabled(false)
	frame:SetMouseMotionEnabled(false)
	if GameTooltip and GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
	for _, child in ipairs({frame:GetChildren()}) do
		DisableMouse(child)
	end
end

local function RequestApply()
	if queued then return end
	queued = true
	C_Timer.After(0, function()
		queued = false
		if InCombatLockdown() then
			pending = true
			return
		end
		pending = false
		if BagsBar then DisableMouse(BagsBar) end
	end)
end

T:RegisterEvent("PLAYER_LOGIN", RequestApply)
T:RegisterEvent("PLAYER_ENTERING_WORLD", RequestApply)
T:RegisterEvent("PLAYER_REGEN_ENABLED", function()
	if pending then RequestApply() end
end)
EventUtil.ContinueOnAddOnLoaded("Blizzard_MainMenuBarBagButtons", RequestApply)
