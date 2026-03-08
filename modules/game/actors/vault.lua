-- =============================================================================
-- BIOME SYSTEM
-- =============================================================================

-- Biome enum
local Biome = {
   A = "A",
   B = "B",
   C = "C"
}

-- Biome visual configurations
local BIOME_COLORS = {
   [Biome.A] = prism.Color4.GREY,
   [Biome.B] = prism.Color4.BROWN,
   [Biome.C] = prism.Color4.RED
}

-- =============================================================================
-- DROP TABLE DEFINITIONS
-- =============================================================================

-- Ammo drop tables by biome
local AMMO_TABLES = {
   [Biome.A] = {
      entries = {
         { weight = 60, entry = "AmmoPistol", quantity = 4 },
         -- { weight = 30, entry = "AmmoShotgun", quantity = 4 },
         { weight = 20, entry = "AmmoRifle",  quantity = 6 },
         -- { weight = 10, entry = "AmmoLaser",   quantity = 2 }
      }
   },
   [Biome.B] = {
      entries = {
         { weight = 35, entry = "AmmoPistol",  quantity = 4 },
         { weight = 35, entry = "AmmoShotgun", quantity = 3 },
         { weight = 20, entry = "AmmoRifle",   quantity = 6 },
         { weight = 10, entry = "AmmoLaser",   quantity = 1 }
      }
   },
   [Biome.C] = {
      entries = {
         { weight = 30, entry = "AmmoPistol",  quantity = 8 },
         { weight = 35, entry = "AmmoRifle",   quantity = 12 },
         { weight = 25, entry = "AmmoLaser",   quantity = 4 },
         { weight = 10, entry = "AmmoShotgun", quantity = 4 }
      }
   }
}

-- Weapon drop tables by biome
local WEAPON_TABLES = {
   [Biome.A] = {
      chance = 0.3,
      entries = {
         { weight = 20, entry = "PistolRanged" },
         { weight = 5,  entry = "Revolver" },
         { weight = 5,  entry = "PistolPusher" },
         { weight = 5,  entry = "KnifeStrong" },
      }
   },
   [Biome.B] = {
      entries = {
         { weight = 35, entry = "Shotgun" },
         { weight = 20, entry = "Rifle" },
         { weight = 5,  entry = "KnifeStrong" },
         { weight = 5,  entry = "Laser" },
      }
   },
   [Biome.C] = {
      entries = {
         { weight = 35, entry = "Rifle" },
         { weight = 20, entry = "Laser" },
         { weight = 10, entry = "Shotgun" },
         { weight = 10, entry = "Sniper" },
         { weight = 5,  entry = "KnifeStrong" },
      }
   }
}

-- Utility drop tables by biome
local UTILITY_TABLES = {
   [Biome.A] = {
      chance = 0.6,
      entries = {
         { weight = 40, entry = "GrenadeBlast", quantity = 1 },
         { weight = 30, entry = "SmokeGrenade", quantity = 1 },
         { weight = 20, entry = "MineItem",     quantity = 2 },
      }
   },
   [Biome.B] = {
      entries = {
         { weight = 45, entry = "GrenadeBlast",  quantity = 1 },
         { weight = 30, entry = "MineItem",      quantity = 2 },
         { weight = 15, entry = "SmokeGrenade",  quantity = 1 },
         { weight = 25, entry = "GrenadePoison", quantity = 2 },
         { weight = 10, entry = "GrenadeStun",   quantity = 1 }
      }
   },
   [Biome.C] = {
      entries = {
         { weight = 35, entry = "SmokeGrenade",  quantity = 3 },
         { weight = 30, entry = "GrenadeStun",   quantity = 2 },
         { weight = 25, entry = "GrenadeBlast",  quantity = 2 },
         { weight = 25, entry = "GrenadePoison", quantity = 2 },
         { weight = 10, entry = "MineItem",      quantity = 3 },
      }
   }
}

-- Money drop tables by biome
local MONEY_TABLES = {
   [Biome.A] = {
      entries = {
         { weight = 60, entry = "CreditsSmall",  quantity = 5 },
         { weight = 30, entry = "CreditsMedium", quantity = 10 },
         { weight = 10, entry = "CreditsLarge",  quantity = 25 }
      }
   },
   [Biome.B] = {
      entries = {
         { weight = 30, entry = "CreditsSmall",  quantity = 5 },
         { weight = 50, entry = "CreditsMedium", quantity = 10 },
         { weight = 20, entry = "CreditsLarge",  quantity = 25 }
      }
   },
   [Biome.C] = {
      entries = {
         { weight = 20, entry = "CreditsMedium",     quantity = 10 },
         { weight = 50, entry = "CreditsLarge",      quantity = 25 },
         { weight = 5,  entry = "CreditsSmall",      quantity = 5 },
         { weight = 50, entry = "CreditsExtraLarge", quantity = 50 }
      }
   }
}

-- Enemy drop tables by biome (ammo or money only)
local ENEMY_DROP_TABLES = {
   [Biome.A] = {
      chance = 0.4, -- 60% chance to drop something
      entries = {
         { weight = 50, entry = "CreditsSmall" },
         { weight = 20, entry = "AmmoPistol",   quantity = 3 },
         -- { weight = 15, entry = "AmmoShotgun",  quantity = 2 },
         { weight = 10, entry = "CreditsMedium" }
      }
   },
   [Biome.B] = {
      chance = 0.5, -- 50% chance to drop something
      entries = {
         { weight = 55, entry = "CreditsSmall" },
         { weight = 25, entry = "AmmoPistol",   quantity = 2 },
         { weight = 15, entry = "AmmoShotgun",  quantity = 1 },
         { weight = 5,  entry = "CreditsMedium" }
      }
   },
   [Biome.C] = {
      chance = 0.4, -- 70% chance to drop something
      entries = {
         { weight = 40, entry = "CreditsMedium" },
         { weight = 30, entry = "AmmoRifle",    quantity = 4 },
         { weight = 15, entry = "AmmoLaser",    quantity = 2 },
         { weight = 10, entry = "CreditsLarge" },
         { weight = 5,  entry = "AmmoPistol",   quantity = 5 }
      }
   }
}

-- =============================================================================
-- ACTOR FACTORIES
-- =============================================================================

-- Ammo Stash
prism.registerActor("AmmoStash", function(biome, guaranteed)
   biome = biome or Biome.A
   local dropTable = AMMO_TABLES[biome]
   if guaranteed then
      dropTable = { chance = 1.0, entries = dropTable.entries }
   end
   return prism.Actor.fromComponents {
      prism.components.Name("Ammo Stash"),
      prism.components.Drawable { index = TILES.VAULT, layer = 50, color = BIOME_COLORS[biome] },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Immoveable(),
      prism.components.Position(),
      prism.components.Health(1),
      prism.components.DropTable(dropTable)
   }
end)

-- Weapon Cache
prism.registerActor("WeaponCache", function(biome, guaranteed)
   biome = biome or Biome.A
   local dropTable = WEAPON_TABLES[biome]
   if guaranteed then
      dropTable = { chance = 1.0, entries = dropTable.entries }
   end
   return prism.Actor.fromComponents {
      prism.components.Name("Weapon Cache"),
      prism.components.Drawable { index = TILES.VAULT, layer = 50, color = BIOME_COLORS[biome] },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Immoveable(),
      prism.components.Position(),
      prism.components.Health(1),
      prism.components.DropTable(dropTable)
   }
end)

-- Utility Container
prism.registerActor("UtilityContainer", function(biome, guaranteed)
   biome = biome or Biome.A
   local dropTable = UTILITY_TABLES[biome]
   if guaranteed then
      dropTable = { chance = 1.0, entries = dropTable.entries }
   end
   return prism.Actor.fromComponents {
      prism.components.Name("Utility Container"),
      prism.components.Drawable { index = TILES.VAULT, layer = 50, color = BIOME_COLORS[biome] },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Position(),
      prism.components.Health(1),
      prism.components.DropTable(dropTable)
   }
end)

-- Money Vault
prism.registerActor("MoneyVault", function(biome, guaranteed)
   biome = biome or Biome.A
   local dropTable = MONEY_TABLES[biome]
   if guaranteed then
      dropTable = { chance = 1.0, entries = dropTable.entries }
   end
   return prism.Actor.fromComponents {
      prism.components.Name("Money Vault"),
      prism.components.Drawable { index = TILES.CREDITS_VAULT, layer = 50, color = BIOME_COLORS[biome] },
      prism.components.Collider(),
      prism.components.Immoveable(),
      prism.components.Opaque(),
      prism.components.Position(),
      prism.components.Health(1),
      prism.components.DropTable(dropTable)
   }
end)


-- Export the Biome enum for use in other files
return Biome
