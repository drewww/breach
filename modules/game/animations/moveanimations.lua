spectrum.registerAnimation("Move", function(level, owner, destination, duration)
   local x, y = owner:getPosition():decompose()
   local mask = owner:expect(prism.components.Mover).mask
   local path = level:findPath(owner:expectPosition(), destination, owner, mask)

   if not path then
      prism.logger.warn("Failed to generate path for move animation from", x, y, "to", destination)
      return nil
   end

   local drawable = owner:get(prism.components.Drawable)
   assert(drawable, "Attempted to animate an entity without a Drawable.")


   return spectrum.Animation(function(t, display)
      local index = math.floor(t / duration) + 1

      if path:length() == 0 then return true end

      local pathNodes = path:getPath()
      if index > #pathNodes then return true end

      local currentNode = pathNodes[index]
      prism.logger.info(currentNode.x * display.cellSize.x, currentNode.y * display.cellSize.y, drawable)
      display:putDrawable(currentNode.x, currentNode.y, drawable)

      if index == path:length() then return true end

      return false
   end)
end)
