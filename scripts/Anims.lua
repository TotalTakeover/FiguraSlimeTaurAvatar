-- Required scripts
require("lib.GSAnimBlend")
local parts     = require("lib.PartsAPI")
local ground    = require("lib.GroundCheck")
local itemCheck = require("lib.ItemCheck")
local pose      = require("scripts.Posing")
local color     = require("scripts.ColorProperties")

-- Animations setup
local anims = animations.SlimeTaur

function events.TICK()
	
	-- Player variables
	local vel = player:getVelocity()
	
	-- Animation variables
	local walking  = vel.xz:length() >= 0.05
	local onGround = ground()
	
	-- Animation states
	local walk = walking and onGround and not (pose.swim or pose.elytra or pose.crawl)
	
	-- Animations
	anims.walk:playing(walk)
	
end

function events.RENDER(delta, context)
	
	-- Player variables
	local vel = player:getVelocity()
	local dir = player:getLookDir()
	
	-- Directional velocity
	local fbVel = player:getVelocity():dot((dir.x_z):normalize())
	local lrVel = player:getVelocity():cross(dir.x_z:normalize()).y
	local udVel = player:getVelocity().y
	
	-- Animation speeds
	local moveSpeed = fbVel < -0.05 and -1 or 1
	anims.walk:speed(moveSpeed)
	
	-- Animation blends
	local moveBlend = pose.crouch and 0.5 or 1
	anims.walk:blend(moveBlend)
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.walk, ticks = {3,3} }
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	blend.anim:blendTime(table.unpack(blend.ticks)):onBlend("easeOutQuad")
end

-- Fixing spyglass jank
function events.RENDER(delta, context)
	
	local rot = vanilla_model.HEAD:getOriginRot()
	rot.x = math.clamp(rot.x, -90, 30)
	parts.group.Spyglass:rot(rot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end