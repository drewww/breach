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

prism.registerCell("Table", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Table"),
      prism.components.Drawable { index = TILES.WALL_4 },
      prism.components.Collider(),
      prism.components.Scorchable()
   }
end)

prism.registerCell("Desk", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Desk"),
      prism.components.Drawable { index = TILES.WALL_4 },
      prism.components.Collider(),
      prism.components.Scorchable()
   }
end)

prism.registerCell("Computer", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Computer"),
      prism.components.Drawable { index = TILES.WALL_4 },
      prism.components.Collider(),
      prism.components.Scorchable()
   }
end)

prism.registerCell("Plant", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Plant"),
      prism.components.Drawable { index = TILES.PLANT_1 },
      prism.components.Collider(),
      prism.components.Scorchable()
   }
end)

prism.registerCell("Server", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Server"),
      prism.components.Drawable { index = TILES.SERVER_1 },
      prism.components.Collider(),
      prism.components.Scorchable()
   }
end)

prism.registerCell("Machine", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Machine"),
      prism.components.Drawable { index = TILES.MACHINE_L },
      prism.components.Collider(),
      prism.components.Scorchable()
   }
end)
