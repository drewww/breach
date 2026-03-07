--- @class MoveBehavior : BehaviorTree.Node
local MoveBehavior = prism.BehaviorTree.Node:extend("MoveBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function MoveBehavior:run(level, actor, controller)
   local destination = actor:get(prism.components.Destination)

   if not destination then return false end

   prism.logger.info("entering MOVE destination: ", destination.pos, destination.path, destination.age)

   if not destination.path then
      prism.logger.info("missing path to destination")
      return false
   end

   -- Get the speed (number of moves per turn)
   -- only use fast speed when hunting
   local speed = 1
   local state = actor:get(prism.components.BehaviorState)
   if actor:has(prism.components.Speed) and state and state.state == "HUNTING" then
      speed = actor:expect(prism.components.Speed).moves
   end

   -- Collect multiple directions based on speed
   local directions = {}
   local currentPos = actor:getPosition()

   for i = 1, speed do
      local nextStep = destination.path:pop()

      if not nextStep then
         prism.logger.info("path exhausted after ", i - 1, " moves")
         -- If we got no moves at all, clear destination
         if i == 1 then
            prism.logger.info("no next step on path, returning, deleting destination.")
            level:perform(prism.actions.ClearDestination(actor))
            return false
         end
         -- Otherwise, break and use what we have
         break
      end

      local direction = (nextStep - currentPos)

      prism.logger.info("Move step ", i, ": next step on path: ", nextStep, " direction: ", direction)

      -- Normalize direction to unit vector
      direction = prism.Vector2(
         direction.x == 0 and 0 or (direction.x > 0 and 1 or -1),
         direction.y == 0 and 0 or (direction.y > 0 and 1 or -1)
      )

      table.insert(directions, direction)
      currentPos = currentPos + direction
   end

   -- If we didn't collect any valid directions, fail
   if #directions == 0 then
      prism.logger.info("no valid directions collected")
      return false
   end

   -- Create the move action with all collected directions
   local action = prism.actions.Move(actor, directions, false)
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
