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
--- @return Action
function BehaviorController:act(level, actor)
   local holder = prism.components.ConditionHolder
   if holder then
      local stunned = prism.components.ConditionHolder.getActorModifiers(actor, prism.modifiers.StunnedModifier)

      if #stunned > 0 then
         return prism.actions.Wait(actor)
      end
   end

   return self.root:run(level, actor, self)
end

return BehaviorController
