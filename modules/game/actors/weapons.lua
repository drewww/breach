prism.registerActor("Pistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol"),
      prism.components.Drawable { index = "p", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { health = 1, push = 1 },
      prism.components.Template { type = "point" }
   }
end)
