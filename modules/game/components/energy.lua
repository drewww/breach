--- @class Energy : Component
--- @field current number
--- @field max number
--- @field regen number

local Energy = prism.Component:extend("Energy")
Energy.name = "Energy"

function Energy:__new(current, max, regen)
   self.current = current
   self.max = max
   self.regen = regen
end

return Energy
