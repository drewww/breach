--- @class Cooldown : Component
--- @field turns integer
local Cooldown = prism.Component:extend("Cooldown")
Cooldown.name = "Cooldown"

function Cooldown:__new(turns, name)
   self.name = name
   self.turns = turns
end

return Cooldown
