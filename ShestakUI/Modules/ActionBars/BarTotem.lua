local T, C, L = unpack(ShestakUI)
if C.actionbar.enable ~= true or T.class ~= "SHAMAN" or not MultiCastActionBarFrame then return end

----------------------------------------------------------------------------------------
--	Shaman totem action bar (Forever)
--	Keep Blizzard's buttons, pages, bindings and flyout spell selection intact.
----------------------------------------------------------------------------------------
local bar = MultiCastActionBarFrame
-- Avoid Edit Mode's SetPoint override: it treats our anchor as a snapped
-- Blizzard system and notifies the layout manager while we are positioning.
local SetBarPoint = bar.SetPointBase or bar.SetPoint
local ClearBarPoints = bar.ClearAllPointsBase or bar.ClearAllPoints
local SetBarScale = bar.SetScaleBase or bar.SetScale
-- MultiCastSummonSpellButton_Update reanchors pages/slot 1 with 8px gaps
-- and 3px padding, even in combat. Match that native geometry rather than
-- trying to repair protected frame anchors after a set switch.
local size, spacing, padding = C.actionbar.button_size, 8, 3
local anchor = CreateFrame("Frame", "TotemBarAnchor", T_PetBattleFrameHider)
anchor:SetSize(size * 6 + spacing * 5 + padding * 2, size + padding * 2)
anchor:SetPoint("BOTTOMLEFT", ActionBarAnchor, "TOPLEFT", 0, size + C.actionbar.button_space * 2 + 18)
anchor:SetFrameStrata("LOW")

-- Blizzard can restore button art when switching sets, including in combat.
-- Keep this cosmetic pass separate from protected frame layout changes.
local function RefreshButtonArt(button)
	if not button or not button.totemSkinned then return end
	local name = button:GetName()
	local normal = button:GetNormalTexture()
	if normal then normal:SetAlpha(0) end
	if button.overlayTex then button.overlayTex:SetAlpha(0) end
	for _, key in ipairs({"NormalTexture", "Border", "Flash", "FloatingBG", "Highlight", "SlotArt", "SlotBackground", "NewActionTexture"}) do
		local texture = _G[name..key] or button[key]
		if texture then texture:SetAlpha(0) end
	end
	if button.IconMask then button.IconMask:Hide() end
end

local function StyleButton(button, buttonSize)
	if not button or button.totemSkinned then return end
	T.StyleActionButtonCooldowns(button)
	local name = button:GetName()
	button:SetSize(buttonSize, buttonSize)
	button:SetNormalTexture(0)
	button:SetTemplate("Transparent")
	if C.actionbar.classcolor_border then
		button:SetBackdropBorderColor(unpack(C.media.classborder_color))
	end

	-- Slot backgrounds use an atlas with element-specific coordinates. Keep those
	-- coordinates, so empty slots still identify their element.
	if button.background then button.background:SetInside() end

	local icon = _G[name.."Icon"] or button.icon
	if icon then icon:CropIcon() end
	for _, key in ipairs({"HotKey", "Count", "Name"}) do
		local text = _G[name..key]
		if text then
			text:SetFont(C.font.action_bars_font, C.font.action_bars_font_size, C.font.action_bars_font_style)
			text:SetShadowOffset(C.font.action_bars_font_shadow and 1 or 0, C.font.action_bars_font_shadow and -1 or 0)
			text:ClearAllPoints()
			if key == "HotKey" then
				text:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -1)
				if not C.actionbar.hotkey then text:Kill() end
			else
				text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 2)
				if key == "Name" and not C.actionbar.macro then text:Kill() end
			end
		end
	end
	button:StyleButton()
	button.totemSkinned = true
	RefreshButtonArt(button)
end

local function RefreshBarArt()
	for i = 1, NUM_MULTI_CAST_BUTTONS_PER_PAGE do
		RefreshButtonArt(_G["MultiCastSlotButton"..i])
	end
	for i = 1, NUM_MULTI_CAST_PAGES * NUM_MULTI_CAST_BUTTONS_PER_PAGE do
		RefreshButtonArt(_G["MultiCastActionButton"..i])
	end
	RefreshButtonArt(MultiCastSummonSpellButton)
	RefreshButtonArt(MultiCastRecallSpellButton)
end

local updating = false
local initialized = false
local function UpdateLayout()
	if not initialized or updating then return end
	RefreshBarArt()
	if InCombatLockdown() then
		anchor:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	updating = true

	ClearBarPoints(bar)
	SetBarPoint(bar, "BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 0)
	SetBarScale(bar, 1)

	local offset = padding + (MultiCastSummonSpellButton:IsShown() and size + spacing or 0)
	MultiCastSummonSpellButton:ClearAllPoints()
	MultiCastSummonSpellButton:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", padding, padding)
	for i = 1, NUM_MULTI_CAST_BUTTONS_PER_PAGE do
		local slot = _G["MultiCastSlotButton"..i]
		slot:ClearAllPoints()
		slot:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", offset + (i - 1) * (size + spacing), padding)
	end
	for page = 1, NUM_MULTI_CAST_PAGES do
		local frame = _G["MultiCastActionPage"..page]
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", offset, padding)
		frame:SetSize(size * NUM_MULTI_CAST_BUTTONS_PER_PAGE + spacing * (NUM_MULTI_CAST_BUTTONS_PER_PAGE - 1), size)
		for slot = 1, NUM_MULTI_CAST_BUTTONS_PER_PAGE do
			local button = _G["MultiCastActionButton"..((page - 1) * NUM_MULTI_CAST_BUTTONS_PER_PAGE + slot)]
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", (slot - 1) * (size + spacing), 0)
		end
	end

	local slots = bar.numActiveSlots or 0
	MultiCastRecallSpellButton:ClearAllPoints()
	MultiCastRecallSpellButton:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", offset + slots * (size + spacing), padding)
	local buttons = slots + (MultiCastSummonSpellButton:IsShown() and 1 or 0) + (MultiCastRecallSpellButton:IsShown() and 1 or 0)
	local width = math.max(size, buttons * (size + spacing) - spacing) + padding * 2
	bar:SetSize(width, size + padding * 2)
	anchor:SetSize(width, size + padding * 2)
	updating = false
end

anchor:RegisterEvent("PLAYER_LOGIN")
anchor:RegisterEvent("PLAYER_ENTERING_WORLD")
anchor:SetScript("OnEvent", function(self, event)
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	if event == "PLAYER_REGEN_ENABLED" then self:UnregisterEvent(event) end
	if not initialized then
		bar:SetParent(anchor)
		for i = 1, NUM_MULTI_CAST_BUTTONS_PER_PAGE do
			StyleButton(_G["MultiCastSlotButton"..i], size)
		end
		for i = 1, NUM_MULTI_CAST_PAGES * NUM_MULTI_CAST_BUTTONS_PER_PAGE do
			StyleButton(_G["MultiCastActionButton"..i], size)
		end
		StyleButton(MultiCastSummonSpellButton, size)
		StyleButton(MultiCastRecallSpellButton, size)
		initialized = true

		-- Blizzard repositions pages when summon spells are learned or changed.
		hooksecurefunc("MultiCastActionBarFrame_Update", UpdateLayout)
		hooksecurefunc("MultiCastActionButton_Update", RefreshButtonArt)
		hooksecurefunc("MultiCastSlotButton_Update", RefreshButtonArt)
		hooksecurefunc("MultiCastSummonSpellButton_Update", RefreshButtonArt)
		hooksecurefunc("MultiCastRecallSpellButton_Update", RefreshButtonArt)
		-- Restore our position after the complete Edit Mode anchor operation,
		-- not halfway through SetPointOverride and its layout notifications.
		if bar.ApplySystemAnchor then
			hooksecurefunc(bar, "ApplySystemAnchor", UpdateLayout)
		end
		hooksecurefunc(bar, bar.SetPointBase and "SetPointBase" or "SetPoint", function(_, _, relativeTo)
			if relativeTo ~= anchor then UpdateLayout() end
		end)
		MultiCastFlyoutFrame:HookScript("OnShow", function(self)
			for _, button in ipairs(self.buttons or {}) do
				StyleButton(button, 24)
			end
		end)
	end
	UpdateLayout()
	if event == "PLAYER_ENTERING_WORLD" then
		-- Let the remaining login handlers and restored frame positions settle.
		C_Timer.After(0, UpdateLayout)
	end
end)
