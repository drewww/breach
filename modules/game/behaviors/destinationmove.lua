local DestinationMoveBehavior = prism.BehaviorTree.Node:extend("DestinationMoveBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function DestinationMoveBehavior:run(level, actor, controller)
   if actor:has(prism.components.Destination) then
      -- compute a path to the destination
      local destination = actor:expect(prism.components.Destination)
      local mover = actor:expect(prism.components.Mover)

      local path = level:findPath(actor:getPosition(), destination.pos, actor, mover.mask, 1)

      if not path then
         actor:remove(prism.components.Destination)
         return false
      end

      local nextStep = path:pop()

      local action = prism.actions.Move(actor, nextStep)

      if level:canPerform(action) then
         if nextStep == destination.pos then
            actor:remove(prism.components.Destination)
         end
         return action
      else
         return false
      end
   else
      prism.logger.info("No destination found.")
      return false
   end
end

return DestinationMoveBehavior
