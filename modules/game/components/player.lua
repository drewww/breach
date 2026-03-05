--- @class Player : Component
local Player = prism.Component:extend("Player")
Player.name = "Player"

function Player:__new()
   self.consumeHoldProgress = 0
end

return Player
