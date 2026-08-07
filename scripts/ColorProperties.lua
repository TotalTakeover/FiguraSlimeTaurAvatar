-- Host only instructions
if not host:isHost() then return end

-- Table setup
local colors = {}

-- Action variables
colors.hover     = vectors.hexToRGB("FFFFFF")
colors.active    = vectors.hexToRGB("FFFFFF")
colors.primary   = "#FFFFFF"
colors.secondary = "#FFFFFF"

-- Return variables
return colors