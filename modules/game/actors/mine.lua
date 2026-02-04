prism.registerActor("Mine", function()
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Mine"),
      prism.components.Drawable { index = "m", color = prism.Color4.ORANGE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 2, fov = true },
      prism.components.Health(4),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives()
   }

   local shoot = prism.behaviors.ShootBehavior()
   local wait = prism.behaviors.WaitBehavior()

   local root = prism.BehaviorTree.Root({ shoot, wait })

   local inventory = actor:expect(prism.components.Inventory)
   local mine = prism.actors.MineExplosion()
   mine:give(prism.components.Active())
   inventory:addItem(mine)

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)
   return actor
end)
