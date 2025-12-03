local WaitBehavior = prism.BehaviorTree.Node:extend("WaitBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function WaitBehavior:run(level, actor, controller)
   return prism.actions.Wait(actor)
end

return WaitBehavior
