-- Gather pehkui scales
local function scale()
	
	-- Variables
	local nbt   = player:getNbt()
	local types = nbt["pehkui:scale_data_types"]
	
	local playerScale = (
		types and
		types["pehkui:base"] and
		types["pehkui:base"]["scale"] or 1)
	local width = (
		types and
		types["pehkui:width"] and
		types["pehkui:width"]["scale"] or 1)
	local modelWidth = (
		types and
		types["pehkui:model_width"] and
		types["pehkui:model_width"]["scale"] or 1)
	local height = (
		types and
		types["pehkui:height"] and
		types["pehkui:height"]["scale"] or 1)
	local modelHeight = (
		types and
		types["pehkui:model_height"] and
		types["pehkui:model_height"]["scale"] or 1)
	
	return vec(width * modelWidth, height * modelHeight, width * modelWidth) * playerScale
	
end

return scale