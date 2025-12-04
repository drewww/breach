local LeaderBotController = prism.components.Controller:extend("LeaderBotController")
LeaderBotController.name = "LeaderBotController"

function LeaderBotController:__new()
   local updateDestination = prism.behaviors.UpdateDestinationBehavior()
   local destinationMove = prism.behaviors.DestinationMoveBehavior()
   local wait = prism.behaviors.WaitBehavior()

   self.root = prism.BehaviorTree.Root({ updateDestination, destinationMove, wait })
end

--- @param level Level
--- @param actor Actor
function LeaderBotController:act(level, actor)
   return self.root:run(level, actor, self)
end

return LeaderBotController
