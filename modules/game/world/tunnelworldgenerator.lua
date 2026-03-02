local TunnelWorldGenerator = prism.Object:extend("TunnelWorldGenerator")


function TunnelWorldGenerator:__new()
   prism.logger.info("Building a tunnel level.")

   self.builder = prism.LevelBuilder()
end

function TunnelWorldGenerator:generate()
   self.builder:rectangle("line", 0, 0, 32, 32, prism.cells.Wall)
   -- Fill the interior with floor tiles
   self.builder:rectangle("fill", 1, 1, 31, 31, prism.cells.Floor)
   -- Add a small block of walls within the map
   self.builder:rectangle("fill", 5, 5, 7, 7, prism.cells.Wall)
   -- Add a pit area to the southeast
   self.builder:rectangle("fill", 20, 20, 25, 25, prism.cells.Pit)

   return self.builder
end

return TunnelWorldGenerator
