prism.registerActor("RandomWaypointBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("RandomWaypointBot"),
      prism.components.Drawable { index = "b", color = prism.Color4.YELLOW, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.BotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.TriggersExplosives()

   }
end)

prism.registerActor("LeaderBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("LeaderBot"),
      prism.components.Drawable { index = "L", color = prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Facing(),
      prism.components.Collider(),
      prism.components.LeaderBotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(10),
      prism.components.Leader(),
      prism.components.TriggersExplosives()

   }
end)

prism.registerActor("FollowerBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("FollowerBot"),
      prism.components.Drawable { index = "f", color = prism.Color4.ORANGE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.FollowerBotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(5),
      prism.components.TriggersExplosives()
   }
end)

prism.registerActor("LaserBot", function()
   local actor = prism.Actor.fromComponents {
      prism.components.Name("LaserBot"),
      prism.components.Drawable { index = "b", color = prism.Color4.ORANGE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(5),
      prism.components.Inventory(),
      prism.components.Intentful(),

      prism.components.TriggersExplosives()
   }

   local laser = prism.actors.BotLaser()
   laser:give(prism.components.Active())
   local inventory = actor:expect(prism.components.Inventory)

   inventory:addItem(laser)
   inventory:addItem(AMMO_TYPES["Laser"](4))

   local shoot = prism.behaviors.ShootBehavior()
   local wait = prism.behaviors.WaitBehavior()
   local reload = prism.behaviors.ReloadBehavior()

   -- TODO eventually we want to be thoughtful about reload using conditional nodes that check ammo levels and ammo availability before reloading.

   local root = prism.BehaviorTree.Root({ reload, shoot, wait })

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)

prism.registerActor("RotateBot", function()
   local actor = prism.Actor.fromComponents {
      prism.components.Name("RotateBot"),
      prism.components.Drawable { index = "b", color = prism.Color4.GREEN, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Facing(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Mover { "walk" },
      prism.components.Health(5),
      prism.components.Intentful(),
      prism.components.TriggersExplosives()
   }

   local rotate = prism.behaviors.RotateMove()
   local wait = prism.behaviors.WaitBehavior()

   local root = prism.BehaviorTree.Root({ rotate, wait })

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)

prism.registerActor("TrainingBurstBot", function()
   local actor = prism.Actor.fromComponents {
      prism.components.Name("TrainingBurstBot"),
      prism.components.Drawable { index = "b", color = prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 1, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(2),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives()
   }

   local shoot = prism.behaviors.ShootBehavior()
   local movetoplayer = prism.behaviors.MoveToPlayer()
   local wait = prism.behaviors.WaitBehavior()

   local root = prism.BehaviorTree.Root({ shoot, movetoplayer, wait })

   local inventory = actor:expect(prism.components.Inventory)
   local burst = prism.actors.BotBurst()
   burst:give(prism.components.Active())
   inventory:addItem(burst)

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)
