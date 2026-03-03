prism.registerCell("Floor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Floor"),
      prism.components.Drawable { index = TILES.FLOOR_1, color = prism.Color4.GREY },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.Scorchable()
   }
end)

prism.registerCell("DoorFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("DoorFloor"),
      prism.components.Drawable { index = TILES.FLOOR_1, color = prism.Color4.GREY },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.Scorchable()
   }
end)

prism.registerCell("WaypointFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("WaypointFloor"),
      prism.components.Drawable { index = TILES.FLOOR_1, color = prism.Color4.GREY },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.Scorchable(),
      prism.components.Waypoint()
   }
end)


prism.registerCell("ObjectiveTriggerFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Floor"),
      prism.components.Drawable { index = 251, color = prism.Color4.GREY, background = prism.Color4.GREEN },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.MapTrigger("objective")
   }
end)

prism.registerCell("DangerTriggerFloor", function()
   return prism.Cell.fromComponents {
      prism.components.Name("Floor"),
      prism.components.Drawable { index = 251, color = prism.Color4.GREY, background = C.SHOOT_INTENT },
      prism.components.Collider({ allowedMovetypes = { "walk", "fly" } }),
      prism.components.MapTrigger("danger")
   }
end)
