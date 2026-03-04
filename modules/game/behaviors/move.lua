--- @class MoveBehavior : BehaviorTree.Node
local MoveBehavior = prism.BehaviorTree.Node:extend("MoveBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function MoveBehavior:run(level, actor, controller)
   -- pick the

   local destination = actor:get(prism.components.Destination)

   if not destination then return false end

   prism.logger.info("entering MOVE destination: ", destination.pos, destination.path, destination.age)

   if not destination.path then
      prism.logger.info("missing path to destination")
      return false
   end

   local nextStep = destination.path:pop()

   if not nextStep then
      prism.logger.info("no next step on path, returning, deleting destination.")
      level:perform(prism.actions.ClearDestination(actor))
      return false
   end

   local direction = (nextStep - actor:getPosition())

   prism.logger.info("Moving, next step on path: ", nextStep, direction)

   direction = prism.Vector2(
      direction.x == 0 and 0 or (direction.x > 0 and 1 or -1),
      direction.y == 0 and 0 or (direction.y > 0 and 1 or -1)
   )

   local action = prism.actions.Move(actor, direction, false)
   local s, e = level:canPerform(action)

   if s then
      return action
   else
      -- trigger a repathing.
      prism.logger.info("REPATH")
      level:perform(prism.actions.ClearDestination(actor))
      level:perform(prism.actions.SetDestination(actor, destination.pos, destination.hunt))

      return false
   end
end

return MoveBehavior
