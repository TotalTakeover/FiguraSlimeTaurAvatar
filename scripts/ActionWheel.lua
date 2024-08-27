-- Disables code if not avatar host
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")

local s, avatar = pcall(require, "scripts.Player")
if not s then avatar = {} end

local s, armor = pcall(require, "scripts.Armor")
if not s then armor = {} end

local s, camera = pcall(require, "scripts.CameraControl")
if not s then camera = {} end

local s, wobble = pcall(require, "scripts.Wobble")
if not s then wobble = {} end

local s, color, colorActs = pcall(require, "scripts.ColorProperties")
if not s then color = {} colorActs = {} end

local s, trail = pcall(require, "scripts.Trail")
if not s then trail = {} end

local s, squish = pcall(require, "scripts.SquishSound")
if not s then squish = {} end

local s, items = pcall(require, "scripts.Items")
if not s then items = {} end

local s, _, anims = pcall(require, "scripts.Anims")
if not s then anims = {} end

local s, squapi = pcall(require, "scripts.SquishyAnims")
if not s then squapi = {} end

-- Logs pages for navigation
local navigation = {}

-- Go forward a page
local function descend(page)
	
	navigation[#navigation + 1] = action_wheel:getCurrentPage() 
	action_wheel:setPage(page)
	
end

-- Go back a page
local function ascend()
	
	action_wheel:setPage(table.remove(navigation, #navigation))
	
end

-- Page setups
local pages = {
	
	main   = action_wheel:newPage("Main"),
	avatar = action_wheel:newPage("Avatar"),
	armor  = action_wheel:newPage("Armor"),
	camera = action_wheel:newPage("Camera"),
	slime  = action_wheel:newPage("Slime"),
	wobble = action_wheel:newPage("Wobble"),
	color  = action_wheel:newPage("Color"),
	anims  = action_wheel:newPage("Anims")
	
}

-- Page actions
local pageActs = {
	
	avatar = action_wheel:newAction()
		:item(itemCheck("armor_stand"))
		:onLeftClick(function() descend(pages.avatar) end),
	
	slime = action_wheel:newAction()
		:item(itemCheck("slime_block"))
		:onLeftClick(function() descend(pages.slime) end),
	
	color = action_wheel:newAction()
		:item(itemCheck("brewing_stand"))
		:onLeftClick(function() descend(pages.color) end),
	
	anims = action_wheel:newAction()
		:item(itemCheck("jukebox"))
		:onLeftClick(function() descend(pages.anims) end),
	
	armor = action_wheel:newAction()
		:item(itemCheck("iron_chestplate"))
		:onLeftClick(function() descend(pages.armor) end),
	
	camera = action_wheel:newAction()
		:item(itemCheck("redstone"))
		:onLeftClick(function() descend(pages.camera) end),
	
	wobble = action_wheel:newAction()
		:onLeftClick(function() descend(pages.wobble) end)
	
}

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		pageActs.avatar
			:title(toJson
				{text = "Avatar Settings", bold = true, color = color.primary}
			)
		
		pageActs.slime
			:title(toJson
				{text = "Slime Settings", bold = true, color = color.primary}
			)
		
		pageActs.color
			:title(toJson
				{text = "Color Settings", bold = true, color = color.primary}
			)
		
		pageActs.anims
			:title(toJson
				{text = "Animations", bold = true, color = color.primary}
			)
		
		pageActs.armor
			:title(toJson
				{text = "Armor Settings", bold = true, color = color.primary}
			)
		
		pageActs.camera
			:title(toJson
				{text = "Camera Settings", bold = true, color = color.primary}
			)
		
		pageActs.wobble
			:title(toJson
				{text = "Wobble Settings", bold = true, color = color.primary}
			)
			:item(itemCheck("potion{\"CustomPotionColor\":" .. tostring(vectors.rgbToInt(color.hover)) .. "}"))
		
		for _, page in pairs(pageActs) do
			page:hoverColor(color.hover)
		end
		
	end
	
end

-- Action back to previous page
local backAct = action_wheel:newAction()
	:title(toJson
		{text = "Go Back?", bold = true, color = "red"}
	)
	:hoverColor(vectors.hexToRGB("FF5555"))
	:item(itemCheck("barrier"))
	:onLeftClick(function() ascend() end)

-- Set starting page to main page
action_wheel:setPage(pages.main)

-- Main actions
pages.main
	:action( -1, pageActs.avatar)
	:action( -1, pageActs.slime)
	:action( -1, pageActs.color)
	:action( -1, pageActs.anims)

-- Avatar actions
pages.avatar
	:action( -1, avatar.vanillaSkinAct)
	:action( -1, avatar.modelAct)
	:action( -1, pageActs.armor)
	:action( -1, pageActs.camera)
	:action( -1, backAct)

-- Armor actions
pages.armor
	:action( -1, armor.allAct)
	:action( -1, armor.bootsAct)
	:action( -1, armor.leggingsAct)
	:action( -1, armor.chestplateAct)
	:action( -1, armor.helmetAct)
	:action( -1, backAct)

-- Camera actions
pages.camera
	:action( -1, camera.posAct)
	:action( -1, camera.eyeAct)
	:action( -1, backAct)

-- Slime actions
pages.slime
	:action( -1, pageActs.wobble)
	:action( -1, items.embedAct)
	:action( -1, wobble.healthSizeAct)
	:action( -1, trail.trailAct)
	:action( -1, squish.soundAct)
	:action( -1, backAct)

-- Wobble actions
pages.wobble
	:action( -1, wobble.strengthAct)
	:action( -1, wobble.damageAct)
	:action( -1, wobble.biomeAct)
	:action( -1, backAct)

-- Color actions
pages.color
	:action( -1, colorActs.pickAct)
	:action( -1, colorActs.camoAct)
	:action( -1, colorActs.rainbowAct)
	:action( -1, backAct)

-- Animation actions
pages.anims
	:action( -1, squapi.armsAct)
	:action( -1, backAct)