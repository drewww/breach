local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"

--- @class MapState: PlayState
--- @overload fun(display: Display, overlayDisplay, display) : MapState
local MapState = spectrum.gamestates.LevelState:extend("MapState")


function MapState:__new(display, overlayDisplay)
   local world = TunnelWorldGenerator()

   local builder = world:generate()

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   builder:addActor(player, 9, 9)

   spectrum.gamestates.LevelState.__new(self, builder:build(prism.cells.Wall), display)
end

--- Override draw to use simple level rendering without senses/FOV
function MapState:draw()
   self.display:clear()
   self.display:putLevel(self.level)
   self.display:draw()
end

return MapState
