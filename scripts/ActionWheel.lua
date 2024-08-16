-- Disables code if not avatar host
if not host:isHost() then return end

-- Required scripts
local itemCheck = require("lib.ItemCheck")
local avatar    = require("scripts.Player")
local armor     = require("scripts.Armor")
local camera    = require("scripts.CameraControl")
local wobble    = require("scripts.Wobble")
local c, color  = require("scripts.ColorProperties")
local trail     = require("scripts.Trail")
local squish    = require("scripts.SquishSound")
local items     = require("scripts.Items")
local anims     = require("scripts.Anims")
local arms      = require("scripts.Arms")

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
	
	main   = action_wheel:newPage(),
	avatar = action_wheel:newPage(),
	armor  = action_wheel:newPage(),
	camera = action_wheel:newPage(),
	slime  = action_wheel:newPage(),
	wobble = action_wheel:newPage(),
	color  = action_wheel:newPage(),
	anims  = action_wheel:newPage()
	
}

-- Page actions
local pageActions = {
	
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
function events.TICK()
	
	if action_wheel:isEnabled() then
		pageActions.avatar
			:title(toJson
				{text = "Avatar Settings", bold = true, color = c.primary}
			)
		
		pageActions.slime
			:title(toJson
				{text = "Slime Settings", bold = true, color = c.primary}
			)
		
		pageActions.color
			:title(toJson
				{text = "Color Settings", bold = true, color = c.primary}
			)
		
		pageActions.anims
			:title(toJson
				{text = "Animations", bold = true, color = c.primary}
			)
		
		pageActions.armor
			:title(toJson
				{text = "Armor Settings", bold = true, color = c.primary}
			)
		
		pageActions.camera
			:title(toJson
				{text = "Camera Settings", bold = true, color = c.primary}
			)
		
		pageActions.wobble
			:title(toJson
				{text = "Wobble Settings", bold = true, color = c.primary}
			)
			:item(itemCheck("potion{\"CustomPotionColor\":" .. tostring(vectors.rgbToInt(c.hover)) .. "}"))
		
		for _, page in pairs(pageActions) do
			page:hoverColor(c.hover)
		end
		
	end
	
end

-- Action back to previous page
local backAction = action_wheel:newAction()
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
	:action( -1, pageActions.avatar)
	:action( -1, pageActions.slime)
	:action( -1, pageActions.color)
	:action( -1, pageActions.anims)

-- Avatar actions
pages.avatar
	:action( -1, avatar.vanillaSkinPage)
	:action( -1, avatar.modelPage)
	:action( -1, pageActions.armor)
	:action( -1, pageActions.camera)
	:action( -1, backAction)

-- Armor actions
pages.armor
	:action( -1, armor.allPage)
	:action( -1, armor.bootsPage)
	:action( -1, armor.leggingsPage)
	:action( -1, armor.chestplatePage)
	:action( -1, armor.helmetPage)
	:action( -1, backAction)

-- Camera actions
pages.camera
	:action( -1, camera.posPage)
	:action( -1, camera.eyePage)
	:action( -1, backAction)

-- Slime actions
pages.slime
	:action( -1, pageActions.wobble)
	:action( -1, items.embedPage)
	:action( -1, wobble.healthSizePage)
	:action( -1, trail.trailPage)
	:action( -1, squish.soundPage)
	:action( -1, backAction)

-- Wobble actions
pages.wobble
	:action( -1, wobble.strengthPage)
	:action( -1, wobble.damagePage)
	:action( -1, wobble.healthModPage)
	:action( -1, wobble.biomePage)
	:action( -1, wobble.hazardPage)
	:action( -1, backAction)

-- Color actions
pages.color
	:action( -1, color.pickPage)
	:action( -1, color.camoPage)
	:action( -1, color.rainbowPage)
	:action( -1, backAction)

-- Animation actions
pages.anims
	:action( -1, arms.movePage)
	:action( -1, backAction)