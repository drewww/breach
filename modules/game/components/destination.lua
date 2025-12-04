--- @class Destination : Component
--- @field pos Vector2 current destination

local Destination = prism.Component:extend("Destination")
Destination.name = "Destination"

function Destination:__new(pos)
   self.pos = pos
end

return Destination
