local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"

--- @class MapState: PlayState
--- @overload fun(display: Display, overlayDisplay, display) : MapState
local MapState = spectrum.gamestates.LevelState:extend("MapState")


function MapState:__new(display, overlayDisplay)
   local world = TunnelWorldGenerator()

   local builder = world:generate()

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   builder:addActor(player, 9, 9)

   spectrum.gamestates.LevelState.__new(self, builder:build(prism.cells.Wall), display)
end

--- Draw a minimap view where each cell is 2x2 pixels
--- Walls are white, everything else is black
function MapState:draw()
   love.graphics.clear(0, 0, 0, 1)

   local cellSize = 2
   local map = self.level.map

   -- Loop through all cells in the level (0-indexed, inclusive)
   for x = 0, map.w do
      for y = 0, map.h do
         local cell = self.level:getCell(x, y)

         if cell then
            -- Check if this cell is a wall by looking for the Name component
            local nameComponent = cell:get(prism.components.Name)
            local isWall = nameComponent and nameComponent.name == "Wall"

            if isWall then
               -- Draw walls as white
               love.graphics.setColor(1, 1, 1, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            else
               -- Draw everything else as black (already cleared, but being explicit)
               love.graphics.setColor(0, 0, 0, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            end
         end
      end
   end

   -- Reset color
   love.graphics.setColor(1, 1, 1, 1)
end

return MapState
