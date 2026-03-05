--- @class Explosive : Component
--- @field exploding boolean
--- @field radius number
--- @field damage number
local Explosive = prism.Component:extend("Explosive")
Explosive.name = "Explosive"

function Explosive:__new(radius, damage)
   self.exploding = false
   self.radius = radius or 2
   self.damage = damage or 3
end

return Explosive
