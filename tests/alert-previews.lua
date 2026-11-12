-- Run from the repository root: luajit tests/alert-previews.lua
local file = assert(io.open("ShestakUI/Core/Commands.lua"))
local source = file:read("*a")
file:close()
local declarations = assert(source:match("(local function AddTestAlert.-)\nSLASH_TEST_ACHIEVEMENT1"))
local systems = {"AchievementAlertSystem", "CriteriaAlertSystem", "GuildChallengeAlertSystem", "InvasionAlertSystem", "WorldQuestCompleteAlertSystem", "GarrisonBuildingAlertSystem", "GarrisonTalentAlertSystem", "MoneyWonAlertSystem", "EntitlementDeliveredAlertSystem", "RafRewardDeliveredAlertSystem", "NewRecipeLearnedAlertSystem", "NewRuneforgePowerAlertSystem", "NewCosmeticAlertFrameSystem", "NewWarbandSceneAlertSystem", "HousingItemEarnedAlertFrameSystem"}
local calls, known
SOUNDKIT = {LFG_REWARDS = 1}
function PlaySound() end
local function setup(available, valid)
	calls, known = {}, valid
	SlashCmdList = {}
	C_Texture = {GetAtlasInfo = function() return {} end}
	AchievementFrame, AchievementFrame_LoadUI = nil, nil
	C_Garrison, C_LegendaryCrafting, C_TransmogCollection, C_WarbandScene, AlertFrameMixin = nil, nil, nil, nil, nil
	for _, name in ipairs(systems) do
		_G[name] = nil
		if available then
			local key = name
			_G[key] = {AddAlert = function(_, ...)
				calls[key] = {...}
				if key == "NewCosmeticAlertFrameSystem" then assert(known, "nil source info would crash Blizzard SetUp") end
			end}
		end
	end
	assert(loadstring(declarations))()
end
setup(false, false)
SlashCmdList.TEST_ACHIEVEMENT() -- APIs and alert subsystems absent
assert(not next(calls))
setup(true, false)
C_Garrison = {GetTalentInfo = function() end}
C_LegendaryCrafting = {GetRuneforgePowerInfo = function() end}
C_TransmogCollection = {GetSourceInfo = function() end}
C_WarbandScene = {GetWarbandSceneEntry = function() end}
AlertFrameMixin = {BuildQuestData = function() end}
SlashCmdList.TEST_ACHIEVEMENT()
for _, name in ipairs({"GarrisonTalentAlertSystem", "NewRuneforgePowerAlertSystem", "NewCosmeticAlertFrameSystem", "NewWarbandSceneAlertSystem", "WorldQuestCompleteAlertSystem"}) do assert(not calls[name]) end
assert(calls.HousingItemEarnedAlertFrameSystem, "invalid examples must not abort later previews")
setup(true, true)
local talent, quest = {icon = 1, treeID = 1}, {questID = 42114}
C_Garrison = {GetTalentInfo = function() return talent end}
C_LegendaryCrafting = {GetRuneforgePowerInfo = function() return {name = "Power", iconFileID = 1} end}
C_TransmogCollection = {GetSourceInfo = function(id) assert(id == 204); return {itemID = 123} end}
C_WarbandScene = {GetWarbandSceneEntry = function(id) assert(id == 1); return {name = "Scene", quality = 4} end}
AlertFrameMixin = {BuildQuestData = function() return quest end}
SlashCmdList.TEST_ACHIEVEMENT()
for _, name in ipairs(systems) do assert(calls[name], name.." should still preview valid data") end
assert(calls.GarrisonTalentAlertSystem[2] == talent)
assert(calls.WorldQuestCompleteAlertSystem[1] == quest)
calls = {}
C_TransmogCollection.GetSourceInfo = function() return {} end
SlashCmdList.TEST_ACHIEVEMENT()
assert(not calls.NewCosmeticAlertFrameSystem, "cosmetic preview requires an itemID")
assert(calls.NewWarbandSceneAlertSystem)
for _, missing in ipairs({"glow", "lightrays02", "divider"}) do
	calls = {}
	C_Texture.GetAtlasInfo = function(atlas)
		if atlas ~= "housing-item-toast-"..missing then return {} end
	end
	SlashCmdList.TEST_ACHIEVEMENT()
	assert(not calls.HousingItemEarnedAlertFrameSystem, "must not instantiate a template with missing atlas "..missing)
	assert(calls.MoneyWonAlertSystem, "other previews must remain available")
end
calls = {}
C_Texture = nil
SlashCmdList.TEST_ACHIEVEMENT()
assert(not calls.HousingItemEarnedAlertFrameSystem)
print("Alert preview data and atlas tests passed")
