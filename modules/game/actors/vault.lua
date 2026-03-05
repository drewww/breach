prism.registerActor("Vault", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Vault"),
      prism.components.Drawable { index = "V", layer = 50 },
      prism.components.Collider(),
      prism.components.Opaque(),
      prism.components.Position(),
      prism.components.Health(1),
      prism.components.DropTable({
         chance = 1.0,
         entry = "Credits"
      })
   }
end)
