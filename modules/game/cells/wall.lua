prism.registerCell("Wall", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Wall"),
      prism.components.Drawable { index = "#" },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Scorchable(),
      prism.components.Impermeable()
   }
end)
