--- @class Player : Component
--- @field consumeHoldProgress integer
--- @field level integer
local Player = prism.Component:extend("Player")
Player.name = "Player"

function Player:__new()
   self.consumeHoldProgress = 0
   self.level = 1
end

return Player
