-- Force load after
require("scripts.Wobble")

-- Required scripts
local parts = require("lib.PartsAPI")
local sync  = require("lib.LetThatSyncFig")

-- Kills script if it cannot find the stored items group
if not parts.group.StoredItems then return {} end

-- Synced variables setup
local embed = sync.new("ItemsEmbed", true):config()
local items = sync.new("ItemsTable", {})

-- Variable
local groups = {}

for i = 1, 27 do
	
	groups[i] = parts.group.StoredItems["StoredItem"..i]:newItem("Item"):displayMode("GROUND")
	items.curr[i]  = "minecraft:air"
	
end

function events.TICK()
	
	for i = 1, 27 do
		
		-- Get slot item
		local item = host:getSlot(i+8)
		
		-- Apply
		groups[i]
			:item(item)
			:visible(embed.curr)
		
		-- Store
		items.curr[i] = item
		
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

-- Host only instructions
if not host:isHost() then return end

-- Required scripts
local s, wheel, c = pcall(require, "scripts.ActionWheel")
if not s then return end -- Kills script early if ActionWheel.lua isnt found
pcall(require, "scripts.ColorChange") -- Tries to find script, not required

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
		:item("slime_block")
		:onLeftClick(function() wheel:descend(slimePage) end)
end

a.embedAct = slimePage:newAction()
	:texture(textures:fromVanilla("BundleFilled", "textures/item/bundle_filled.png"))
	:toggleTexture(textures:fromVanilla("Bundle", "textures/item/bundle.png"))
	:onToggle(function(bool)
		embed:update(bool)
	end)
	:toggled(embed.curr)

-- Update actions
function events.RENDER(delta, context)
	
	if action_wheel:isEnabled() then
		if a.pageAct then
			a.pageAct
				:title(toJson(
					{text = "Slime Settings", bold = true, color = c.primary}
				))
		end
		
		a.embedAct
			:title(toJson(
				{
					"",
					{text = "Toggle Slime Items\n\n", bold = true, color = c.primary},
					{text = "Toggles the visibility of inventory items within your slime.", color = c.secondary},
					{text = "\n\nNotice:\n", bold = true, color = "gold"},
					{text = "This feature currently does not function for other clients, only the host.\nThis is because I suck at coding. -Total", color = "yellow"}
				}
			))
		
		for _, act in pairs(a) do
			act:hoverColor(c.hover):toggleColor(c.active)
		end
		
	end
	
end