local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"

--- @class MapState: PlayState
--- @overload fun(display: Display, overlayDisplay, display) : MapState
local MapState = spectrum.gamestates.LevelState:extend("MapState")


function MapState:__new(display, overlayDisplay)
   self.display = display
   self:initializeGeneration()
end

--- Initialize or reinitialize the generation process
function MapState:initializeGeneration()
   -- Create the world generator
   self.world = TunnelWorldGenerator()

   -- Create a coroutine for step-by-step generation
   self.generationCoroutine = coroutine.create(function()
      return self.world:generate()
   end)

   -- Track if generation is complete
   self.generationComplete = false
   self.builder = nil
   self.stepsPerAdvance = 5

   -- Create an empty level initially (just walls)
   local tempBuilder = prism.LevelBuilder()
   tempBuilder:rectangle("fill", 0, 0, self.world.size.x, self.world.size.y, prism.cells.Wall)

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   tempBuilder:addActor(player, 50, 50)

   self.level = tempBuilder:build(prism.cells.Wall)
   self.time = 0
end

--- Override update to check for held spacebar
function MapState:update(dt)
   self.time = self.time + dt

   -- If space is held and generation not complete, advance
   if love.keyboard.isDown("space") and not self.generationComplete then
      self:advanceGeneration()
   end

   -- If tab is held and generation not complete, run to completion
   if love.keyboard.isDown("tab") then
      if not self.generationComplete then
         self:completeGeneration()
      else
         -- Generate a fresh map
         self:initializeGeneration()
      end
   end
end

--- Advance the generation by multiple steps
function MapState:advanceGeneration()
   for i = 1, self.stepsPerAdvance do
      if self.generationComplete then break end

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
            break
         end
      else
         prism.logger.error("Generation error:", result)
         self.generationComplete = true
         break
      end
   end

   -- Rebuild the level with current state after all steps
   if not self.generationComplete then
      local player = prism.actors.Player()
      self.world.builder:addActor(player, 50, 50)
      self.level = self.world.builder:build(prism.cells.Wall)
   end
end

--- Complete the generation instantly
function MapState:completeGeneration()
   while not self.generationComplete do
      local success, result = coroutine.resume(self.generationCoroutine)

      if success then
         if coroutine.status(self.generationCoroutine) == "dead" then
            self.generationComplete = true
            self.builder = result

            -- Rebuild the level with the final generated map
            local player = prism.actors.Player()
            self.builder:addActor(player, 50, 50)

            self.level = self.builder:build(prism.cells.Wall)
            prism.logger.info("Generation complete!")
            break
         end
      else
         prism.logger.error("Generation error:", result)
         self.generationComplete = true
         break
      end
   end
end

function MapState:draw()
   love.graphics.clear(0, 0, 0, 1)

   local cellSize = 4
   local map = self.level.map

   -- First pass: Draw all cells
   for x = 0, map.w do
      for y = 0, map.h do
         local cell = self.level:getCell(x, y)

         if cell then
            -- Check if this cell is a wall by looking for the Name component
            local nameComponent = cell:get(prism.components.Name)
            local isWall = nameComponent and nameComponent.name == "Wall"
            local isHalfWall = nameComponent and nameComponent.name == "HalfWall"
            local isWaypoint = nameComponent and nameComponent.name == "WaypointFloor"

            if isWall then
               -- Draw walls as white
               love.graphics.setColor(1, 1, 1, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            elseif isHalfWall then
               love.graphics.setColor(0.5, 0.8, 0.8, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            elseif isWaypoint then
               love.graphics.setColor(0.2, 0.8, 0.2, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            else
               -- Draw everything else as black (already cleared, but being explicit)
               love.graphics.setColor(0, 0, 0, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            end
         end
      end
   end

   -- Second pass: Draw all actors on top
   for x = 0, map.w do
      for y = 0, map.h do
         local actors = self.level:query():at(x, y):gather()

         for _, actor in ipairs(actors) do
            local nameComponent = actor:get(prism.components.Name)
            local isDoor = nameComponent and nameComponent.name == "Door"
            local isAmmoStash = nameComponent and nameComponent.name == "Ammo Stash"
            local isWeaponCache = nameComponent and nameComponent.name == "Weapon Cache"
            local isUtilityContainer = nameComponent and nameComponent.name == "Utility Container"
            local isMoneyVault = nameComponent and nameComponent.name == "Money Vault"

            if isDoor then
               love.graphics.setColor(0.6, 0.6, 0.6, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            elseif isAmmoStash then
               -- Blue for ammo
               love.graphics.setColor(0.2, 0.4, 1.0, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            elseif isWeaponCache then
               -- Red for weapons
               love.graphics.setColor(1.0, 0.2, 0.2, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            elseif isUtilityContainer then
               -- Yellow for utility
               love.graphics.setColor(1.0, 1.0, 0.2, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            elseif isMoneyVault then
               -- Gold/orange for money
               love.graphics.setColor(1.0, 0.7, 0.0, 1)
               love.graphics.rectangle("fill", x * cellSize, y * cellSize, cellSize, cellSize)
            end
         end
      end
   end

   -- Reset color
   love.graphics.setColor(1, 1, 1, 1)
end

return MapState
