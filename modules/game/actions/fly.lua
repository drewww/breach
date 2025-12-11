local FlyDirection = prism.Target():isType("table")

---@class Fly : Action
---@field name string
---@field targets Target[]
---@field previousPosition Vector2
local Fly = prism.Action:extend("Fly")
Fly.name = "move"
Fly.targets = { FlyDirection }

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

   local adjustedSteps = {}
   for i, step in ipairs(steps) do
      table.insert(adjustedSteps, step + self.owner:getPosition())
   end

   for i, step in ipairs(adjustedSteps) do
      if not level:getCellPassable(step.x, step.y, self.owner:expect(prism.components.Mover).mask) then
         -- if rocket is trying to move into a space it can't, die
         level:tryPerform(prism.actions.Die(self.owner))
         return
      else
         -- leave a smoke trail
         local smoke = prism.actors.Smoke(0.5)
         level:addActor(smoke, self.owner:getPosition():decompose())

         -- animate the newly ejected smoke.
         level:yield(prism.messages.AnimationMessage({
            animation = spectrum.animations.Explosion(self.owner:getPosition(), 0.4 * i, 1, prism.Color4.DARKGREY),
            actor = smoke,
            blocking = false,
            skippable = false
         }))

         level:moveActor(self.owner, step)
      end
   end
end

--- @return Vector2[] The intended direction of the move in actor-relative coordinates.
function Fly:getDirections()
   return self:getTargeted(1)
end

--- @return Vector2 The intended destination of this move in world coordinates. (It may not resolve to this location if the actor is pushed or altered before the action is performed.)
function Fly:getDestinations()
   local destinations = {}

   for _, pos in ipairs(self:getTargeted(1)) do
      table.insert(destinations, pos + self.owner:getPosition())
   end

   return destinations
end

return Fly
