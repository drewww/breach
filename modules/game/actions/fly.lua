local FlyDestination = prism.Target()
    :isPrototype(prism.Vector2)

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

   -- TODO check the intervening spaces for something that causes explosion or collision

   level:moveActor(self.owner, steps)
end

return Fly
