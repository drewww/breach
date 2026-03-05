local MoveDirection = prism.Target()
    :isType("table")

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
--- @param directions Vector2|Vector2[] The direction(s) to move, relative to the actor's position.
function Move:canPerform(level, directions)
   -- Handle both single direction and array of directions
   local directionList = {}
   if type(directions) == "table" and directions.x == nil then
      -- It's an array of directions
      directionList = directions
   else
      -- It's a single Vector2
      directionList = { directions }
   end

   if #directionList == 0 then
      return false
   end

   local mover = self.owner:expect(prism.components.Mover)
   local currentPos = self.owner:getPosition()

   -- Check each step in the sequence
   for i, direction in ipairs(directionList) do
      local destination = direction + currentPos

      -- only allow moves into the 8way neighborhood.
      -- if we later want to limit to 4way, change this.
      local inRange = direction:distanceChebyshev(prism.Vector2(0, 0)) <= 1

      if not inRange then
         return false
      end

      local passable = level:getCellPassableByActor(destination.x, destination.y, self.owner, mover.mask)

      if not passable then
         return false
      end

      -- Update current position for next iteration
      currentPos = destination
   end

   return true
end

--- @param level Level
--- @param directions Vector2|Vector2[] The direction(s) to move, relative to the actor's position.
function Move:perform(level, directions, smooth)
   -- Handle both single direction and array of directions
   local directionList = {}
   if type(directions) == "table" and directions.x == nil then
      -- It's an array of directions
      directionList = directions
   else
      -- It's a single Vector2
      directionList = { directions }
   end

   local currentPos = self.owner:getPosition()
   local finalDirection = nil

   -- Perform each move step
   for i, direction in ipairs(directionList) do
      local destination = direction + currentPos

      -- ensure we've got integers here.
      destination:compose(math.floor(destination.x + 0.5), math.floor(destination.y + 0.5))

      -- Animation handling (commented out, but kept for reference)
      -- local duration = 0.3
      -- local blocking = true
      -- if self.owner:has(prism.components.PlayerController) then
      --    duration = 0.1
      --    blocking = false
      -- end

      -- level:yield(prism.messages.AnimationMessage {
      --    animation = spectrum.animations.Move(level, self.owner, destination, duration, smooth),
      --    actor = self.owner,
      --    blocking = blocking,
      --    skippable = false,
      --    override = true
      -- })

      level:moveActor(self.owner, destination)
      currentPos = destination
      finalDirection = direction
   end

   -- Update facing based on the final direction
   if finalDirection and self.owner:has(prism.components.Facing) then
      local facing = self.owner:expect(prism.components.Facing)
      facing.dir = finalDirection
   end
end

--- @return Vector2|Vector2[] The intended direction(s) of the move in actor-relative coordinates.
function Move:getDirection()
   return self:getTargeted(1)
end

--- @return Vector2 The intended final destination of this move in world coordinates. (It may not resolve to this location if the actor is pushed or altered before the action is performed.)
function Move:getDestination()
   local directions = self:getTargeted(1)

   -- Handle both single direction and array of directions
   if type(directions) == "table" and directions.x == nil then
      -- It's an array - calculate cumulative destination
      local finalPos = self.owner:getPosition()
      for _, dir in ipairs(directions) do
         finalPos = finalPos + dir
      end
      return finalPos
   else
      -- It's a single Vector2
      return directions + self.owner:getPosition()
   end
end

function Move:getDestinations()
   local destinations = {}
   local cur = self.owner:getPosition()
   for _, pos in ipairs(self:getTargeted(1)) do
      table.insert(destinations, pos + cur)
      cur = pos + cur
   end

   return destinations
end

return Move
