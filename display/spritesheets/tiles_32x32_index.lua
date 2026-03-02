TILES = {}

TILES.OFFSET = 256

-- Helper to convert (row, col) to index
-- For a 16-wide grid
local function at(row, col, width)
   width = width or 16
   return TILES.OFFSET + (row * width) + col
end

TILES.WALL_1 = at(1, 1)
TILES.WALL_2 = at(1, 2)
TILES.WALL_3 = at(1, 3)

return TILES
