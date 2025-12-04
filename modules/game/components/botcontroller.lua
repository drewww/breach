local BotController = prism.components.Controller:extend("BotController")
BotController.name = "BotController"

function BotController:__new()
   local updateDestination = prism.behaviors.UpdateDestinationBehavior()
   local destinationMove = prism.behaviors.DestinationMoveBehavior()
   local wait = prism.behaviors.WaitBehavior()

   self.root = prism.BehaviorTree.Root({ updateDestination, destinationMove, wait })
end

--- @param level Level
--- @param actor Actor
function BotController:act(level, actor)
   return self.root:run(level, actor, self)
end

return BotController
