local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"

--- @class MapState: PlayState
--- @overload fun(display: Display, overlayDisplay, display) : MapState
local MapState = spectrum.gamestates.LevelState:extend("MapState")


function MapState:__new(display, overlayDisplay)
   -- Create the world generator
   self.world = TunnelWorldGenerator()

   -- Create a coroutine for step-by-step generation
   self.generationCoroutine = coroutine.create(function()
      return self.world:generate()
   end)

   -- Track if generation is complete
   self.generationComplete = false
   self.builder = nil

   -- Create an empty level initially (just walls)
   local tempBuilder = prism.LevelBuilder()
   tempBuilder:rectangle("fill", 0, 0, self.world.size.x, self.world.size.y, prism.cells.Wall)

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   tempBuilder:addActor(player, 50, 50)

   spectrum.gamestates.LevelState.__new(self, tempBuilder:build(prism.cells.Wall), display)
end

--- Handle keyboard input
function MapState:keypressed(key)
   if key == "space" and not self.generationComplete then
      -- Resume the coroutine to advance one step
      local success, result = coroutine.resume(self.generationCoroutine)

      if success then
         -- Check if the coroutine is finished
         if coroutine.status(self.generationCoroutine) == "dead" then
            self.generationComplete = true
            self.builder = result

            -- Rebuild the level with the final generated map
            local player = prism.actors.Player()
            self.builder:addActor(player, 50, 50)

            self.level = self.builder:build(prism.cells.Wall)
            prism.logger.info("Generation complete!")
         else
            -- Rebuild the level with current state
            local player = prism.actors.Player()
            self.world.builder:addActor(player, 50, 50)

            self.level = self.world.builder:build(prism.cells.Wall)
         end
      else
         prism.logger.error("Generation error:", result)
      end
   end
end

--- Draw a minimap view where each cell is 2x2 pixels
--- Walls are white, everything else is black
function MapState:draw()
   love.graphics.clear(0, 0, 0, 1)

   local cellSize = 4
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

   -- Draw instruction text
   if not self.generationComplete then
      love.graphics.print("Press SPACE to step through generation", 10, 10)
   else
      love.graphics.print("Generation complete!", 10, 10)
   end
end

return MapState
