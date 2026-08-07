-- Required scripts
require("lib.GSAnimBlend")
require("lib.Molang")
local parts  = require("lib.PartsAPI")
local sync   = require("lib.LetThatSyncFig")
local lerp   = require("lib.LerpAPI")
local ground = require("lib.GroundCheck")
local pose   = require("scripts.Posing")

-- Animations setup
local anims = animations.SlimeTaur

-- Synced variables setup
local armsMove = sync.new("AnimsArms", false):config()

-- Arms setup
local leftArmLerp  = lerp.new(armsMove.curr and 1 or 0, 0.5)
local rightArmLerp = lerp.new(armsMove.curr and 1 or 0, 0.5)

-- Gets the origin rotation of a part, clamped
local function getOriginRot(part, delta)
	return (vanilla_model[part]:getOriginRot(delta) + 180) % 360 - 180
end

-- Parrot pivots
local parrots = {
	
	parts.group.LeftParrotPivot,
	parts.group.RightParrotPivot
	
}

-- Calculate parent's rotations
local function calculateParentRot(m)
	
	local parent = m:getParent()
	if not parent then
		return m:getTrueRot()
	end
	return calculateParentRot(parent) + m:getTrueRot()
	
end

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
	
	-- Arm variables
	local handedness = player:isLeftHanded()
	local mainL = not handedness and "OFF_HAND" or "MAIN_HAND"
	local mainR = handedness and "OFF_HAND" or "MAIN_HAND"
	local swingL = player:getSwingArm() == mainL
	local swingR = player:getSwingArm() == mainR
	local using = player:isUsingItem()
	local active = player:getActiveHand()
	local itemL = player:getHeldItem(not handedness)
	local itemR = player:getHeldItem(handedness)
	local usingL = using and active == mainL and itemL:getUseAction()
	local usingR = using and active == mainR and itemR:getUseAction()
	local bow = (usingL or usingR or ""):find("BOW") or (itemL:getTag().Charged or itemR:getTag().Charged) == 1
	
	-- Arms movement override
	local armShouldMove = pose.swim or pose.elytra or pose.crawl or pose.climb
	
	-- Arms movement targets
	leftArmLerp.target  = (armsMove.curr or armShouldMove or swingL or usingL or bow) and 0 or -1
	rightArmLerp.target = (armsMove.curr or armShouldMove or swingR or usingR or bow) and 0 or -1
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local vel = player:getVelocity()
	local yaw = player:getBodyYaw()
	local dir = vec(math.sin(math.rad(-yaw)), 0, math.cos(math.rad(-yaw)))
	
	-- Directional velocity
	local fbVel = vel:dot((dir.x_z):normalized())
	local lrVel = vel:crossed(dir.x_z:normalized()).y
	local udVel = vel.y
	
	-- Animation speeds
	local moveSpeed = fbVel < -0.05 and -1 or 1
	anims.walk:speed(moveSpeed)
	
	-- Animation blends
	local moveBlend = pose.crouch and 0.5 or 1
	anims.walk:blend(moveBlend)
	
	-- Arm idle rotation
	local idleTimer = world.getTime(delta)
	local idleRot   = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	
	-- Apply arm rotations
	parts.group.LeftArm:offsetRot((getOriginRot("LEFT_ARM", delta) + idleRot) * leftArmLerp.currPos)
	parts.group.RightArm:offsetRot((getOriginRot("RIGHT_ARM", delta) - idleRot) * rightArmLerp.currPos)
	
	-- Parrot rot offset
	for _, parrot in pairs(parrots) do
		parrot:rot(-calculateParentRot(parrot:getParent()) - getOriginRot("BODY", delta))
	end
	
	-- Crouch offset
	local bodyRot = getOriginRot("BODY", delta)
	local crouchPos = vec(0, -math.sin(math.rad(bodyRot.x)) * 2, -math.sin(math.rad(bodyRot.x)) * 12)
	parts.group.Player:pos(-crouchPos)
	parts.group.UpperBody_Wobble:offsetPivot(crouchPos):pos(parts.group.UpperBody_Wobble:getPos() + crouchPos.xy_ * 2)
	parts.group.LowerBody:pos(crouchPos)
	
	-- Spyglass rotations
	local headRot = getOriginRot("HEAD", delta)
	headRot.x = math.clamp(headRot.x, -90, 30)
	parts.group.Spyglass:offsetRot(headRot)
		:pos(pose.crouch and vec(0, -4, 0) or nil)
	
end

-- GS Blending Setup
local blendAnims = {
	{ anim = anims.walk, ticks = {3,3} }
}

-- Apply GS Blending
for _, blend in ipairs(blendAnims) do
	if blend.anim ~= nil then
		blend.anim:blendTime(table.unpack(blend.ticks)):blendCurve("easeOutQuad")
	end
end

-- Host only instructions
if not host:isHost() then return end

-- Required script
local s, pageNav, acts, colors = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

-- Check for if page already exists
local pageExists = action_wheel:getPage("Anims")

-- Pages
local parentPage = action_wheel:getPage("Main")
local animsPage  = pageExists or action_wheel:newPage("Anims")

-- Actions
if not pageExists then
	acts.animsPage = parentPage:newAction()
		:item("jukebox")
		:onLeftClick(function() pageNav.descend(animsPage) end)
end

acts.animsArmsToggle = animsPage:newAction()
	:item("red_dye")
	:toggleItem("rabbit_foot")
	:onToggle(function(bool)
		armsMove:update(bool)
	end)
	:toggled(armsMove.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if acts.animsPage then
			acts.animsPage
				:title(toJson(
					{text = "Animation Settings", bold = true, color = colors.primary}
				))
				:hoverColor(colors.hover)
		end
		
		acts.animsArmsToggle
			:title(toJson(
				{
					"",
					{text = "Arm Movement Toggle\n\n", bold = true, color = colors.primary},
					{text = "Toggles the movement swing movement of the arms.\nActions are not effected.", color = colors.secondary}
				}
			))
			:hoverColor(colors.hover)
			:toggleColor(colors.active)
		
	end
	
end