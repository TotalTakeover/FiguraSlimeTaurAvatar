-- Required script
local parts = require("lib.PartsAPI")

-- Config setup
config:name("SlimeTaur")
local vanillaSkin = config:load("AvatarVanillaSkin")
local slim        = config:load("AvatarSlim") or false
if vanillaSkin == nil then vanillaSkin = true end

-- Reenabled parts
parts.group.Skull   :visible(true)
parts.group.Portrait:visible(true)

-- Vanilla skin parts
local skin = {
	
	parts.group.Head.Head,
	parts.group.Head.Layer,
	
	parts.group.Body.Body,
	parts.group.Body.Layer,
	
	parts.group.leftArmDefault,
	parts.group.leftArmSlim,
	parts.group.leftArmDefaultFP,
	parts.group.leftArmSlimFP,
	
	parts.group.rightArmDefault,
	parts.group.rightArmSlim,
	parts.group.rightArmDefaultFP,
	parts.group.rightArmSlimFP,
	
	parts.group.Portrait.Head,
	parts.group.Portrait.Layer,
	
	parts.group.Skull.Head,
	parts.group.Skull.Layer
	
}

-- Layer parts
local layer = {
	
	HAT = {
		parts.group.Head.Layer
	},
	JACKET = {
		parts.group.Body.Layer
	},
	LEFT_SLEEVE = {
		parts.group.leftArmDefault.Layer,
		parts.group.leftArmSlim.Layer,
		parts.group.leftArmDefaultFP.Layer,
		parts.group.leftArmSlimFP.Layer
	},
	RIGHT_SLEEVE = {
		parts.group.rightArmDefault.Layer,
		parts.group.rightArmSlim.Layer,
		parts.group.rightArmDefaultFP.Layer,
		parts.group.rightArmSlimFP.Layer
	},
	CAPE = {
		parts.group.Cape
	},
	LOWER_BODY = {
		parts.group.Slime.Layer
	}
	
}

-- Determine vanilla player type on init
local vanillaAvatarType
function events.ENTITY_INIT()
	
	vanillaAvatarType = player:getModelType()
	
end

function events.RENDER(delta, context)
	
	-- Model shape
	local slimShape = (vanillaSkin and vanillaAvatarType == "SLIM") or (slim and not vanillaSkin)
	
	parts.group.leftArmDefault:visible(not slimShape)
	parts.group.rightArmDefault:visible(not slimShape)
	parts.group.leftArmDefaultFP:visible(not slimShape)
	parts.group.rightArmDefaultFP:visible(not slimShape)
	
	parts.group.leftArmSlim:visible(slimShape)
	parts.group.rightArmSlim:visible(slimShape)
	parts.group.leftArmSlimFP:visible(slimShape)
	parts.group.rightArmSlimFP:visible(slimShape)
	
	-- Skin textures
	local skinType = vanillaSkin and "SKIN" or "PRIMARY"
	for _, part in ipairs(skin) do
		part:primaryTexture(skinType)
	end
	
	-- Cape textures
	parts.group.Cape:primaryTexture(vanillaSkin and "CAPE" or "PRIMARY")
	
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
		parts.group.Player:scale(0.7)
	end
	
end

function events.POST_RENDER(delta, context)
	
	-- After scaling models to fit GUIs, immediately scale back
	parts.group.Player:scale(1)
	
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
local s, color = pcall(require, "scripts.ColorProperties")
if not s then color = {} end

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
	:item(itemCheck("player_head{SkullOwner:"..avatar:getEntityName().."}"))
	:onToggle(pings.setAvatarVanillaSkin)
	:toggled(vanillaSkin)

t.modelAct = action_wheel:newAction()
	:item(itemCheck("player_head"))
	:toggleItem(itemCheck("player_head{SkullOwner:MHF_Alex}"))
	:onToggle(pings.setAvatarModelType)
	:toggled(slim)

-- Update actions
function events.RENDER(delta, context)
	
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