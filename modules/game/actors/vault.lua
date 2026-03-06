prism.registerActor("Vault", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Vault"),
      prism.components.Drawable { index = "V", layer = 50 },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Position(),
      prism.components.Health(1),
      prism.components.DropTable({
         entries = {
            { weight = 50, entry = "Credits", quantity = 2 },
            { weight = 40, entry = "Credits", quantity = 5 },
            { weight = 10, entry = "Credits", quantity = 20 }
         }
      })
   }
end)
