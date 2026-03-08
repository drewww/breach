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
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW },
      prism.components.Value(5),
   }
end)

prism.registerActor("KnifeStrong", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Spike"),
      prism.components.Item(),
      prism.components.Health(1),
      prism.components.Immoveable(),
      prism.components.SlotType("Melee"),
      prism.components.Ability(),
      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 3 },
      prism.components.Template { type = "point" },
      prism.components.Value(20),
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)


prism.registerActor("KnifePush", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Spike PSH"),
      prism.components.Item(),
      prism.components.SlotType("Melee"),
      prism.components.Immoveable(),
      prism.components.Health(1),
      prism.components.Ability(),
      prism.components.Value(20),

      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 1, push = 1 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)

prism.registerActor("Pistol", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Pistol"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.PISTOL, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(5),
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
      prism.components.Value(20),

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
      prism.components.Value(25),

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
      prism.components.Value(15),

      prism.components.Range { min = 1, max = 8, miss_odds = 0.1, min_miss = math.pi / 32, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 6, max = 6, type = "Pistol" },
      prism.components.Effect { health = 3, push = 0, crit = 0.05 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)


prism.registerActor("Rifle", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Rifle"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.RIFLE, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Value(25),
      prism.components.Health(1),

      prism.components.Flavor(prism.components.Flavor.Category.RIFLE),
      prism.components.Range { min = 1, max = 10, miss_odds = 0.3, min_miss = 0, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 3, multi = 3 },
      prism.components.Clip { ammo = 12, max = 12, type = "Rifle" },
      prism.components.Effect { health = 1, push = 0, crit = 0 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("RifleRNG", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Rifle RNG"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.RIFLE, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Value(25),
      prism.components.Health(1),

      prism.components.Flavor(prism.components.Flavor.Category.RIFLE),
      prism.components.Range { min = 1, max = 14, miss_odds = 0.15, min_miss = 0, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 3, multi = 3 },
      prism.components.Clip { ammo = 12, max = 12, type = "Rifle" },
      prism.components.Effect { health = 1, push = 0, crit = 0 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("RifleDMG", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Rifle DMG"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.RIFLE, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Value(25),
      prism.components.Health(1),
      prism.components.Flavor(prism.components.Flavor.Category.RIFLE),
      prism.components.Range { min = 1, max = 8, miss_odds = 0.25, min_miss = 0, max_miss = math.pi / 16 },
      prism.components.Cost { ammo = 3, multi = 3 },
      prism.components.Clip { ammo = 9, max = 9, type = "Rifle" },
      prism.components.Effect { health = 2, push = 0, crit = 0 },
      prism.components.Template { type = "point", passabilityMask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.YELLOW, index = 250 }
   }
end)


prism.registerActor("Laser", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Laser"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(50),
      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 4, max = 4, type = "Laser" },
      prism.components.Effect { health = 3, push = 0 },
      prism.components.Template { type = "line", range = 10, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.GREEN }
   }
end)

prism.registerActor("LaserDMG", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Laser DMG"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(50),
      prism.components.Range { min = 0, max = 8 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 4, max = 4, type = "Laser" },
      prism.components.Effect { health = 5, push = 0 },
      prism.components.Template { type = "line", range = 10, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.GREEN }
   }
end)

prism.registerActor("LaserRNG", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Laser RNG"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = "l", color = prism.Color4.BLUE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(50),
      prism.components.Range { min = 0, max = 12 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 4, max = 4, type = "Laser" },
      prism.components.Effect { health = 3, push = 0 },
      prism.components.Template { type = "line", range = 10, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Flash", duration = 0.2, color = prism.Color4.GREEN }
   }
end)

prism.registerActor("Shotgun", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Shotgun"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.SHOTGUN, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(40),
      prism.components.Range { min = 0, max = 4 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 2, max = 2, type = "Shotgun" },
      prism.components.Effect { health = 1, push = 0.5 },
      prism.components.Template { type = "arc", range = 4, arcLength = math.pi / 3, multishot = true, mask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.15, color = prism.Color4.YELLOW, index = 250 }
   }
end)


prism.registerActor("ShotgunPSH", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Shotgun PSH"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.SHOTGUN, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(40),
      prism.components.Range { min = 0, max = 5 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 2, max = 2, type = "Shotgun" },
      prism.components.Effect { health = 0, push = 2 },
      prism.components.Template { type = "arc", range = 4, arcLength = math.pi / 3, multishot = true, mask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.15, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("ShotgunRNG", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Shotgun RNG"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Drawable { index = TILES.SHOTGUN, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(40),
      prism.components.Range { min = 0, max = 6 },
      prism.components.Cost { ammo = 1 },
      prism.components.Clip { ammo = 2, max = 2, type = "Shotgun" },
      prism.components.Effect { health = 0, push = 2 },
      prism.components.Template { type = "arc", range = 6, arcLength = math.pi / 4, multishot = true, mask = { "walk" } },
      prism.components.Animate { name = "Projectile", duration = 0.15, color = prism.Color4.YELLOW, index = 250 }
   }
end)

prism.registerActor("MineItem", function(count)
   return prism.Actor.fromComponents {
      prism.components.Name("Prox Mine"),
      prism.components.Item { stackable = "mine", stackCount = count },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(5),
      prism.components.SlotType("Utility"),
      prism.components.Drawable { index = TILES.MINE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 2 },
      prism.components.Effect { spawnActor = "Mine" },
      prism.components.Template { type = "point" },
      prism.components.Cost { ammo = 1 }
   }
end)

prism.registerActor("MineExplosion", function()
   return prism.Actor.fromComponents {
      prism.components.Name("MineExplosion"),
      prism.components.Item(),
      prism.components.SlotType("Weapon"),
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(5),
      prism.components.Drawable { index = "m", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 0, max = 1 },
      prism.components.Effect { health = 3 },
      prism.components.Template { type = "point", range = 1.8, requiredComponents = { prism.components.TriggersExplosives } },
      prism.components.Trigger { type = "circle", range = 1.8, requiredComponents = { prism.components.TriggersExplosives } },
      prism.components.Cost { ammo = 1 },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.RED, index = 8, explode = true, radius = 2.9, explodeColor = prism.Color4.ORANGE },
      prism.components.SelfDestruct()
   }
end)


prism.registerActor("SmokeGrenade", function(num)
   return prism.Actor.fromComponents {
      prism.components.Name("Grenade SMOKE"),
      prism.components.Item { stackable = "SmokeGrenade", stackCount = num },
      prism.components.SlotType("Utility"),
      prism.components.Drawable { index = TILES.SMOKE_GRENADE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(5),

      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { spawnActor = "Smoke", actorOptions = { 10 } },
      prism.components.Template { type = "circle", range = 2, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.WHITE, index = 8, explode = true, explodeColor = prism.Color4.ORANGE, radius = 2.5 }
   }
end)

prism.registerActor("GrenadeStun", function(count)
   return prism.Actor.fromComponents {
      prism.components.Name("Grenade STUN"),
      prism.components.Item { stackable = "grenade_concussion", stackCount = count },
      prism.components.SlotType("Utility"),
      prism.components.Drawable { index = TILES.STUN_GRENADE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(5),
      prism.components.Range { min = 2, max = 8 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { condition = prism.conditions.TickedCondition(3, prism.modifiers.StunnedModifier()) },
      prism.components.Template { type = "circle", range = 2, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.RED, index = 8, explode = true, radius = 2.5, explodeColor = prism.Color4.ORANGE }
   }
end)

prism.registerActor("GrenadeBlast", function(count)
   return prism.Actor.fromComponents {
      prism.components.Name("Grenade PSH"),
      prism.components.SlotType("Utility"),
      prism.components.Item { stackable = "grenade_concussion", stackCount = count },
      prism.components.Drawable { index = TILES.PUSH_GRENADE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(5),
      prism.components.Range { min = 2, max = 8 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { health = 0, push = 3, pushFromCenter = true },
      prism.components.Template { type = "circle", range = 2, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.RED, index = 8, explode = true, radius = 2.5, explodeColor = prism.Color4.ORANGE }
   }
end)


prism.registerActor("PoisonGrenade", function(num)
   return prism.Actor.fromComponents {
      prism.components.Name("Grenade POISON"),
      prism.components.Item { stackable = "PoisonGrenade", stackCount = num },
      prism.components.SlotType("Utility"),
      prism.components.Drawable { index = TILES.POISON_GRENADE, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Ability(),
      prism.components.Health(1),
      prism.components.Value(5),

      prism.components.Range { min = 0, max = 10 },
      prism.components.Cost { ammo = 1 },
      prism.components.Effect { spawnActor = "Poison", actorOptions = { 10 } },
      prism.components.Template { type = "circle", range = 2, passabilityMask = { "fly" } },
      prism.components.Animate { name = "Projectile", duration = 0.2, color = prism.Color4.WHITE, index = 8, explode = true, explodeColor = prism.Color4.ORANGE, radius = 2.5 }
   }
end)
