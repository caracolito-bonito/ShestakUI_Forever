local T, C, L = unpack(ShestakUI)
if C.bag.enable ~= true then return end

----------------------------------------------------------------------------------------
--	Stuffing hides BankPanel on BANKFRAME_CLOSED to prevent item-use taint.
--	On reopening, Forever's BankFrame:SetTab sets the bank type but does not
--	show the panel. GetActiveBankType then returns nil, and RefreshBagButtons
--	calls FetchMaxNumBankTabs(nil). Restore the panel after its type is set,
--	before SetTab continues refreshing the bank. Keep the close workaround.
----------------------------------------------------------------------------------------
hooksecurefunc(BankFrame.BankPanel, "SetBankType", function(self, bankType)
	if bankType ~= nil and not self:IsShown() then
		self:Show()
	end
end)
