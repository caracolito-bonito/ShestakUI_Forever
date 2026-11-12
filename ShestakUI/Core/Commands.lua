local T, C, L = unpack(ShestakUI)

----------------------------------------------------------------------------------------
--	Slash commands
----------------------------------------------------------------------------------------
SlashCmdList.RELOADUI = function() ReloadUI() end
SLASH_RELOADUI1 = "/rl"
SLASH_RELOADUI2 = "/кд"
SLASH_RELOADUI3 = "//"
SLASH_RELOADUI4 = "/."

SlashCmdList.RCSLASH = function() C_PartyInfo.DoReadyCheck() end
SLASH_RCSLASH1 = "/rc"
SLASH_RCSLASH2 = "/кс"

SlashCmdList.TICKET = function() ToggleHelpFrame() end
SLASH_TICKET1 = "/gm"
SLASH_TICKET2 = "/гм"
SLASH_TICKET3 = "/пь"

SlashCmdList.JOURNAL = function() ToggleEncounterJournal() end
SLASH_JOURNAL1 = "/ej"
SLASH_JOURNAL2 = "/уо"

SlashCmdList.ROLECHECK = function() InitiateRolePoll() end
SLASH_ROLECHECK1 = "/role"
SLASH_ROLECHECK2 = "/кщду"

SlashCmdList.CLEARCOMBAT = function() C_CombatLog.ClearEntries() end
SLASH_CLEARCOMBAT1 = "/clc"
SLASH_CLEARCOMBAT2 = "/сдс"

----------------------------------------------------------------------------------------
--	Description of the slash commands
----------------------------------------------------------------------------------------
SlashCmdList.UIHELP = function()
	for _, v in ipairs(L_SLASHCMD_HELP) do print("|cffffff00"..("%s"):format(tostring(v)).."|r") end
end
SLASH_UIHELP1 = "/uihelp"
SLASH_UIHELP2 = "/helpui"
SLASH_UIHELP3 = "/гшрудз"

----------------------------------------------------------------------------------------
--	Enable/Disable addons
----------------------------------------------------------------------------------------
SlashCmdList.DISABLE_ADDON = function(addon)
	local _, _, _, _, _, reason = C_AddOns.GetAddOnInfo(addon)
	if reason ~= "MISSING" then
		C_AddOns.DisableAddOn(addon)
		ReloadUI()
	else
		print("|cffffff00"..L_TOGGLE_ADDON.."'"..addon.."'"..L_TOGGLE_NOT_FOUND.."|r")
	end
end
SLASH_DISABLE_ADDON1 = "/dis"
SLASH_DISABLE_ADDON2 = "/disable"

SlashCmdList.ENABLE_ADDON = function(addon)
	local _, _, _, _, _, reason = C_AddOns.GetAddOnInfo(addon)
	if reason ~= "MISSING" then
		C_AddOns.EnableAddOn(addon)
		C_AddOns.LoadAddOn(addon)
		ReloadUI()
	else
		print("|cffffff00"..L_TOGGLE_ADDON.."'"..addon.."'"..L_TOGGLE_NOT_FOUND.."|r")
	end
end
SLASH_ENABLE_ADDON1 = "/en"
SLASH_ENABLE_ADDON2 = "/enable"

SlashCmdList.ONLY_UI = function()
	for i = 1, C_AddOns.GetNumAddOns() do
		local name = C_AddOns.GetAddOnInfo(i)
		if name ~= "ShestakUI" and name ~= "ShestakUI_Config" and name ~= "!BaudErrorFrame" and C_AddOns.GetAddOnEnableState(T.name, name) == 2 then
			C_AddOns.DisableAddOn(name, T.name)
		end
	end
	ReloadUI()
end
SLASH_ONLY_UI1 = "/onlyui"

----------------------------------------------------------------------------------------
--	Disband party or raid(by Monolit)
----------------------------------------------------------------------------------------
local function DisbandRaidGroup()
	if InCombatLockdown() then return end
	if UnitInRaid("player") then
		T.SendChatMessage(L_INFO_DISBAND, "RAID")
		for i = 1, GetNumGroupMembers() do
			local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			if online and name ~= T.name then
				C_PartyInfo.UninviteUnit(name)
			end
		end
	else
		T.SendChatMessage(L_INFO_DISBAND, "PARTY")
		for i = MAX_PARTY_MEMBERS, 1, -1 do
			if GetNumGroupMembers(i) then
				C_PartyInfo.UninviteUnit(UnitName("party"..i))
			end
		end
	end
	C_PartyInfo.LeaveParty()
end

StaticPopupDialogs.DISBAND_RAID = {
	text = L_POPUP_DISBAND_RAID,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = DisbandRaidGroup,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = true,
	preferredIndex = 5,
}

SlashCmdList.GROUPDISBAND = function()
	StaticPopup_Show("DISBAND_RAID")
end
SLASH_GROUPDISBAND1 = "/rd"
SLASH_GROUPDISBAND2 = "/кв"

----------------------------------------------------------------------------------------
--	Convert party to raid
----------------------------------------------------------------------------------------
SlashCmdList.PARTYTORAID = function()
	if GetNumGroupMembers() > 0 then
		if UnitInRaid("player") and (UnitIsGroupLeader("player")) then
			C_PartyInfo.ConvertToParty()
		elseif UnitInParty("player") and (UnitIsGroupLeader("player")) then
			C_PartyInfo.ConvertToRaid()
		end
	else
		print("|cffffff00"..ERR_NOT_IN_GROUP.."|r")
	end
end
SLASH_PARTYTORAID1 = "/toraid"
SLASH_PARTYTORAID2 = "/toparty"
SLASH_PARTYTORAID3 = "/convert"
SLASH_PARTYTORAID4 = "/сщтмуке"

----------------------------------------------------------------------------------------
--	Instance teleport
----------------------------------------------------------------------------------------
SlashCmdList.INSTTELEPORT = function()
	local inInstance = IsInInstance()
	if inInstance then
		LFGTeleport(true)
	else
		LFGTeleport()
	end
end
SLASH_INSTTELEPORT1 = "/teleport"
SLASH_INSTTELEPORT2 = "/еудузщке"

----------------------------------------------------------------------------------------
--	Spec switching(by Monolit)
----------------------------------------------------------------------------------------
SlashCmdList.SPEC = function(spec)
	local canUse, failureReason = C_SpecializationInfo.CanPlayerUseTalentSpecUI()
	if canUse then
		if C_SpecializationInfo.GetSpecialization() ~= tonumber(spec) then
			C_SpecializationInfo.SetSpecialization(spec)
		end
	else
		print("|cffffff00"..failureReason.."|r")
	end
end
SLASH_SPEC1 = "/ss"
SLASH_SPEC2 = "/spec"
SLASH_SPEC3 = "/ыы"

----------------------------------------------------------------------------------------
--	Get target NPC name and ID
----------------------------------------------------------------------------------------
SlashCmdList.NPCID = function()
	local name = UnitName("target")
	local unitGUID = UnitGUID("target")
	local id = unitGUID and select(6, strsplit('-', unitGUID))
	if id then
		print(name..": "..id)
	end
end
SLASH_NPCID1 = "/getid"

----------------------------------------------------------------------------------------
--	Demo mode for DBM
----------------------------------------------------------------------------------------
SlashCmdList.DBMTEST = function() if C_AddOns.IsAddOnLoaded("DBM-Core") then DBM:DemoMode() end end
SLASH_DBMTEST1 = "/dbmtest"
SLASH_DBMTEST2 = "/виьеуые"

----------------------------------------------------------------------------------------
--	Command to show frame you currently have mouseovered
----------------------------------------------------------------------------------------
SlashCmdList.FRAME = function(arg)
	if arg ~= "" then
		arg = _G[arg]
	else
		local frames = GetMouseFoci()
		arg = frames and frames[1]
	end
	if arg ~= nil then _G.FRAME = arg end
	if arg ~= nil and not arg:IsForbidden() and arg:GetName() ~= nil then
		local point, relativeTo, relativePoint, xOfs, yOfs = arg:GetPoint()
		print("|cffCC0000--------------------------------------------------------------------|r")
		print("Name: |cffFFD100"..arg:GetName().."|r")
		if arg:GetParent() and arg:GetParent():GetName() then
			print("Parent: |cffFFD100"..arg:GetParent():GetName().."|r")
		end

		print("Width: |cffFFD100"..format("%.2f", arg:GetWidth()).."|r")
		print("Height: |cffFFD100"..format("%.2f", arg:GetHeight()).."|r")
		print("Strata: |cffFFD100"..arg:GetFrameStrata().."|r")
		print("Level: |cffFFD100"..arg:GetFrameLevel().."|r")

		if relativeTo and relativeTo:GetName() then
			print('Point: |cffFFD100 "'..point..'", '..relativeTo:GetName()..', "'..relativePoint..'"'.."|r")
		end
		if xOfs then
			print("X: |cffFFD100"..format("%.2f", xOfs).."|r")
		end
		if yOfs then
			print("Y: |cffFFD100"..format("%.2f", yOfs).."|r")
		end
		print("|cffCC0000--------------------------------------------------------------------|r")
	elseif arg == nil then
		print("Invalid frame name")
	else
		print("Could not find frame info")
	end
end
SLASH_FRAME1 = "/frame"
SLASH_FRAME2 = "/акфьу"

----------------------------------------------------------------------------------------
--	Print /framestack info in chat
----------------------------------------------------------------------------------------
SlashCmdList["FRAMELIST"] = function(msg)
	if not FrameStackTooltip then
		C_AddOns.LoadAddOn("Blizzard_DebugTools")
	end

	local isPreviouslyShown = FrameStackTooltip:IsShown()
	if not isPreviouslyShown then
		if msg == tostring(true) then
			FrameStackTooltip_Toggle(true, true, true)
		else
			FrameStackTooltip_Toggle(false, true, true)
		end
	end

	print("|cffCC0000--------------------------------------------------------------------|r")
	for i = 2, FrameStackTooltip:NumLines() do
		local text = _G["FrameStackTooltipTextLeft"..i]:GetText()
		-- if text and text ~= "" then
			local r, g, b = _G["FrameStackTooltipTextLeft"..i]:GetTextColor()
			if canaccessvalue(r) then
				text = format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
			end
			print(text)
		-- end
	end
	print("|cffCC0000--------------------------------------------------------------------|r")

	FrameStackTooltip_Toggle()
	SlashCmdList.COPY_CHAT()
end
SLASH_FRAMELIST1 = "/framelist"
SLASH_FRAMELIST2 = "/акфьудшые"
SLASH_FRAMELIST3 = "/fl"
SLASH_FRAMELIST4 = "/ад"

----------------------------------------------------------------------------------------
--	Allow to copy frame name via chat
----------------------------------------------------------------------------------------
local function OnMouseDown(self, button)
	if button == "MiddleButton" or button == "RightButton" then
		local text = self.Text:GetText()
		print(text)
		if CopyFrame and CopyFrame:IsShown() then
			SlashCmdList.COPY_CHAT()
			SlashCmdList.COPY_CHAT()
		else
			SlashCmdList.COPY_CHAT()
		end
		if FrameStackTooltip:IsShown() then
			FrameStackTooltip_Toggle()
		end
	else
		_G.TableAttributeDisplayValueButton_OnMouseDown(self)
	end
end

local function UpdateLines(self)
	local scrollFrame = self.LinesScrollFrame or _G.TableAttributeDisplay.LinesScrollFrame -- tinspect, or fstack ctrl
	if not scrollFrame then return end
	for _, child in next, { scrollFrame.LinesContainer:GetChildren() } do
		if child.ValueButton and child.ValueButton:GetScript("OnMouseDown") ~= OnMouseDown then
			child.ValueButton:SetScript("OnMouseDown", OnMouseDown)
		end
	end
end

local event = "ADDON_LOADED"
local function Setup(frame)
	if frame.Registered then return end

	local debugTools = C_AddOns.IsAddOnLoaded("Blizzard_DebugTools")
	if debugTools then
		hooksecurefunc(_G.TableInspectorMixin, "RefreshAllData", UpdateLines) -- /tinspect
		hooksecurefunc(_G.TableAttributeDisplay.dataProviders[2], "RefreshData", UpdateLines) -- fstack ctrl
		frame.Registered = true

		if frame:IsEventRegistered(event) then
			frame:UnregisterEvent(event)
		end
	elseif not frame:IsEventRegistered(event) then
		frame:RegisterEvent(event)
	end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", Setup)
Setup(frame)

----------------------------------------------------------------------------------------
--	Frame Stack on Cyrillic
----------------------------------------------------------------------------------------
SlashCmdList.FSTACK = function()
	C_AddOns.LoadAddOn("Blizzard_DebugTools")
	FrameStackTooltip_Toggle(false, true, true)
end
SLASH_FSTACK1 = "/аыефсл"
SLASH_FSTACK2 = "/fs"
SLASH_FSTACK3 = "/аы"
SLASH_FRAMESTK1 = nil -- fix LFGFilter

----------------------------------------------------------------------------------------
--	Clear chat
----------------------------------------------------------------------------------------
SlashCmdList.CLEAR_CHAT = function()
	for i = 1, Constants.ChatFrameConstants.MaxChatWindows do
		_G[format("ChatFrame%d", i)]:Clear()
	end
end
SLASH_CLEAR_CHAT1 = "/clear"
SLASH_CLEAR_CHAT2 = "/сдуфк"

----------------------------------------------------------------------------------------
--	Test Blizzard Alerts
----------------------------------------------------------------------------------------
local function AddTestAlert(system, ...)
	if system and type(system.AddAlert) == "function" then system:AddAlert(...) end
end

SlashCmdList.TEST_ACHIEVEMENT = function()
	PlaySound(SOUNDKIT.LFG_REWARDS)
	if not AchievementFrame and AchievementFrame_LoadUI then
		AchievementFrame_LoadUI()
	end
	AddTestAlert(AchievementAlertSystem, 112)
	AddTestAlert(CriteriaAlertSystem, 9023, "Doing great!")
	AddTestAlert(GuildChallengeAlertSystem, 3, 2, 5)
	AddTestAlert(InvasionAlertSystem, 678, DUNGEON_FLOOR_THENEXUS1, true, 1, 1)
	if WorldQuestCompleteAlertSystem and AlertFrameMixin and AlertFrameMixin.BuildQuestData then
		local questData = AlertFrameMixin:BuildQuestData(42114)
		if questData then AddTestAlert(WorldQuestCompleteAlertSystem, questData) end
	end
	AddTestAlert(GarrisonBuildingAlertSystem, GARRISON_CACHE)
	local talent = C_Garrison and C_Garrison.GetTalentInfo and C_Garrison.GetTalentInfo(370)
	if talent then AddTestAlert(GarrisonTalentAlertSystem, 3, talent) end
	AddTestAlert(MoneyWonAlertSystem, 81500)
	AddTestAlert(EntitlementDeliveredAlertSystem, "", "Interface\\Icons\\Ability_pvp_gladiatormedallion", TRINKET0SLOT, 214)
	AddTestAlert(RafRewardDeliveredAlertSystem, "", "Interface\\Icons\\Ability_pvp_gladiatormedallion", TRINKET0SLOT, 214, nil, 2)
	AddTestAlert(NewRecipeLearnedAlertSystem, 204)

	-- Retail example IDs are not necessarily present in Forever. Validate
	-- their data before enqueueing: Blizzard's setup functions dereference it.
	local power = C_LegendaryCrafting and C_LegendaryCrafting.GetRuneforgePowerInfo and C_LegendaryCrafting.GetRuneforgePowerInfo(204)
	if power then AddTestAlert(NewRuneforgePowerAlertSystem, 204) end
	local source = C_TransmogCollection and C_TransmogCollection.GetSourceInfo and C_TransmogCollection.GetSourceInfo(204)
	if source and source.itemID then AddTestAlert(NewCosmeticAlertFrameSystem, 204) end
	local scene = C_WarbandScene and C_WarbandScene.GetWarbandSceneEntry and C_WarbandScene.GetWarbandSceneEntry(1)
	if scene then AddTestAlert(NewWarbandSceneAlertSystem, 1) end
	AddTestAlert(HousingItemEarnedAlertFrameSystem, {itemType = 2, itemName = "Test"})
end
SLASH_TEST_ACHIEVEMENT1 = "/tach"
SLASH_TEST_ACHIEVEMENT2 = "/ефср"

----------------------------------------------------------------------------------------
--	Test Blizzard Extra Action Button
----------------------------------------------------------------------------------------
SlashCmdList.TEST_EXTRABUTTON = function()
	if ExtraActionBarFrame:IsShown() then
		ExtraActionBarFrame:Hide()
	else
		ExtraActionBarFrame:Show()
		ExtraActionBarFrame:SetAlpha(1)
		ExtraActionButton1:Show()
		ExtraActionButton1:SetAlpha(1)
		ExtraActionButton1.icon:SetTexture("Interface\\Icons\\spell_deathknight_breathofsindragosa")
		ExtraActionButton1.icon:Show()
		ExtraActionButton1.icon:SetAlpha(1)
		ExtraActionButton1.Count:SetText("2")
	end
end
SLASH_TEST_EXTRABUTTON1 = "/teb"
SLASH_TEST_EXTRABUTTON2 = "/еуи"

----------------------------------------------------------------------------------------
--	Grid on screen
----------------------------------------------------------------------------------------
local grid
SlashCmdList.GRIDONSCREEN = function(msg)
	if grid then
		grid:Hide()
		grid = nil
	else
		if msg and msg == "hide" then return end
		grid = CreateFrame("Frame", nil, UIParent)
		grid:SetAllPoints(UIParent)
		local width = GetScreenWidth() / 128
		local height = GetScreenHeight() / 72
		for i = 0, 128 do
			local texture = grid:CreateTexture(nil, "BACKGROUND")
			if i == 64 then
				texture:SetColorTexture(1, 0, 0, 0.8)
			else
				texture:SetColorTexture(0.01, 0.01, 0.01, 0.8)
			end
			texture:SetPoint("TOPLEFT", grid, "TOPLEFT", i * width - 1, 0)
			texture:SetPoint("BOTTOMRIGHT", grid, "BOTTOMLEFT", i * width, 0)
		end
		for i = 0, 72 do
			local texture = grid:CreateTexture(nil, "BACKGROUND")
			if i == 36 then
				texture:SetColorTexture(1, 0, 0, 0.8)
			else
				texture:SetColorTexture(0.01, 0.01, 0.01, 0.8)
			end
			texture:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -i * height)
			texture:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -i * height - 1)
		end
	end
end
SLASH_GRIDONSCREEN1 = "/align"
SLASH_GRIDONSCREEN2 = "/фдшпт"