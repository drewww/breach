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

      if destination.pos == actor:getPosition() then
         actor:remove(prism.components.Destination)

         return false
      end

      local path = level:findPath(actor:getPosition(), destination.pos, actor, mover.mask)

      prism.logger.info("Moving to destination: ", destination.pos)


      if not path then return false end


      local nextStep = path:pop()

      prism.logger.info("next step: ", nextStep)
      local action = prism.actions.Move(actor, nextStep)

      if level:canPerform(action) then
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
