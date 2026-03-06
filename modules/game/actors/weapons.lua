prism.registerActor("Knife", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Knife"),
      prism.components.Item(),
      prism.components.SlotType("Melee"),
      prism.components.Ability(),
      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 1 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)

prism.registerActor("KnifeStrong", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Knife"),
      prism.components.Item(),
      prism.components.SlotType("Melee"),
      prism.components.Ability(),
      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 3 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)


prism.registerActor("KnifePush", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Knife"),
      prism.components.Item(),
      prism.components.SlotType("Melee"),
      prism.components.Ability(),
      prism.components.Drawable { index = TILES.SWORD, color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 99 },
      prism.components.Range { min = 1, max = 1 },
      prism.components.Effect { health = 1, push = 1 },
      prism.components.Template { type = "point" },
      prism.components.Animate { name = "Flash", duration = 0.1, color = prism.Color4.YELLOW }
   }
end)
