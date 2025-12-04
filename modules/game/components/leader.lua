--- @class Leader : Component
--- @field mask Bitmask
local Leader = prism.Component:extend("Leader")
Leader.name = "Leader"

function Leader:__new()
   self.followerPositions = { prism.Vector2(-2, 0) }
end

return Leader
