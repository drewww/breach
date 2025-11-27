prism.registerActor("Fire", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("Fire"),
      prism.components.Drawable { index = 22, color = prism.Color4.ORANGE, background = prism.Color4.RED },
      prism.components.Position(),
      prism.components.WaitController(),
      prism.components.Gas("fire", volume or 50)
   }
end)
