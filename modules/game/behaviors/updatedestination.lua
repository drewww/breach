local UpdateDestinationBehavior = prism.BehaviorTree.Node:extend("UpdateDestinationBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function UpdateDestinationBehavior:run(level, actor, controller)
   if not actor:has(prism.components.Destination) then
      -- TODO make sure the destination is pathable
      local x, y = level.RNG:random(1, level.map.w), level.RNG:random(1, level.map.h)
      actor:give(prism.components.Destination(prism.Vector2(x, y)))
      return true
   end
   return false
end

return UpdateDestinationBehavior
