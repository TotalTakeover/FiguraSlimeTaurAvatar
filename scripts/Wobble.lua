-- Required scripts
local parts   = require("lib.PartsAPI")
local lerp    = require("lib.LerpAPI")
local wobble  = require("lib.CMWobble")
local origins = require("lib.OriginsAPI")
local pose    = require("scripts.Posing")

-- Wobble Setup
local slimeWobble = wobble:newWobbleSetup()

-- Config setup
config:name("SlimeTaur")
local speed      = config:load("WobbleSpeed") or 0.0075
local dampen     = config:load("WobbleDampening") or 0.0075
local wobbleRot  = config:load("WobbleRot")
local damage     = config:load("WobbleDamage")
local biome      = config:load("WobbleBiome")
local healthSize = config:load("WobbleHealthSize") or false
local upWobble   = config:load("WobbleUpperBody") or false
local armorClip  = config:load("WobbleArmorClip") or false
if wobbleRot == nil then wobbleRot = true end
if damage    == nil then damage    = true end
if biome     == nil then biome     = true end

armorClip = true

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
local slimePivots = {
	
	parts.group.UpperBody,
	parts.group.Slime,
	table.unpack(parts.group.Embeded:getChildren())
	
}

-- Choose objects to stay consistent with the slime
local slimeBodyPivots = {
	
	--table.unpack(parts.group.HeadEmbeded:getChildren())
	
}

-- Choose objects to stay consistent with the upper body
local slimeHeadPivots = {
	
	table.unpack(parts.group.HeadEmbeded:getChildren())
	
}

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

-- Lerp variables
local scaleLerp = lerp:new(0.2, 1)
local upperLerp = lerp:new(0.2, upWobble and 1 or 0)
local helmet    = lerp:new(0.2, 1)

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
		
	elseif healthSize then
		
		scaleLerp.target = (player:getHealth() / player:getMaxHealth()) * 1.5 + 0.5
		
	else
		
		scaleLerp.target = 1
		
	end
	
	-- Upper body wobble strength
	upperLerp.target = upWobble and 1 or 0
	
end

function events.RENDER(delta, context)
	
	-- Variables
	local vel     = player:getVelocity()
	local animPos = parts.group.Player:getAnimPos().y
	local water   = player:isInWater()
	
	-- Apply speed and dampen values
	slimeWobble.s = speed
	slimeWobble.d = dampen
	
	-- Modify based on biome
	if biome then
		
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
	if damage and player:getNbt()["HurtTime"] == 10 and slimeWobble.d ~= 0.1 then
		
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
		local offsetPos = (pivot * parts.group.Slime:getScale()) - pivot
		part:pos(offsetPos)
		
	end
	for _, part in ipairs(slimeHeadPivots) do
		
		local pivot     = part:getPivot()
		local offsetPos = (pivot * parts.group.Body:getScale()) - pivot
		part:pos(offsetPos)
		
	end
	for _, part in ipairs(slimeBodyPivots) do
		
		local pivot     = part:getPivot()
		local offsetPos = (pivot * parts.group.Slime:getScale()) - pivot
		part:pos(offsetPos)
		
	end
	
	-- Applies offset to lowerBody itself
	local offsetPivot = parts.group.Slime:getPivot() * parts.group.Slime:getScale()
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
		if wobbleRot and (pose.stand or pose.crouch) then
			
			-- Calc rot application
			local rotDif = currRot - prevRot
			calcRot = (-rotDif.x + math.abs(rotDif.y)) / 450
			
		else
			
			calcRot = 0
			
		end
		-- Calculates the Wobble and applies it
		slimeWobble:update(scaleApply + calcRot, true)
		local calcWobble = slimeWobble.wobble * scaleLerp.currPos
		parts.group.Slime:scale(
			vec(scaleLerp.currPos - calcWobble,
				scaleLerp.currPos + calcWobble,
				scaleLerp.currPos - calcWobble)
				+ increase
			)
		
		local isHelmet = not armorClip and player:getItem(6).id ~= "minecraft:air"
		parts.group.Head:scale((vec(-slimeWobble.wobble, slimeWobble.wobble, -slimeWobble.wobble) * upperLerp.currPos + 1):applyFunc(function(v) return isHelmet and math.min(v, 1) or v end))
		
		-- Scale shadow to size
		renderer:shadowRadius(scaleLerp.currPos - 0.25 * scaleLerp.currPos)
		
	end
end

-- Set wobble values
local function setStrength(x)
	
	local apply = x * 0.0005
	
	if strengthSwitch then 
		speed = math.clamp(speed + apply, speedMin, speedMax)
		config:save("WobbleSpeed", speed)
	else
		dampen = math.clamp(dampen + apply, dampenMin, dampenMax)
		config:save("WobbleDampening", dampen)
	end
	
end

-- Wobble value selection toggle
local function setStrengthSwitch()
	
	strengthSwitch = not strengthSwitch
	
end

-- Rotation wobble toggle
function pings.setWobbleRot(boolean)
	
	wobbleRot = boolean
	config:save("WobbleRot", wobbleRot)
	
end

-- Damage wobble toggle
function pings.setWobbleDamage(boolean)
	
	damage = boolean
	config:save("WobbleDamage", damage)
	
end

-- Biome wobble toggle
function pings.setWobbleBiome(boolean)
	
	biome = boolean
	config:save("WobbleBiome", biome)
	
end

-- Health size toggle
function pings.setWobbleHealthSize(boolean)
	
	healthSize = boolean
	config:save("WobbleHealthSize", healthSize)
	
end

-- Upper body wobble toggle
function pings.setWobbleUpperBody(boolean)
	
	upWobble = boolean
	config:save("WobbleUpperBody", upWobble)
	
end

-- Sync variables
function pings.syncWobble(a, b, c, d, e, f, g)
	
	speed      = a
	dampen     = b
	wobbleRot  = c
	damage     = d
	biome      = e
	healthSize = f
	upWobble   = g
	
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
		pings.syncWobble(speed, dampen, wobbleRot, damage, biome, healthSize, upWobble)
	end
	
end

-- Table setup
local t = {}

-- Actions
t.strengthAct = action_wheel:newAction()
	:onScroll(setStrength)
	:onLeftClick(setStrengthSwitch)
	:onRightClick(function()
		if strengthSwitch then
			speed = 0.0075
			config:save("WobbleSpeed", speed)
		else
			dampen = 0.0075
			config:save("WobbleDampening", dampen)
		end
	end)

t.rotAct = action_wheel:newAction()
	:item(itemCheck("music_disc_chirp"))
	:toggleItem(itemCheck("music_disc_far"))
	:onToggle(pings.setWobbleRot)
	:toggled(wobbleRot)

t.damageAct = action_wheel:newAction()
	:item(itemCheck("shield"))
	:toggleItem(itemCheck("iron_sword"))
	:onToggle(pings.setWobbleDamage)
	:toggled(damage)

t.biomeAct = action_wheel:newAction()
	:item(itemCheck("snow_block"))
	:toggleItem(itemCheck("water_bucket"))
	:onToggle(pings.setWobbleBiome)
	:toggled(biome)

t.healthSizeAct = action_wheel:newAction()
	:item(itemCheck("beef"))
	:toggleItem(itemCheck("cooked_beef"))
	:onToggle(pings.setWobbleHealthSize)
	:toggled(healthSize)

t.upperBodyAct = action_wheel:newAction()
	:onToggle(pings.setWobbleUpperBody)
	:toggled(upWobble)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		-- Variables
		local potionColor = math.lerp(vectors.hexToRGB("4CFF00"), vectors.hexToRGB("FFD800"),
		strengthSwitch and math.map(speed, speedMin, speedMax, 0, 1) or math.map(dampen, dampenMin, dampenMax, 0, 1))
		
		t.strengthAct
			:title(toJson
				{"",
				{text = "Set Wobble Strength\n\n", bold = true, color = color.primary},
				{text = "Sets the Speed/Dampening of the slime.\n\n", color = color.secondary},
				{text = "Set Speed: ", bold = true, color = color.secondary},
				{text = (strengthSwitch and "[%s]\n" or "%s\n"):format(math.map(speed, speedMin, speedMax, 0, 100).."%")},
				{text = "Modified Speed: ", bold = true, color = color.secondary},
				{text = math.map(slimeWobble.s, speedMin, speedMax, 0, 100).."%\n\n"},
				{text = "Set Dampening: ", bold = true, color = color.secondary},
				{text = (not strengthSwitch and "[%s]\n" or "%s\n"):format(math.map(dampen, dampenMin, dampenMax, 0, 100).."%")},
				{text = "Modified Dampening: ", bold = true, color = color.secondary},
				{text = math.map(slimeWobble.d, dampenMin, dampenMax, 0, 100).."%\n\n"},
				{text = "Scroll to adjust a value.\nLeft click selects which value is being adjusted.\nRight click resets the value back to 7.5%.", color = color.secondary}}
			)
			:item(itemCheck("potion{\"CustomPotionColor\":" .. tostring(vectors.rgbToInt(potionColor)) .. "}"))
		
		t.rotAct
			:title(toJson
				{"",
				{text = "Set Rotational Wobble\n\n", bold = true, color = color.primary},
				{text = "Sets if slime should wobble while you look around.", color = color.secondary}}
			)
		
		t.damageAct
			:title(toJson
				{"",
				{text = "Set Damage Wobble\n\n", bold = true, color = color.primary},
				{text = "Sets if slime should wobble if damage is taken.", color = color.secondary}}
			)
		
		t.biomeAct
			:title(toJson
				{"",
				{text = "Set Temperature Modifier\n\n", bold = true, color = color.primary},
				{text = "Sets if biome temperature should affect the slime wobble.", color = color.secondary}}
			)
		
		t.healthSizeAct
			:title(toJson
				{"",
				{text = "Set Health Size\n\n", bold = true, color = color.primary},
				{text = "Sets if your slime size is determinded by your health."..(powerActive and "\n\n" or ""), color = color.secondary},
				{text = powerActive and "Notice:\n" or "", bold = true, color = "gold"},
				{text = powerActive and "Origins is currently overriding this toggle." or "", color = "yellow"}}
			)
		
		t.upperBodyAct
			:title(toJson
				{"",
				{text = "Set Upper Body Wobble\n\n", bold = true, color = color.primary},
				{text = "Sets if your upper body should wobble just like your lower body.", color = color.secondary}}
			)
		
		for _, act in pairs(t) do
			act:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return actions
return t