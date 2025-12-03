local BotController = prism.components.Controller:extend("BotController")
BotController.name = "BotController"

function BotController:__new()
   local randomMove = prism.behaviors.RandomMoveBehavior()
   local wait = prism.behaviors.WaitBehavior()

   self.root = prism.BehaviorTree.Root({ randomMove, wait })
end

--- @param level Level
--- @param actor Actor
function BotController:act(level, actor)
   return self.root:run(level, actor, self)
end

return BotController
