local FlyDestination = prism.Target():isType("table")

---@class Fly : Action
---@field name string
---@field targets Target[]
---@field previousPosition Vector2
local Fly = prism.Action:extend("Fly")
Fly.name = "move"
Fly.targets = { FlyDestination }

Fly.requiredComponents = {
   prism.components.Controller,
   prism.components.Mover
}

--- @param level Level
--- @param destination Vector2
function Fly:canPerform(level, destination)
   local mover = self.owner:expect(prism.components.Mover)
   return true
end

--- @param level Level
--- @param steps Vector2[]
function Fly:perform(level, steps)
   -- calculate the best integer cell to land in

   for _, step in ipairs(steps) do
      if not level:getCellPassable(step.x, step.y, self.owner:expect(prism.components.Mover).mask) then
         -- if rocket is trying to move into a space it can't, die
         level:tryPerform(prism.actions.Die(self.owner))
         return
      else
         -- leave a smoke trail
         local smoke = prism.actors.Smoke(1)
         level:addActor(smoke, self.owner:getPosition():decompose())
         level:moveActor(self.owner, step)
      end
   end
end

return Fly
