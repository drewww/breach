--- @class Tick : Action
local Tick = prism.Action:extend("Tick")

function Tick:canPerform(level)
   return self.owner:has(prism.components.ConditionHolder)
end

function Tick:perform(level)
   local holder = self.owner:expect(prism.components.ConditionHolder)

   holder:each(function(condition)
      if prism.conditions.TickedCondition:is(condition) then
         --- @cast condition TickedCondition
         condition.duration = condition.duration - 1

         prism.logger.info("Ticked condition to: ", condition.duration)
      end
   end)

   holder:removeIf(function(condition)
      if prism.conditions.TickedCondition:is(condition) then
         ---@cast condition TickedCondition
         prism.logger.info("Checking for removal: ", condition.duration)
         return condition.duration <= 0
      end

      return false
   end)
end

return Tick
