local FollowerBotController = prism.components.Controller:extend("FollowerBotController")
FollowerBotController.name = "FollowerBotController"

function FollowerBotController:__new()
   local wait = prism.behaviors.WaitBehavior()

   self.root = prism.BehaviorTree.Root({ wait })
end

--- @param level Level
--- @param actor Actor
function FollowerBotController:act(level, actor)
   return self.root:run(level, actor, self)
end

return FollowerBotController
