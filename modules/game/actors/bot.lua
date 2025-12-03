prism.registerActor("Bot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Bot"),
      prism.components.Drawable { index = "b", color = prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.BotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" }
   }
end)
