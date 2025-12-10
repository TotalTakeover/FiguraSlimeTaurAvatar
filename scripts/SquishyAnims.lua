-- Kills script if squAPI cannot be found
local s, squapi = pcall(require, "lib.SquAPI")
if not s then return {} end

-- Required script
local parts = require("lib.PartsAPI")

-- Animation setup
local anims = animations.SlimeTaur

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getOffsetRot()
	end
	return calculateParentRot(parent) + m:getOffsetRot()
	
end

-- Head table
local headParts = {
	
	parts.group.UpperBody_Wobble
	
}

-- Squishy smooth torso
local head = squapi.smoothHead:new(
	headParts,
	0.5,  -- Strength (0.5)
	0.4,  -- Tilt (0.4)
	1,    -- Speed (1)
	false -- Keep Original Head Pos (false)
)

function events.RENDER(delta, context)
	
	-- Set upperbody to offset rot and crouching pivot point
	parts.group.UpperBody_Wobble:rot(-parts.group.LowerBody:getRot())
	
	-- Offset smooth torso in various parts
	-- Note: acts strangely with `parts.group.body`
	for _, group in ipairs(parts.group.UpperBody_Wobble:getChildren()) do
		if group ~= parts.group.Body then
			group:rot(-calculateParentRot(group:getParent()))
		end
	end
	
end