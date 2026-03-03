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

--- Find floor tiles suitable for spawning 3-wide (width=1) agents and return up to
--- `count` new agents positioned on those tiles facing open wall-space.
---@param count integer Number of agents to try to spawn
---@return table agents The spawned TunnelAgent instances (may be fewer than `count`)
function TunnelWorldGenerator:spawn3WideAgents(count)
   local agentWidth     = 1 -- width=1 → 3-wide hallway
   local minAhead       = 8
   local margin         = agentWidth + 2

   -- Collect every floor tile within the safe margin
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
      return {}
   end

   local cardinals = {
      prism.Vector2.UP,
      prism.Vector2.DOWN,
      prism.Vector2.LEFT,
      prism.Vector2.RIGHT,
   }

   local spawned   = {}
   local attempts  = 0

   while #spawned < count and attempts < 300 do
      attempts = attempts + 1
      local pos = floorPositions[RNG:random(1, #floorPositions)]

      -- Shuffle directions so we don't always prefer UP
      local dirOrder = { 1, 2, 3, 4 }
      for i = 4, 2, -1 do
         local j = RNG:random(1, i)
         dirOrder[i], dirOrder[j] = dirOrder[j], dirOrder[i]
      end

      for _, di in ipairs(dirOrder) do
         local dir = cardinals[di]
         if self:hasOpenSpaceAhead(pos, dir, agentWidth, minAhead) then
            local agent = TunnelAgent(pos, dir, agentWidth, nil, self.size)
            table.insert(spawned, agent)
            break
         end
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

return TunnelWorldGenerator
