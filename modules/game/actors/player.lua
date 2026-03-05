local defaultWeaponLoad = require("util.helpers").defaultWeaponLoad


prism.registerActor("Player", function(weapons)
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Player"),
      prism.components.Drawable { index = TILES.PLAYER, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.PlayerController(),
      prism.components.Player(),
      prism.components.Senses(),
      prism.components.Sight { range = 64, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Dasher { "walk" },
      prism.components.Health(8),
      prism.components.Energy(4, 4, 0.1),
      prism.components.TriggersExplosives(),
      prism.components.Inventory(),
      prism.components.Slots({
         { type = "Melee" },
         { type = "Weapon" },
         { type = "Weapon" },
         { type = "Utility" },
         { type = "Utility" },
         { type = "Utility" },
         { type = "Utility" },
      }),
      prism.components.Dialog()
   }

   if weapons then
      defaultWeaponLoad(actor)
   end
   return actor
end)
