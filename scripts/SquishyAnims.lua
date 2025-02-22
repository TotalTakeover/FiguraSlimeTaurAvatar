-- Kills script if squAPI cannot be found
local s, squapi = pcall(require, "lib.SquAPI")
if not s then return {} end

-- Required scripts
local parts = require("lib.PartsAPI")
local lerp  = require("lib.LerpAPI")
local pose  = require("scripts.Posing")

-- Animation setup
local anims = animations.SlimeTaur

-- Config setup
config:name("SlimeTaur")
local armsMove = config:load("SquapiArmsMove") or false

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getOffsetRot()
	end
	return calculateParentRot(parent) + m:getOffsetRot()
	
end

-- Lerp tables
local leftArmLerp  = lerp:new(0.5, armsMove and 1 or 0)
local rightArmLerp = lerp:new(0.5, armsMove and 1 or 0)

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

-- Squishy vanilla arms
local leftArm = squapi.arm:new(
	parts.group.LeftArm,
	1,     -- Strength (1)
	false, -- Right Arm (false)
	true   -- Keep Position (false)
)

local rightArm = squapi.arm:new(
	parts.group.RightArm,
	1,    -- Strength (1)
	true, -- Right Arm (true)
	true  -- Keep Position (false)
)

-- Arm strength variables
local leftArmStrength  = leftArm.strength
local rightArmStrength = rightArm.strength

function events.TICK()
	
	-- Arm variables
	local handedness  = player:isLeftHanded()
	local activeness  = player:getActiveHand()
	local leftActive  = not handedness and "OFF_HAND" or "MAIN_HAND"
	local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
	local leftSwing   = player:getSwingArm() == leftActive
	local rightSwing  = player:getSwingArm() == rightActive
	local leftItem    = player:getHeldItem(not handedness)
	local rightItem   = player:getHeldItem(handedness)
	local using       = player:isUsingItem()
	local usingL      = activeness == leftActive and leftItem:getUseAction() or "NONE"
	local usingR      = activeness == rightActive and rightItem:getUseAction() or "NONE"
	local bow         = using and (usingL == "BOW" or usingR == "BOW")
	local crossL      = leftItem.tag and leftItem.tag["Charged"] == 1
	local crossR      = rightItem.tag and rightItem.tag["Charged"] == 1
	
	-- Arm movement overrides
	local armShouldMove = pose.swim or pose.elytra or pose.crawl or pose.climb
	
	-- Control targets based on variables
	leftArmLerp.target  = (armsMove or armShouldMove or leftSwing  or bow or ((crossL or crossR) or (using and usingL ~= "NONE"))) and 1 or 0
	rightArmLerp.target = (armsMove or armShouldMove or rightSwing or bow or ((crossL or crossR) or (using and usingR ~= "NONE"))) and 1 or 0
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local idleTimer   = world.getTime(delta)
	local idleRot     = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	local firstPerson = context == "FIRST_PERSON"
	
	-- Adjust arm strengths
	leftArm.strength  = leftArmStrength  * leftArmLerp.currPos
	rightArm.strength = rightArmStrength * rightArmLerp.currPos
	
	-- Adjust arm characteristics after applied by squapi
	parts.group.LeftArm
		:offsetRot(
			parts.group.LeftArm:getOffsetRot()
			+ ((-idleRot + (vanilla_model.BODY:getOriginRot() * 0.75)) * math.map(leftArmLerp.currPos, 0, 1, 1, 0))
			+ (parts.group.LeftArm:getAnimRot() * math.map(leftArmLerp.currPos, 0, 1, 0, -2))
		)
		:pos(parts.group.LeftArm:getPos() * vec(1, 1, -1))
		:visible(not firstPerson)
	
	parts.group.RightArm
		:offsetRot(
			parts.group.RightArm:getOffsetRot()
			+ ((idleRot + (vanilla_model.BODY:getOriginRot() * 0.75)) * math.map(rightArmLerp.currPos, 0, 1, 1, 0))
			+ (parts.group.RightArm:getAnimRot() * math.map(rightArmLerp.currPos, 0, 1, 0, -2))
		)
		:pos(parts.group.RightArm:getPos() * vec(1, 1, -1))
		:visible(not firstPerson)
	
	-- Set visible if in first person
	parts.group.LeftArmFP:visible(firstPerson)
	parts.group.RightArmFP:visible(firstPerson)
	
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

-- Arm movement toggle
function pings.setSquapiArmsMove(boolean)
	
	armsMove = boolean
	config:save("SquapiArmsMove", armsMove)
	
end

-- Sync variable
function pings.syncSquapi(a)
	
	armsMove = a
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local s, color = pcall(require, "scripts.ColorProperties")
if not s then color = {} end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncSquapi(armsMove)
	end
	
end

-- Table setup
local t = {}

-- Action
t.armsAct = action_wheel:newAction()
	:item(itemCheck("red_dye"))
	:toggleItem(itemCheck("rabbit_foot"))
	:onToggle(pings.setSquapiArmsMove)
	:toggled(armsMove)

-- Update action
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		t.armsAct
			:title(toJson
				{"",
				{text = "Arm Movement Toggle\n\n", bold = true, color = color.primary},
				{text = "Toggles the movement swing movement of the arms.\nActions are not effected.", color = color.secondary}}
			)
		
		for _, act in pairs(t) do
			act:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return action
return t