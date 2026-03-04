--- @class Destination : Component
--- @field pos? Vector2 current destination
--- @field path? Path precomputed path to destination, saving us repathing calls
--- @field age integer
--- @field hunt boolean true if we set this destination as a player location

local Destination = prism.Component:extend("Destination")
Destination.name = "Destination"

function Destination:__new(pos)
   self.pos = pos
   self.path = nil
   self.age = 0
end

return Destination
