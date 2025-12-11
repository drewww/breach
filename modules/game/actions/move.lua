local MoveDirection = prism.Target()
    :isPrototype(prism.Vector2)

local SmoothMove = prism.Target():isType("boolean")

---@class Move : Action
---@field name string
---@field targets Target[]
---@field previousPosition Vector2
local Move = prism.Action:extend("Move")
Move.name = "move"
Move.targets = { MoveDirection, SmoothMove }

Move.requiredComponents = {
   prism.components.Mover
}

--- @param level Level
--- @param direction Vector2 The direction to move, relative to the actor's position.
function Move:canPerform(level, direction)
   local mover = self.owner:expect(prism.components.Mover)
   local destination = direction + self.owner:getPosition()
   local passable = level:getCellPassableByActor(destination.x, destination.y, self.owner, mover.mask)

   -- only allow moves into the 8way neighborhood.
   -- if we later want to limit to 4way, change this.
   local inRange = direction:distanceChebyshev(prism.Vector2(0, 0)) <= 1

   return passable and inRange
end

--- @param level Level
--- @param direction Vector2 The direction to move, relative to the actor's position.
function Move:perform(level, direction, smooth)
   local destination = direction + self.owner:getPosition()

   -- ensure we've got integers here.
   destination:compose(math.floor(destination.x + 0.5), math.floor(destination.y + 0.5))

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
      facing.dir = direction
   end

   level:moveActor(self.owner, destination)
end

--- @return Vector2 The intended direction of the move in actor-relative coordinates.
function Move:getDirection()
   return self:getTargeted(1)
end

--- @return Vector2 The intended destination of this move in world coordinates. (It may not resolve to this location if the actor is pushed or altered before the action is performed.)
function Move:getDestination()
   return self:getTargeted(1) + self.owner:getPosition()
end

return Move
