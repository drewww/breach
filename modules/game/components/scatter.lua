--- @class Scatter : Component
--- @field max_range number
--- @field min_range number

local Scatter = prism.Component:extend("Scatter")
Scatter.name = "Scatter"

function Scatter:__new(min_range, max_range)
   self.min_range = min_range or 0
   self.max_range = max_range or 1
end

return Scatter
