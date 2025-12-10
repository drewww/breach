prism.registerActor("Door", function()
   return prism.Actor.fromComponents {
      prism.components.Name("Door"),
      prism.components.Drawable { index = "-", color = prism.Color4.WHITE, background = prism.Color4.BLACK, layer = 50 },
      prism.components.DoorController(),
      prism.components.Collider(),
      prism.components.Immoveable(),
      prism.components.Opaque(),
      prism.components.Senses(),
      prism.components.Sight { range = 2, fov = true }
   }
end)
