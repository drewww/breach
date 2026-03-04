--- @class BehaviorState : Component
--- @field state string
local BehaviorState = prism.Component:extend("BehaviorState")
BehaviorState.name = "BehaviorState"

function BehaviorState:__new()
   self.state = "none"
end

return BehaviorState
