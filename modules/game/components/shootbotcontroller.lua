--- @class ShootBotController : Controller, IIntentful
--- @field intent Action

ShootBotController = prism.components.Controller:extend("ShootBotController")
ShootBotController.name = "ShootBotController"

function ShootBotController:__new()
   local shoot = prism.behaviors.ShootBehavior()
   local wait = prism.behaviors.WaitBehavior()
   local reload = prism.behaviors.ReloadBehavior()

   -- TODO eventually we want to be thoughtful about reload using conditional nodes that check ammo levels and ammo availability before reloading.

   self.root = prism.BehaviorTree.Root({ reload, shoot, wait })
end

--- @param level Level
--- @param actor Actor
function ShootBotController:act(level, actor)
   local action

   if self.intent then
      action = self.intent
   end

   self.intent = self.root:run(level, actor, self)

   prism.logger.info("shoot setting intent: ", self.intent:getName())

   if action then
      prism.logger.info(" firing action: ", action:getName())
   else
      prism.logger.info(" no action to fire, waiting")
   end

   return action or prism.actions.Wait(actor)
end

return ShootBotController
