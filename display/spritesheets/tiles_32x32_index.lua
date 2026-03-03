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

TILES.WALL_EDGE_1 = at(1, 1)
TILES.WALL_EDGE_2 = at(1, 2)
TILES.WALL_EDGE_3 = at(1, 3)
TILES.WALL_EDGE_4 = at(1, 4)
TILES.WALL_EDGE_5 = at(1, 5)
TILES.WALL_EDGE_6 = at(1, 6)
TILES.WALL_EDGE_7 = at(1, 7)

TILES.FLOOR_1 = at(2, 1)
TILES.FLOOR_2 = at(2, 2)
TILES.FLOOR_3 = at(2, 3)

TILES.PLANT_1 = at(3, 1)
TILES.PLANT_2 = at(3, 2)
TILES.CABINET = at(3, 3)
TILES.SERVERS = at(3, 4)
TILES.DESK = at(3, 5)
TILES.MACHINE_L = at(3, 6)
TILES.MACHINE_S = at(3, 7)

TILES.DOOR_CLOSED = at(2, 4)
TILES.DOOR_OPEN = at(2, 5)

TILES.PLAYER = at(5, 1)
TILES.PLAYER_GUN = at(5, 2)
TILES.PLAYER_MELEE = at(5, 3)
TILES.BOT_MELEE = at(5, 4)
TILES.BOT_CRAB = at(5, 5)

TILES.PISTOL = at(6, 2)
TILES.SWORD = at(6, 3)
TILES.RIFLE = at(7, 2)
TILES.SHOTGUN = at(8, 2)

return TILES
