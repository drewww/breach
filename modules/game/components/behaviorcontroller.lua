--- @class BehaviorController : Controller, IIntentful
--- @field root BehaviorTree.Root
--- @field intent Action
local BehaviorController = prism.components.Controller:extend("BehaviorController")
BehaviorController.name = "BehaviorController"

---@param root BehaviorTree.Root
function BehaviorController:__new(root)
   self.root = root
end

--- @param level Level
--- @param actor Actor
function BehaviorController:act(level, actor)
   local action = self.root:run(level, actor, self)
   prism.logger.info("acting, BT returned: ", action, action or action:getName())
   return self.root:run(level, actor, self)
end

return BehaviorController
