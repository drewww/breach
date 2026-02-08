--- @class TickSystem : System
local TickSystem = prism.System:extend("TickSystem")

function TickSystem:onTurnEnd(level, actor)
   if not actor:has(prism.components.PlayerController) then
      return
   end

   prism.logger.info("--------------TICKING--------------")
   for tickable in level:query(prism.components.ConditionHolder):iter() do
      level:tryPerform(prism.actions.Tick(tickable))
   end
end

return TickSystem
