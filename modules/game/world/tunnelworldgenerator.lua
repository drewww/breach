local TunnelAgent = require "modules.game.world.tunnelagent"

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local CONFIG = {
   -- Map dimensions
   MAP_WIDTH = 60,
   MAP_HEIGHT = 60,

   -- Hallway width parameters
   WIDTH_5_WIDE = 2, -- Creates 5-tile-wide hallways
   WIDTH_3_WIDE = 1, -- Creates 3-tile-wide hallways

   -- 5-wide pass parameters
   STEPS_5WIDE_MIN = 100,
   STEPS_5WIDE_MAX = 200,
   FLOOR_FRACTION_5WIDE = 0.15, -- 15% coverage cap
   MAX_RESPAWNS_5WIDE = 8,
   MIN_AHEAD_5WIDE = 12,        -- Wall cells required ahead for respawn

   -- 3-wide pass parameters
   STEPS_3WIDE_MIN = 200,
   STEPS_3WIDE_MAX = 400,
   FLOOR_FRACTION_3WIDE = 0.30, -- 30% combined coverage cap
   MAX_RESPAWNS_3WIDE = 5,
   MIN_AHEAD_3WIDE = 8,
   INITIAL_AGENTS_3WIDE_MIN = 3,
   INITIAL_AGENTS_3WIDE_MAX = 5,

   -- Wall density mapping (for 3-wide spawn points)
   WALL_DENSITY_RADIUS = 8,
   WALL_DENSITY_THRESHOLD = 0.8, -- Only spawn in 80%+ wall-dense areas

   -- Room generation parameters
   FLOOR_FRACTION_ROOMS = 0.75,       -- 75% final coverage cap with rooms
   ROOM_MIN_SIZE_TOTAL = 6,           -- Minimum 7x7 including walls (5x5 interior)
   ROOM_MIN_SIZE_INTERIOR = 4,        -- Minimum 5x5 interior
   ROOM_MAX_DIMENSION = 10,           -- Maximum room dimension (prevents huge rooms)
   ROOM_MAX_ASPECT_RATIO = 3,         -- 3:1 max aspect ratio
   ROOM_MAX_CONSECUTIVE_FAILURES = 50,
   ROOM_DOOR_WIDTH_2WIDE_CHANCE = 50, -- 50% chance for 2-wide door vs 1-wide

   -- Termination threshold
   COMPLETION_THRESHOLD = 0.8, -- 80% of budget counts as "complete"

   -- Safety margins
   MARGIN_EDGE = 5,  -- Margin from map edge for spawning
   MARGIN_AGENT = 2, -- Margin for agent validity checking
   MARGIN_ROOM = 3,  -- Margin for room placement

   -- Sampling limits
   MAX_RESPAWN_ATTEMPTS = 60,
   MAX_3WIDE_SPAWN_ATTEMPTS = 300,

   -- Filler system
   FILLER_SKIP_CHANCE = 5,           -- 5% chance to leave room empty
   FILLER_JUNCTION_SKIP_CHANCE = 20, -- 40% chance to leave junction empty
   FILLER_DOOR_CLEARANCE = 2,        -- Cells of clearance around doors
   FILLER_EDGE_PADDING = 1,          -- Padding from room edges
}

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
---@field rooms table<table> List of room bounds {x, y, width, height} for filler pass
---@field junctions table<table> List of junction bounds {x, y, width, height} for filler pass
---@field cachedFloorCount integer Cached count of floor tiles for performance
---@field floorCountDirty boolean Whether floor count needs recalculating
---@field cachedWallDensityMap table|nil Cached wall density map for 3-wide spawning

local TunnelWorldGenerator = prism.Object:extend("TunnelWorldGenerator")

--- Constructor for the world generator
function TunnelWorldGenerator:__new(biome, existingPlayer)
   biome = biome or "A"                 -- Default to BiomeA
   self.biome = biome
   self.existingPlayer = existingPlayer -- Store existing player to reuse when descending floors
   prism.logger.info(string.format("Building a tunnel level (new system) for Biome %s.", biome))

   self.size = prism.Vector2(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT)
   self.builder = prism.LevelBuilder()
   self.agents = {}

   -- 5-wide pass
   self.totalSteps5Wide = 0
   self.maxSteps5Wide = RNG:random(CONFIG.STEPS_5WIDE_MIN, CONFIG.STEPS_5WIDE_MAX)
   self.maxFloorFraction = CONFIG.FLOOR_FRACTION_5WIDE
   prism.logger.info(string.format("5-wide step budget: %d", self.maxSteps5Wide))

   -- 3-wide pass
   self.totalSteps3Wide = 0
   self.maxSteps3Wide = RNG:random(CONFIG.STEPS_3WIDE_MIN, CONFIG.STEPS_3WIDE_MAX)
   self.maxFloorFraction3Wide = CONFIG.FLOOR_FRACTION_3WIDE
   prism.logger.info(string.format("3-wide step budget: %d", self.maxSteps3Wide))

   -- Room pass
   self.maxFloorFractionRooms = CONFIG.FLOOR_FRACTION_ROOMS
   self.roomsPlaced = 0
   self.rooms = {}      -- Track rooms for filler pass
   self.junctions = {}  -- Track junctions for filler pass
   self.spawnSpots = {} -- Track valid enemy spawn locations (hallways and skipped rooms)

   -- Vault placement tracking
   self.vaultCounts = {
      ammo = 6,
      weapon = 6,
      utility = 6,
      money = 6
   }

   -- Stairs placement tracking
   self.stairsPlaced = false

   -- Squad definitions - list of bot constructor lists
   self.squadDefinitions = {
      { prism.actors.BurstBot, prism.actors.BurstBot,    prism.actors.LaserBot },
      { prism.actors.BurstBot, prism.actors.GrenadierBot },
      { prism.actors.LaserBot, prism.actors.LaserBot,    prism.actors.GrenadierBot },
      { prism.actors.BoomBot,  prism.actors.BoomBot },
   }

   -- Performance caching
   self.cachedFloorCount = 0
   self.floorCountDirty = true
   self.cachedWallDensityMap = nil

   -- Progress tracking
   -- Rough estimate: 5-wide steps + 3-wide steps + ~100 room attempts + ~50 filler steps
   self.estimatedRoomSteps = 100
   self.estimatedFillerSteps = 50
   self.estimatedTotalSteps = self.maxSteps5Wide + self.maxSteps3Wide + self.estimatedRoomSteps +
       self.estimatedFillerSteps
   self.currentStep = 0
   self.progressPhase = "Initializing"
end

--- Get current generation progress for UI display
--- @return {phase: string, current: number, total: number, percentage: number}
function TunnelWorldGenerator:getProgress()
   return {
      phase = self.progressPhase,
      current = self.currentStep,
      total = self.estimatedTotalSteps,
      percentage = math.floor((self.currentStep / self.estimatedTotalSteps) * 100)
   }
end

--- Count the number of floor tiles currently dug in the builder.
--- Uses cached value when available for performance.
---@return integer count
function TunnelWorldGenerator:countFloorTiles()
   if not self.floorCountDirty then
      return self.cachedFloorCount
   end

   local count = 0
   for _, _, cell in self.builder:each() do
      local nameComp = cell:get(prism.components.Name)
      if nameComp and nameComp.name == "Floor" then
         count = count + 1
      end
   end

   self.cachedFloorCount = count
   self.floorCountDirty = false
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
   self:spawnAgent(startPos, startDir, CONFIG.WIDTH_5_WIDE)

   local maxRespawns = CONFIG.MAX_RESPAWNS_5WIDE

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
      self.floorCountDirty = true -- Agents dug floors, invalidate cache

      -- Yield after each tick for step-by-step visualization
      self.currentStep = self.currentStep + 1
      self.progressPhase = string.format("Tunneling (5-wide): %d/%d", self.totalSteps5Wide, self.maxSteps5Wide)
      coroutine.yield()

      -- Handle the case where all agents have died
      if not anyAlive then
         local progress = self.totalSteps5Wide / self.maxSteps5Wide

         if progress >= CONFIG.COMPLETION_THRESHOLD then
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
            self:spawnAgent(respawnPos, respawnDir, CONFIG.WIDTH_5_WIDE)
            maxRespawns = maxRespawns - 1
         else
            prism.logger.info("No valid respawn spot found, stopping generation.")
            break
         end
      end
   end

   -- Phase 9: run the 3-wide hallway pass on top of the completed 5-wide map
   self.progressPhase = "Starting 3-wide pass"
   self:run3WidePass()

   -- Accumulate all hallway floor tiles as spawn spots (before rooms are added)
   self.progressPhase = "Accumulating hallway spawn spots"
   prism.logger.info("Accumulating hallway spawn spots...")
   for y = 0, self.size.y - 1 do
      for x = 0, self.size.x - 1 do
         local cell = self.builder:get(x, y)
         if cell then
            local nameComp = cell:get(prism.components.Name)
            if nameComp and nameComp.name == "Floor" then
               table.insert(self.spawnSpots, { x = x, y = y })
            end
         end
      end
   end
   prism.logger.info(string.format("Found %d hallway spawn spots.", #self.spawnSpots))

   -- Phase 10: run the rooms pass, which carves out rooms in the remaining wall space
   -- Rooms: fill remaining wall space with rooms
   self.progressPhase = "Generating rooms"
   self:runRoomsPass()

   -- Fillers: add objects inside rooms and junctions
   self.progressPhase = "Adding room details"
   self:runFillersPass()

   -- Randomize tile visuals
   self.progressPhase = "Randomizing tiles"
   self:randomizeTiles()

   -- Spawn player in a random room
   self.progressPhase = "Placing player"
   self:spawnPlayer()

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
   local margin = CONFIG.MARGIN_EDGE

   if edge == 1 then -- Top edge
      position = prism.Vector2(RNG:random(margin * 2, self.size.x - margin * 2), margin)
      direction = prism.Vector2.DOWN
   elseif edge == 2 then -- Right edge
      position = prism.Vector2(self.size.x - margin, RNG:random(margin * 2, self.size.y - margin * 2))
      direction = prism.Vector2.LEFT
   elseif edge == 3 then -- Bottom edge
      position = prism.Vector2(RNG:random(margin * 2, self.size.x - margin * 2), self.size.y - margin)
      direction = prism.Vector2.UP
   else -- Left edge
      position = prism.Vector2(margin, RNG:random(margin * 2, self.size.y - margin * 2))
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
         local spawnedAgents, shouldContinue, junctionBounds = agent:step(self.builder, terminationPressure)

         -- Collect junction bounds for filler pass
         if junctionBounds then
            table.insert(self.junctions, junctionBounds)
            prism.logger.info(string.format(
               "Recorded junction at (%d,%d) size %dx%d",
               junctionBounds.x, junctionBounds.y, junctionBounds.width, junctionBounds.height
            ))
         end

         -- Kill the agent if it stepped out of bounds
         if shouldContinue and self:isAgentInBounds(agent) then
            table.insert(continuingAgents, agent)
         else
            agent.alive = false

            -- Place stairs at first dead-end (but not at junctions)
            if not self.stairsPlaced and not junctionBounds then
               -- Ensure the cell is Floor before placing stairs
               self.builder:set(agent.position.x, agent.position.y, prism.cells.Floor())
               local stairs = prism.actors.Stairs()
               self.builder:addActor(stairs, agent.position.x, agent.position.y)
               self.stairsPlaced = true
               prism.logger.info(string.format(
                  "Placed stairs at first dead-end (%d,%d)",
                  agent.position.x, agent.position.y
               ))
            end
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
   local margin = agent.width + CONFIG.MARGIN_AGENT
   return agent.position.x >= margin and agent.position.x <= self.size.x - margin and
       agent.position.y >= margin and agent.position.y <= self.size.y - margin
end

--- Find a floor cell on the existing map from which a new agent can dig into
--- uncharted (wall) territory.  Returns nil, nil if no suitable spot exists.
---@return Vector2|nil position
---@return Vector2|nil direction
function TunnelWorldGenerator:findRespawnSpot()
   local agentWidth = CONFIG.WIDTH_5_WIDE
   local margin = agentWidth + CONFIG.MARGIN_AGENT
   local minAhead = CONFIG.MIN_AHEAD_5WIDE

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

   local attempts = math.min(CONFIG.MAX_RESPAWN_ATTEMPTS, #floorPositions)
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
   local radius   = CONFIG.WALL_DENSITY_RADIUS
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
   local agentWidth       = CONFIG.WIDTH_3_WIDE
   local minAhead         = CONFIG.MIN_AHEAD_3WIDE
   local margin           = agentWidth + CONFIG.MARGIN_AGENT
   local densityThreshold = CONFIG.WALL_DENSITY_THRESHOLD

   -- Use cached wall-density map for performance
   local densityMap       = self.cachedWallDensityMap
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

   while #spawned < count and attempts < CONFIG.MAX_3WIDE_SPAWN_ATTEMPTS do
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
   self.agents = {}

   -- Compute wall density map once and cache it for all 3-wide spawning
   self.cachedWallDensityMap = self:computeWallDensityMap()

   local initialCount = RNG:random(CONFIG.INITIAL_AGENTS_3WIDE_MIN, CONFIG.INITIAL_AGENTS_3WIDE_MAX)
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

   local maxRespawns = CONFIG.MAX_RESPAWNS_3WIDE

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
      self.floorCountDirty = true -- Agents dug floors, invalidate cache

      self.currentStep = self.currentStep + 1
      self.progressPhase = string.format("Tunneling (3-wide): %d/%d", self.totalSteps3Wide, self.maxSteps3Wide)
      coroutine.yield()

      if not anyAlive then
         local progress = self.totalSteps3Wide / self.maxSteps3Wide

         if progress >= CONFIG.COMPLETION_THRESHOLD then
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

   for width = CONFIG.ROOM_MIN_SIZE_TOTAL, CONFIG.ROOM_MAX_DIMENSION do
      for height = CONFIG.ROOM_MIN_SIZE_TOTAL, CONFIG.ROOM_MAX_DIMENSION do
         -- Check aspect ratio constraint
         local interiorW = width - 2
         local interiorH = height - 2
         if not (interiorW > interiorH * CONFIG.ROOM_MAX_ASPECT_RATIO or
                interiorH > interiorW * CONFIG.ROOM_MAX_ASPECT_RATIO) then
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
         end
      end
   end

   if bestWidth >= CONFIG.ROOM_MIN_SIZE_TOTAL and bestHeight >= CONFIG.ROOM_MIN_SIZE_TOTAL then
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
   -- Incrementally update cached floor count
   self.cachedFloorCount = self.cachedFloorCount + (width * height)
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

   -- Track placed door positions to avoid adjacency
   local placedDoors = {}

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
            if wall1 and wall2 then
               local name1 = wall1:get(prism.components.Name)
               local name2 = wall2:get(prism.components.Name)
               if name1 and name1.name == "Wall" and name2 and name2.name == "Wall" then
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
               end
            end
         end
      else
         -- Vertical edge - scan top to bottom for 2-wide door spots
         for dy = edge.y1, edge.y2 - 1 do
            local wallX, wallY1 = edge.x1, dy
            local wallY2 = dy + 1

            -- Check if both wall cells exist
            local wall1 = self.builder:get(wallX, wallY1)
            local wall2 = self.builder:get(wallX, wallY2)
            if wall1 and wall2 then
               local name1 = wall1:get(prism.components.Name)
               local name2 = wall2:get(prism.components.Name)
               if name1 and name1.name == "Wall" and name2 and name2.name == "Wall" then
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
               end
            end
         end
      end

      -- Place doors if candidates exist
      if #doorCandidates > 0 then
         local maxDoors = math.min(2, math.floor(#doorCandidates / 2))
         local numDoors = RNG:random(1, maxDoors)

         -- Shuffle candidates
         for i = #doorCandidates, 2, -1 do
            local j = RNG:random(1, i)
            doorCandidates[i], doorCandidates[j] = doorCandidates[j], doorCandidates[i]
         end

         -- Place the doors (only 1-wide or 2-wide, checking for adjacency)
         for i = 1, math.min(numDoors, #doorCandidates) do
            local door = doorCandidates[i]

            -- Check if this door candidate is adjacent to any placed doors
            local isAdjacent = false
            for _, placedPos in ipairs(placedDoors) do
               local dx = math.abs(door.x1 - placedPos.x)
               local dy = math.abs(door.y1 - placedPos.y)
               local dx2 = math.abs(door.x2 - placedPos.x)
               local dy2 = math.abs(door.y2 - placedPos.y)

               -- Check if either door position is adjacent (within 1 cell)
               if (dx <= 1 and dy <= 1) or (dx2 <= 1 and dy2 <= 1) then
                  isAdjacent = true
                  break
               end
            end

            -- Only place door if it's not adjacent to an existing door
            if not isAdjacent then
               local twoWide = RNG:random(1, 100) <= CONFIG.ROOM_DOOR_WIDTH_2WIDE_CHANCE

               if twoWide then
                  -- 2-wide door
                  self.builder:setCell(door.x1, door.y1, prism.cells.Floor())
                  self.builder:setCell(door.x2, door.y2, prism.cells.Floor())
                  self.builder:addActor(prism.actors.Door(), door.x1, door.y1)
                  self.builder:addActor(prism.actors.Door(), door.x2, door.y2)
                  self.cachedFloorCount = self.cachedFloorCount + 2

                  -- Track both door positions
                  table.insert(placedDoors, { x = door.x1, y = door.y1 })
                  table.insert(placedDoors, { x = door.x2, y = door.y2 })
               else
                  -- 1-wide door (pick one of the two cells randomly)
                  local doorX, doorY
                  if RNG:random(1, 2) == 1 then
                     doorX, doorY = door.x1, door.y1
                  else
                     doorX, doorY = door.x2, door.y2
                  end

                  self.builder:setCell(doorX, doorY, prism.cells.Floor())
                  self.builder:addActor(prism.actors.Door(), doorX, doorY)
                  self.cachedFloorCount = self.cachedFloorCount + 1

                  -- Track door position
                  table.insert(placedDoors, { x = doorX, y = doorY })
               end
            end
         end
      end
   end
end

--- Attempt to place a room adjacent to a random floor tile.
--- Returns true if a room was successfully placed, false otherwise.
---@return boolean success
function TunnelWorldGenerator:tryPlaceRoom()
   local margin = CONFIG.MARGIN_ROOM

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
      if x and w >= CONFIG.ROOM_MIN_SIZE_INTERIOR and h >= CONFIG.ROOM_MIN_SIZE_INTERIOR then
         self:carveRoom(x, y, w, h)
         self:createDoors(x, y, w, h)
         self.roomsPlaced = self.roomsPlaced + 1
         -- Track room bounds for filler pass
         table.insert(self.rooms, { x = x, y = y, width = w, height = h })
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

   local maxFailures = CONFIG.ROOM_MAX_CONSECUTIVE_FAILURES
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
         self.currentStep = self.currentStep + 1
         self.progressPhase = string.format("Rooms: %d placed", self.roomsPlaced)
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

--- Find all door cells in a room (floor cells in the walls surrounding the interior).
---@param x integer Room interior top-left x
---@param y integer Room interior top-left y
---@param width integer Room interior width
---@param height integer Room interior height
---@return table<Vector2> doors List of door cell positions
function TunnelWorldGenerator:findDoors(x, y, width, height)
   local doors = {}

   -- Check all four edges for floor cells (doors)
   -- Top edge
   for dx = x, x + width - 1 do
      local cell = self.builder:get(dx, y - 1)
      if cell then
         local nameComp = cell:get(prism.components.Name)
         if nameComp and nameComp.name == "Floor" then
            table.insert(doors, prism.Vector2(dx, y - 1))
         end
      end
   end

   -- Bottom edge
   for dx = x, x + width - 1 do
      local cell = self.builder:get(dx, y + height)
      if cell then
         local nameComp = cell:get(prism.components.Name)
         if nameComp and nameComp.name == "Floor" then
            table.insert(doors, prism.Vector2(dx, y + height))
         end
      end
   end

   -- Left edge
   for dy = y, y + height - 1 do
      local cell = self.builder:get(x - 1, dy)
      if cell then
         local nameComp = cell:get(prism.components.Name)
         if nameComp and nameComp.name == "Floor" then
            table.insert(doors, prism.Vector2(x - 1, dy))
         end
      end
   end

   -- Right edge
   for dy = y, y + height - 1 do
      local cell = self.builder:get(x + width, dy)
      if cell then
         local nameComp = cell:get(prism.components.Name)
         if nameComp and nameComp.name == "Floor" then
            table.insert(doors, prism.Vector2(x + width, dy))
         end
      end
   end

   return doors
end

--- Check if a position is within clearance distance of any door.
---@param px integer
---@param py integer
---@param doors table<Vector2>
---@param clearance integer
---@return boolean
function TunnelWorldGenerator:isNearDoor(px, py, doors, clearance)
   for _, door in ipairs(doors) do
      local dx = px - door.x
      local dy = py - door.y
      if dx * dx + dy * dy <= clearance * clearance then
         return true
      end
   end
   return false
end

--- Conference room filler: single horizontal or vertical halfwall line.
---@param room table {x, y, width, height}
---@param doors table<Vector2>
function TunnelWorldGenerator:fillConferenceRoom(room, doors)
   local x, y, w, h = room.x, room.y, room.width, room.height
   local clearance = CONFIG.FILLER_DOOR_CLEARANCE

   -- Choose orientation based on room shape
   local horizontal = w >= h

   if horizontal then
      -- Horizontal line through the middle
      local lineY = y + math.floor(h / 2)
      for lx = x + 1, x + w - 2 do
         if not self:isNearDoor(lx, lineY, doors, clearance) then
            self.builder:set(lx, lineY, prism.cells.HalfWall())
         end
      end
   else
      -- Vertical line through the middle
      local lineX = x + math.floor(w / 2)
      for ly = y + 1, y + h - 2 do
         if not self:isNearDoor(lineX, ly, doors, clearance) then
            self.builder:set(lineX, ly, prism.cells.HalfWall())
         end
      end
   end
end

--- Server rows filler: parallel rows of walls with 1 or 2 cell spacing.
---@param room table {x, y, width, height}
---@param doors table<Vector2>
function TunnelWorldGenerator:fillServerRows(room, doors)
   local x, y, w, h = room.x, room.y, room.width, room.height
   local clearance = CONFIG.FILLER_DOOR_CLEARANCE
   local padding = CONFIG.FILLER_EDGE_PADDING

   -- Random orientation
   local horizontal = RNG:random(1, 2) == 1
   -- Random spacing (1 or 2)
   local spacing = RNG:random(1, 2)

   if horizontal then
      -- Horizontal rows
      local rowY = y + padding
      while rowY <= y + h - padding - 1 do
         for rx = x + padding, x + w - padding - 1 do
            if not self:isNearDoor(rx, rowY, doors, clearance) then
               self.builder:set(rx, rowY, prism.cells.Wall())
            end
         end
         rowY = rowY + spacing + 1
      end

      -- If room is long enough, add perpendicular hallway
      if w >= 12 then
         local hallX = x + math.floor(w / 2) + RNG:random(-2, 2)
         hallX = math.max(x + padding + 1, math.min(hallX, x + w - padding - 2))
         for hy = y + padding, y + h - padding - 1 do
            self.builder:set(hallX, hy, prism.cells.Floor())
         end
      end
   else
      -- Vertical rows
      local rowX = x + padding
      while rowX <= x + w - padding - 1 do
         for ry = y + padding, y + h - padding - 1 do
            if not self:isNearDoor(rowX, ry, doors, clearance) then
               self.builder:set(rowX, ry, prism.cells.Wall())
            end
         end
         rowX = rowX + spacing + 1
      end

      -- If room is long enough, add perpendicular hallway
      if h >= 12 then
         local hallY = y + math.floor(h / 2) + RNG:random(-2, 2)
         hallY = math.max(y + padding + 1, math.min(hallY, y + h - padding - 2))
         for hx = x + padding, x + w - padding - 1 do
            self.builder:set(hx, hallY, prism.cells.Floor())
         end
      end
   end
end

--- Sparse machines filler: random halfwall rectangles scattered around.
---@param room table {x, y, width, height}
---@param doors table<Vector2>
function TunnelWorldGenerator:fillSparseMachines(room, doors)
   local x, y, w, h = room.x, room.y, room.width, room.height
   local clearance = CONFIG.FILLER_DOOR_CLEARANCE
   local padding = CONFIG.FILLER_EDGE_PADDING

   local area = w * h
   local numMachines = math.floor(area / 20) -- 1 per 20 sqft

   for i = 1, numMachines do
      -- Random machine dimensions (1-3 wide, 1-3 tall)
      local mw = RNG:random(1, 3)
      local mh = RNG:random(1, 3)

      -- Random position within padding
      local mx = x + padding + RNG:random(0, math.max(0, w - padding * 2 - mw))
      local my = y + padding + RNG:random(0, math.max(0, h - padding * 2 - mh))

      -- Place machine if not near doors
      local canPlace = true
      for dx = 0, mw - 1 do
         for dy = 0, mh - 1 do
            if self:isNearDoor(mx + dx, my + dy, doors, clearance) then
               canPlace = false
               break
            end
         end
         if not canPlace then break end
      end

      if canPlace then
         for dx = 0, mw - 1 do
            for dy = 0, mh - 1 do
               self.builder:set(mx + dx, my + dy, prism.cells.HalfWall())
            end
         end
      end
   end
end

--- Cafeteria filler: 1-wide table rows with 3 cells spacing between.
---@param room table {x, y, width, height}
---@param doors table<Vector2>
function TunnelWorldGenerator:fillCafeteria(room, doors)
   local x, y, w, h = room.x, room.y, room.width, room.height
   local clearance = CONFIG.FILLER_DOOR_CLEARANCE
   local padding = CONFIG.FILLER_EDGE_PADDING

   -- Random orientation
   local horizontal = RNG:random(1, 2) == 1
   local tableSpacing = 3

   if horizontal then
      -- Horizontal tables (1 cell wide, up to 3 long)
      local tableY = y + padding
      while tableY <= y + h - padding - 1 do
         local tableX = x + padding
         while tableX <= x + w - padding - 1 do
            local tableLen = math.min(3, x + w - padding - tableX)
            for i = 0, tableLen - 1 do
               if not self:isNearDoor(tableX + i, tableY, doors, clearance) then
                  self.builder:set(tableX + i, tableY, prism.cells.HalfWall())
               end
            end
            tableX = tableX + tableLen + tableSpacing
         end
         tableY = tableY + tableSpacing + 1
      end
   else
      -- Vertical tables
      local tableX = x + padding
      while tableX <= x + w - padding - 1 do
         local tableY = y + padding
         while tableY <= y + h - padding - 1 do
            local tableLen = math.min(3, y + h - padding - tableY)
            for i = 0, tableLen - 1 do
               if not self:isNearDoor(tableX, tableY + i, doors, clearance) then
                  self.builder:set(tableX, tableY + i, prism.cells.HalfWall())
               end
            end
            tableY = tableY + tableLen + tableSpacing
         end
         tableX = tableX + tableSpacing + 1
      end
   end
end

--- Central terminal filler: central full-wall object with 3x1 halfwall desks around it.
---@param room table {x, y, width, height}
---@param doors table<Vector2>
function TunnelWorldGenerator:fillCentralTerminal(room, doors)
   local x, y, w, h = room.x, room.y, room.width, room.height
   local clearance = CONFIG.FILLER_DOOR_CLEARANCE

   -- Central object size based on room size
   local centerSize = math.min(5, math.max(3, math.floor(math.min(w, h) / 3)))

   -- Center position
   local cx = x + math.floor((w - centerSize) / 2)
   local cy = y + math.floor((h - centerSize) / 2)

   -- Place central object (full walls)
   for dx = 0, centerSize - 1 do
      for dy = 0, centerSize - 1 do
         self.builder:set(cx + dx, cy + dy, prism.cells.Wall())
      end
   end

   -- Place desks (3x1 halfwalls) around the center facing it
   -- Top side
   if cy - 2 >= y then
      for dx = 0, centerSize - 1 do
         if not self:isNearDoor(cx + dx, cy - 2, doors, clearance) then
            self.builder:set(cx + dx, cy - 2, prism.cells.HalfWall())
         end
      end
   end

   -- Bottom side
   if cy + centerSize + 1 < y + h then
      for dx = 0, centerSize - 1 do
         if not self:isNearDoor(cx + dx, cy + centerSize + 1, doors, clearance) then
            self.builder:set(cx + dx, cy + centerSize + 1, prism.cells.HalfWall())
         end
      end
   end

   -- Left side
   if cx - 2 >= x then
      for dy = 0, centerSize - 1 do
         if not self:isNearDoor(cx - 2, cy + dy, doors, clearance) then
            self.builder:set(cx - 2, cy + dy, prism.cells.HalfWall())
         end
      end
   end

   -- Right side
   if cx + centerSize + 1 < x + w then
      for dy = 0, centerSize - 1 do
         if not self:isNearDoor(cx + centerSize + 1, cy + dy, doors, clearance) then
            self.builder:set(cx + centerSize + 1, cy + dy, prism.cells.HalfWall())
         end
      end
   end
end

--- Central pillar filler for junctions: single pillar in the middle.
---@param junction table {x, y, width, height}
function TunnelWorldGenerator:fillJunctionCentralPillar(junction)
   local x, y, w, h = junction.x, junction.y, junction.width, junction.height

   -- Pillar size scales with junction size: 3x3 minimum, up to 5x5
   -- local pillarSize = math.min(5, math.max(3, math.floor(math.min(w, h) / 5)))
   local pillarSize = 4

   -- Center the pillar
   local px = x + math.floor((w - pillarSize) / 2)
   local py = y + math.floor((h - pillarSize) / 2)

   -- Place pillar (full walls)
   for dx = 0, pillarSize - 1 do
      for dy = 0, pillarSize - 1 do
         if px + dx >= x and px + dx < x + w and py + dy >= y and py + dy < y + h then
            self.builder:set(px + dx, py + dy, prism.cells.Wall())
         end
      end
   end

   -- Place waypoint floors in the corners, inset by 1 from walls (closer to corners)
   local inset = 1
   local corners = {
      { x = x + inset,         y = y + inset },         -- Top-left
      { x = x + w - inset - 1, y = y + inset },         -- Top-right
      { x = x + inset,         y = y + h - inset - 1 }, -- Bottom-left
      { x = x + w - inset - 1, y = y + h - inset - 1 }  -- Bottom-right
   }

   for _, corner in ipairs(corners) do
      if corner.x >= x and corner.x < x + w and corner.y >= y and corner.y < y + h then
         self.builder:set(corner.x, corner.y, prism.cells.WaypointFloor())
      end
   end
end

--- Corner pillars filler for junctions: large pillars in corners.
---@param junction table {x, y, width, height}
function TunnelWorldGenerator:fillJunctionCornerPillars(junction)
   local x, y, w, h = junction.x, junction.y, junction.width, junction.height

   -- Pillar size: 2x2 to 4x4 based on junction size
   local pillarSize = math.min(4, math.max(2, math.floor(math.min(w, h) / 6)))

   -- Leave at least 3 cells clearance for navigation in the center
   local clearance = 3
   -- Inset pillars from edges by 2 cells
   local inset = 2

   prism.logger.info(string.format(
      "Corner pillars: pillarSize=%d, required space=%d, actual space=%dx%d",
      pillarSize, pillarSize * 2 + clearance, w, h
   ))

   if w < pillarSize * 2 + clearance + inset * 2 or h < pillarSize * 2 + clearance + inset * 2 then
      prism.logger.info("Corner pillars: Junction too small, aborting")
      return -- Junction too small for corner pillars
   end

   -- Place pillar in each corner, inset from edges
   local corners = {
      { x + inset,                  y + inset },                  -- Top-left
      { x + w - pillarSize - inset, y + inset },                  -- Top-right
      { x + inset,                  y + h - pillarSize - inset }, -- Bottom-left
      { x + w - pillarSize - inset, y + h - pillarSize - inset }  -- Bottom-right
   }

   for _, corner in ipairs(corners) do
      for dx = 0, pillarSize - 1 do
         for dy = 0, pillarSize - 1 do
            local px, py = corner[1] + dx, corner[2] + dy
            if px >= x and px < x + w and py >= y and py < y + h then
               self.builder:set(px, py, prism.cells.Wall())
            end
         end
      end
   end
end

--- Fill a room with vaults along the walls
---@param room table {x, y, width, height}
function TunnelWorldGenerator:fillVaultRoom(room)
   local numVaults = RNG:random(2, 5)
   local vaultsPlaced = 0

   -- Collect wall positions
   local wallPositions = {}
   -- Top and bottom walls
   for rx = room.x + 1, room.x + room.width - 2 do
      table.insert(wallPositions, { x = rx, y = room.y + 1 })
      table.insert(wallPositions, { x = rx, y = room.y + room.height - 2 })
   end
   -- Left and right walls
   for ry = room.y + 1, room.y + room.height - 2 do
      table.insert(wallPositions, { x = room.x + 1, y = ry })
      table.insert(wallPositions, { x = room.x + room.width - 2, y = ry })
   end

   -- Shuffle wall positions
   for i = #wallPositions, 2, -1 do
      local j = RNG:random(1, i)
      wallPositions[i], wallPositions[j] = wallPositions[j], wallPositions[i]
   end

   -- Place vaults
   for i = 1, math.min(numVaults, #wallPositions) do
      local vaultTypes = {}
      if self.vaultCounts.ammo > 0 then table.insert(vaultTypes, "ammo") end
      if self.vaultCounts.weapon > 0 then table.insert(vaultTypes, "weapon") end
      if self.vaultCounts.utility > 0 then table.insert(vaultTypes, "utility") end
      if self.vaultCounts.money > 0 then table.insert(vaultTypes, "money") end

      if #vaultTypes > 0 then
         local vaultType = vaultTypes[RNG:random(1, #vaultTypes)]
         local pos = wallPositions[i]

         -- Place the vault actor
         local vaultActor
         if vaultType == "ammo" then
            vaultActor = prism.actors.AmmoStash(self.biome)
            self.vaultCounts.ammo = self.vaultCounts.ammo - 1
         elseif vaultType == "weapon" then
            vaultActor = prism.actors.WeaponCache(self.biome)
            self.vaultCounts.weapon = self.vaultCounts.weapon - 1
         elseif vaultType == "utility" then
            vaultActor = prism.actors.UtilityContainer(self.biome)
            self.vaultCounts.utility = self.vaultCounts.utility - 1
         elseif vaultType == "money" then
            vaultActor = prism.actors.MoneyVault(self.biome)
            self.vaultCounts.money = self.vaultCounts.money - 1
         end

         self.builder:addActor(vaultActor, pos.x, pos.y)
         vaultsPlaced = vaultsPlaced + 1
      end
   end

   prism.logger.info(string.format(
      "Fillers: Placed %d vaults in room at (%d,%d) %dx%d",
      vaultsPlaced, room.x, room.y, room.width, room.height
   ))
end

--- Run the filler pass on all rooms and junctions.
function TunnelWorldGenerator:runFillersPass()
   prism.logger.info(string.format(
      "Fillers: Starting filler pass for %d rooms and %d junctions.",
      #self.rooms, #self.junctions
   ))

   local roomsFilled = 0
   local roomsSkipped = 0
   local junctionsFilled = 0
   local junctionsSkipped = 0

   for roomIndex, room in ipairs(self.rooms) do
      -- First 3 rooms are vault rooms
      if roomIndex <= 3 then
         self:fillVaultRoom(room)
         roomsFilled = roomsFilled + 1
         -- 5% chance to skip room filler entirely
      elseif RNG:random(1, 100) <= CONFIG.FILLER_SKIP_CHANCE then
         roomsSkipped = roomsSkipped + 1
         -- Add all interior floor cells of this skipped room to spawn spots
         for ry = room.y + 1, room.y + room.height - 2 do
            for rx = room.x + 1, room.x + room.width - 2 do
               local cell = self.builder:get(rx, ry)
               if cell then
                  local nameComp = cell:get(prism.components.Name)
                  if nameComp and nameComp.name == "Floor" then
                     table.insert(self.spawnSpots, { x = rx, y = ry })
                  end
               end
            end
         end
      else
         local w, h = room.width, room.height
         local area = w * h
         local doors = self:findDoors(room.x, room.y, room.width, room.height)

         -- Build list of eligible fillers
         local eligible = {}

         -- Conference room: works for any size >= 5x5
         if w >= 5 and h >= 5 then
            table.insert(eligible, "conference")
         end

         -- Server rows: needs at least 7x7
         if w >= 7 and h >= 7 then
            table.insert(eligible, "server_rows")
         end

         -- Sparse machines: needs at least 8x8
         if w >= 8 and h >= 8 then
            table.insert(eligible, "sparse_machines")
         end

         -- Cafeteria: needs at least 9x9
         if w >= 9 and h >= 9 then
            table.insert(eligible, "cafeteria")
         end

         -- Central terminal: needs at least 11x11
         if w >= 11 and h >= 11 then
            table.insert(eligible, "central_terminal")
         end

         -- Pick random eligible filler
         if #eligible > 0 then
            local choice = eligible[RNG:random(1, #eligible)]

            if choice == "conference" then
               self:fillConferenceRoom(room, doors)
            elseif choice == "server_rows" then
               self:fillServerRows(room, doors)
            elseif choice == "sparse_machines" then
               self:fillSparseMachines(room, doors)
            elseif choice == "cafeteria" then
               self:fillCafeteria(room, doors)
            elseif choice == "central_terminal" then
               self:fillCentralTerminal(room, doors)
            end

            roomsFilled = roomsFilled + 1
            prism.logger.info(string.format(
               "Fillers: Applied '%s' to room at (%d,%d) %dx%d",
               choice, room.x, room.y, room.width, room.height
            ))
         else
            roomsSkipped = roomsSkipped + 1
         end
      end

      self.currentStep = self.currentStep + 1
      self.progressPhase = string.format("Filling rooms: %d/%d", roomsFilled + roomsSkipped, #self.rooms)
      coroutine.yield()
   end

   -- Process junctions
   for _, junction in ipairs(self.junctions) do
      -- 40% chance to skip junction filler (higher than rooms)
      if RNG:random(1, 100) <= CONFIG.FILLER_JUNCTION_SKIP_CHANCE then
         junctionsSkipped = junctionsSkipped + 1
      else
         local w, h = junction.width, junction.height

         prism.logger.info(string.format(
            "Processing junction at (%d,%d) size %dx%d",
            junction.x, junction.y, w, h
         ))

         -- Build list of eligible junction fillers
         local eligible = {}

         -- Central pillar: works for any junction >= 9x9
         if w >= 8 and h >= 8 then
            table.insert(eligible, "central_pillar")
            prism.logger.info("  -> central_pillar eligible")
         end

         -- Corner pillars: needs at least 10x10
         -- if w >= 10 and h >= 10 then
         --    table.insert(eligible, "corner_pillars")
         --    prism.logger.info("  -> corner_pillars eligible")
         -- end

         prism.logger.info(string.format("  Total eligible fillers: %d", #eligible))

         -- Pick random eligible filler
         if #eligible > 0 then
            local choice = eligible[RNG:random(1, #eligible)]

            if choice == "central_pillar" then
               self:fillJunctionCentralPillar(junction)
            elseif choice == "corner_pillars" then
               self:fillJunctionCornerPillars(junction)
            end

            junctionsFilled = junctionsFilled + 1
            prism.logger.info(string.format(
               "Fillers: Applied '%s' to junction at (%d,%d) %dx%d",
               choice, junction.x, junction.y, junction.width, junction.height
            ))
         else
            junctionsSkipped = junctionsSkipped + 1
         end
      end

      self.currentStep = self.currentStep + 1
      self.progressPhase = string.format("Filling junctions: %d/%d", junctionsFilled + junctionsSkipped, #self.junctions)
      coroutine.yield()
   end

   prism.logger.info(string.format(
      "Fillers: Complete. Rooms: %d filled, %d skipped. Junctions: %d filled, %d skipped.",
      roomsFilled, roomsSkipped, junctionsFilled, junctionsSkipped
   ))
end

--- Spawn the player actor in a random room
function TunnelWorldGenerator:spawnPlayer()
   -- Use existing player if provided, otherwise create a new one
   local player = self.existingPlayer or prism.actors.Player(true)

   if #self.rooms == 0 then
      prism.logger.warn("No rooms available to spawn player, placing at fallback position.")
      -- Fallback: find any floor tile
      for y = 1, self.size.y - 1 do
         for x = 1, self.size.x - 1 do
            local cell = self.builder:get(x, y)
            if cell then
               local nameComp = cell:get(prism.components.Name)
               if nameComp and nameComp.name == "Floor" then
                  self.builder:addActor(player, x, y)
                  prism.logger.info(string.format("Player spawned at fallback position (%d, %d)", x, y))
                  return
               end
            end
         end
      end
      prism.logger.error("Could not find any floor tiles to spawn player!")
      return
   end

   -- Pick a random room
   local room = self.rooms[RNG:random(1, #self.rooms)]

   -- Find a floor tile in the room that doesn't have an actor
   local attempts = 0
   local maxAttempts = 100

   while attempts < maxAttempts do
      local x = room.x + RNG:random(1, room.width - 2)
      local y = room.y + RNG:random(1, room.height - 2)

      local cell = self.builder:get(x, y)
      if cell then
         local nameComp = cell:get(prism.components.Name)
         if nameComp and nameComp.name == "Floor" then
            -- Check if there's already an actor at this position
            -- (we can't check this in builder, so just place it)
            self.builder:addActor(player, x, y)
            prism.logger.info(string.format(
               "Player spawned in room at (%d, %d) [room size: %dx%d]",
               x, y, room.width, room.height
            ))
            return
         end
      end

      attempts = attempts + 1
   end

   -- If we couldn't find a spot in the random room, try the center
   local centerX = room.x + math.floor(room.width / 2)
   local centerY = room.y + math.floor(room.height / 2)
   self.builder:addActor(player, centerX, centerY)
   prism.logger.info(string.format(
      "Player spawned at room center (%d, %d)",
      centerX, centerY
   ))
end

--- Randomize tile visuals for walls and floors
function TunnelWorldGenerator:randomizeTiles()
   local wallTiles = {
      TILES.WALL_1, TILES.WALL_2, TILES.WALL_3, TILES.WALL_4,
      TILES.WALL_5, TILES.WALL_6, TILES.WALL_7
   }
   local wallEdgeTiles = {
      TILES.WALL_EDGE_1, TILES.WALL_EDGE_2, TILES.WALL_EDGE_3, TILES.WALL_EDGE_4,
      TILES.WALL_EDGE_5, TILES.WALL_EDGE_6, TILES.WALL_EDGE_7
   }
   local floorTiles = {
      TILES.FLOOR_1, TILES.FLOOR_2, TILES.FLOOR_3
   }

   for y = 0, self.size.y - 1 do
      for x = 0, self.size.x - 1 do
         local cell = self.builder:get(x, y)

         if cell then
            local nameComp = cell:get(prism.components.Name)
            local drawable = cell:get(prism.components.Drawable)

            if nameComp and drawable then
               if nameComp.name == "Wall" then
                  -- Check if there's a floor directly south
                  local southY = y + 1
                  local hasFloorSouth = false

                  if southY < self.size.y then
                     local southCell = self.builder:get(x, southY)
                     if southCell then
                        local southName = southCell:get(prism.components.Name)
                        if southName and southName.name == "Floor" then
                           hasFloorSouth = true
                        end
                     end
                  end

                  -- Pick appropriate wall tile
                  if hasFloorSouth then
                     drawable.index = wallEdgeTiles[RNG:random(1, #wallEdgeTiles)]
                  else
                     drawable.index = wallTiles[RNG:random(1, #wallTiles)]
                  end
               elseif nameComp.name == "Floor" then
                  -- Randomize floor tiles
                  drawable.index = floorTiles[RNG:random(1, #floorTiles)]
               end
            end
         end
      end
   end

   prism.logger.info("Tile randomization complete.")

   -- now, let's add a bunch of enemies.

   local NUM_SQUADS = RNG:random(5, 7)

   prism.logger.info(string.format("Spawning %d squads from %d valid spawn spots.", NUM_SQUADS, #self.spawnSpots))

   for i = 1, NUM_SQUADS do
      -- Pick a random squad definition
      local squadDef = self.squadDefinitions[RNG:random(1, #self.squadDefinitions)]
      local squadSize = #squadDef

      -- Check if we have enough spots for a full squad
      if #self.spawnSpots < squadSize then
         prism.logger.warn("Not enough spawn spots available for more squads.")
         break
      end

      -- Pick a random starting spot
      local startIndex = RNG:random(1, #self.spawnSpots - squadSize + 1)

      -- Spawn each bot in the squad at adjacent spots
      for j = 1, squadSize do
         -- make the first bot in each squad the leader, the rest followers. tint the leader red.
         local botConstructor = squadDef[j]
         local bot = botConstructor({
            leader = j == 1,
            follower = j ~= 1,
            tint = j == 1 and prism.Color4(1.0, 0.75, 0.75) or prism.Color4.WHITE
         })
         local spotIndex = startIndex + j - 1
         local spot = self.spawnSpots[spotIndex]

         -- Place the bot at this spot
         local pos = prism.Vector2(spot.x, spot.y)
         self.builder:addActor(bot, pos.x, pos.y)
      end

      -- Remove all used spots (remove from back to front to maintain indices)
      for j = squadSize, 1, -1 do
         table.remove(self.spawnSpots, startIndex + j - 1)
      end
   end
end

return TunnelWorldGenerator
