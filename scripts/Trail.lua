-- Required scripts
local parts       = require("lib.PartsAPI")
local sync        = require("lib.LetThatSyncFig")
local lerp        = require("lib.LerpAPI")
local pehkuiScale = require("lib.PehkuiScale")
local pose        = require("scripts.Posing")

-- Synced variables setup
local trail = sync.add(config:load("TrailToggle"), true)
local melt = sync.add(config:load("TrailMeltSpeed"), 0.02)

-- Variables
local worldPart = models:newPart("world", "WORLD")
local trailPart = parts.group.Trail

-- Kills script if it cannot find the trailpart
if not trailPart then return {} end

-- Prevents visible culling
trailPart:primaryRenderType("TRANSLUCENT_CULL")

-- Trail table
local trails = {}

-- Deep copy
local function deepCopy(model)
	local copy = model:copy(model:getName()..tostring(#trails+1))
	for _, child in pairs(copy:getChildren()) do
		copy:removeChild(child):addChild(deepCopy(child))
	end
	return copy
end

-- Box check
local function inBox(pos, box_min, box_max)
	return pos.x >= box_min.x and pos.x <= box_max.x and
		   pos.y >= box_min.y and pos.y <= box_max.y and
		   pos.z >= box_min.z and pos.z <= box_max.z
end

local function new(pos, scale)
	
	-- Establish trail part
	local copy = deepCopy(trailPart)
		:pos(pos * 16)
		:rot(0, -player:getBodyYaw() - 180, 0)
		:visible(true)
	
	-- Set trail to world
	worldPart:addChild(copy)
	
	-- Add part to table
	trails[#trails + 1] = {
		pos    = pos,
		scale  = lerp:new(scale * 0.75),
		fused  = true,
		trails = copy
	}
	
end

function events.TICK()
	
	-- Variables
	local pos   = player:getPos()
	local scale = parts.group.Slime_Wobble:getScale() * pehkuiScale()
	
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
	
	-- Spawn new trail if on ground and not currently fused
	if sync[trail] and onGround and not (trails[#trails] and trails[#trails].fused) then
		
		-- Find collision
		local _, blockPos = raycast:block(pos, pos - vec(0, 1, 0), "COLLIDER")
		
		-- Create trail
		new(blockPos, scale)
		
		-- If a trail is too close to the newly formed trail, remove it
		for _, part in ipairs(trails) do
			
			if part.fused then return end
			
			local dis = (blockPos - part.pos):length()
			
			if dis < 0.25 then
				
				part.scale:remove()
				part.trails:remove()
				table.remove(trails, _)
				
			end
			
		end
		
	end
	
	-- Cycle through trail parts
	for _, part in ipairs(trails) do
		
		-- Variables
		local dis = (pos - part.pos):length()
		
		-- Check if trails should not be fused anymore
		if not sync[trail] or dis >= 0.25 or not onGround then
			
			part.fused = false
			
		end
		
		-- Tick lerp
		if part.fused then
			
			part.scale.target = scale
			part.scale.stiff  = 0.2
			
		else
			
			part.scale.target = 0
			part.scale.stiff  = sync[melt]
			
			-- If trail is too small, remove it
			if part.scale.currPos:length() <= 0.05 then
				
				part.scale:remove()
				part.trails:remove()
				table.remove(trails, _)
				
			end
			
		end
		
	end
	
end

function events.RENDER(delta, context)
	
	-- Lerp scale
	for _, part in ipairs(trails) do
		
		-- Set light level
		local blockLight = world.getBlockLightLevel(part.pos + vec(0, 0.5, 0))
		local skyLight = world.getSkyLightLevel(part.pos + vec(0, 0.5, 0))
		
		part.trails:light(blockLight, skyLight)
		
		-- If part is fused to player, control it
		if part.fused then
			
			-- Variables
			local rot = -player:getBodyYaw(delta) - 180
			
			-- Apply
			part.trails
				:rot(0, rot, 0)
				:scale(part.scale.currPos)
			
			for _, child in ipairs(part.trails:getChildren()) do
				
				-- Find child's original
				local origin
				for _, o in ipairs(trailPart:getChildren()) do
					if child:getName():find(o:getName()) then
						origin = o
						break
					end
				end
				
				-- Apply
				if origin then
					
					child
						:color(origin:getColor())
						:opacity(origin:getOpacity())
					
				end
				
			end
			
		else
			
			-- Apply
			part.trails:scale(part.scale.currPos)
			
		end
		
	end
	
end

-- Trail toggle
function pings.setTrailToggle(boolean)

	sync[trail] = boolean
	config:save("TrailToggle", sync[trail])
	if host:isHost() and player:isLoaded() and sync[trail] then
		sounds:playSound("entity.slime.squish", player:getPos(), 0.35)
	end
	
end

-- Melt speed
local function setMeltSpeed(x)
	
	sync[melt] = math.clamp(sync[melt] + (x * 0.001), 0.01, 0.1)
	config:save("TrailMeltSpeed", sync[melt])
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
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
		:onLeftClick(function() wheel:descend(slimePage) end)
end

a.trailAct = slimePage:newAction()
	:item("snow")
	:toggleItem("lime_carpet")
	:onToggle(pings.setTrailToggle)
	:onScroll(setMeltSpeed)
	:onRightClick(function() sync[melt] = 0.02 config:save("TrailMeltSpeed", sync[melt]) end)
	:toggled(sync[trail])

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Slime Settings", bold = true, color = c.primary}
				))
		end
		
		a.trailAct
			:title(toJson(
				{
					"",
					{text = "Toggle Trail/Melt Speed\n\n", bold = true, color = c.primary},
					{text = "Toggles the formation of slime trails as you move, and how long they take to melt.\n\n", color = c.secondary},
					{text = "Current melt speed: ", bold = true, color = c.secondary},
					{text = (sync[melt] * 100).."% Each Tick\n\n"},
					{text = "Scroll to adjust the speed.\nRight click resets speed to 2%.", color = c.secondary}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end