prism.registerActor("Pistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol"),
      prism.components.Item(),
      prism.components.Drawable { index = "p", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 6 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 10, max = 10, type = "Pistol" },
      prism.components.Effect { health = 1, push = 1 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("Laser", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Laser"),
      prism.components.Item(),
      prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 4, max = 4, type = "Laser" },
      prism.components.Effect { health = 3, push = 0 },
      prism.components.Template { type = "line", range = 10 },
      prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.GREEN }
   }
end)

prism.registerActor("BotLaser", function()
   return prism.Actor.fromComponents {
      prism.components.Name("BotLaser"),
      prism.components.Item(),
      prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 2, max = 2, type = "Laser" },
      prism.components.Effect { health = 3, push = 0 },
      prism.components.Template { type = "line", range = 10 },
      prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.RED }

   }
end)

prism.registerActor("Grenade", function(count)
   return prism.Actor.fromComponents {
      prism.components.Name("Grenade"),
      prism.components.Item { stackable = "grenade", stackCount = count },
      prism.components.Drawable { index = "g", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 2, max = 8 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { health = 1, push = 2, pushFromCenter = true },
      prism.components.Template { type = "circle", range = 2 },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.RED, index = 8, explode = true, radius = 2.5, explodeColor = prism.Color4.ORANGE }
   }
end)

prism.registerActor("Shotgun", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Shotgun"),
      prism.components.Item(),
      prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 2, max = 2, type = "Shotgun" },
      prism.components.Effect { health = 2, push = 3 },
      prism.components.Template { type = "wedge", range = 4.5, arcLength = math.pi / 3 },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.WHITE }
   }
end)

prism.registerActor("SmokeGrenade", function(num)
   return prism.Actor.fromComponents {
      prism.components.Name("SmokeGrenade"),
      prism.components.Item { stackable = "SmokeGrenade", stackCount = num },
      prism.components.Drawable { index = "s", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { spawnActor = "Smoke", actorOptions = { 10 } },
      prism.components.Template { type = "circle", range = 2 },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.WHITE, index = 8, explode = true, explodeColor = prism.Color4.ORANGE, radius = 2.5 }
   }
end)
