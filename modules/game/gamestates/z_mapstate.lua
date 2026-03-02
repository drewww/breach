--- @class MapState: PlayState
--- @overload fun(display: Display, overlayDisplay, display) : MapState
local MapState = spectrum.gamestates.PlayState:extend("MapState")


function MapState:__new(display, overlayDisplay)
   local builder = prism.LevelBuilder()
   builder:rectangle("line", 0, 0, 32, 32, prism.cells.Wall)
   -- Fill the interior with floor tiles
   builder:rectangle("fill", 1, 1, 31, 31, prism.cells.Floor)
   -- Add a small block of walls within the map
   builder:rectangle("fill", 5, 5, 7, 7, prism.cells.Wall)
   -- Add a pit area to the southeast
   builder:rectangle("fill", 20, 20, 25, 25, prism.cells.Pit)

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   builder:addActor(player, 9, 9)

   spectrum.gamestates.PlayState.__new(self, display, overlayDisplay, builder)
end

return MapState
