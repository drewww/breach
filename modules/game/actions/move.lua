local MoveTarget = prism.Target()
    :isPrototype(prism.Vector2)
    :range(1)
local SmoothMove = prism.Target():isType("boolean")

---@class Move : Action
---@field name string
---@field targets Target[]
---@field previousPosition Vector2
local Move = prism.Action:extend("Move")
Move.name = "move"
Move.targets = { MoveTarget, SmoothMove }

Move.requiredComponents = {
   prism.components.Mover
}

--- @param level Level
--- @param destination Vector2
function Move:canPerform(level, destination)
   local mover = self.owner:expect(prism.components.Mover)
   return level:getCellPassableByActor(destination.x, destination.y, self.owner, mover.mask)
end

--- @param level Level
--- @param destination Vector2
function Move:perform(level, destination, smooth)
   local duration = 0.3
   local blocking = true
   if self.owner:has(prism.components.PlayerController) then
      duration = 0.1
      blocking = false
   end

   level:yield(prism.messages.AnimationMessage {
      animation = spectrum.animations.Move(level, self.owner, destination, duration, smooth),
      actor = self.owner,
      blocking = blocking,
      skippable = false,
      override = true
   })

   -- there's risk that for longer distance moves this may not normalize to neighborhood8
   if self.owner:has(prism.components.Facing) then
      local facing = self.owner:expect(prism.components.Facing)
      facing.dir = (destination - self.owner:getPosition())
   end

   level:moveActor(self.owner, destination)
end

return Move
