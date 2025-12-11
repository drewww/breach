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
      local mover       = actor:expect(prism.components.Mover)

      local intendedPos = actor:getPosition()

      prism.logger.info("Destination: ", destination.pos)
      -- if we are planning a move in our intent, plot our course assuming
      -- we have completed that move already.
      ---@cast controller Controller
      ---@cast controller +IIntentful
      if controller.intent and prism.actions.Move:is(controller.intent) then
         intendedPos = controller.intent:getTargeted(1) + actor:getPosition()
      end

      -- TODO something is busted here, we're not pathing around obstacles correctly
      local path = level:findPath(intendedPos, destination.pos, actor, mover.mask, 2)

      if not path then
         actor:remove(prism.components.Destination)
         return false
      end

      local nextStep = path:pop()

      local direction = (nextStep - intendedPos)
      prism.logger.info("destination: ", nextStep, actor:getPosition(), direction)
      -- Normalize to Chebyshev distance of 1 (clamp components to [-1, 1])
      direction = prism.Vector2(
         direction.x == 0 and 0 or (direction.x > 0 and 1 or -1),
         direction.y == 0 and 0 or (direction.y > 0 and 1 or -1)
      )
      local action = prism.actions.Move(actor, direction, false)
      local s, e = level:canPerform(action)
      prism.logger.info("destinationmove: ", s, e, direction)
      if s then
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
