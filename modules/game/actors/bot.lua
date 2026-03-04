--- @class BotOptions
--- @field leader? boolean
--- @field follower? boolean
--- @field hp? integer
--- @field vision? integer
--- @field tint? Color4 Set the foreground color.



prism.registerActor("BurstBot", function(options)
   options = options or {}
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Burst Bot"),
      prism.components.Drawable { index = TILES.BOT_CRAB, color = options.tint or prism.Color4.TRANSPARENT, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = options.vision or 4, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(options.hp or 4),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.ConditionHolder(),
      prism.components.BehaviorState()
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end

   local shoot = prism.behaviors.ShootBehavior()
   local movetoplayer = prism.behaviors.MoveToPlayer()
   local wait = prism.behaviors.WaitBehavior()
   local detect = prism.behaviors.DetectPlayer()
   local setLeader = prism.behaviors.SelectLeaderBehavior()
   local moveLeader = prism.behaviors.MoveToLeader()

   local root = prism.BehaviorTree.Root({ detect, shoot, movetoplayer, setLeader, moveLeader, wait })

   local inventory = actor:expect(prism.components.Inventory)
   local burst = prism.actors.BotBurstWeapon()
   burst:give(prism.components.Active())
   inventory:addItem(burst)

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)

prism.registerActor("LaserBot", function(options)
   options = options or {}
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Laser Bot"),
      prism.components.Drawable { index = TILES.BOT_MELEE, color = options.tint or prism.Color4.TRANSPARENT, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = options.vision or 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(options.hp or 3),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.ConditionHolder(),
      prism.components.BehaviorState()
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end

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


prism.registerActor("GrenadierBot", function(options)
   options = options or {}
   local actor = prism.Actor.fromComponents {
      prism.components.Name("GrenadierBot"),

      prism.components.Drawable { index = "G", color = options.tint or prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = options.vision or 8, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Health(options.hp or 4),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.BehaviorState(),
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end


   -- TODO make a separate branch that handles leader/follower so they all have the capacity
   -- to do either.
   local shoot = prism.behaviors.ShootBehavior()
   local movetoplayer = prism.behaviors.MoveToPlayer()
   local wait = prism.behaviors.WaitBehavior()
   local detect = prism.behaviors.DetectPlayer()
   local setLeader = prism.behaviors.SelectLeaderBehavior()
   local moveLeader = prism.behaviors.MoveToLeader()
   local reload = prism.behaviors.ReloadBehavior()

   local root = prism.BehaviorTree.Root({ detect, reload, shoot, movetoplayer, setLeader, moveLeader, wait })


   local inventory = actor:expect(prism.components.Inventory)

   local launcher = prism.actors.BotPoisonGrenadeLauncher()
   launcher:give(prism.components.Active())

   inventory:addItem(launcher)
   inventory:addItem(AMMO_TYPES["PoisonGrenade"](4))

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)
