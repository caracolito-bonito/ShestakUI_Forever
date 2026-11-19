-- Run from the repository root: luajit tests/real-links-colors.lua
local file = assert(io.open("ShestakUI/Modules/Chat/RealLinks.lua"))
local source = file:read("*a")
file:close()
local definition = assert(source:match("(local function GetLinkColor.-)\nlocal function MessageFilter"))
format = string.format
function string.split(separator, value)
	local result = {}
	for part in (value..separator):gmatch("(.-)"..separator) do result[#result + 1] = part end
	return unpack(result)
end
local color
function GetQuestDifficultyColor(level)
	assert(level == "60")
	return color
end
-- The removed Blizzard helper must not be needed by the quest link path.
ConvertRGBtoColorString = nil
local GetLinkColor = assert(loadstring(definition.."\nreturn GetLinkColor"))()
for _, case in ipairs({
	{{r = 1, g = 0, b = 0}, "|cffff0000"},
	{{r = 0, g = 1, b = 0}, "|cff00ff00"},
	{{r = 1, g = 0.82, b = 0}, "|cffffd100"},
	{{r = 0, g = 0, b = 0}, "|cff000000"},
}) do
	color = case[1]
	local result = GetLinkColor("quest:123:60")
	assert(result == case[2])
	assert(result:match("^|cff%x%x%x%x%x%x$"), "color codes must contain six hex digits, not spaces")
end
assert(GetLinkColor("quest:123") == "|cffffd100")
assert(GetLinkColor("spell:123") == "|cff71d5ff")
print("RealLinks quest color padding tests passed")
