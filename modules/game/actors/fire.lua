prism.registerActor("Fire", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("Fire"),
      prism.components.Drawable { index = 22, color = prism.Color4.ORANGE, background = prism.Color4.RED, layer = 11 },
      prism.components.Position(),
      prism.components.Gas("fire", volume or 50)
   }
end)
