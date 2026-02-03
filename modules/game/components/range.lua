--- @class RangeOptions
--- @field max integer
--- @field min integer
--- @field miss_odds number Probability of missing (0-1)
--- @field min_miss number Minimum angle to miss by, in radians
--- @field max_miss number Maximum angle to miss by, in radians

--- @class Range : Component
--- @field max integer
--- @field min integer
--- @field miss_odds number Probability of missing (0-1)
--- @field min_miss number Minimum angle to miss by, in radians
--- @field max_miss number Maximum angle to miss by, in radians
local Range = prism.Component:extend("Range")
Range.name = "Range"

---@param options RangeOptions
function Range:__new(options)
   self.max = options.max or 0
   self.min = options.min or 0
   self.miss_odds = options.miss_odds or 0
   self.min_miss = options.min_miss or math.pi / 8
   self.max_miss = options.max_miss or math.pi / 4
end

return Range
