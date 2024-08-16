-- Required scripts
local slimeParts = require("lib.GroupIndex")(models.models.SlimeTaur)
local squapi     = require("lib.SquAPI")
local pose       = require("scripts.Posing")

-- Animation setup
local anims = animations["models.SlimeTaur"]

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getOffsetRot()
	end
	return calculateParentRot(parent) + m:getTrueRot()
	
end

-- Squishy smooth torso
squapi.smoothTorso(
	slimeParts.UpperBody,
	0.5, -- Strength Multiplier (0.5)
	0.4  -- Tilt (0.4)
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