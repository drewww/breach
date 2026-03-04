prism.registerActor("Player", function(weapons)
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Player"),
      prism.components.Drawable { index = TILES.PLAYER, background = prism.Color4.BLACK, layer = 100 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.PlayerController(),
      -- prism.components.Player(),
      prism.components.Senses(),
      prism.components.Sight { range = 64, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Dasher { "walk" },
      prism.components.Health(8),
      prism.components.Energy(4, 4, 0.1),
      prism.components.TriggersExplosives(),
      prism.components.Inventory(),
      prism.components.Dialog()
   }

   if weapons then
      local inventory = actor:expect(prism.components.Inventory)

      local pistol = prism.actors.Pistol()
      pistol:give(prism.components.Active())
      inventory:addItem(AMMO_TYPES["Pistol"](60))
      inventory:addItem(pistol)

      local concussion = prism.actors.SmokeGrenade(4)
      inventory:addItem(concussion)

      local rifle = prism.actors.Rifle()
      inventory:addItem(rifle)
      inventory:addItem(AMMO_TYPES["Rifle"](60))

      local shotgun = prism.actors.Shotgun()
      inventory:addItem(shotgun)
      inventory:addItem(AMMO_TYPES["Shotgun"](20))
   end
   return actor
end)
