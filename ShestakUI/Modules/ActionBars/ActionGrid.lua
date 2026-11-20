local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true or C.actionbar.show_grid ~= true then return end

----------------------------------------------------------------------------------------
-- Keep ShestakUI's empty slots independent of Blizzard's per-bar Edit Mode setting.
----------------------------------------------------------------------------------------
local prefixes = {
	"ActionButton", "MultiBarBottomLeftButton", "MultiBarLeftButton", "MultiBarRightButton",
	"MultiBarBottomRightButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
}
local handler = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
local events = CreateFrame("Frame")
local queued = false

-- Use a private reason bit, not Blizzard's CVAR (1), drag (2) or spellbook (4)
-- reasons. Native SetShowGrid can clear those bits without clearing our preference.
-- Execute is the normal secure-handler mechanism also used by Bar1's page driver:
-- only public UI attributes are read, and changes are made outside combat.
local apply = [[
	local reason = 1048576
	for i = 1, self:GetAttribute("button-count") do
		local button = self:GetFrameRef("button"..i)
		local grid = button:GetAttribute("showgrid") or 0
		if grid % (reason * 2) < reason then
			button:SetAttribute("showgrid", grid + reason)
		end
		if not button:GetAttribute("statehidden") then
			button:Show(true) -- do not change the secure statehidden attribute
		end
	end
]]

local function RequestApply()
	if queued then return end
	queued = true
	-- Run after the other login/world-entry handlers have initialized the bars.
	C_Timer.After(0, function()
		queued = false
		if InCombatLockdown() then
			events:RegisterEvent("PLAYER_REGEN_ENABLED")
			return
		end

		local count = 0
		for bar, prefix in ipairs(prefixes) do
			if bar <= 6 or C.actionbar["bar"..bar.."_enable"] == true then
				local limit = 12
				if C.actionbar.editor or bar > 6 then
					limit = math.min(12, C.actionbar["bar"..bar.."_num"] or 12)
				end
				for i = 1, limit do
					local button = _G[prefix..i]
					if button and not button:IsForbidden() then
						count = count + 1
						handler:SetFrameRef("button"..count, button)
					end
				end
			end
		end
		handler:SetAttribute("button-count", count)
		handler:Execute(apply)
	end)
end

events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_REGEN_ENABLED" then self:UnregisterEvent(event) end
	RequestApply()
end)
