--- @class RangeOptions
--- @field max integer
--- @field min integer

--- @class Range : Component
--- @field max integer
--- @field min integer
local Range = prism.Component:extend("Range")
Range.name = "Range"

---@param options RangeOptions
function Range:__new(options)
   self.max = options.max or 0
   self.min = options.min or 0
end

return Range
