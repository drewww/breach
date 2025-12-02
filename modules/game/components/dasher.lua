--- @class Dasher : Component
--- @field mask Bitmask
local Dasher = prism.Component:extend("Dasher")
Dasher.name = "Mover"

--- @param movetypes string[]
function Dasher:__new(movetypes)
   self.mask = prism.Collision.createBitmaskFromMovetypes(movetypes)
end

return Dasher
