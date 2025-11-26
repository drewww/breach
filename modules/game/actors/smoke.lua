prism.registerActor("Smoke", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Smoke"),
      prism.components.Drawable { index = "s", color = prism.Color4.BLACK, background = prism.Color4.GREY },
      prism.components.Position(),
      prism.components.Opaque(),
      prism.components.Expiring(10),
      prism.components.WaitController(),
      prism.components.Gas(10)
   }
end)
