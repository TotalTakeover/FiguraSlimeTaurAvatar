-- Force load after
require("scripts.Wobble")

-- Required script
local parts = require("lib.PartsAPI")

-- Kills script if it cannot find the stored items group
if not parts.group.StoredItems then return {} end

-- Config setup
config:name("SlimeTaur")
local embed = config:load("ItemsEmbed")
if embed == nil then embed = true end

local groups = {}
local items  = {}

for i = 1, 27 do
	
	groups[i] = parts.group.StoredItems["StoredItem"..i]:newItem("Item"):displayMode("GROUND")
	items[i]  = "minecraft:air"
	
end

function events.TICK()
	
	for i = 1, 27 do
		
		-- Get slot item
		local item = host:getSlot(i+8)
		
		-- Apply
		groups[i]
			:item(item)
			:visible(embed)
		
		-- Store
		items[i] = item
		
	end
	
end

function events.RENDER(delta, context)
	
	local timer = world.getTime(delta)
	
	for i = 1, 27 do
		
		groups[i]
			:pos(math.sin(timer * 0.01 + (i * 2)) * parts.group.Slime_Wobble:getScale())
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

-- Required script
local s, color = pcall(require, "scripts.ColorProperties")
if not s then color = {} end

-- Sync on tick
function events.TICK()
	
	if world.getTime() % 200 == 0 then
		pings.syncItems(embed, items)
	end
	
end

-- Table setup
local t = {}

-- Action
t.embedAct = action_wheel:newAction()
	:texture(textures:fromVanilla("BundleFilled", "textures/item/bundle_filled.png"))
	:toggleTexture(textures:fromVanilla("Bundle", "textures/item/bundle.png"))
	:onToggle(pings.setItems)
	:toggled(embed)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		t.embedAct
			:title(toJson
				{"",
				{text = "Toggle Slime Items\n\n", bold = true, color = color.primary},
				{text = "Toggles the visibility of inventory items within your slime.", color = color.secondary},
				{text = "\n\nNotice:\n", bold = true, color = "gold"},
				{text = "This feature currently does not function for other clients, only the host.\nThis is because I suck at coding. -Total", color = "yellow"}}
			)
		
		for _, page in pairs(t) do
			page:hoverColor(color.hover):toggleColor(color.active)
		end
		
	end
	
end

-- Return action
return t