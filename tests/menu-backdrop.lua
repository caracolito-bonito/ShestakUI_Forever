-- Run from the repository root: luajit tests/menu-backdrop.lua
local module = "ShestakUI/Modules/Skins/Blizzard/MenuBackdrop.lua"
local frames, textures = {}, {}
local methods = {}
local function object(parent)
	return setmetatable({parent = parent, points = {}}, {__index = methods})
end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:EnableMouse(value) self.mouse = value end
function methods:GetFrameLevel() return self.level or 5 end
function methods:SetFrameLevel(value) self.level = value end
function methods:SetTexture(value) self.texture = value end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetHeight(value) assert(type(value) == "number"); self.height = value end
function methods:SetWidth(value) assert(type(value) == "number"); self.width = value end
function methods:GetWidth() error("must not read secret width") end
function methods:GetHeight() error("must not read secret height") end
function methods:GetSize() error("must not read secret dimensions") end
function methods:GetEffectiveScale() error("must not calculate texture coordinates") end
function methods:SetBackdrop() error("must not use BackdropTemplate") end
function methods:CreateTexture(_, layer)
	local texture = object(self)
	texture.layer = layer
	textures[#textures + 1] = texture
	return texture
end
function CreateFrame(_, name, parent, template)
	assert(not template, "must not inherit BackdropTemplate size-change handlers")
	local frame = object(parent)
	frame.name = name
	frames[#frames + 1] = frame
	return frame
end
local T = {screenHeight = 1080, mult = 1}
ShestakUI = {T, {media = {blank = "blank", border_color = {0.1, 0.2, 0.3, 1}, backdrop_color = {0.05, 0.05, 0.05, 1}, backdrop_alpha = 0.8}}, {}}
assert(loadfile(module))()
local menu = object()
local backdrop = T.CreateMenuBackdrop(menu)
assert(menu.backdrop == backdrop and backdrop.parent == menu)
assert(#frames == 3 and #textures == 13)
assert(backdrop.iborder.parent == backdrop and backdrop.oborder.parent == backdrop)
assert(backdrop.level == 4 and backdrop.oborder.level == 5)
for _, frame in ipairs(frames) do
	assert(frame.mouse == false and #frame.points == 2)
	assert(not rawget(frame, "OnSizeChanged") and not rawget(frame, "SetupTextureCoordinates"))
end
assert(textures[1].height == 1 and textures[3].width == 1)
assert(textures[5].color[4] == 0.8, "transparent fill must be retained")
backdrop:SetBackdropBorderColor(1, 0, 0, 0.5)
assert(textures[1].color[1] == 1 and textures[1].color[4] == 0.5)
backdrop:SetBackdropColor(0.2, 0.3, 0.4, 0.6)
assert(textures[5].color[4] == 0.6)
assert(T.CreateMenuBackdrop(menu) == backdrop and #frames == 3, "repeated skinning must reuse backdrop")
-- A low-level menu still needs a valid non-negative backdrop frame level.
local lowMenu = object()
lowMenu.level = 0
assert(T.CreateMenuBackdrop(lowMenu).level == 0)
print("Secret-safe menu backdrop tests passed")
