prism.registerCell("Wall", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Wall"),
      prism.components.Drawable { index = "#" },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Health(200),
      prism.components.DamagedState(prism.Color4.DARKGREY, 0.999)
   }
end)
