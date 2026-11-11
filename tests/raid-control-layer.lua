-- Run from the repository root: luajit tests/raid-control-layer.lua
local module = "ShestakUI/Modules/Misc/RaidUtility.lua"
local frames = {}
local methods = {}
local function noop() end
local function frame(name, parent)
	return setmetatable({name = name, parent = parent, scripts = {}, attributes = {}, refs = {}}, {__index = methods})
end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetFrameStrata(strata) self.strata = strata end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
function methods:CreatePanel(_, w, h) self:SetSize(w, h); self:SetFrameStrata("BACKGROUND") end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetFrameRef(name, value) self.refs[name] = value end
function methods:SetAttribute(name, value) self.attributes[name] = value end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:Show() self.hidden = false end
function methods:Hide() self.hidden = true end
function methods:CreateFontString() return frame() end
function methods:CreateTexture() return frame() end
for _, name in ipairs({"SetPoint", "SetFont", "SetJustifyH", "SetText", "SetTexture", "ClearAllPoints", "CreateBackdrop", "SetNormalTexture", "RegisterForClicks", "RegisterEvent", "UnregisterEvent"}) do methods[name] = noop end
function CreateFrame(_, name, parent)
	local value = frame(name, parent)
	frames[#frames + 1] = value
	if name then _G[name] = value end
	return value
end
function GetCVarBool() return false end
function UnitInRaid() return false end
function IsInInstance() return false, "none" end
function GetNumGroupMembers() return 2 end
function UnitIsGroupLeader() return true end
function UnitIsGroupAssistant() return false end
function InCombatLockdown() return false end
C_AddOns = {IsAddOnLoaded = function() return false end}
format = string.format
RAID_CONTROL, CLOSE = "Raid Control", "Close"
local C = {misc = {raid_tools = true}, media = {pixel_font_size = 8}, position = {raid_utility = {"TOP", {}, "TOP", -280, 1}}}
ShestakUI = {{}, C, {}}
T_PetBattleFrameHider = frame("Hider")
T_PetBattleFrameHider:SetFrameStrata("LOW")
assert(loadfile(module))()
assert(RaidUtilityPanel:GetFrameStrata() == "MEDIUM")
assert(RaidUtilityShowButton:GetFrameStrata() == "MEDIUM")
assert(RaidUtilityShowButton.parent == T_PetBattleFrameHider)
assert(RaidUtilityShowButton.mouse)
assert(RaidUtilityShowButton.refs.RaidUtilityPanel == RaidUtilityPanel)
assert(RaidUtilityShowButton.attributes._onclick:find('self:Hide()', 1, true))
for _, name in ipairs({"RaidUtilityCloseButton", "RaidUtilityRoleButton", "RaidUtilityReadyCheckButton", "RaidUtilityRaidControlButton"}) do
	assert(_G[name]:GetFrameStrata() == "MEDIUM", name)
	assert(_G[name].mouse)
end
-- Existing leader visibility logic must remain unchanged.
local leadership = frames[#frames]
leadership.scripts.OnEvent(leadership, "PLAYER_ENTERING_WORLD")
assert(not RaidUtilityShowButton.hidden and RaidUtilityPanel.hidden)
RaidUtilityPanel.toggled = true
leadership.scripts.OnEvent(leadership, "GROUP_ROSTER_UPDATE")
assert(RaidUtilityShowButton.hidden and not RaidUtilityPanel.hidden)
print("Raid control layer tests passed")
