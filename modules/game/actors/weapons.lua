prism.registerActor("Pistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Impact Pistol"),
      prism.components.Item(),
      prism.components.Drawable { index = "p", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 1, max = 6, miss_odds = 0.1, min_miss = math.pi / 32, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 4, max = 4, type = "Pistol" },
      prism.components.Effect { health = 1, push = 1, crit = 0.05 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("Rifle", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Rifle"),
      prism.components.Item(),
      prism.components.Drawable { index = "r", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 1, max = 10, miss_odds = 0.3, min_miss = 0, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 3, multi = 3 },
      prism.components.Clip { ammo = 16, max = 16, type = "Rifle" },
      prism.components.Effect { health = 1, push = 0, crit = 0 },
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

prism.registerActor("BotPoisonGrenadeLauncher", function()
   return prism.Actor.fromComponents {
      prism.components.Name("BotPoisonGrenadeLauncher"),
      prism.components.Item(),
      prism.components.Ability(),
      prism.components.Drawable { index = "l", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 6 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 1, max = 1, type = "PoisonGrenade", turns = 4 },
      prism.components.Effect { spawnActor = "Poison", actorOptions = { 3 } },
      prism.components.Scatter(0, 3),
      prism.components.Template { type = "circle", range = 1.5, passabilityMask = { "fly" }, mustSeePlayerToFire = false },
   }
end)

prism.registerActor("MineLayer", function()
   return prism.Actor.fromComponents {
      prism.components.Name("MineLayer"),
      prism.components.Item(),
      prism.components.Ability(),
      prism.components.Drawable { index = "m", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { spawnActor = "Mine" },
      prism.components.Template { type = "point" },
      prism.components.Cost { ammo = 1 }
   }
end)

prism.registerActor("MineExplosion", function()
   return prism.Actor.fromComponents {
      prism.components.Name("MineExplosion"),
      prism.components.Item(),
      prism.components.Ability(),
      prism.components.Drawable { index = "m", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 0, max = 1 },
      prism.components.Effect { health = 2, push = 1 },
      prism.components.Template { type = "circle", range = 1.8, mustSeePlayerToFire = true },

      -- prism.components.Trigger { type = "circle", range = 1.8, mustSeePlayerToFire = true },

      prism.components.Cost { ammo = 1 },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.RED, index = 8, explode = true, radius = 2.9, explodeColor = prism.Color4.ORANGE }
   }
end)
