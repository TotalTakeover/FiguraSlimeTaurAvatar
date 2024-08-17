-- Required script
local slimeParts = require("lib.GroupIndex")(models.SlimeTaur)

-- Config setup
config:name("SlimeTaur")
local vanillaSkin = config:load("AvatarVanillaSkin")
local slim        = config:load("AvatarSlim") or false
if vanillaSkin == nil then vanillaSkin = true end

-- Set skull and portrait groups to visible (incase disabled in blockbench)
slimeParts.Skull   :visible(true)
slimeParts.Portrait:visible(true)

-- Vanilla skin parts
local skin = {
	
	slimeParts.Head.Head,
	slimeParts.Head.Layer,
	
	slimeParts.Body.Body,
	slimeParts.Body.Layer,
	
	slimeParts.leftArmDefault,
	slimeParts.leftArmSlim,
	slimeParts.leftArmDefaultFP,
	slimeParts.leftArmSlimFP,
	
	slimeParts.rightArmDefault,
	slimeParts.rightArmSlim,
	slimeParts.rightArmDefaultFP,
	slimeParts.rightArmSlimFP,
	
	slimeParts.Portrait.Head,
	slimeParts.Portrait.Layer,
	
	slimeParts.Skull.Head,
	slimeParts.Skull.Layer
	
}

-- Layer parts
local layer = {
	
	HAT = {
		slimeParts.Head.Layer
	},
	JACKET = {
		slimeParts.Body.Layer
	},
	LEFT_SLEEVE = {
		slimeParts.leftArmDefault.Layer,
		slimeParts.leftArmSlim.Layer,
		slimeParts.leftArmDefaultFP.Layer,
		slimeParts.leftArmSlimFP.Layer
	},
	RIGHT_SLEEVE = {
		slimeParts.rightArmDefault.Layer,
		slimeParts.rightArmSlim.Layer,
		slimeParts.rightArmDefaultFP.Layer,
		slimeParts.rightArmSlimFP.Layer
	},
	CAPE = {
		slimeParts.Cape
	},
	LOWER_BODY = {
		slimeParts.Slime.Layer
	}
	
}

-- Determine vanilla player type on init
local vanillaAvatarType
function events.ENTITY_INIT()
	
	vanillaAvatarType = player:getModelType()
	
end

-- Misc tick required events
function events.TICK()
	
	-- Model shape
	local slimShape = (vanillaSkin and vanillaAvatarType == "SLIM") or (slim and not vanillaSkin)
	
	slimeParts.leftArmDefault:visible(not slimShape)
	slimeParts.rightArmDefault:visible(not slimShape)
	slimeParts.leftArmDefaultFP:visible(not slimShape)
	slimeParts.rightArmDefaultFP:visible(not slimShape)
	
	slimeParts.leftArmSlim:visible(slimShape)
	slimeParts.rightArmSlim:visible(slimShape)
	slimeParts.leftArmSlimFP:visible(slimShape)
	slimeParts.rightArmSlimFP:visible(slimShape)
	
	-- Skin textures
	local skinType = vanillaSkin and "SKIN" or "PRIMARY"
	for _, part in ipairs(skin) do
		part:primaryTexture(skinType)
	end
	
	-- Cape textures
	slimeParts.Cape:primaryTexture(vanillaSkin and "CAPE" or "PRIMARY")
	
	-- Layer toggling
	for layerType, parts in pairs(layer) do
		local enabled = enabled
		if layerType == "LOWER_BODY" then
			enabled = player:isSkinLayerVisible("RIGHT_PANTS_LEG") or player:isSkinLayerVisible("LEFT_PANTS_LEG")
		else
			enabled = player:isSkinLayerVisible(layerType)
		end
		for _, part in ipairs(parts) do
			part:visible(enabled)
		end
	end
	
end

function events.RENDER(delta, context)
	
	-- Scales models to fit GUIs better
	if context == "FIGURA_GUI" or context == "MINECRAFT_GUI" or context == "PAPERDOLL" then
		slimeParts.Player:scale(0.7)
	end
	
end

function events.POST_RENDER(delta, context)
	
	-- After scaling models to fit GUIs, immediately scale back
	slimeParts.Player:scale(1)
	
end

-- Vanilla skin toggle
function pings.setAvatarVanillaSkin(boolean)
	
	vanillaSkin = boolean
	config:save("AvatarVanillaSkin", vanillaSkin)
	
end

-- Model type toggle
function pings.setAvatarModelType(boolean)
	
	slim = boolean
	config:save("AvatarSlim", slim)
	
end

-- Sync variables
function pings.syncPlayer(a, b)
	
	vanillaSkin = a
	slim = b
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local color     = require("scripts.ColorProperties")

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncPlayer(vanillaSkin, slim)
	end
	
end

-- Table setup
local t = {}

-- Actions
t.vanillaSkinAct = action_wheel:newAction()
	:item(itemCheck("player_head{'SkullOwner':'"..avatar:getEntityName().."'}"))
	:onToggle(pings.setAvatarVanillaSkin)
	:toggled(vanillaSkin)

t.modelAct = action_wheel:newAction()
	:item(itemCheck("player_head"))
	:toggleItem(itemCheck("player_head{'SkullOwner':'MHF_Alex'}"))
	:onToggle(pings.setAvatarModelType)
	:toggled(slim)

-- Update actions
function events.TICK()
	
	if action_wheel:isEnabled() then
		t.vanillaSkinAct
			:title(toJson
				{"",
				{text = "Toggle Vanilla Texture\n\n", bold = true, color = color.primary},
				{text = "Toggles the usage of your vanilla skin.", color = color.secondary}}
			)
		
		t.modelAct
			:title(toJson
				{"",
				{text = "Toggle Model Shape\n\n", bold = true, color = color.primary},
				{text = "Adjust the model shape to use Default or Slim Proportions.\nWill be overridden by the vanilla skin toggle.", color = color.secondary}}
			)
		
		for _, page in pairs(t) do
			page:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return actions
return t