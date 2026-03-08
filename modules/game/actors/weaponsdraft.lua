prism.registerActor("InfinitePistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.PISTOL, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
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
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.PISTOL, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Range { min = 0, max = 4 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 3, max = 3, type = "Pistol" },
      prism.components.Effect { health = 0, push = 1 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)


-- prism.registerActor("Laser", function()
--    return prism.Actor.fromComponents {
--       prism.components.Name("Laser"),
--       prism.components.Item(),
--       prism.components.SlotType("Weapon"),
--       prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
--       prism.components.Ability(),
--       prism.components.Range { min = 0, max = 10 },
--       prism.components.Cost { ammo = 1 },
--       prism.components.Clip { ammo = 4, max = 4, type = "Laser" },
--       prism.components.Effect { health = 3, push = 0 },
--       prism.components.Template { type = "line", range = 10, passabilityMask = { "fly" } },
--       prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.GREEN }
--    }
-- end)




-- prism.registerActor("Shotgun", function()
--    return prism.Actor.fromComponents {
--       prism.components.Name("Shotgun"),
--       prism.components.Item(),
--       prism.components.SlotType("Weapon"),
--       prism.components.Drawable { index = TILES.SHOTGUN, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
--       prism.components.Ability(),
--       prism.components.Range { min = 0, max = 5 },
--       prism.components.Cost { ammo = 1 },
--       prism.components.Clip { ammo = 2, max = 2, type = "Shotgun" },
--       prism.components.Effect { health = 1, push = 0.5 },
--       prism.components.Template { type = "arc", range = 4, arcLength = math.pi / 3, multishot = true, mask = { "walk" } },
--       prism.components.Animate { name = "Projectile", duration = 0.15, color = prism.Color4.YELLOW, index = 250 }
--    }
-- end)



prism.registerActor("BotPoisonGrenadeLauncher", function()
   return prism.Actor.fromComponents {
      prism.components.Name("BotPoisonGrenadeLauncher"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Ability(),
      prism.components.Drawable { index = "l", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 6 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 1, max = 1, type = "Grenade", turns = 4 },
      prism.components.Effect { spawnActor = "Poison", actorOptions = { 3 } },
      prism.components.Scatter(0, 3),
      prism.components.Template { type = "circle", range = 1.5, passabilityMask = { "fly" }, mustSeePlayerToFire = false },
   }
end)
