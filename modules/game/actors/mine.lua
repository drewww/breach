prism.registerActor("Mine", function()
   local actor = prism.Actor.fromComponents {
      prism.components.Name("Mine"),
      prism.components.Drawable { index = "m", color = prism.Color4.ORANGE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Position(),
      prism.components.Collider(),
      prism.components.Senses(),
      prism.components.Sight { range = 1.8, fov = true },
      prism.components.Health(3),
      prism.components.Intentful(),
      prism.components.Inventory(),
      prism.components.TriggersExplosives(),
      prism.components.Explosive()
   }

   local alwaysShoot = prism.behaviors.AlwaysShoot()
   local wait = prism.behaviors.WaitBehavior()

   local root = prism.BehaviorTree.Root({ alwaysShoot, wait })

   local inventory = actor:expect(prism.components.Inventory)
   local mine = prism.actors.MineExplosion()
   mine:give(prism.components.Active())
   inventory:addItem(mine)

   local controller = prism.components.BehaviorController(root)
   actor:give(controller)

   -- prime it with an explode plan
   controller.intent = prism.actions.ItemAbility(actor, mine, prism.Vector2(0, 0))

   return actor
end)
