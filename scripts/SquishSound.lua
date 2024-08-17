-- Required scripts
local slimeParts = require("lib.GroupIndex")(models.SlimeTaur)
local itemCheck  = require("lib.ItemCheck")
local effects    = require("scripts.SyncedVariables")
local color      = require("scripts.ColorProperties")

-- Config setup
config:name("SlimeTaur")
local squishSound = config:load("SquishSoundToggle")
if squishSound == nil then squishSound = true end

-- Variables setup
local wasInAir = false
local cooldown = 0

-- Box check
local function inBox(pos, box_min, box_max)
	return pos.x >= box_min.x and pos.x <= box_max.x and
		   pos.y >= box_min.y and pos.y <= box_max.y and
		   pos.z >= box_min.z and pos.z <= box_max.z
end

function events.TICK()
	
	-- Prevents overlap
	cooldown = math.clamp(cooldown - 1, 0, 10)
	
	if squishSound and not player:getVehicle() and not player:isInWater() and not effects.cF  then
		
		-- Ground check
		-- Block variables
		local groundPos   = slimeParts.Ground:partToWorldMatrix():apply()
		local blockPos    = groundPos:copy():floor()
		local groundBlock = world.getBlockState(groundPos)
		local groundBoxes = groundBlock:getCollisionShape()
		
		-- Check for ground
		local onGround = false
		if groundBoxes then
			for i = 1, #groundBoxes do
				local box = groundBoxes[i]
				if inBox(groundPos, blockPos + box[1], blockPos + box[2]) then
					
					onGround = true
					break
					
				end
			end
		end
		
		local pitch = math.clamp(-slimeParts.Slime:getScale():length() / 4 + 1.5, 0.25, 1.75)
		
		-- Play sound if conditions are met
		if cooldown == 0 and not wasInAir and not onGround then
			
			sounds:playSound("entity.slime.jump", player:getPos(), 0.4, pitch)
			
		elseif wasInAir and onGround then
			
			sounds:playSound("entity.slime.squish", player:getPos(), 0.4, pitch)
			
			cooldown = 10
			
		end
		
		wasInAir = not onGround
		
	end
	
end

-- Sound toggle
function pings.setSquishSoundToggle(boolean)

	squishSound = boolean
	config:save("SquishSoundToggle", squishSound)
	if host:isHost() and player:isLoaded() and squishSound then
		sounds:playSound("entity.slime.squish", player:getPos(), 0.35, 0.6)
	end
	
end

-- Sync variables
function pings.syncSquishSound(a)
	
	squishSound = a
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local color     = require("scripts.ColorProperties")

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncSquishSound(squishSound)
	end
	
end

-- Table setup
local t = {}

-- Action
t.soundAct = action_wheel:newAction()
	:item(itemCheck("snow_block"))
	:toggleItem(itemCheck("slime_block"))
	:onToggle(pings.setSquishSoundToggle)
	:toggled(squishSound)

-- Update action
function events.TICK()
	
	if action_wheel:isEnabled() then
		t.soundAct
			:title(toJson
				{"",
				{text = "Toggle Jumping/Falling Sound\n\n", bold = true, color = color.primary},
				{text = "Toggles slime sound effects when jumping or landing.", color = color.secondary}}
			)
		
		for _, page in pairs(t) do
			page:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return action
return t