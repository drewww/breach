prism.registerActor("Stairs", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Stairs"),
      prism.components.Position(),
      prism.components.Drawable { index = ">" },
      prism.components.Stair(),
      prism.components.Remembered(),
   }
end)
