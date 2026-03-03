local TunnelAgent = require "modules.game.world.tunnelagent"

---@class TunnelWorldGenerator:Object
---@field size Vector2
---@field builder LevelBuilder
---@field agents table<TunnelAgent>
---@field totalSteps5Wide integer Running count of ticks taken so far
---@field maxSteps5Wide integer Target step budget for the 5-wide pass
---@field maxFloorFraction number Maximum fraction of total map area to fill with 5-wide hallways
---@field totalSteps3Wide integer Running count of ticks for the 3-wide pass
---@field maxSteps3Wide integer Target step budget for the 3-wide pass
---@field maxFloorFraction3Wide number Combined coverage cap including 3-wide hallways
---@field maxFloorFractionRooms number Maximum floor coverage including rooms (75%)
---@field roomsPlaced integer Count of successfully placed rooms

local TunnelWorldGenerator = prism.Object:extend("TunnelWorldGenerator")

--- Constructor for the world generator
function TunnelWorldGenerator:__new()
   prism.logger.info("Building a tunnel level (new system).")

   self.size = prism.Vector2(100, 100)
   self.builder = prism.LevelBuilder()
   self.agents = {}

   -- Phase 7: step budget
   self.totalSteps5Wide = 0
   self.maxSteps5Wide = RNG:random(175, 300)
   prism.logger.info(string.format("Step budget: %d", self.maxSteps5Wide))

   -- Phase 9: coverage cap — 5-wide hallways may not exceed this fraction of total area
   self.maxFloorFraction = 0.15

   -- Phase 9: 3-wide hallway pass budget
   self.totalSteps3Wide = 0
   self.maxSteps3Wide = RNG:random(200, 400)
   self.maxFloorFraction3Wide = 0.30 -- combined cap: 5-wide + 3-wide together
   prism.logger.info(string.format("3-wide step budget: %d", self.maxSteps3Wide))

   -- Room generation cap
   self.maxFloorFractionRooms = 0.75
   self.roomsPlaced = 0
end

--- Count the number of floor tiles currently dug in the builder.
---@return integer count
function TunnelWorldGenerator:countFloorTiles()
   local count = 0
   for _, _, cell in self.builder:each() do
      local nameComp = cell:get(prism.components.Name)
      if nameComp and nameComp.name == "Floor" then
         count = count + 1
      end
   end
   return count
end

--- Calculate how close we are to either the step budget or the floor-coverage cap,
--- whichever is more restrictive (0.0 = just started, 1.0 = must stop now).
---@return number pressure 0.0 to 1.0
function TunnelWorldGenerator:calculateTerminationPressure()
   local stepPressure = math.min(self.totalSteps5Wide / self.maxSteps5Wide, 1.0)

   local totalArea = self.size.x * self.size.y
   local floorCount = self:countFloorTiles()
   local coveragePressure = math.min(floorCount / (totalArea * self.maxFloorFraction), 1.0)

   if coveragePressure > stepPressure then
      prism.logger.info(string.format(
         "Coverage pressure dominant: %.1f%% of map used (cap %.0f%%)",
         (floorCount / totalArea) * 100, self.maxFloorFraction * 100
      ))
   end

   return math.max(stepPressure, coveragePressure)
end

--- Generate the world
---@return LevelBuilder The built level
function TunnelWorldGenerator:generate()
   -- Fill with walls
   self.builder:rectangle("fill", 0, 0, self.size.x, self.size.y, prism.cells.Wall)

   -- Spawn initial agent at a random edge
   local startPos, startDir = self:findOpenEdgeSpot()
   self:spawnAgent(startPos, startDir, 2)

   local maxRespawns = 10

   while true do
      local pressure = self:calculateTerminationPressure()

      -- When budget is fully consumed, force-kill every agent immediately
      if pressure >= 1.0 then
         for _, agent in ipairs(self.agents) do
            agent.alive = false
         end
      end

      -- Advance all active agents one tick
      local anyAlive = self:stepAllAgents(pressure)
      self.totalSteps5Wide = self.totalSteps5Wide + 1

      -- Yield after each tick for step-by-step visualization
      coroutine.yield()

      -- Handle the case where all agents have died
      if not anyAlive then
         local progress = self.totalSteps5Wide / self.maxSteps5Wide

         if progress >= 0.8 then
            -- Within the acceptable 20% window of the target — we're done
            prism.logger.info(string.format(
               "Generation complete: %d/%d steps (%.0f%% of budget)",
               self.totalSteps5Wide, self.maxSteps5Wide, progress * 100
            ))
            break
         end

         if maxRespawns <= 0 then
            prism.logger.info("Exhausted respawn limit, stopping generation.")
            break
         end

         -- Try to seed a brand-new agent from existing floor territory
         local respawnPos, respawnDir = self:findRespawnSpot()
         if respawnPos and respawnDir then
            prism.logger.info(string.format(
               "Respawning agent (%d remaining) at %d,%d heading %d,%d",
               maxRespawns, respawnPos.x, respawnPos.y, respawnDir.x, respawnDir.y
            ))
            self:spawnAgent(respawnPos, respawnDir, 2)
            maxRespawns = maxRespawns - 1
         else
            prism.logger.info("No valid respawn spot found, stopping generation.")
            break
         end
      end
   end

   -- Phase 9: run the 3-wide hallway pass on top of the completed 5-wide map
   self:run3WidePass()

   -- Rooms: fill remaining wall space with rooms
   self:runRoomsPass()

   return self.builder
end

--- Spawn a new agent at a specified position
---@param position Vector2 Starting position
---@param direction Vector2 Direction vector
---@param width integer Hallway width
---@return TunnelAgent The newly created agent
function TunnelWorldGenerator:spawnAgent(position, direction, width)
   local agent = TunnelAgent(position, direction, width, nil, self.size)
   table.insert(self.agents, agent)
   return agent
end

--- Find an open spot on the edge of the map pointing inward
---@return Vector2 position
---@return Vector2 direction
function TunnelWorldGenerator:findOpenEdgeSpot()
   local edge = RNG:random(1, 4)
   local position, direction

   if edge == 1 then -- Top edge
      position = prism.Vector2(RNG:random(10, self.size.x - 10), 5)
      direction = prism.Vector2.DOWN
   elseif edge == 2 then -- Right edge
      position = prism.Vector2(self.size.x - 5, RNG:random(10, self.size.y - 10))
      direction = prism.Vector2.LEFT
   elseif edge == 3 then -- Bottom edge
      position = prism.Vector2(RNG:random(10, self.size.x - 10), self.size.y - 5)
      direction = prism.Vector2.UP
   else -- Left edge
      position = prism.Vector2(5, RNG:random(10, self.size.y - 10))
      direction = prism.Vector2.RIGHT
   end

   return position, direction
end

--- Step all active agents forward one tick and collect any newly spawned agents.
---@param terminationPressure number 0.0–1.0 passed through to each agent
---@return boolean anyAlive True if any agents survived this tick
function TunnelWorldGenerator:stepAllAgents(terminationPressure)
   local newAgents = {}
   local continuingAgents = {}

   for _, agent in ipairs(self.agents) do
      if agent.alive then
         local spawnedAgents, shouldContinue = agent:step(self.builder, terminationPressure)

         -- Kill the agent if it stepped out of bounds
         if shouldContinue and self:isAgentInBounds(agent) then
            table.insert(continuingAgents, agent)
         else
            agent.alive = false
         end

         -- Collect agents spawned this tick (e.g. from junctions)
         for _, newAgent in ipairs(spawnedAgents) do
            table.insert(newAgents, newAgent)
         end
      end
   end

   -- Newly spawned agents join the active pool next iteration
   for _, agent in ipairs(newAgents) do
      table.insert(continuingAgents, agent)
   end

   self.agents = continuingAgents
   return #self.agents > 0
end

--- Check if an agent is within map bounds (accounting for width)
---@param agent TunnelAgent The agent to check
---@return boolean inBounds True if agent is within bounds
function TunnelWorldGenerator:isAgentInBounds(agent)
   local margin = agent.width + 1
   return agent.position.x >= margin and agent.position.x <= self.size.x - margin and
       agent.position.y >= margin and agent.position.y <= self.size.y - margin
end

--- Find a floor cell on the existing map from which a new agent can dig into
--- uncharted (wall) territory.  Returns nil, nil if no suitable spot exists.
---@return Vector2|nil position
---@return Vector2|nil direction
function TunnelWorldGenerator:findRespawnSpot()
   local agentWidth     = 2  -- 5-wide
   local margin         = agentWidth + 2
   local minAhead       = 12 -- tiles of uncarved wall required in the exit direction

   -- Collect every floor cell that lies within the safe margin
   local floorPositions = {}
   for x, y, cell in self.builder:each() do
      local nameComp = cell:get(prism.components.Name)
      if nameComp and nameComp.name == "Floor" then
         if x >= margin and x <= self.size.x - margin and
             y >= margin and y <= self.size.y - margin then
            table.insert(floorPositions, prism.Vector2(x, y))
         end
      end
   end

   if #floorPositions == 0 then
      return nil, nil
   end

   local cardinals = {
      prism.Vector2.UP,
      prism.Vector2.DOWN,
      prism.Vector2.LEFT,
      prism.Vector2.RIGHT,
   }

   -- Try up to 60 randomly-chosen floor cells before giving up
   local attempts = math.min(60, #floorPositions)
   for _ = 1, attempts do
      local pos = floorPositions[RNG:random(1, #floorPositions)]

      -- Shuffle the four cardinal directions so we don't always prefer UP
      local dirOrder = { 1, 2, 3, 4 }
      for i = 4, 2, -1 do
         local j = RNG:random(1, i)
         dirOrder[i], dirOrder[j] = dirOrder[j], dirOrder[i]
      end

      for _, di in ipairs(dirOrder) do
         local dir = cardinals[di]
         if self:hasOpenSpaceAhead(pos, dir, agentWidth, minAhead) then
            return pos, dir
         end
      end
   end

   return nil, nil
end

--- Return true if the path ahead of `pos` in `dir` is free of floor tiles for
--- at least `minDistance` cells (at full hallway width), and stays in-bounds.
---@param pos Vector2
---@param dir Vector2
---@param width integer Half-width of the prospective agent
---@param minDistance integer
---@return boolean
function TunnelWorldGenerator:hasOpenSpaceAhead(pos, dir, width, minDistance)
   local perpendicular = dir:rotateClockwise()
   local margin = width + 1

   for d = 1, minDistance do
      local checkCenter = pos + (dir * d)

      -- Stay inside the safe margin
      if checkCenter.x < margin or checkCenter.x > self.size.x - margin or
          checkCenter.y < margin or checkCenter.y > self.size.y - margin then
         return false
      end

      -- Confirm every cell across the agent's full width is non-floor
      for w = -width, width do
         local checkPos = checkCenter + (perpendicular * w)
         local cell = self.builder:get(checkPos.x, checkPos.y)
         if cell then
            local nameComp = cell:get(prism.components.Name)
            if nameComp and nameComp.name == "Floor" then
               return false
            end
         end
      end
   end

   return true
end

--- Calculate termination pressure for the 3-wide pass.
--- Uses the 3-wide step counter and a combined floor-coverage cap.
---@return number pressure 0.0 to 1.0
function TunnelWorldGenerator:calculateTerminationPressure3Wide()
   local stepPressure     = math.min(self.totalSteps3Wide / self.maxSteps3Wide, 1.0)

   local totalArea        = self.size.x * self.size.y
   local floorCount       = self:countFloorTiles()
   local coveragePressure = math.min(floorCount / (totalArea * self.maxFloorFraction3Wide), 1.0)

   if coveragePressure > stepPressure then
      prism.logger.info(string.format(
         "Phase 9 coverage pressure dominant: %.1f%% of map used (cap %.0f%%)",
         (floorCount / totalArea) * 100, self.maxFloorFraction3Wide * 100
      ))
   end

   return math.max(stepPressure, coveragePressure)
end

--- Build a normalized wall-density map.
--- For every cell, count wall tiles within Euclidean radius 8, then normalize
--- so the highest-density cell scores 1.0.
---@return table<integer, table<integer, number>> densityMap [x][y] → 0.0–1.0
function TunnelWorldGenerator:computeWallDensityMap()
   local radius   = 8
   local radiusSq = radius * radius

   -- Build a fast wall-presence lookup to avoid repeated builder:get() calls
   local isWall   = {}
   for x = 0, self.size.x - 1 do
      isWall[x] = {}
      for y = 0, self.size.y - 1 do
         local cell     = self.builder:get(x, y)
         local nameComp = cell and cell:get(prism.components.Name)
         isWall[x][y]   = not (nameComp and nameComp.name == "Floor")
      end
   end

   -- Sweep every cell and count walls within the radius
   local densityMap = {}
   local maxDensity = 0

   for x = 0, self.size.x - 1 do
      densityMap[x] = {}
      for y = 0, self.size.y - 1 do
         local count = 0
         for dx = -radius, radius do
            local dxSq = dx * dx
            if dxSq <= radiusSq then
               for dy = -radius, radius do
                  if dxSq + dy * dy <= radiusSq then
                     local nx, ny = x + dx, y + dy
                     if nx >= 0 and nx < self.size.x and ny >= 0 and ny < self.size.y then
                        if isWall[nx][ny] then count = count + 1 end
                     end
                  end
               end
            end
         end
         densityMap[x][y] = count
         if count > maxDensity then maxDensity = count end
      end
   end

   -- Normalize to [0, 1]
   if maxDensity > 0 then
      for x = 0, self.size.x - 1 do
         for y = 0, self.size.y - 1 do
            densityMap[x][y] = densityMap[x][y] / maxDensity
         end
      end
   end

   return densityMap
end

--- Snap a free vector (dx, dy) to the nearest cardinal direction Vector2.
---@param dx number
---@param dy number
---@return Vector2
function TunnelWorldGenerator:snapToCardinal(dx, dy)
   if math.abs(dx) >= math.abs(dy) then
      return dx >= 0 and prism.Vector2.RIGHT or prism.Vector2.LEFT
   else
      return dy >= 0 and prism.Vector2.DOWN or prism.Vector2.UP
   end
end

--- Return the nearest high-density destination Vector2 to `pos`, or nil if the
--- destinations table is empty.
---@param pos Vector2
---@param destinations table<Vector2>
---@return Vector2|nil
function TunnelWorldGenerator:nearestDestination(pos, destinations)
   local bestDest   = nil
   local bestDistSq = math.huge
   for _, dest in ipairs(destinations) do
      local dx     = dest.x - pos.x
      local dy     = dest.y - pos.y
      local distSq = dx * dx + dy * dy
      if distSq < bestDistSq then
         bestDistSq = distSq
         bestDest   = dest
      end
   end
   return bestDest
end

--- Spawn up to `count` 3-wide (width=1) agents.
--- Start points are existing hallway floor tiles; heading is toward the nearest
--- high-wall-density destination so the new tunnel connects back to the network
--- while pushing into unexplored territory.
---@param count integer Number of agents to try to spawn
---@return table agents The spawned TunnelAgent instances (may be fewer than `count`)
function TunnelWorldGenerator:spawn3WideAgents(count)
   local agentWidth       = 1 -- width=1 → 3-wide hallway
   local minAhead         = 8
   local margin           = agentWidth + 2
   local densityThreshold = 0.8

   -- Compute wall-density map and collect high-density destination points
   local densityMap       = self:computeWallDensityMap()
   local destinations     = {}

   for x = margin, self.size.x - margin do
      for y = margin, self.size.y - margin do
         if densityMap[x][y] >= densityThreshold then
            table.insert(destinations, prism.Vector2(x, y))
         end
      end
   end

   if #destinations == 0 then
      prism.logger.info(string.format(
         "Phase 9: No high-density wall destinations found (threshold %.2f).",
         densityThreshold
      ))
      return {}
   end

   prism.logger.info(string.format(
      "Phase 9: %d high-density destinations, seeking hallway start points (threshold %.2f).",
      #destinations, densityThreshold
   ))

   -- Collect eligible hallway floor tiles as start points
   local floorPositions = {}
   for x, y, cell in self.builder:each() do
      local nameComp = cell:get(prism.components.Name)
      if nameComp and nameComp.name == "Floor" then
         if x >= margin and x <= self.size.x - margin and
             y >= margin and y <= self.size.y - margin then
            table.insert(floorPositions, prism.Vector2(x, y))
         end
      end
   end

   if #floorPositions == 0 then
      prism.logger.info("Phase 9: No hallway floor tiles found for start points.")
      return {}
   end

   local spawned  = {}
   local attempts = 0

   while #spawned < count and attempts < 300 do
      attempts = attempts + 1

      -- Pick a random hallway floor tile as the start
      local startPos = floorPositions[RNG:random(1, #floorPositions)]

      -- Aim toward the nearest high-density destination
      local dest = self:nearestDestination(startPos, destinations)
      if not dest then break end

      local dir = self:snapToCardinal(dest.x - startPos.x, dest.y - startPos.y)

      if self:hasOpenSpaceAhead(startPos, dir, agentWidth, minAhead) then
         local agent = TunnelAgent(startPos, dir, agentWidth, nil, self.size)
         table.insert(spawned, agent)
         prism.logger.info(string.format(
            "Phase 9: Spawned agent at %d,%d heading %d,%d toward destination %d,%d.",
            startPos.x, startPos.y, dir.x, dir.y, dest.x, dest.y
         ))
      end
   end

   return spawned
end

--- Run the 3-wide hallway generation pass.
--- Spawns width=1 agents branching off the existing 5-wide hallway network and runs
--- them under their own step/coverage budget.
function TunnelWorldGenerator:run3WidePass()
   -- The 5-wide agents are all dead by now; start fresh.
   self.agents         = {}

   local initialCount  = RNG:random(3, 5)
   local initialAgents = self:spawn3WideAgents(initialCount)

   if #initialAgents == 0 then
      prism.logger.info("Phase 9: No valid 3-wide spawn points found, skipping pass.")
      return
   end

   for _, agent in ipairs(initialAgents) do
      table.insert(self.agents, agent)
   end

   prism.logger.info(string.format(
      "Phase 9: Starting 3-wide pass with %d agents (budget: %d steps).",
      #self.agents, self.maxSteps3Wide
   ))

   local maxRespawns = 5

   while true do
      local pressure = self:calculateTerminationPressure3Wide()

      -- Budget exhausted — kill all agents immediately
      if pressure >= 1.0 then
         for _, agent in ipairs(self.agents) do
            agent.alive = false
         end
      end

      local anyAlive = self:stepAllAgents(pressure)
      self.totalSteps3Wide = self.totalSteps3Wide + 1

      coroutine.yield()

      if not anyAlive then
         local progress = self.totalSteps3Wide / self.maxSteps3Wide

         if progress >= 0.8 then
            prism.logger.info(string.format(
               "Phase 9 complete: %d/%d steps (%.0f%% of budget).",
               self.totalSteps3Wide, self.maxSteps3Wide, progress * 100
            ))
            break
         end

         if maxRespawns <= 0 then
            prism.logger.info("Phase 9: Exhausted respawn limit.")
            break
         end

         local respawnAgents = self:spawn3WideAgents(1)
         if #respawnAgents > 0 then
            for _, agent in ipairs(respawnAgents) do
               table.insert(self.agents, agent)
            end
            maxRespawns = maxRespawns - 1
            prism.logger.info(string.format(
               "Phase 9: Respawned 3-wide agent (%d remaining).",
               maxRespawns
            ))
         else
            prism.logger.info("Phase 9: No valid respawn spot found, stopping.")
            break
         end
      end
   end
end

--- Check if a rectangular region [x1,y1] to [x2,y2] (inclusive) is all walls.
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@return boolean
function TunnelWorldGenerator:isRectangleAllWalls(x1, y1, x2, y2)
   for x = x1, x2 do
      for y = y1, y2 do
         if x < 0 or x >= self.size.x or y < 0 or y >= self.size.y then
            return false
         end
         local cell = self.builder:get(x, y)
         if not cell then return false end
         local nameComp = cell:get(prism.components.Name)
         if nameComp and nameComp.name == "Floor" then
            return false
         end
      end
   end
   return true
end

--- Find the largest axis-aligned rectangle of walls adjacent to a floor tile,
--- respecting the 3:1 aspect ratio constraint and minimum 4x4 size.
--- Returns nil if no valid room can fit.
---@param floorPos Vector2 Starting floor tile position
---@param direction Vector2 Cardinal direction to search (UP, DOWN, LEFT, RIGHT)
---@return integer|nil x Top-left x coordinate of room interior
---@return integer|nil y Top-left y coordinate of room interior
---@return integer|nil width Interior width
---@return integer|nil height Interior height
function TunnelWorldGenerator:findLargestRoom(floorPos, direction)
   -- Step 1 cell into wall space from the floor tile
   local startPos = floorPos + direction

   -- Check if start position is valid and is a wall
   if startPos.x < 1 or startPos.x >= self.size.x - 1 or
       startPos.y < 1 or startPos.y >= self.size.y - 1 then
      return nil
   end

   local cell = self.builder:get(startPos.x, startPos.y)
   if not cell then return nil end
   local nameComp = cell:get(prism.components.Name)
   if nameComp and nameComp.name == "Floor" then
      return nil -- Already floor
   end

   -- Try to expand outward from startPos
   local bestWidth, bestHeight = 0, 0

   -- Maximum dimensions to try (including 1-cell wall border on all sides)
   local maxDim = 40

   for width = 5, maxDim do -- 5 = 3 interior + 2 walls
      for height = 5, maxDim do
         -- Check aspect ratio constraint (3:1 max)
         local interiorW = width - 2
         local interiorH = height - 2
         if interiorW > interiorH * 3 or interiorH > interiorW * 3 then
            goto continue
         end

         -- Calculate room bounds with 1-cell wall border
         local x1, y1, x2, y2
         if direction == prism.Vector2.UP then
            x1 = startPos.x - math.floor((width - 1) / 2)
            x2 = x1 + width - 1
            y2 = startPos.y
            y1 = y2 - height + 1
         elseif direction == prism.Vector2.DOWN then
            x1 = startPos.x - math.floor((width - 1) / 2)
            x2 = x1 + width - 1
            y1 = startPos.y
            y2 = y1 + height - 1
         elseif direction == prism.Vector2.LEFT then
            y1 = startPos.y - math.floor((height - 1) / 2)
            y2 = y1 + height - 1
            x2 = startPos.x
            x1 = x2 - width + 1
         else -- RIGHT
            y1 = startPos.y - math.floor((height - 1) / 2)
            y2 = y1 + height - 1
            x1 = startPos.x
            x2 = x1 + width - 1
         end

         -- Check if this rectangle is all walls
         if self:isRectangleAllWalls(x1, y1, x2, y2) then
            bestWidth = width
            bestHeight = height
         end

         ::continue::
      end
   end

   if bestWidth >= 5 and bestHeight >= 5 then
      -- Return interior coordinates (excluding walls)
      local x1, y1, x2, y2
      if direction == prism.Vector2.UP then
         x1 = startPos.x - math.floor((bestWidth - 1) / 2)
         x2 = x1 + bestWidth - 1
         y2 = startPos.y
         y1 = y2 - bestHeight + 1
      elseif direction == prism.Vector2.DOWN then
         x1 = startPos.x - math.floor((bestWidth - 1) / 2)
         x2 = x1 + bestWidth - 1
         y1 = startPos.y
         y2 = y1 + bestHeight - 1
      elseif direction == prism.Vector2.LEFT then
         y1 = startPos.y - math.floor((bestHeight - 1) / 2)
         y2 = y1 + bestHeight - 1
         x2 = startPos.x
         x1 = x2 - bestWidth + 1
      else -- RIGHT
         y1 = startPos.y - math.floor((bestHeight - 1) / 2)
         y2 = y1 + bestHeight - 1
         x1 = startPos.x
         x2 = x1 + bestWidth - 1
      end

      return x1 + 1, y1 + 1, bestWidth - 2, bestHeight - 2
   end

   return nil
end

--- Carve out a room's floor tiles.
---@param x integer Top-left x (interior)
---@param y integer Top-left y (interior)
---@param width integer Interior width
---@param height integer Interior height
function TunnelWorldGenerator:carveRoom(x, y, width, height)
   for rx = x, x + width - 1 do
      for ry = y, y + height - 1 do
         self.builder:set(rx, ry, prism.cells.Floor())
      end
   end
end

--- Find all floor tiles adjacent to a room and punch doors through the walls.
--- Doors are 2 cells wide. Place between 1 and half of max possible doors.
---@param x integer Room interior top-left x
---@param y integer Room interior top-left y
---@param width integer Room interior width
---@param height integer Room interior height
function TunnelWorldGenerator:createDoors(x, y, width, height)
   local edges = {
      { dir = "top",    x1 = x,         y1 = y - 1,      x2 = x + width - 1, y2 = y - 1 },
      { dir = "bottom", x1 = x,         y1 = y + height, x2 = x + width - 1, y2 = y + height },
      { dir = "left",   x1 = x - 1,     y1 = y,          x2 = x - 1,         y2 = y + height - 1 },
      { dir = "right",  x1 = x + width, y1 = y,          x2 = x + width,     y2 = y + height - 1 },
   }

   for _, edge in ipairs(edges) do
      local doorCandidates = {}

      if edge.dir == "top" or edge.dir == "bottom" then
         -- Horizontal edge - scan left to right for 2-wide door spots
         for dx = edge.x1, edge.x2 - 1 do
            local wallX1, wallY = dx, edge.y1
            local wallX2 = dx + 1

            -- Check if both wall cells exist
            local wall1 = self.builder:get(wallX1, wallY)
            local wall2 = self.builder:get(wallX2, wallY)
            if not wall1 or not wall2 then goto continue_h end

            local name1 = wall1:get(prism.components.Name)
            local name2 = wall2:get(prism.components.Name)
            if not name1 or name1.name ~= "Wall" or not name2 or name2.name ~= "Wall" then
               goto continue_h
            end

            -- Check if there's floor on the other side
            local beyondY = edge.dir == "top" and (wallY - 1) or (wallY + 1)
            local beyond1 = self.builder:get(wallX1, beyondY)
            local beyond2 = self.builder:get(wallX2, beyondY)
            if beyond1 and beyond2 then
               local bname1 = beyond1:get(prism.components.Name)
               local bname2 = beyond2:get(prism.components.Name)
               if bname1 and bname1.name == "Floor" and bname2 and bname2.name == "Floor" then
                  table.insert(doorCandidates, { x1 = wallX1, y1 = wallY, x2 = wallX2, y2 = wallY })
               end
            end

            ::continue_h::
         end
      else
         -- Vertical edge - scan top to bottom for 2-wide door spots
         for dy = edge.y1, edge.y2 - 1 do
            local wallX, wallY1 = edge.x1, dy
            local wallY2 = dy + 1

            -- Check if both wall cells exist
            local wall1 = self.builder:get(wallX, wallY1)
            local wall2 = self.builder:get(wallX, wallY2)
            if not wall1 or not wall2 then goto continue_v end

            local name1 = wall1:get(prism.components.Name)
            local name2 = wall2:get(prism.components.Name)
            if not name1 or name1.name ~= "Wall" or not name2 or name2.name ~= "Wall" then
               goto continue_v
            end

            -- Check if there's floor on the other side
            local beyondX = edge.dir == "left" and (wallX - 1) or (wallX + 1)
            local beyond1 = self.builder:get(beyondX, wallY1)
            local beyond2 = self.builder:get(beyondX, wallY2)
            if beyond1 and beyond2 then
               local bname1 = beyond1:get(prism.components.Name)
               local bname2 = beyond2:get(prism.components.Name)
               if bname1 and bname1.name == "Floor" and bname2 and bname2.name == "Floor" then
                  table.insert(doorCandidates, { x1 = wallX, y1 = wallY1, x2 = wallX, y2 = wallY2 })
               end
            end

            ::continue_v::
         end
      end

      -- Place doors if candidates exist
      if #doorCandidates > 0 then
         local maxDoors = math.max(1, math.floor(#doorCandidates / 2))
         local numDoors = RNG:random(1, maxDoors)

         -- Shuffle candidates
         for i = #doorCandidates, 2, -1 do
            local j = RNG:random(1, i)
            doorCandidates[i], doorCandidates[j] = doorCandidates[j], doorCandidates[i]
         end

         -- Place the doors
         for i = 1, math.min(numDoors, #doorCandidates) do
            local door = doorCandidates[i]
            self.builder:set(door.x1, door.y1, prism.cells.Floor())
            self.builder:set(door.x2, door.y2, prism.cells.Floor())
         end
      end
   end
end

--- Attempt to place a room adjacent to a random floor tile.
--- Returns true if a room was successfully placed, false otherwise.
---@return boolean success
function TunnelWorldGenerator:tryPlaceRoom()
   local margin = 3

   -- Collect eligible floor tiles
   local floorTiles = {}
   for x, y, cell in self.builder:each() do
      local nameComp = cell:get(prism.components.Name)
      if nameComp and nameComp.name == "Floor" then
         if x >= margin and x < self.size.x - margin and
             y >= margin and y < self.size.y - margin then
            table.insert(floorTiles, prism.Vector2(x, y))
         end
      end
   end

   if #floorTiles == 0 then
      return false
   end

   -- Pick a random floor tile
   local floorPos = floorTiles[RNG:random(1, #floorTiles)]

   -- Try all four cardinal directions
   local cardinals = {
      prism.Vector2.UP,
      prism.Vector2.DOWN,
      prism.Vector2.LEFT,
      prism.Vector2.RIGHT,
   }

   -- Shuffle directions
   for i = 4, 2, -1 do
      local j = RNG:random(1, i)
      cardinals[i], cardinals[j] = cardinals[j], cardinals[i]
   end

   for _, dir in ipairs(cardinals) do
      local x, y, w, h = self:findLargestRoom(floorPos, dir)
      if x and w >= 3 and h >= 3 then
         self:carveRoom(x, y, w, h)
         self:createDoors(x, y, w, h)
         self.roomsPlaced = self.roomsPlaced + 1
         prism.logger.info(string.format(
            "Rooms: Placed room #%d at (%d,%d) size %dx%d",
            self.roomsPlaced, x, y, w, h
         ))
         return true
      end
   end

   return false
end

--- Run the room generation pass.
--- Randomly samples floor tiles and attempts to place rooms in adjacent wall space
--- until either we fail to place rooms for many consecutive attempts or hit 75% coverage.
function TunnelWorldGenerator:runRoomsPass()
   prism.logger.info("Rooms: Starting room generation pass.")

   local maxFailures = 100
   local consecutiveFailures = 0

   while true do
      -- Check coverage cap
      local totalArea = self.size.x * self.size.y
      local floorCount = self:countFloorTiles()
      local coverage = floorCount / totalArea

      if coverage >= self.maxFloorFractionRooms then
         prism.logger.info(string.format(
            "Rooms: Coverage cap reached (%.1f%% of map).",
            coverage * 100
         ))
         break
      end

      -- Try to place a room
      local success = self:tryPlaceRoom()

      if success then
         consecutiveFailures = 0
         coroutine.yield()
      else
         consecutiveFailures = consecutiveFailures + 1
         if consecutiveFailures >= maxFailures then
            prism.logger.info(string.format(
               "Rooms: %d consecutive placement failures, stopping.",
               maxFailures
            ))
            break
         end
      end
   end

   prism.logger.info(string.format(
      "Rooms: Complete. Placed %d rooms. Final coverage: %.1f%%",
      self.roomsPlaced,
      (self:countFloorTiles() / (self.size.x * self.size.y)) * 100
   ))
end

return TunnelWorldGenerator
