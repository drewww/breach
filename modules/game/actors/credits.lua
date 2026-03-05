prism.registerActor("Credits", function(count)
   return prism.Actor.fromComponents {
      prism.components.Name("Credits"),
      prism.components.Drawable { index = "$", layer = 100, color = prism.Color4.YELLOW },
      prism.components.Immoveable(),
      prism.components.Position(),
      prism.components.Item({
         stackable = "credits",
         stackCount = count or 1
      })
   }
end)
