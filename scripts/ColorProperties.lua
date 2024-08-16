-- Required scripts
local slimeParts = require("lib.GroupIndex")(models.models.SlimeTaur)
local ground     = require("lib.GroundCheck")

-- Config setup
config:name("SlimeTaur")
local pick        = config:load("ColorPick") or false
local pickedColor = config:load("ColorPicked") or vectors.hexToRGB("E56216")
local camo        = config:load("ColorCamo") or false
local rainbow     = config:load("ColorRainbow") or false

-- Variables
local selectedRGB = 0
local groundTimer = 0

-- All color parts
local colorParts = {
	
	slimeParts.Slime.Slime,
	slimeParts.Trail.Trail
	
}

-- Lerp color table
local colorLerp = {
	current    = vec(1, 1, 1),
	nextTick   = vec(1, 1, 1),
	target     = vec(1, 1, 1),
	currentPos = vec(1, 1, 1)
}

-- Lerp opacity table
local opacityLerp = {
	current    = 1,
	nextTick   = 1,
	target     = 1,
	currentPos = 1
}

function events.TICK()
	
	if pick then
		
		-- Set to picked color
		colorLerp.target = pickedColor
		
	elseif camo then
		
		-- Variables
		local pos    = slimeParts.Slime:partToWorldMatrix():apply(0, -10, 0)
		local scale  = slimeParts.Slime:getScale()
		local blocks = world.getBlocks(pos - scale, pos + scale)
		
		-- Gather blocks
		for i = #blocks, 1, -1 do
			
			local block = blocks[i]
			
			if block:isAir() then
				table.remove(blocks, i)
			end	
			
		end
		
		if #blocks ~= 0 then
			
			-- Init colors
			local calcColor   = vectors.vec3()
			local calcOpacity = #blocks
			
			for _, block in ipairs(blocks) do
				
				-- Gather colors
				if block.id == "minecraft:water" then
					calcColor = calcColor + world.getBiome(block:getPos()):getWaterColor()
				else
					calcColor = calcColor + block:getMapColor()
				end
				
				-- Gather translucency
				if block.id:find("glass") then
					calcOpacity = calcOpacity - 0.8
				end
				
			end
			
			-- Find averages
			colorLerp.target = calcColor / #blocks
			opacityLerp.target = calcOpacity / #blocks
			
		elseif groundTimer >= 40 then
			
			-- Find sky color if ground not found
			colorLerp.target = world.getBiome(pos):getSkyColor()
			opacityLerp.target = 1
			
		end
		
		-- Ground timer
		groundTimer = ground() and 0 or groundTimer + 1
		
	elseif rainbow then
		
		-- Set to RGB
		local calcColor = world.getTime() % 360 / 360
		colorLerp.target = vectors.hsvToRGB(calcColor, 1, 1)
		opacityLerp.target = 1
		
	else
		
		-- Set to default
		colorLerp.target = vec(1, 1, 1)
		opacityLerp.target = 1
		
	end
	
	-- Tick lerp
	colorLerp.current = colorLerp.nextTick
	colorLerp.nextTick = math.lerp(colorLerp.nextTick, colorLerp.target, 0.2)
	opacityLerp.current = opacityLerp.nextTick
	opacityLerp.nextTick = math.lerp(opacityLerp.nextTick, opacityLerp.target, 0.2)
	
end

function events.RENDER(delta, context)
	
	-- Render lerp
	colorLerp.currentPos = math.lerp(colorLerp.current, colorLerp.nextTick, delta)
	opacityLerp.currentPos = math.lerp(opacityLerp.current, opacityLerp.nextTick, delta)
	
	-- Slime textures
	for _, part in ipairs(colorParts) do
		part:color(colorLerp.currentPos)
		part:opacity(opacityLerp.currentPos)
	end
	
	-- Glowing outline
	renderer:outlineColor(colorLerp.currentPos)
	
	-- Avatar color
	avatar:color(colorLerp.currentPos)
	
end

-- Choose color function
local function pickColor(x)
	
	x = x/255
	pickedColor[selectedRGB+1] = math.clamp(pickedColor[selectedRGB+1] + x, 0, 1)
	
	config:save("ColorPicked", pickedColor)
	
end

-- Swaps selected rgb value
local function selectRGB()
	
	selectedRGB = (selectedRGB + 1) % 3
	
end

-- Color type toggle
function pings.setColorType(type)
	
	pick    = type == 1
	camo    = type == 2
	rainbow = type == 3
	
	config:save("ColorPick", pick)
	config:save("ColorCamo", camo)
	config:save("ColorRainbow", rainbow)
	
end

-- Sync variables
function pings.syncColor(a, b, c, d)
	
	pick        = a
	pickedColor = b
	camo        = c
	rainbow     = d
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required script
local itemCheck = require("lib.ItemCheck")

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncColor(pick, pickedColor, camo, rainbow)
	end
	
end

-- Table setup
local c = {}

-- Action variables
c.hover     = vectors.vec3()
c.active    = vectors.vec3()
c.primary   = "#"..vectors.rgbToHex(vectors.vec3())
c.secondary = "#"..vectors.rgbToHex(vectors.vec3())

function events.TICK()
	
	-- Set colors
	c.hover     = colorLerp.currentPos
	c.active    = (colorLerp.currentPos):applyFunc(function(a) return math.map(a, 0, 1, 0.1, 0.9) end)
	c.primary   = "#"..vectors.rgbToHex(colorLerp.currentPos)
	c.secondary = "#"..vectors.rgbToHex((colorLerp.currentPos):applyFunc(function(a) return math.map(a, 0, 1, 0.1, 0.9) end))
	
end

-- Table setup
local t = {}

-- Actions
t.pickPage = action_wheel:newAction()
	:item(itemCheck("glass_bottle"))
	:onToggle(function(apply) pings.setColorType(apply and 1) end)
	:onRightClick(selectRGB)
	:onScroll(pickColor)

t.camoPage = action_wheel:newAction()
	:item(itemCheck("glass_bottle"))
	:onToggle(function(apply) pings.setColorType(apply and 2) end)

t.rainbowPage = action_wheel:newAction()
	:item(itemCheck("glass_bottle"))
	:onToggle(function(apply) pings.setColorType(apply and 3) end)

-- Update actions
function events.TICK()
	
	if action_wheel:isEnabled() then
		t.pickPage
			:title(toJson
				{"",
				{text = "Toggle Picked Color Mode\n\n", bold = true, color = c.primary},
				{text = "Toggles the usage of a picked color.\n\n", color = c.secondary},
				{text = "Selected RGB: ", bold = true, color = c.secondary},
				{text = (selectedRGB == 0 and "[%d] "  or "%d " ):format(pickedColor[1] * 255), color = "red"},
				{text = (selectedRGB == 1 and "[%d] "  or "%d " ):format(pickedColor[2] * 255), color = "green"},
				{text = (selectedRGB == 2 and "[%d]\n" or "%d\n"):format(pickedColor[3] * 255), color = "blue"},
				{text = "Selected Hex: ", bold = true, color = c.secondary},
				{text = vectors.rgbToHex(pickedColor).."\n\n", color = "#"..vectors.rgbToHex(pickedColor)},
				{text = "Scroll to adjust an RGB Value.\nRight click to change selection.", color = c.secondary}}
			)
			:toggleItem(itemCheck("potion{\"CustomPotionColor\":" .. tostring(vectors.rgbToInt(colorLerp.currentPos)) .. "}"))
			:toggled(pick)
		
		t.camoPage
			:title(toJson
				{"",
				{text = "Toggle Camo Mode\n\n", bold = true, color = c.primary},
				{text = "Toggles changing your slime color to match your surroundings.", color = c.secondary}}
			)
			:toggleItem(itemCheck("splash_potion{\"CustomPotionColor\":" .. tostring(vectors.rgbToInt(colorLerp.currentPos)) .. "}"))
			:toggled(camo)
		
		t.rainbowPage
			:title(toJson
				{"",
				{text = "Toggle Rainbow Mode\n\n", bold = true, color = c.primary},
				{text = "Toggles on hue-shifting creating a rainbow effect.", color = c.secondary}}
			)
			:toggleItem(itemCheck("lingering_potion{\"CustomPotionColor\":" .. tostring(vectors.rgbToInt(colorLerp.currentPos)) .. "}"))
			:toggled(rainbow)
		
		for _, page in pairs(t) do
			page:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end

-- Return variables/actions
return c, t