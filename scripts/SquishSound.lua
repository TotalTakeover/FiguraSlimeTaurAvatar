-- Required scripts
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local effects = require("scripts.SyncedVariables")

-- Synced variables setup
local squishSound = sync.new("SquishSoundToggle", true):config()

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
	
	if squishSound.curr and not player:getVehicle() and not player:isInWater() and not effects.cF  then
		
		-- Ground check
		-- Block variables
		local groundPos   = parts.group.Ground:partToWorldMatrix():apply()
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
		
		local pitch = math.clamp(-parts.group.Slime_Wobble:getScale():length() / 4 + 1.5, 0.25, 1.75)
		
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

-- Host only instructions
if not host:isHost() then return end

-- Apply sound function
squishSound:applyFunc(function()
	if player:isLoaded() and squishSound.curr then
		sounds:playSound("entity.slime.squish", player:getPos(), 0.35, 0.6)
	end
end)

-- Required scripts
local s, pageNav, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

-- Check for if page already exists
local pageExists = action_wheel:getPage("Slime")

-- Pages
local parentPage = action_wheel:getPage("Main")
local slimePage  = pageExists or action_wheel:newPage("Slime")

-- Actions table setup
local a = {}

-- Actions
if not pageExists then
	a.pageAct = parentPage:newAction()
		:item("slime_block")
		:onLeftClick(function() pageNav.descend(slimePage) end)
end

a.soundAct = slimePage:newAction()
	:item("snow_block")
	:toggleItem("slime_block")
	:onToggle(function(bool)
		squishSound:update(bool)
	end)
	:toggled(squishSound.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Slime Settings", bold = true, color = c.primary}
				))
		end
		
		a.soundAct
			:title(toJson(
				{
					"",
					{text = "Toggle Jumping/Falling Sound\n\n", bold = true, color = c.primary},
					{text = "Toggles slime sound effects when jumping or landing.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end