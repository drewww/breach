prism.registerActor("Smoke", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("Smoke"),
      prism.components.Drawable { index = "s", color = prism.Color4.BLACK, background = prism.Color4.GREY },
      prism.components.Position(),
      -- prism.components.Opaque(),
      prism.components.WaitController(),
      prism.components.Gas(volume or 100)
   }
end)
