local T, C, L = unpack(ShestakUI)
local Mult = T.screenHeight > 1200 and T.Scale(1) or T.mult

----------------------------------------------------------------------------------------
--	Menu dimensions can be secret (e.g. a unit popup opened in combat).
--	BackdropTemplate computes texture coordinates from GetWidth/GetHeight in
--	Lua. Solid, anchored textures need no access to the menu's dimensions.
----------------------------------------------------------------------------------------
local function CreateSolidBorder(parent, name, inset, color)
	local border = CreateFrame("Frame", name, parent)
	border:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
	border:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
	border:EnableMouse(false)

	local edges = {}
	for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
		local edge = border:CreateTexture(nil, "BORDER")
		edge:SetTexture(C.media.blank)
		if side == "TOP" or side == "BOTTOM" then
			edge:SetPoint(side.."LEFT", border, side.."LEFT")
			edge:SetPoint(side.."RIGHT", border, side.."RIGHT")
			edge:SetHeight(Mult)
		else
			edge:SetPoint("TOP"..side, border, "TOP"..side)
			edge:SetPoint("BOTTOM"..side, border, "BOTTOM"..side)
			edge:SetWidth(Mult)
		end
		edges[#edges + 1] = edge
	end
	function border:SetBackdropBorderColor(r, g, b, a)
		for _, edge in ipairs(edges) do edge:SetVertexColor(r, g, b, a or 1) end
	end
	border:SetBackdropBorderColor(unpack(color))
	return border
end

function T.CreateMenuBackdrop(frame)
	if frame.backdrop then return frame.backdrop end
	local backdrop = CreateSolidBorder(frame, "$parentBackdrop", 0, C.media.border_color)
	backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
	local background = backdrop:CreateTexture(nil, "BACKGROUND")
	background:SetPoint("TOPLEFT", backdrop, "TOPLEFT", -Mult, Mult)
	background:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", Mult, -Mult)
	background:SetTexture(C.media.blank)
	function backdrop:SetBackdropColor(r, g, b, a)
		background:SetVertexColor(r, g, b, a or 1)
	end
	backdrop:SetBackdropColor(C.media.backdrop_color[1], C.media.backdrop_color[2], C.media.backdrop_color[3], C.media.backdrop_alpha)

	backdrop.iborder = CreateSolidBorder(backdrop, "$parentInnerBorder", Mult, C.media.backdrop_color)
	backdrop.oborder = CreateSolidBorder(backdrop, "$parentOuterBorder", -Mult, C.media.backdrop_color)
	backdrop.oborder:SetFrameLevel(backdrop:GetFrameLevel() + 1)
	frame.backdrop = backdrop
	return backdrop
end
