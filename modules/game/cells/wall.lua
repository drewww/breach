prism.registerCell("Wall", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Wall"),
      prism.components.Drawable { index = TILES.WALL_5 },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Scorchable(),
      prism.components.Impermeable()
   }
end)

prism.registerCell("HalfWall", function()
   return prism.Cell.fromComponents {
      prism.components.Name("HalfWall"),
      prism.components.Drawable { index = TILES.WALL_4 },
      prism.components.Collider(),
      prism.components.Scorchable()
   }
end)
