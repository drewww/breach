local Tunneler = require "modules.game.world.tunneler"

local TunnelWorldGenerator = prism.Object:extend("TunnelWorldGenerator")


function TunnelWorldGenerator:__new()
   prism.logger.info("Building a tunnel level.")

   self.size = prism.Vector2(100, 100)

   self.builder = prism.LevelBuilder()

   self.agents = {}
   table.insert(self.agents, Tunneler(prism.Vector2(1, 50), prism.Vector2.RIGHT))
end

function TunnelWorldGenerator:generate()
   self.builder:rectangle("fill", 0, 0, self.size.x, self.size.y, prism.cells.Wall)


   while #self.agents > 0 do
      local continuingAgents = {}
      for _, agent in ipairs(self.agents) do
         local children = agent:step(self.builder)

         if self:continueAgent(agent) then
            table.insert(continuingAgents, agent)
         end

         for _, child in ipairs(children) do
            if self:continueAgent(child) then
               table.insert(continuingAgents, child)
            end
         end
      end
      self.agents = continuingAgents

      -- Yield after each generation step to allow stepping through
      coroutine.yield()
   end

   return self.builder
end

---@return boolean
function TunnelWorldGenerator:continueAgent(agent)
   return agent.position.x > 0 and agent.position.x < self.size.x and agent.position.y > 0 and
       agent.position.y < self.size.y
end

return TunnelWorldGenerator
