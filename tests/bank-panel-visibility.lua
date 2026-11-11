-- Run from the repository root: luajit tests/bank-panel-visibility.lua
local module = "ShestakUI/Modules/Blizzard/BankPanelVisibility.lua"
local hooks, reads
Enum = {BankType = {Character = 0, Account = 2}}
function hooksecurefunc(target, method, callback)
	hooks = hooks + 1
	local original = target[method]
	target[method] = function(self, ...)
		original(self, ...)
		callback(self, ...)
	end
end
local function setup(enabled)
	hooks, reads = 0, 0
	ShestakUI = {{}, {bag = {enable = enabled}}, {}}
	local panel = {shown = true, showCount = 0}
	function panel:IsShown() return self.shown end
	function panel:Show()
		assert(self.bankType ~= nil, "must set the bank type before showing")
		self.shown = true
		self.showCount = self.showCount + 1
	end
	function panel:Hide() self.shown = false end
	function panel:SetBankType(bankType) self.bankType = bankType end
	function panel:GetActiveBankType() return self.bankType end
	BankFrame = {BankPanel = panel, TabIDToBankType = {[1] = Enum.BankType.Character, [2] = Enum.BankType.Account}}
	function BankFrame:GetActiveBankType()
		return self.BankPanel:IsShown() and self.BankPanel:GetActiveBankType() or nil
	end
	function BankFrame:RefreshBagButtons()
		local bankType = self:GetActiveBankType()
		assert(bankType ~= nil, "FetchMaxNumBankTabs(nil)")
		reads = reads + 1
	end
	function BankFrame:SetTab(tabID)
		self.BankPanel:SetBankType(self.TabIDToBankType[tabID])
		self:RefreshBagButtons()
	end
	assert(loadfile(module))()
	return panel
end
local panel = setup(false)
assert(hooks == 0, "do not change the default bank when Stuffing is disabled")
panel:Hide()
assert(not pcall(BankFrame.SetTab, BankFrame, 1), "the mock must reproduce the original bug")
panel = setup(true)
assert(hooks == 1)
BankFrame:SetTab(1)
assert(panel.showCount == 0, "do not reshow an already shown panel")
for i = 1, 3 do
	panel:Hide() -- Stuffing:BANKFRAME_CLOSED
	BankFrame:SetTab(1)
	assert(panel:IsShown() and BankFrame:GetActiveBankType() == Enum.BankType.Character)
	panel:Hide()
	BankFrame:SetTab(2)
	assert(panel:IsShown() and BankFrame:GetActiveBankType() == Enum.BankType.Account)
end
assert(panel.showCount == 6 and reads == 7)
panel:Hide()
panel:SetBankType(nil)
assert(not panel:IsShown(), "do not invent a bank type or open an uninitialized panel")
print("Bank panel visibility tests passed")
