prism.registerActor("Rocket", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Rocket"),
      prism.components.Drawable { index = 17, color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 50 },
      prism.components.RocketController(),
      prism.components.Facing(),
      prism.components.Mover { "fly" },
      prism.components.Explosive(),
      prism.components.Senses(),
      prism.components.Sight { range = 1, fov = true }
   }
end)
