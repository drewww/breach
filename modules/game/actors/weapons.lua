prism.registerActor("Pistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Impact Pistol"),
      prism.components.Item(),
      prism.components.Drawable { index = "p", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 1, max = 6 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 4, max = 4, type = "Pistol" },
      prism.components.Effect { health = 1, push = 1 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("InfinitePistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol"),
      prism.components.Item(),
      prism.components.Drawable { index = "p", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 6 },
      prism.components.Effect { health = 1, push = 1 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("PushPistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Impact Pistol"),
      prism.components.Item(),
      prism.components.Drawable { index = "p", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 4 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 3, max = 3, type = "Pistol" },
      prism.components.Effect { health = 0, push = 1 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
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
      prism.components.Template { type = "line", range = 10, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.GREEN }
   }
end)

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

prism.registerActor("GrenadeConscussion", function(count)
   return prism.Actor.fromComponents {
      prism.components.Name("CNC GRN"),
      prism.components.Item { stackable = "grenade_concussion", stackCount = count },
      prism.components.Drawable { index = "g", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 2, max = 8 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { health = 1, push = 2, pushFromCenter = true },
      prism.components.Template { type = "circle", range = 2, passabilityMask = { "fly" } },
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
      prism.components.Template { type = "wedge", range = 4.5, arcLength = math.pi / 3, passabilityMask = { "walk" } },
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
      prism.components.Template { type = "circle", range = 2, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.WHITE, index = 8, explode = true, explodeColor = prism.Color4.ORANGE, radius = 2.5 }
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
