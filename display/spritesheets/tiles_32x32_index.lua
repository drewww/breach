TILES = {}

TILES.OFFSET = 256

-- Helper to convert (row, col) to index
-- For a 16-wide grid
local function at(row, col, width)
   width = width or 16
   return TILES.OFFSET + (row * width) + col
end

TILES.WALL_1 = at(0, 1)
TILES.WALL_2 = at(0, 2)
TILES.WALL_3 = at(0, 3)
TILES.WALL_4 = at(0, 4)
TILES.WALL_5 = at(0, 5)
TILES.WALL_6 = at(0, 6)
TILES.WALL_7 = at(0, 7)
TILES.WALL_8 = at(0, 8)


TILES.WALL_EDGE_1 = at(1, 1)
TILES.WALL_EDGE_2 = at(1, 2)
TILES.WALL_EDGE_3 = at(1, 3)
TILES.WALL_EDGE_4 = at(1, 4)
TILES.WALL_EDGE_5 = at(1, 5)
TILES.WALL_EDGE_6 = at(1, 6)
TILES.WALL_EDGE_7 = at(1, 7)
TILES.WALL_EDGE_8 = at(1, 8)

TILES.FLOOR_1 = at(2, 1)
TILES.FLOOR_2 = at(2, 2)
TILES.FLOOR_3 = at(2, 3)

TILES.DOOR_CLOSED = at(2, 4)
TILES.DOOR_OPEN = at(2, 5)

TILES.PLAYER = at(5, 1)
TILES.BOT = at(5, 5)

return TILES
