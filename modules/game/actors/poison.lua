prism.registerActor("Poison", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("Poison"),
      prism.components.Drawable { index = 177, color = prism.Color4.WHITE, background = prism.Color4.LIME },
      prism.components.Position(),
      prism.components.WaitController(),
      prism.components.Gas("poison", volume or 50)
   }
end)
