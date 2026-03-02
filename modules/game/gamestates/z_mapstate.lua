local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"

--- @class MapState: PlayState
--- @overload fun(display: Display, overlayDisplay, display) : MapState
local MapState = spectrum.gamestates.PlayState:extend("MapState")


function MapState:__new(display, overlayDisplay)
   local world = TunnelWorldGenerator()

   local builder = world:generate()

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   builder:addActor(player, 9, 9)

   spectrum.gamestates.PlayState.__new(self, display, overlayDisplay, builder)
end

return MapState
