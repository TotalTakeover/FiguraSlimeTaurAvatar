-- Required scripts
local slimeParts  = require("lib.GroupIndex")(models.SlimeTaur)
local pehkuiScale = require("lib.PehkuiScale")
local pose        = require("scripts.Posing")

-- Config setup
config:name("SlimeTaur")
local trail = config:load("TrailToggle")
local melt  = config:load("TrailMeltSpeed") or 0.02
if trail == nil then trail = true end

-- Variables
local worldPart = models:newPart("world", "WORLD")
local trailPart = slimeParts.Trail

-- Prevents visible culling
trailPart:primaryRenderType("TRANSLUCENT_CULL")

-- Trail table
local parts = {}

-- Deep copy
local function deepCopy(model)
	local copy = model:copy(model:getName()..tostring(#parts+1))
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
		:visible(true)
	
	-- Set trail to world
	worldPart:addChild(copy)
	
	-- Add part to table
	parts[#parts + 1] = {
		pos   = pos,
		scale = {current = scale, nextTick = scale, target = scale, currentPos = scale},
		fused = true,
		parts = copy
	}
	
end

function events.TICK()
	
	-- Variables
	local pos   = player:getPos()
	local scale = slimeParts.Slime:getScale() * pehkuiScale()
	
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
	
	-- Spawn new trail if on ground and not currently fused
	if trail and onGround and not (parts[#parts] and parts[#parts].fused) then
		
		-- Find collision
		local _, blockPos = raycast:block(pos, pos - vec(0, 1, 0), "COLLIDER")
		
		-- Create trail
		new(blockPos + vec(0, 0.01, 0), scale)
		
	end
	
	-- Cycle through trail parts
	for _, part in ipairs(parts) do
		
		-- Variables
		local dis = (pos - part.pos):length()
		
		-- Check if trails are too far away to be fused
		if dis >= 0.25 or not onGround then
			
			part.fused = false
			
		end
		
		-- Store previous scale value
		part.scale.prev = part.scale.next
		
		-- Tick lerp
		if part.fused then
			
			part.scale.target = slimeParts.Slime:getScale() * pehkuiScale()
			part.scale.current = part.scale.nextTick
			part.scale.nextTick = math.lerp(part.scale.nextTick, part.scale.target, 0.2)
			
		else
			
			part.scale.target = 0
			part.scale.current = part.scale.nextTick
			part.scale.nextTick = math.lerp(part.scale.nextTick, part.scale.target, melt)
			
		end
		
		-- If trail is too small, or too close when not fused, delete
		if part.scale.current:length() <= 0.05 or (not part.fused and dis < 0.25) then
			
			part.parts:remove()
			table.remove(parts, _)
			
		end
		
	end
	
end

function events.RENDER(delta, context)
	
	-- Lerp scale
	for _, part in ipairs(parts) do
		
		-- Render lerp
		part.scale.currentPos = math.lerp(part.scale.current, part.scale.nextTick, delta)
		
		-- If part is fused to player, control it
		if trail and part.fused then
			
			-- Variables
			local rot     = -player:getBodyYaw(delta) - 180
			local color   = trailPart.Trail:getColor()
			local opacity = trailPart.Trail:getOpacity()
			
			-- Apply
			part.parts
				:rot(0, rot, 0)
				:scale(part.scale.currentPos)
			
			for _, part in ipairs(part.parts:getChildren()) do
				if not part:getName():find("Overlay") then
					part
						:color(color)
						:opacity(opacity)
				end
			end
			
		else
			
			-- Apply
			part.parts:scale(part.scale.currentPos)
			
		end
		
	end
	
end

-- Trail toggle
function pings.setTrailToggle(boolean)

	trail = boolean
	config:save("TrailToggle", trail)
	if host:isHost() and player:isLoaded() and trail then
		sounds:playSound("entity.slime.squish", player:getPos(), 0.35)
	end
	
end

-- Melt speed
local function setMeltSpeed(x)
	
	melt = math.clamp(melt + (x * 0.001), 0.01, 0.1)
	config:save("TrailMeltSpeed", melt)
	
end

-- Sync variables
function pings.syncTrail(a, x)
	
	trail = a
	melt  = x
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local color     = require("scripts.ColorProperties")

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncTrail(trail, melt)
	end
	
end

-- Table setup
local t = {}

-- Action
t.trailPage = action_wheel:newAction()
	:item(itemCheck("snow"))
	:toggleItem(itemCheck("lime_carpet"))
	:onToggle(pings.setTrailToggle)
	:onScroll(setMeltSpeed)
	:onRightClick(function() melt = 0.02 config:save("TrailMeltSpeed", melt) end)
	:toggled(trail)

-- Update actions
function events.TICK()
	
	if action_wheel:isEnabled() then
		t.trailPage
			:title(toJson
				{"",
				{text = "Toggle Trail/Melt Speed\n\n", bold = true, color = color.primary},
				{text = "Toggles the formation of slime trails as you move, and how long they take to melt.\n\n", color = color.secondary},
				{text = "Current melt speed: ", bold = true, color = color.secondary},
				{text = (melt * 100).."% Each Tick\n\n"},
				{text = "Scroll to adjust the speed.\nRight click resets speed to 2%.", color = color.secondary}}
			)
		
		for _, page in pairs(t) do
			page:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return action
return t