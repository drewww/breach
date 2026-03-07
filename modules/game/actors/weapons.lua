prism.registerActor("Knife", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Knife"),
      prism.components.Item(),
      prism.components.SlotType("Melee"),
      prism.components.Ability(),
      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Immoveable(),
      prism.components.Health(1),
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 1 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)

prism.registerActor("KnifeStrong", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Knife"),
      prism.components.Item(),
      prism.components.Health(1),
      prism.components.Immoveable(),
      prism.components.SlotType("Melee"),
      prism.components.Ability(),
      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 3 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)


prism.registerActor("KnifePush", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Knife"),
      prism.components.Item(),
      prism.components.SlotType("Melee"),
      prism.components.Immoveable(),
      prism.components.Health(1),
      prism.components.Ability(),
      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 1, push = 1 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)

prism.registerActor("Pistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Impact Pistol"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.PISTOL, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Immoveable(),
      prism.components.Flavor(prism.components.Flavor.Category.PISTOL),
      prism.components.Range { min = 1, max = 6, miss_odds = 0.1, min_miss = math.pi / 32, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 4, max = 4, type = "Pistol" },
      prism.components.Effect { health = 1, push = 1, crit = 0.05 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("PistolRanged", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol LR"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.PISTOL, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Immoveable(),
      prism.components.Flavor(prism.components.Flavor.Category.PISTOL),

      prism.components.Range { min = 1, max = 8, miss_odds = 0.1, min_miss = math.pi / 32, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 6, max = 6, type = "Pistol" },
      prism.components.Effect { health = 1, push = 1, crit = 0.05 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("Revolver", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol DMG"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.PISTOL, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Immoveable(),
      prism.components.Flavor(prism.components.Flavor.Category.PISTOL),

      prism.components.Range { min = 1, max = 8, miss_odds = 0.2, min_miss = math.pi / 32, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 1, max = 1, type = "Pistol" },
      prism.components.Effect { health = 6, push = 0, crit = 0.15 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("PistolPusher", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol PSH"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.PISTOL, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Immoveable(),
      prism.components.Flavor(prism.components.Flavor.Category.PISTOL),

      prism.components.Range { min = 1, max = 8, miss_odds = 0.1, min_miss = math.pi / 32, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 6, max = 6, type = "Pistol" },
      prism.components.Effect { health = 3, push = 0, crit = 0.05 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)
