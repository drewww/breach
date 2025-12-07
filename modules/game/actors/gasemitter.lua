prism.registerActor("SteamPipe", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("SteamPipe"),
      prism.components.Drawable { index = 187, color = prism.Color4.GREY, background = prism.Color4.TRANSPARENT, layer = 11 },
      prism.components.Position(),
      prism.components.Health(100)
   }
end)
