prism.registerCell("Floor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Floor"),
      prism.components.Drawable { index = ".", color = prism.Color4.WHITE },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.Scorchable()
   }
end)
