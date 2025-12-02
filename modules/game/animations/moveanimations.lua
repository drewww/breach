spectrum.registerAnimation("Move", function(level, owner, destination, duration)
   local startPos = owner:getPosition()
   local startX, startY = startPos:decompose()

   prism.logger.info("Initializing smooth move animation from", startX, startY, "to", destination.x, destination.y)

   local drawable = owner:get(prism.components.Drawable)
   assert(drawable, "Attempted to animate an entity without a Drawable.")

   return spectrum.Animation(function(t, display)
      -- Calculate interpolation factor (0.0 to 1.0)
      local progress = math.min(t / duration, 1.0)

      -- Smooth interpolation between start and end positions
      local currentX = startX + (destination.x - startX) * progress
      local currentY = startY + (destination.y - startY) * progress

      -- Convert to pixel coordinates
      -- make sure to build in camera offsets, drawDrawable does not respect
      -- them.
      --
      local pixelX = (currentX + display.camera.x - 1) * display.cellSize.x
      local pixelY = (currentY + display.camera.y - 1) * display.cellSize.y

      -- prism.logger.info("Smooth animation progress:", progress, "pixel coords:", pixelX, pixelY, "cellCoords: ", currentX,
      --    currentY)
      display:drawDrawable(pixelX, pixelY, drawable)

      -- Animation is complete when progress reaches 1.0
      return progress >= 1.0
   end)
end)
