--- @class Facing : Component
--- @field dir Vector2
local Facing = prism.Component:extend("Facing")
Facing.name = "Facing"

function Facing:__new()
   self.dir = prism.Vector2(1, 0)
end

return Facing
