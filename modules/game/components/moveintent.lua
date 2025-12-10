--- @class MoveIntent : Component
--- @field moves Vector2[] The moves the actor intends to make next turn.
local MoveIntent = prism.Component:extend("MoveIntent")
MoveIntent.name = "MoveIntent"

function MoveIntent:__new(moves)
   self.moves = moves
end

return MoveIntent
