-- Required scripts
local parts  = require("lib.PartsAPI")
local lerp   = require("lib.LerpAPI")
local ground = require("lib.GroundCheck")

-- Config setup
config:name("SlimeTaur")
local color = config:load("ColorType") or "UUID"

-- Color types
local colorTypes = {
	
	-- Preset colors (add one to the list if you want a preexisting option!)
	vectors.hexToRGB("528A3F"),
	vectors.hexToRGB("FF00DC"),
	vectors.hexToRGB("FF6A00"),
	
	-- Special colors
	UUID = vec(client.uuidToIntArray(avatar:getUUID())).xyz % 256 / 255,
	Camo = vectors.vec3(),
	RGB  = vectors.vec3(),
	Pick = config:load("ColorPicked") or vec(1, 1, 1),
	None = vec(1, 1, 1)
	
}

-- Reset if color is out of bounds
if type(color) == "number" and color > #colorTypes then
	color = 1
end

-- Variable
local groundTimer = 0

-- All parts
local colorParts = parts:createTable(function(part) return part:getName():find("_[cC]olou?r") end)
local transParts = parts:createTable(function(part) return part:getName():find("_[tT]rans") end)

-- Lerps
local colorLerp   = lerp:new(vec(1, 1, 1))
local opacityLerp = lerp:new(1)

function events.TICK()
	
	-- Calc camo
	if color == "Camo" then
		
		-- Variables
		local pos    = parts.group.Slime_Wobble:partToWorldMatrix():apply(0, -10, 0)
		local scale  = parts.group.Slime_Wobble:getScale()
		local blocks = world.getBlocks(pos - scale, pos + scale)
		local solid  = false
		
		-- Check for solid blocks
		for _, block in ipairs(blocks) do
			
			if block:hasCollision() then
				solid = true
				break
			end
			
		end
		
		-- Gather blocks
		for i = #blocks, 1, -1 do
			
			local block = blocks[i]
			
			if block:isAir() or solid and block.id == "minecraft:water" then
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
			colorTypes.Camo = calcColor / #blocks
			opacityLerp.target = calcOpacity / #blocks
			
		elseif groundTimer >= 40 then
			
			-- Find sky color if ground not found
			colorTypes.Camo = world.getBiome(pos):getSkyColor()
			opacityLerp.target = 1
			
		end
		
		-- Ground timer
		groundTimer = ground() and 0 or groundTimer + 1
		
	-- Calc rainbow
	elseif color == "RGB" then
		
		local calcColor = world.getTime() % 360 / 360
		colorTypes.RGB  = vectors.hsvToRGB(calcColor, 1, 1)
		opacityLerp.target = 1
		
	-- Any other state
	else
		
		opacityLerp.target = 1
		
	end
	
	-- Set target
	colorLerp.target = colorTypes[color]
	
end

function events.RENDER(delta, context)
	
	-- Slime textures
	for _, part in ipairs(colorParts) do
		part:color(colorLerp.currPos)
	end
	for _, part in ipairs(transParts) do
		part:opacity(opacityLerp.currPos)
	end
	
	-- Glowing outline
	renderer:outlineColor(colorLerp.currPos)
	
	-- Avatar color
	avatar:color(colorLerp.currPos)
	
end

-- Select preset colors
function pings.setPreset(i)
	
	-- Sets to preset if its in another mode
	if type(color) ~= "number" then
		color = 1
		config:save("ColorType", color)
		return
	end
	
	-- Sets preset
	color = ((color + i - 1) % #colorTypes) + 1
	config:save("ColorType", color)
	
end

-- Color type
function pings.setColorType(type)
	
	color = type
	config:save("ColorType", color)
	
end

-- Pick color
function pings.setPickedColor(v)
	
	colorTypes.Pick = v
	color = "Pick"
	config:save("ColorType", color)
	config:save("ColorPicked", colorTypes.Pick)
	
end

-- Sync variables
function pings.syncColor(...)
	
	color, colorTypes.Pick = ...
	
end

-- Host only instructions
if not host:isHost() then return end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncColor(color, colorTypes.Pick)
	end
	
end

-- Required scripts
local s, wheel, itemCheck, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found

-- Dont preform if color properties is empty
if next(c) ~= nil then
	
	-- Store init colors
	local initColors = {}
	for k, v in pairs(c) do
		initColors[k] = v
	end
	
	-- Update action wheel colors
	function events.RENDER(delta, context)
		
		-- Create mermod colors
		local appliedColors = {
			hover     = colorLerp.currPos,
			active    = (colorLerp.currPos):applyFunc(function(a) return math.map(a, 0, 1, 0.1, 0.9) end),
			primary   = "#"..vectors.rgbToHex(colorLerp.currPos),
			secondary = "#"..vectors.rgbToHex((colorLerp.currPos):applyFunc(function(a) return math.map(a, 0, 1, 0.1, 0.9) end))
		}
		
		-- Update action wheel colors
		for k in pairs(c) do
			c[k] = appliedColors[k]
		end
		
	end
	
end

-- Color pick comnmand
function events.CHAT_SEND_MESSAGE(msg)
	
	-- Checks for command
	if msg:match("^!slimecolor ") then
		
		-- Adds the message to chat history
		host:appendChatHistory(msg)
		
		-- Removes command from string
		msg = msg:gsub("!slimecolor ", "")
		
		-- Tests validity of hex code
		if msg:match("^#?[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
			
			-- Apply
			msg = vectors.hexToRGB(msg)
			pings.setPickedColor(msg)
			
			-- Notify
			host:setActionbar("Color Applied!")
			
		else
			
			-- Notify
			host:setActionbar("Color Failed! Not a valid hex!")
			
		end
		
		-- Removes message
		return
		
	end
	
	-- Sends message if reached
	return msg
	
end

-- Cycles color functions
local setFunctions = {
	function() pings.setPreset() end,
	function() pings.setColorType("UUID") end,
	function() pings.setColorType("Camo") end,
	function() pings.setColorType("RGB")  end,
	function() pings.setColorType("Pick") end,
	function() pings.setColorType("None") end
}
local function pickFunction(i, x)
	
	i = ((i + x - 1) % #setFunctions) + 1
	return setFunctions[i]()
	
end

-- Action wheel info
local actStuff = {
	Preset = {
		title = "Preset",
		info = "be selected from the list of \npre-existing colors in the ColorChange.lua script.\n\nScroll to pick which color is selected.",
		item = "slime_ball",
		scrAct = function(x) pings.setPreset(x) end,
		id = 1
	},
	UUID = {
		title = "UUID",
		info = "be determined by your account\'s UUID.\nThis is YOUR color.",
		item = "player_head{SkullOwner:"..avatar:getEntityName().."}",
		id = 2
	},
	Camo = {
		title = "Camo",
		info = "blend in with surrounding blocks!\nIt will also attempt to match transparency.",
		item = "splash_potion",
		id = 3
	},
	RGB = {
		title = "RGB",
		info = "hue-shift creating a rainbow effect.",
		item = "lingering_potion",
		id = 4
	},
	Pick = {
		title = "Picked color",
		info = "determinded by whatever you decide!\n\nType !slimecolor <hexcolor> to pick a color.",
		item = "potion",
		id = 5
	},
	None = {
		title = "None",
		info = "not have any additive effects.\nIt will match the original texture.",
		item = "glass",
		id = 6
	}
}

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
		:item(itemCheck("slime_block"))
		:onLeftClick(function() wheel:descend(slimePage) end)
end

a.colorAct = slimePage:newAction()

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Slime Settings", bold = true, color = c.primary}
				))
		end
		
		-- Gets info
		local actState = actStuff[type(color) == "string" and color or "Preset"]
		
		a.colorAct
			:title(toJson(
				{
					"",
					{text = ("%s\n\n"):format(actState.title), bold = true, color = c.primary},
					{text = ("Your slime\'s color will %s\n\nLeft or Right click to change color modes."):format(actState.info), color = c.secondary}
				}
			))
			:item(itemCheck(actState.item.."{CustomPotionColor:" .. tostring(vectors.rgbToInt(colorLerp.currPos)) .. "}"))
			:onLeftClick(function() pickFunction(actState.id, 1) end)
			:onRightClick(function() pickFunction(actState.id, -1) end)
			:onScroll(actState.scrAct)
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover)
		end
		
	end
	
end