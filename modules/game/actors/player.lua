prism.registerActor("Player", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Player"),
      prism.components.Drawable { index = "@", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.PlayerController(),
      prism.components.Senses(),
      prism.components.Sight { range = 64, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Dasher { "walk" },
      prism.components.Health(100),
      prism.components.TriggersExplosives()
   }
end)
