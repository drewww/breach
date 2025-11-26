--- @class ExpiringSystem : System
local ExpiringSystem = prism.System:extend("ExpiringSystem")

function ExpiringSystem:onTurn(level, actor)
   -- if the actor has an expiring component...
   if actor:has(prism.components.Expiring) then
      --- @type Expiring
      local expiringC = actor:get(prism.components.Expiring)

      expiringC.turns = expiringC.turns - 1

      if expiringC.turns <= 0 then
         level:removeActor(actor)
      end
   end
end

return ExpiringSystem
