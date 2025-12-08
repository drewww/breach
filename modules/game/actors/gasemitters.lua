prism.registerActor("SteamPipe", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("SteamPipe"),
      prism.components.Drawable { index = 187, color = prism.Color4.GREY, background = prism.Color4.TRANSPARENT, layer = 11 },
      prism.components.Position(),
      prism.components.Health(100),
      prism.components.GasEmitter({
         gas = "smoke",
         direction = 0,
         template = { prism.Vector2(1, 0), prism.Vector2(2, 0), prism.Vector2(3, 0), prism.Vector2(4, 0), prism.Vector2(5, 0) },
         volume = 0.8,
         duration = 10,
         disabled = true
      })
   }
end)


prism.registerActor("PoisonMachine", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("PoisonMachine"),
      prism.components.Drawable { index = 9, color = prism.Color4.LIME, background = prism.Color4.TRANSPARENT, layer = 11 },
      prism.components.Position(),
      prism.components.Health(30),
      prism.components.GasEmitter({
         gas = "poison",
         volume = 2,
         direction = math.random(0, 4),
         period = math.random(2, 8),
         template = { prism.Vector2(1, 1) },
      })
   }
end)

prism.registerActor("PoisonBarrel", function(volume)
   return prism.Actor.fromComponents {
      prism.components.Name("PoisonBarrel"),
      prism.components.Drawable { index = 10, color = prism.Color4.LIME, background = prism.Color4.TRANSPARENT, layer = 11 },
      prism.components.Position(),
      prism.components.Health(10)
   }
end)
