prism.registerActor("Door", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Door"),
      prism.components.Drawable { index = "-" },
      prism.components.DoorController(),
      prism.components.Collider(),
      prism.components.Opaque()
   }
end)
