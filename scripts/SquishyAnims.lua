-- Required scripts
local slimeParts = require("lib.GroupIndex")(models.SlimeTaur)
local squapi     = require("lib.SquAPI")
local pose       = require("scripts.Posing")

-- Animation setup
local anims = animations.SlimeTaur

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getOffsetRot()
	end
	return calculateParentRot(parent) + m:getTrueRot()
	
end

-- Head table
local headParts = {
	
	slimeParts.UpperBody
	
}

-- Squishy smooth torso
local head = squapi.smoothHead:new(
	headParts,
	0.5,  -- Strength (0.5)
	0.4,  -- Tilt (0.4)
	1,    -- Speed (1)
	false -- Keep Original Head Pos (false)
)

-- Squishy crounch
squapi.crouch(anims.crouch)

function events.RENDER(delta, context)
	
	-- Offset smooth torso in various parts
	-- Note: acts strangely with `slimeParts.body` and when sleeping
	for _, group in ipairs(slimeParts.UpperBody:getChildren()) do
		if group ~= slimeParts.Body and not pose.sleep then
			group:rot(-calculateParentRot(group:getParent()))
		end
	end
	
end