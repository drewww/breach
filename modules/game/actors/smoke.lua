prism.registerActor("Smoke", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("Smoke"),
      prism.components.Drawable { index = 178, color = prism.Color4.BLACK, background = prism.Color4.GREY },
      prism.components.Position(),
      prism.components.WaitController(),
      prism.components.Gas("smoke", volume or 100)
   }
end)
