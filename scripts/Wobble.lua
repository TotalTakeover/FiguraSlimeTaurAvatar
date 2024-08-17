-- Required scripts
local slimeParts = require("lib.GroupIndex")(models.SlimeTaur)
local wobble     = require("lib.CMWobble")
local origins    = require("lib.OriginsAPI")
local pose       = require("scripts.Posing")

-- Wobble Setup
local slimeWobble = wobble:newWobbleSetup()

-- Config setup
config:name("SlimeTaur")
local speed      = config:load("WobbleSpeed") or 0.0075
local dampen     = config:load("WobbleDampening") or 0.0075
local damage     = config:load("WobbleDamage")
local healthMod  = config:load("WobbleHealthMod")
local biome      = config:load("WobbleBiome")
local hazard     = config:load("WobbleHazard")
local healthSize = config:load("WobbleHealthSize") or false
if damage    == nil then damage    = true end
if healthMod == nil then healthMod = true end
if biome     == nil then biome     = true end
if hazard    == nil then hazard    = true end

-- Variables
local scaleApply   = 0
local crouchWobble = 0.02
local damageWobble = 0.025
local isCrouching  = false
local powerActive  = false
local swimTimer    = 0
local speedMin,  speedMax  = 0, 0.1
local dampenMin, dampenMax = 0, 0.1
local strengthSwitch = true

-- Choose objects to stay consistent in the slime
local slimePivots = {
	
	slimeParts.UpperBody,
	slimeParts.Slime,
	slimeParts.LeftLeggingPivot,
	slimeParts.RightLeggingPivot,
	slimeParts.LeftBootPivot,
	slimeParts.RightBootPivot

}

-- Establish embedded items
for i = 1, 27 do
	
	local newPart = slimeParts.StoredItems:newPart("StoredItem"..i)
	table.insert(slimePivots, newPart)
	newPart
		:pivot(slimeParts.StoredItems:getPivot() + vec((i-1)%3-1, math.ceil(i/9-2), math.floor((i-1)/3%3-1)) * 5)
	
end

-- Scale lerp
local scaleSize = {
	current    = 1,
	nextTick   = 1,
	target     = 1,
	currentPos = 1
}

function events.TICK()
	
	-- Check if origin power is active
	powerActive = origins.getPowerData(player, "slime_taur:varied_sizing_toggle") == 1
	
	-- Change size based on health or origin power
	if powerActive then
		
		local moisture = origins.getPowerData(player, "slime_taur:moisture_bar") or 50
		scaleSize.target = ((player:getHealth() / player:getMaxHealth()) * 1.5) * (moisture / 100 + 0.5)
		
	elseif healthSize then
		
		scaleSize.target = (player:getHealth() / player:getMaxHealth()) * 1.5 + 0.5
		
	else
		
		scaleSize.target = 1
		
	end
	
	--log(scaleSize.target)
	
	-- Tick lerp
	scaleSize.current = scaleSize.nextTick
	scaleSize.nextTick = math.lerp(scaleSize.nextTick, scaleSize.target, 0.2)
	
end

function events.RENDER(delta, context)
	
	-- Render lerp
	scaleSize.currentPos = math.lerp(scaleSize.current, scaleSize.nextTick, delta)
	
	-- Variables
	local vel     = player:getVelocity()
	local animPos = slimeParts.Player:getAnimPos().y
	local water   = player:isInWater()
	
	-- Apply speed and dampen values
	slimeWobble.s = speed
	slimeWobble.d = dampen
	
	-- Modify based on health
	if healthMod then
		
		local apply = player:getHealth() / player:getMaxHealth()
		
		slimeWobble.s = slimeWobble.s * math.map(apply, 0, 1, 2, 1)
		slimeWobble.d = slimeWobble.d * apply
		
	end
	
	-- Modify based on biome
	if biome then
		
		local biomePos = world.getBiome(player:getPos())
		local apply = math.map(biomePos:getTemperature(), -0.7, 2, 0.1, 1.9)
		
		slimeWobble.s = slimeWobble.s * apply
		slimeWobble.d = slimeWobble.d * (math.map(apply, 0, 1, 1, 0) + 1)
		
	end
	
	-- Modify based on hazards
	if hazard then
		
		local frozen = math.map(player:getFrozenTicks(), 0, 140, 0, 1)
		local fire   = player:isOnFire() and 1 or 0
		
		slimeWobble.s = math.lerp(slimeWobble.s, 0,   frozen)
		slimeWobble.d = math.lerp(slimeWobble.d, 0.1, frozen)
		
		slimeWobble.d = math.lerp(slimeWobble.d, 0, fire)
		
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
		local offsetPos = (pivot * slimeParts.Slime:getScale()) - pivot
		part:pos(offsetPos)
		
	end
	
	-- Applies offset to lowerBody itself
	local offsetPivot = slimeParts.Slime:getPivot() * slimeParts.Slime:getScale()
	slimeParts.LowerBody:pivot(offsetPivot)
	
end

function events.WORLD_RENDER(delta, context)
	if player:isLoaded() then
		
		-- Check for passengers
		local increase = vec(0, 0, 0)
		if #player:getPassengers() ~= 0 then
			
			local rider = player:getPassengers()[1]
			increase = rider:getBoundingBox()
			
		end
		
		-- Calculates the Wobble and applies it
		slimeWobble:update(scaleApply, true)
		local calcWobble = slimeWobble.wobble * scaleSize.currentPos
		slimeParts.Slime:scale(
			vec(scaleSize.currentPos - calcWobble,
				scaleSize.currentPos + calcWobble,
				scaleSize.currentPos - calcWobble)
				+ increase
			)
		
		-- Scale shadow to size
		renderer:shadowRadius(scaleSize.currentPos - 0.25 * scaleSize.currentPos)
		
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

-- Damage wobble toggle
function pings.setWobbleDamage(boolean)
	
	damage = boolean
	config:save("WobbleDamage", damage)
	
end

-- Health wobble toggle
function pings.setWobbleHealthMod(boolean)
	
	healthMod = boolean
	config:save("WobbleHealthMod", healthMod)
	
end

-- Biome wobble toggle
function pings.setWobbleBiome(boolean)
	
	biome = boolean
	config:save("WobbleBiome", biome)
	
end

-- Hazard wobble toggle
function pings.setWobbleHazard(boolean)
	
	hazard = boolean
	config:save("WobbleHazard", hazard)
	
end

-- Health size toggle
function pings.setWobbleHealthSize(boolean)
	
	healthSize = boolean
	config:save("WobbleHealthSize", healthSize)
	
end

-- Sync variables
function pings.syncWobble(a, b, c, d, e, f, g)
	
	speed      = a
	dampen     = b
	damage     = c
	healthMod  = d
	biome      = e
	hazard     = f
	healthSize = g
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local color     = require("scripts.ColorProperties")

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncWobble(speed, dampen, damage, healthMod, biome, hazard, healthSize)
	end
	
end

-- Table setup
local t = {}

-- Actions
t.strengthPage = action_wheel:newAction()
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

t.damagePage = action_wheel:newAction()
	:item(itemCheck("shield"))
	:toggleItem(itemCheck("iron_sword"))
	:onToggle(pings.setWobbleDamage)
	:toggled(damage)

t.healthModPage = action_wheel:newAction()
	:item(itemCheck("apple"))
	:toggleItem(itemCheck("golden_apple"))
	:onToggle(pings.setWobbleHealthMod)
	:toggled(healthMod)

t.biomePage = action_wheel:newAction()
	:item(itemCheck("snow_block"))
	:toggleItem(itemCheck("water_bucket"))
	:onToggle(pings.setWobbleBiome)
	:toggled(biome)

t.hazardPage = action_wheel:newAction()
	:item(itemCheck("flint"))
	:toggleItem(itemCheck("flint_and_steel"))
	:onToggle(pings.setWobbleHazard)
	:toggled(hazard)

t.healthSizePage = action_wheel:newAction()
	:item(itemCheck("beef"))
	:toggleItem(itemCheck("cooked_beef"))
	:onToggle(pings.setWobbleHealthSize)
	:toggled(healthSize)

-- Update actions
function events.TICK()
	
	if action_wheel:isEnabled() then
		-- Variables
		local potionColor = math.lerp(vectors.hexToRGB("4CFF00"), vectors.hexToRGB("FFD800"),
		strengthSwitch and math.map(speed, speedMin, speedMax, 0, 1) or math.map(dampen, dampenMin, dampenMax, 0, 1))
		
		t.strengthPage
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
		
		t.damagePage
			:title(toJson
				{"",
				{text = "Set Damage Wobble\n\n", bold = true, color = color.primary},
				{text = "Sets if slime should wobble if damage is taken.", color = color.secondary}}
			)
		
		t.healthModPage
			:title(toJson
				{"",
				{text = "Set Health Modifier\n\n", bold = true, color = color.primary},
				{text = "Sets if damage taken should affect your ability to maintain form.", color = color.secondary}}
			)
		
		t.biomePage
			:title(toJson
				{"",
				{text = "Set Temperature Modifier\n\n", bold = true, color = color.primary},
				{text = "Sets if biome temperature should affect the slime wobble.", color = color.secondary}}
			)
		
		t.hazardPage
			:title(toJson
				{"",
				{text = "Set Hazard Modifier\n\n", bold = true, color = color.primary},
				{text = "Sets if hazards like Fire and Powder Snow should affect the slime wobble.", color = color.secondary}}
			)
		
		t.healthSizePage
			:title(toJson
				{"",
				{text = "Set Health Size\n\n", bold = true, color = color.primary},
				{text = "Sets if your slime size is determinded by your health."..(powerActive and "\n\n" or ""), color = color.secondary},
				{text = powerActive and "Notice:\n" or "", bold = true, color = "gold"},
				{text = powerActive and "Origins is currently overriding this toggle." or "", color = "yellow"}}
			)
		
		for _, page in pairs(t) do
			page:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return actions
return t