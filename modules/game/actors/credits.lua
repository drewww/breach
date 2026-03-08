local function makeCredits(count, name)
   return prism.Actor.fromComponents {
      prism.components.Name(name or "Credits"),
      prism.components.Drawable { index = TILES.CREDITS, layer = 100, color = prism.Color4.YELLOW },
      prism.components.Immoveable(),
      prism.components.Accumulated(),
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
   return makeCredits(5, "Credits S")
end)

prism.registerActor("CreditsMedium", function()
   return makeCredits(10, "Credits M")
end)

prism.registerActor("CreditsLarge", function()
   return makeCredits(25, "Credits L")
end)

prism.registerActor("CreditsExtraLarge", function()
   return makeCredits(50, "Credits XL")
end)
