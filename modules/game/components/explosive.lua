--- @class Explosive : Component
--- @field exploding boolean
local Explosive = prism.Component:extend("Explosive")
Explosive.name = "Explosive"

function Explosive:__new()
   self.exploding = false
end

return Explosive
