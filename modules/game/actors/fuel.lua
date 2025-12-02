prism.registerActor("Fuel", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("Fuel"),
      prism.components.Drawable { index = 177, color = prism.Color4.YELLOW, background = prism.Color4.TRANSPARENT, layer = 8 },
      prism.components.Position(),
      prism.components.Gas("fuel", volume or 50)
   }
end)
