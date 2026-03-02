local TunnelAgent = require "modules.game.world.tunnelagent"

---@class TunnelWorldGenerator:Object
---@field size Vector2
---@field builder LevelBuilder
---@field agents table<TunnelAgent>

local TunnelWorldGenerator = prism.Object:extend("TunnelWorldGenerator")

--- Constructor for the world generator
function TunnelWorldGenerator:__new()
   prism.logger.info("Building a tunnel level (new system).")

   self.size = prism.Vector2(100, 100)
   self.builder = prism.LevelBuilder()
   self.agents = {}
end

--- Generate the world
---@return LevelBuilder The built level
function TunnelWorldGenerator:generate()
   -- Fill with walls
   self.builder:rectangle("fill", 0, 0, self.size.x, self.size.y, prism.cells.Wall)

   -- TODO: Phase 2 - Spawn initial agent and run generation loop

   -- Yield to allow visualization
   coroutine.yield()

   return self.builder
end

--- Spawn a new agent at a specified position
---@param position Vector2 Starting position
---@param direction Vector2 Direction vector
---@param width integer Hallway width
---@return TunnelAgent The newly created agent
function TunnelWorldGenerator:spawnAgent(position, direction, width)
   -- TODO: Implement in Phase 2
   local agent = TunnelAgent(position, direction, width)
   table.insert(self.agents, agent)
   return agent
end

--- Find an open spot on the edge of the map pointing inward
---@return Vector2 position
---@return Vector2 direction
function TunnelWorldGenerator:findOpenEdgeSpot()
   -- TODO: Implement in Phase 2
   -- Pick a random edge and point inward
   local edge = love.math.random(1, 4)
   local position, direction

   if edge == 1 then -- Top edge
      position = prism.Vector2(love.math.random(10, self.size.x - 10), 5)
      direction = prism.Vector2.DOWN
   elseif edge == 2 then -- Right edge
      position = prism.Vector2(self.size.x - 5, love.math.random(10, self.size.y - 10))
      direction = prism.Vector2.LEFT
   elseif edge == 3 then -- Bottom edge
      position = prism.Vector2(love.math.random(10, self.size.x - 10), self.size.y - 5)
      direction = prism.Vector2.UP
   else -- Left edge
      position = prism.Vector2(5, love.math.random(10, self.size.y - 10))
      direction = prism.Vector2.RIGHT
   end

   return position, direction
end

--- Step all active agents forward
---@return boolean anyAlive True if any agents are still alive
function TunnelWorldGenerator:stepAllAgents()
   -- TODO: Implement in Phase 2
   local newAgents = {}
   local continuingAgents = {}

   for _, agent in ipairs(self.agents) do
      if agent.alive then
         local spawnedAgents, shouldContinue = agent:step(self.builder)

         if shouldContinue then
            table.insert(continuingAgents, agent)
         end

         -- Collect any newly spawned agents
         for _, newAgent in ipairs(spawnedAgents) do
            table.insert(newAgents, newAgent)
         end
      end
   end

   -- Add new agents to continuing agents
   for _, agent in ipairs(newAgents) do
      table.insert(continuingAgents, agent)
   end

   self.agents = continuingAgents

   return #self.agents > 0
end

return TunnelWorldGenerator
