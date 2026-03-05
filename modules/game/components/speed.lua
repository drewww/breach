--- @class Speed : Component
--- @field moves integer
local Speed = prism.Component:extend("Speed")
Speed.name = "Speed"

function Speed:__new(moves)
   self.moves = moves
end

return Speed
