--- @class BehaviorController : Controller, IIntentful
--- @field root BehaviorTree.Root
--- @field intent Action
local BehaviorController = prism.components.Controller:extend("BehaviorController")
BehaviorController.name = "BehaviorController"

---@param root BehaviorTree.Root
function BehaviorController:__new(root)
   self.root = root

   self.blackboard = {}
   self.blackboard.priorActionPerformed = true
end

--- @param level Level
--- @param actor Actor
function BehaviorController:act(level, actor)
   return self.root:run(level, actor, self)
end

return BehaviorController
