prism.registerActor("BotLaser", function()
   return prism.Actor.fromComponents {
      prism.components.Name("BotLaser"),
      prism.components.Item(),
      prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 7 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 1, max = 1, type = "Laser", turns = 2 },
      prism.components.Effect { health = 3, push = 0 },
      prism.components.Template { type = "line", range = 7, passabilityMask = { "fly" }, mustSeePlayerToFire = false },
      prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.RED }

   }
end)

prism.registerActor("BotBurstWeapon", function()
   return prism.Actor.fromComponents {
      prism.components.Name("BotBurstWeapon"),
      prism.components.Item(),
      prism.components.Ability(),
      prism.components.Drawable { index = "w", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 0, max = 1 },
      prism.components.Effect { health = 2, push = 0 },
      prism.components.Template { type = "wedge", range = 1.8, arcLength = math.pi / 2, excludeOrigin = true, passabilityMask = { "walk" }, mustSeePlayerToFire = true },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)
