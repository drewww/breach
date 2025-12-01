--- @class DamagedState : Component
--- @field color Color4 color to change fg color to, when below hp threshold.
--- @field threshold number threshold, in 0.0-1.0 range, to change color at

local DamagedState = prism.Component:extend("DamagedState")
DamagedState.name = "DamagedState"

function DamagedState:__new(color, threshold)
   self.color = color
   self.threshold = threshold
end

return DamagedState
