prism.registerActor("RandomWaypointBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("RandomWaypointBot"),
      prism.components.Drawable { index = "b", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.BotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.TriggersExplosives()

   }
end)

prism.registerActor("LeaderBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("LeaderBot"),
      prism.components.Drawable { index = "L", color = prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Facing(),
      prism.components.Collider(),
      prism.components.LeaderBotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(10),
      prism.components.Leader(),
      prism.components.TriggersExplosives()

   }
end)

prism.registerActor("FollowerBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("FollowerBot"),
      prism.components.Drawable { index = "f", color = prism.Color4.ORANGE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.FollowerBotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(5),
      prism.components.TriggersExplosives()
   }
end)
