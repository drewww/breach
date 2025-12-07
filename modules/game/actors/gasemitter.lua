prism.registerActor("GasEmitter", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("GasEmitter"),
      prism.components.Drawable { index = "g", color = prism.Color4.ORANGE, background = prism.Color4.TRANSPARENT, layer = 11 },
      prism.components.Position(),
      prism.components.GasEmitter("poison", 0, { prism.Vector2(1, 0) }, 20)
   }
end)
