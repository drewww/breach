local BotController = prism.components.Controller:extend("BotController")
BotController.name = "BotController"

function BotController:__new()
   self.behavior = prism.BehaviorTree.Root({ prism.BehaviorTree.Node(function(self, level, actor, controller)
      prism.logger.info("in wait node")
      return prism.actions.Wait(actor)
   end)
   })
end

--- @param level Level
--- @param actor Actor
function BotController:act(level, actor)
   -- does not work
   local behaviorResult = self.behavior:run(level, actor, self)
   prism.logger.info("bot controller behavior result: ", behaviorResult, prism.actions.Wait:is(behaviorResult))

   return behaviorResult

   -- works fine
   -- return prism.actions.Wait(actor)
end

return BotController
