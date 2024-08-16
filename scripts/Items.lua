-- Force load after
require("scripts.Wobble")

-- Required script
local slimeParts = require("lib.GroupIndex")(models.SlimeTaur)

-- Config setup
config:name("SlimeTaur")
local embed = config:load("ItemsEmbed")
if embed == nil then embed = true end

local items = {}
local parts = {}

for i = 1, 27 do
	
	parts[i] = slimeParts.StoredItems["StoredItem"..i]:newItem("Item"):displayMode("GROUND")
	items[i] = "minecraft:air"
	
end

function events.TICK()
	
	for i = 1, 27 do
		
		-- Get slot item
		local item = host:getSlot(i+8)
		
		-- Apply
		parts[i]
			:item(item)
			:visible(embed)
		
		-- Store
		items[i] = item
		
	end
	
end

function events.RENDER(delta, context)
	
	local timer = world.getTime(delta)
	
	for i = 1, 27 do
		
		parts[i]
			:pos(math.sin(timer * 0.01 + (i * 2)) * slimeParts.Slime:getScale())
			:rot(0, (timer * 0.1 + (i * 13.3)) % 360, 0)
		
	end
	
end

-- Items toggle
function pings.setItems(boolean)
	
	embed = boolean
	config:save("ItemsEmbed", embed)
	
end

-- Sync variables
function pings.syncItems(a, b)
	
	embed = a
	items = b
	
end

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local color = require("scripts.ColorProperties")

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncItems(embed, items)
	end
	
end

-- Table setup
local t = {}

-- Action
t.embedPage = action_wheel:newAction()
	:texture(textures:fromVanilla("BundleFilled", "textures/item/bundle_filled.png"))
	:toggleTexture(textures:fromVanilla("Bundle", "textures/item/bundle.png"))
	:onToggle(pings.setItems)
	:toggled(embed)

-- Update actions
function events.TICK()
	
	if action_wheel:isEnabled() then
		t.embedPage
			:title(toJson
				{"",
				{text = "Toggle Slime Items\n\n", bold = true, color = color.primary},
				{text = "Toggles the visibility of inventory items within your slime.", color = color.secondary}}
			)
		
		for _, page in pairs(t) do
			page:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return action
return t