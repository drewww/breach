--- @class Expiring : Component
--- @field turns number
local Expiring = prism.Component:extend("Expiring")
Expiring.name = "Expiring"

function Expiring:__new(turns)
   self.turns = turns
end

return Expiring
