-- Required scripts
local parts   = require("lib.PartsAPI")
local sync    = require("lib.LetThatSyncFig")
local lerp    = require("lib.LerpAPI")
local wobble  = require("lib.CMWobble")
local origins = require("lib.OriginsAPI")
local pose    = require("scripts.Posing")

-- Wobble Setup
local slimeWobble = wobble:newWobbleSetup()

-- Synced variables setup
local speed       = sync.add(config:load("WobbleSpeed"), 0.0075)
local dampen      = sync.add(config:load("WobbleDampening"), 0.0075)
local wobbleRot   = sync.add(config:load("WobbleRot"), true)
local damage      = sync.add(config:load("WobbleDamage"), true)
local upperWobble = sync.add(config:load("WobbleUpper"), false)
local biome       = sync.add(config:load("WobbleBiome"), true)
local healthSize  = sync.add(config:load("WobbleHealthSize"), false)

-- Variables
local scaleApply   = 0
local crouchWobble = 0.02
local damageWobble = 0.025
local currRot      = 0
local prevRot      = 0
local isCrouching  = false
local powerActive  = false
local swimTimer    = 0
local speedMin,  speedMax  = 0, 0.1
local dampenMin, dampenMax = 0, 0.1
local strengthSwitch = true

-- Choose objects to stay consistent in the slime
local slimePivots = parts:createTable(function(part) return part:getName():find("_[wW]obble") end)

if parts.group.StoredItems then
	
	-- Establish embedded items
	for i = 1, 27 do
		
		local newPart = parts.group.StoredItems:newPart("StoredItem"..i)
		table.insert(slimePivots, newPart)
		newPart
			:pivot(parts.group.StoredItems:getPivot() + vec((i-1)%3-1, math.ceil(i/9-2), math.floor((i-1)/3%3-1)) * 5)
		
	end
	
	-- After creating item groups, update parts API
	parts:update()
	
end

-- Lerps
local scaleLerp = lerp:new(1)
local upperLerp = lerp:new(sync[upperWobble] and 1 or 0)

function events.ENTITY_INIT()
	
	-- Init rots
	currRot = player:getRot()
	prevRot = currRot
	
end

function events.TICK()
	
	-- Update rots
	prevRot = currRot
	currRot = player:getRot()
	
	-- Check if origin power is active
	powerActive = origins.getPowerData(player, "slime_taur:varied_sizing_toggle") == 1
	
	-- Change size based on health or origin power
	if powerActive then
		
		local moisture = origins.getPowerData(player, "slime_taur:moisture_bar") or 50
		scaleLerp.target = ((player:getHealth() / player:getMaxHealth()) * 1.5) * (moisture / 100) + 0.5
		
	elseif sync[healthSize] then
		
		scaleLerp.target = (player:getHealth() / player:getMaxHealth()) * 1.5 + 0.5
		
	else
		
		scaleLerp.target = 1
		
	end
	
	upperLerp.target = sync[upperWobble] and 1 or 0
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local vel     = player:getVelocity()
	local animPos = parts.group.Player:getAnimPos().y
	local water   = player:isInWater()
	
	-- Apply speed and dampen values
	slimeWobble.s = sync[speed]
	slimeWobble.d = sync[dampen]
	
	-- Modify based on biome
	if sync[biome] then
		
		local biomePos = world.getBiome(player:getPos())
		local apply = math.map(biomePos:getTemperature(), -0.7, 2, 0.1, 1.9)
		
		slimeWobble.s = slimeWobble.s * apply
		slimeWobble.d = slimeWobble.d * (math.map(apply, 0, 1, 1, 0) + 1)
		
	end
	
	-- Clamp after changes
	slimeWobble.s = math.clamp(slimeWobble.s, speedMin,  speedMax)
	slimeWobble.d = math.clamp(slimeWobble.d, dampenMin, dampenMax)
	
	-- Gathers wobble values
	if pose.stand then
		
		scaleApply = (vel.y / 2) + (-animPos * 0.01)
		
	elseif pose.crouch then
		
		scaleApply = (vel.y / 4) + (-animPos * 0.04) - 0.35
		
	elseif pose.swim then
		
		if vel:length() ~= 0 then
			
			swimTimer = swimTimer + (vel:length() / 5)
			
		else
			
			swimTimer = 0
			
		end
		
		scaleApply = (vel:length() / 4) + math.sin(swimTimer) * 0.1
		
	elseif pose.elytra then
		
		scaleApply = vel:length() / 4
		
	end
	
	-- Causes wobble if player crouches or uncrouches
	if pose.crouch and not isCrouching and slimeWobble.d ~= 0.1 then
		
		slimeWobble:setWobble(-crouchWobble, -crouchWobble, -crouchWobble)
		isCrouching = true
		
	elseif not pose.crouch and isCrouching and slimeWobble.d ~= 0.1 then
		
		slimeWobble:setWobble(crouchWobble, crouchWobble, crouchWobble)
		isCrouching = false
		
	end
	
	-- Cause wobble if damage taken and enabled
	if sync[wobbleRot] and player:getNbt()["HurtTime"] == 10 and slimeWobble.d ~= 0.1 then
		
		slimeWobble:setWobble(-damageWobble, -damageWobble, -damageWobble)
		
	end
	
	-- Limits how much each direction may wobble
	if slimeWobble.wobble < -0.6 or slimeWobble.wobble > 0.6 then
		
		slimeWobble.wobble = math.clamp(slimeWobble.wobble, -0.6, 0.6)
		slimeWobble.wobbleVel = 0
		
	end
	
	-- Applies offsets to pivots to keep parts attached/embeded
	for _, part in ipairs(slimePivots) do
		
		local pivot     = part:getPivot()
		local offsetPos = (pivot * parts.group.Slime_Wobble:getScale()) - pivot
		part:pos(offsetPos)
		
	end
	
	-- Applies offset to lowerBody itself
	local offsetPivot = parts.group.Slime_Wobble:getPivot() * parts.group.Slime_Wobble:getScale()
	parts.group.LowerBody:pivot(offsetPivot)
	
end

function events.WORLD_RENDER(delta, context)
	if player:isLoaded() then
		
		-- Check for passengers
		local increase = vec(0, 0, 0)
		if #player:getPassengers() ~= 0 then
			
			local rider = player:getPassengers()[1]
			increase = rider:getBoundingBox()
			
		end
		
		local calcRot 
		if sync[wobbleRot] and (pose.stand or pose.crouch) then
			
			-- Calc rot application
			local rotDif = currRot - prevRot
			calcRot = (-rotDif.x + math.abs(rotDif.y)) / 450
			
		else
			
			calcRot = 0
			
		end
		
		-- Calculates the Wobble and applies it
		slimeWobble:update(scaleApply + calcRot, true)
		local calcWobble = slimeWobble.wobble * scaleLerp.currPos
		parts.group.Slime_Wobble:scale(
			vec(scaleLerp.currPos - calcWobble,
				scaleLerp.currPos + calcWobble,
				scaleLerp.currPos - calcWobble)
				+ increase
			)
		
		-- Calculates the Wobble and applies it, but for the upper body
		parts.group.UpperBody_Wobble:scale(1 + (upperLerp.currPos * vec(-calcWobble, calcWobble, -calcWobble)))
		
		-- Scale shadow to size
		renderer:shadowRadius(scaleLerp.currPos - 0.25 * scaleLerp.currPos)
		
	end
end

-- Set wobble values
local function setStrength(x)
	
	local apply = x * 0.0005
	
	if strengthSwitch then 
		sync[speed] = math.clamp(sync[speed] + apply, speedMin, speedMax)
		config:save("WobbleSpeed", sync[speed])
	else
		sync[dampen] = math.clamp(sync[dampen] + apply, dampenMin, dampenMax)
		config:save("WobbleDampening", sync[dampen])
	end
	
end

-- Wobble value selection toggle
local function setStrengthSwitch()
	
	strengthSwitch = not strengthSwitch
	
end

-- Rotation wobble toggle
function pings.setWobbleRot(boolean)
	
	sync[wobbleRot] = boolean
	config:save("WobbleRot", sync[wobbleRot])
	
end

-- Damage wobble toggle
function pings.setWobbleDamage(boolean)
	
	sync[wobbleRot] = boolean
	config:save("WobbleDamage", sync[wobbleRot])
	
end

-- Upper body wobble toggle
function pings.setWobbleUpper(boolean)
	
	sync[upperWobble] = boolean
	config:save("WobbleUpper", sync[upperWobble])
	
end

-- Biome wobble toggle
function pings.setWobbleBiome(boolean)
	
	sync[biome] = boolean
	config:save("WobbleBiome", sync[biome])
	
end

-- Health size toggle
function pings.setWobbleHealthSize(boolean)
	
	sync[healthSize] = boolean
	config:save("WobbleHealthSize", sync[healthSize])
	
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
local wobblePage = action_wheel:newPage("Wobble")

-- Actions table setup
local a = {}

-- Actions
if not pageExists then
	a.slimePageAct = parentPage:newAction()
		:item("slime_block")
		:onLeftClick(function() wheel:descend(slimePage) end)
end

a.wobblePageAct = slimePage:newAction()
	:item("brewing_stand")
	:onLeftClick(function() wheel:descend(wobblePage) end)

a.strengthAct = wobblePage:newAction()
	:onScroll(setStrength)
	:onLeftClick(setStrengthSwitch)
	:onRightClick(function()
		if strengthSwitch then
			sync[speed] = 0.0075
			config:save("WobbleSpeed", sync[speed])
		else
			sync[dampen] = 0.0075
			config:save("WobbleDampening", sync[dampen])
		end
	end)

a.rotAct = wobblePage:newAction()
	:item("music_disc_chirp")
	:toggleItem("music_disc_far")
	:onToggle(pings.setWobbleRot)
	:toggled(sync[wobbleRot])

a.damageAct = wobblePage:newAction()
	:item("shield")
	:toggleItem("iron_sword")
	:onToggle(pings.setWobbleDamage)
	:toggled(sync[wobbleRot])

a.upperAct = wobblePage:newAction()
	:item("armor_stand")
	:toggleItem("slime_ball")
	:onToggle(pings.setWobbleUpper)
	:toggled(sync[upperWobble])

a.biomeAct = wobblePage:newAction()
	:item("snow_block")
	:toggleItem("water_bucket")
	:onToggle(pings.setWobbleBiome)
	:toggled(sync[biome])

a.healthSizeAct = wobblePage:newAction()
	:item("beef")
	:toggleItem("cooked_beef")
	:onToggle(pings.setWobbleHealthSize)
	:toggled(sync[healthSize])

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.slimePageAct then
			a.slimePageAct
				:title(toJson(
					{text = "Slime Settings", bold = true, color = c.primary}
				))
		end
		
		a.wobblePageAct
			:title(toJson(
				{text = "Wobble Settings", bold = true, color = c.primary}
			))
		
		-- Variables
		local potionColor = math.lerp(vectors.hexToRGB("4CFF00"), vectors.hexToRGB("FFD800"),
		strengthSwitch and math.map(sync[speed], speedMin, speedMax, 0, 1) or math.map(sync[dampen], dampenMin, dampenMax, 0, 1))
		
		a.strengthAct
			:title(toJson(
				{
					"",
					{text = "Set Wobble Strength\n\n", bold = true, color = c.primary},
					{text = "Sets the Speed/Dampening of the slime.\n\n", color = c.secondary},
					{text = "Set Speed: ", bold = true, color = c.secondary},
					{text = (strengthSwitch and "[%s]\n" or "%s\n"):format(math.map(sync[speed], speedMin, speedMax, 0, 100).."%")},
					{text = "Modified Speed: ", bold = true, color = c.secondary},
					{text = math.map(slimeWobble.s, speedMin, speedMax, 0, 100).."%\n\n"},
					{text = "Set Dampening: ", bold = true, color = c.secondary},
					{text = (not strengthSwitch and "[%s]\n" or "%s\n"):format(math.map(sync[dampen], dampenMin, dampenMax, 0, 100).."%")},
					{text = "Modified Dampening: ", bold = true, color = c.secondary},
					{text = math.map(slimeWobble.d, dampenMin, dampenMax, 0, 100).."%\n\n"},
					{text = "Scroll to adjust a value.\nLeft click selects which value is being adjusted.\nRight click resets the value back to 7.5%.", color = c.secondary}
				}
			))
			:item("potion{\"CustomPotionColor\":" .. tostring(vectors.rgbToInt(potionColor)) .. "}")
		
		a.rotAct
			:title(toJson(
				{
					"",
					{text = "Set Rotational Wobble\n\n", bold = true, color = c.primary},
					{text = "Sets if slime should wobble while you look around.", color = c.secondary}
				}
			))
		
		a.damageAct
			:title(toJson(
				{
					"",
					{text = "Set Damage Wobble\n\n", bold = true, color = c.primary},
					{text = "Sets if slime should wobble if damage is taken.", color = c.secondary}
				}
			))
		
		a.upperAct
			:title(toJson(
				{
					"",
					{text = "Set Upper Body Wobble\n\n", bold = true, color = c.primary},
					{text = "Sets if the upper body should wobble as well.", color = c.secondary}
				}
			))
		
		a.biomeAct
			:title(toJson(
				{
					"",
					{text = "Set Temperature Modifier\n\n", bold = true, color = c.primary},
					{text = "Sets if biome temperature should affect the slime wobble.", color = c.secondary}
				}
			))
		
		a.healthSizeAct
			:title(toJson(
				{
					"",
					{text = "Set Health Size\n\n", bold = true, color = c.primary},
					{text = "Sets if your slime size is determinded by your health."..(powerActive and "\n\n" or ""), color = c.secondary},
					{text = powerActive and "Notice:\n" or "", bold = true, color = "gold"},
					{text = powerActive and "Origins is currently overriding this toggle." or "", color = "yellow"}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end