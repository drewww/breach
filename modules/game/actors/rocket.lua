prism.registerActor("Rocket", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Rocket"),
      prism.components.Drawable { index = 5, color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 50 },
      prism.components.RocketController(),
      prism.components.Facing({ 17, 32, 18, 31 }),
      prism.components.Mover { "fly" },
      prism.components.Collider { mask = prism.Collision.createBitmaskFromMovetypes({ "fly" }) },
      prism.components.Health(5),
      prism.components.Explosive(),
      prism.components.Senses(),
      prism.components.Sight { range = 1, fov = true }
   }
end)
