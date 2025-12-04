prism.registerActor("RandomWaypointBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("RandomWaypointBot"),
      prism.components.Drawable { index = "b", color = prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.BotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" }
   }
end)

prism.registerActor("LeaderBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("LeaderBot"),
      prism.components.Drawable { index = "L", color = prism.Color4.PURPLE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Facing(),
      prism.components.Collider(),
      prism.components.LeaderBotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Leader()
   }
end)
