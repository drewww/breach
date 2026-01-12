---@class EnergySystem : System
local EnergySystem = prism.System:extend("EnergySystem")

function EnergySystem:onTurn(level, actor)
   if actor:has(prism.components.Energy) then
      local energy = actor:expect(prism.components.Energy)
      energy.current = math.min(energy.max, energy.current + energy.regen)
   end
end

return EnergySystem
