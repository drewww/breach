prism.registerActor("BurstBot", function()
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Burst Bot"),
      prism.components.Drawable { index = TILES.BOT_CRAB, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 4, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(4),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.ConditionHolder(),
      prism.components.BehaviorState()
   }

   local shoot = prism.behaviors.ShootBehavior()
   local movetoplayer = prism.behaviors.MoveToPlayer()
   local wait = prism.behaviors.WaitBehavior()
   local detect = prism.behaviors.DetectPlayer()
   local pickWaypoint = prism.behaviors.SelectWaypoint()
   local moveWaypoint = prism.behaviors.MoveToWaypoint()

   local root = prism.BehaviorTree.Root({ detect, shoot, movetoplayer, pickWaypoint, moveWaypoint, wait })

   local inventory = actor:expect(prism.components.Inventory)
   local burst = prism.actors.BotBurstWeapon()
   burst:give(prism.components.Active())
   inventory:addItem(burst)

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)


prism.registerActor("LaserBot", function()
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Laser Bot"),
      prism.components.Drawable { index = TILES.BOT_MELEE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(3),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.ConditionHolder(),
      prism.components.BehaviorState()
   }

   local shoot = prism.behaviors.ShootBehavior()
   local movetoplayer = prism.behaviors.MoveToPlayer()
   local wait = prism.behaviors.WaitBehavior()
   local detect = prism.behaviors.DetectPlayer()
   local pickWaypoint = prism.behaviors.SelectWaypoint()
   local moveWaypoint = prism.behaviors.MoveToWaypoint()
   local reload = prism.behaviors.ReloadBehavior()

   local root = prism.BehaviorTree.Root({ detect, reload, shoot, movetoplayer, pickWaypoint, moveWaypoint, wait })

   local laser = prism.actors.BotLaser()
   laser:give(prism.components.Active())

   local inventory = actor:expect(prism.components.Inventory)

   inventory:addItem(laser)
   inventory:addItem(AMMO_TYPES["Laser"](20))

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)
