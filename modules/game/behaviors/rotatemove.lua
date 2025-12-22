--- @class RotateMove : BehaviorTree.Node
local RotateMove = prism.BehaviorTree.Node:extend("RotateMove")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function RotateMove:run(level, actor, controller)
   -- return a move in the facing direction, unless you see a collideable object in that space. if you do, return a move that is CW 90degrees of that.

   local facing = actor:get(prism.components.Facing)

   if not facing then
      prism.logger.warn("No facing found on Actor, cannot use this behavior.")
      return false
   end

   local next = (actor:getPosition() + facing.dir):round()

   local mask = actor:expect(prism.components.Mover).mask

   if level:inBounds(next:decompose()) and level:getCellPassableByActor(next.x, next.y, actor, mask) then
      -- if the next space is passable, set intent to move there.
      local destination = (next - actor:getPosition())
      local action = prism.actions.Move(actor, destination, false)
      local s, e = level:canPerform(action)
      return action
   else
      local action = prism.actions.Rotate(actor, math.pi / 2)
      local s, e = level:canPerform(action)
      prism.logger.info(s, e)
      return action
   end

   return false
end

return RotateMove
