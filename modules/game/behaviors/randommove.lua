local RandomMoveBehavior = prism.BehaviorTree.Node:extend("RandomMoveBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function RandomMoveBehavior:run(level, actor, controller)
   local vec = prism.Vector2.neighborhood8[math.random(1, 9)]

   return prism.actions.Move(actor, actor:getPosition() + vec)
end

return RandomMoveBehavior
