-- Run from the repository root: luajit tests/optional-ui-previews.lua
local file = assert(io.open("ShestakUI/Modules/Maps/ToggleMenu.lua"))
local source = file:read("*a"):gsub("^\239\187\191", "")
file:close()
-- Load the real menu declarations without instantiating the minimap UI.
local declarations = assert(source:match("^(.-)%-%- Definde toggle functions"))
local commands = {"RaidCD", "EnemyCD", "PulseCD", "TEST_UF", "TESTROLL", "alThreat", "DBMTEST", "TEST_EXTRABUTTON", "TEST_ACHIEVEMENT"}
local function setup(enabled)
	local C = {minimap = {enable = true, toggle_menu = true}, raidcooldown = {enable = enabled}, enemycooldown = {enable = enabled}, pulsecooldown = {enable = enabled}, unitframe = {enable = enabled}, loot = {rolllootframe = enabled}, threat = {enable = enabled}}
	ShestakUI = {{}, C, {}}
	SlashCmdList = {}
	assert(loadstring(declarations))()
	for _, entry in ipairs(C.togglemainmenu) do
		if entry.text == "Test UI" then return entry["function"] end
	end
	error("Test UI entry missing")
end
local preview = setup(true)
preview() -- no modules registered: must not error
local called = {}
for _, name in ipairs(commands) do
	local key = name
	SlashCmdList[key] = function() called[#called + 1] = key end
end
SlashCmdList.EnemyCD = nil -- current Midnight configuration
preview()
assert(#called == 8 and called[1] == "RaidCD" and called[2] == "PulseCD")
assert(called[8] == "TEST_ACHIEVEMENT", "missing EnemyCD must not abort later previews")
preview = setup(false)
called = {}
for _, name in ipairs(commands) do
	local key = name
	SlashCmdList[key] = function() called[#called + 1] = key end
end
preview()
assert(#called == 3 and called[1] == "DBMTEST", "preserve feature setting gates")
preview = setup(true)
SlashCmdList.RaidCD = function() error("real preview error") end
local ok, err = pcall(preview)
assert(not ok and err:find("real preview error"), "do not suppress errors inside registered previews")
print("Optional UI preview command tests passed")
