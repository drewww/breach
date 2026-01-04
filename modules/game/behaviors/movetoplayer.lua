--- @class MoveToPlayer : BehaviorTree.Node
local MoveToPlayer = prism.BehaviorTree.Node:extend("MoveToPlayer")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function MoveToPlayer:run(level, actor, controller)
   prism.logger.info("RUN MOVE TO PLAYER")

   local player = level:query(prism.components.Player):first()
   assert(player)

   local mover = actor:expect(prism.components.Mover)

   local path = level:findPath(actor:getPosition(), player:getPosition(), actor, mover.mask, 1)

   prism.logger.info("path: ", path, " from ", actor:getPosition(), " to: ", player:getPosition())

   if not path then
      return false
   end

   local nextStep = path:pop()

   local direction = (nextStep - actor:getPosition())

   direction = prism.Vector2(
      direction.x == 0 and 0 or (direction.x > 0 and 1 or -1),
      direction.y == 0 and 0 or (direction.y > 0 and 1 or -1)
   )

   local action = prism.actions.Move(actor, direction, false)
   local s, e = level:canPerform(action)

   if s then
      return action
   else
      return false
   end
end

return MoveToPlayer
