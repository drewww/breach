local function makeCredits(count, name)
   return prism.Actor.fromComponents {
      prism.components.Name(name or "Credits"),
      prism.components.Drawable { index = "$", layer = 100, color = prism.Color4.YELLOW },
      prism.components.Immoveable(),
      prism.components.Position(),
      prism.components.Health(1),
      prism.components.Item({
         stackable = "credits",
         stackCount = count or 1
      })
   }
end

prism.registerActor("Credits", makeCredits)

-- Register different denominations with baked-in counts
prism.registerActor("CreditsSmall", function()
   return makeCredits(2, "Credits (Small)")
end)

prism.registerActor("CreditsMedium", function()
   return makeCredits(5, "Credits (Medium)")
end)

prism.registerActor("CreditsLarge", function()
   return makeCredits(10, "Credits (Large)")
end)

prism.registerActor("CreditsExtraLarge", function()
   return makeCredits(20, "Credits (Extra Large)")
end)
