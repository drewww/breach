--- @class MoveToWaypoint : BehaviorTree.Node
local MoveToWaypoint = prism.BehaviorTree.Node:extend("MoveToWaypoint")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function MoveToWaypoint:run(level, actor, controller)
   if not controller.blackboard.waypoint or not controller.blackboard.path then
      return false
   end

   local path = controller.blackboard.path

   local nextStep = path:pop()

   if nextStep then
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
         -- if we fail the move, clear the waypoint and repath.
         controller.blackboard.path = nil
         return false
      end
   else
      controller.blackboard.waypoint = nil
      controller.blackboard.path = nil

      return false
   end
end

return MoveToWaypoint
