--- @class BotOptions
--- @field leader? boolean
--- @field follower? boolean
--- @field hp? integer
--- @field vision? integer
--- @field tint? Color4 Set the foreground color.

---@return BehaviorTree.Root
local function generateBehaviorTree()
   local leader = prism.behaviors.SelectLeaderBehavior()

   local combat = prism.BehaviorTree.Selector({ prism.behaviors.ReloadBehavior(),
      prism.behaviors.ShootBehavior() })
   local plan = prism.BehaviorTree.Sequence({
      prism.behaviors.HuntPlan(),
      prism.behaviors.LeaderPlan(),
      prism.behaviors.WaypointPlan(),
   })
   local move = prism.BehaviorTree.Selector({
      -- PATH
      prism.behaviors.MoveBehavior()
   })

   return prism.BehaviorTree.Root({ leader, combat, plan, move, prism.behaviors.WaitBehavior() })
end


prism.registerActor("BurstBot", function(options)
   options = options or {}

   if options.leader == nil then options.leader = true end
   if options.follower == nil then options.follower = false end

   local actor = prism.Actor.fromComponents {
      prism.components.Name("LUCANUS"),
      prism.components.Drawable { index = TILES.BOT_CRAB, color = options.tint or prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = options.vision or 10, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Speed(1),
      -- prism.components.Armor(1),
      prism.components.Health(options.hp or 6),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.Flavor(prism.components.Flavor.Category.BURST_BOT),
      prism.components.TriggersExplosives(),
      prism.components.ConditionHolder(),
      prism.components.BehaviorState()
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end

   if options.follower then
      actor:give(prism.components.Follower())
   end

   local root = generateBehaviorTree()

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
   if options.leader == nil then options.leader = false end
   if options.follower == nil then options.follower = true end
   local actor = prism.Actor.fromComponents {
      prism.components.Name("TABANUS"),
      prism.components.Drawable { index = TILES.BOT_MELEE, color = options.tint or prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = options.vision or 10, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Speed(1),
      prism.components.Health(options.hp or 6),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.Flavor(prism.components.Flavor.Category.LASER_BOT),
      prism.components.TriggersExplosives(),
      prism.components.ConditionHolder(),
      prism.components.BehaviorState()
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end

   if options.follower then
      actor:give(prism.components.Follower())
   end

   local root = generateBehaviorTree()

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
      prism.components.Name("AMPULEX"),

      prism.components.Drawable { index = "G", color = options.tint or prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = options.vision or 10, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Speed(1),
      prism.components.Health(options.hp or 8),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.BehaviorState(),
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end

   if options.follower then
      actor:give(prism.components.Follower())
   end

   local root = generateBehaviorTree()


   local inventory = actor:expect(prism.components.Inventory)

   local launcher = prism.actors.BotPoisonGrenadeLauncher()
   launcher:give(prism.components.Active())

   inventory:addItem(launcher)
   inventory:addItem(AMMO_TYPES["Grenade"](4))

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)

prism.registerActor("BruteBot", function(options)
   options = options or {}
   local actor = prism.Actor.fromComponents {
      prism.components.Name("MEGACHILE"),

      prism.components.Drawable { index = "B", color = options.tint or prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Armor(1),
      prism.components.Sight { range = options.vision or 10, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Speed(1),
      prism.components.Health(options.hp or 12),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.BehaviorState(),
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end

   if options.follower then
      actor:give(prism.components.Follower())
   end

   local root = generateBehaviorTree()


   local inventory = actor:expect(prism.components.Inventory)

   local shotgun = prism.actors.BotShotgun()
   shotgun:give(prism.components.Active())

   inventory:addItem(shotgun)
   inventory:addItem(AMMO_TYPES["Shotgun"](10))

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)


prism.registerActor("BoomBot", function(options)
   options = options or {}
   local actor = prism.Actor.fromComponents {
      prism.components.Name("COLOBOPSIS"),

      prism.components.Drawable { index = "b", color = options.tint or prism.Color4.RED, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = options.vision or 10, fov = true },
      prism.components.Mover { "walk" },
      prism.components.Speed(2),
      prism.components.Health(options.hp or 4),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.Flavor(prism.components.Flavor.Category.BOOM_BOT),
      prism.components.TriggersExplosives(),
      prism.components.BehaviorState(),
      prism.components.Explosive(3, 5)
   }

   if options.leader then
      actor:give(prism.components.Leader())
   end

   if options.follower then
      actor:give(prism.components.Follower())
   end

   local root = generateBehaviorTree()

   local inventory = actor:expect(prism.components.Inventory)

   local explode = prism.actors.BotMineExplosion()
   explode:give(prism.components.Active())

   inventory:addItem(explode)

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)
