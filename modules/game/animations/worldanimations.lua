spectrum.registerAnimation("Jet", function(owner, duration, index, color, distance, direction)
   local startPos = owner:getPosition()
   local startX, startY = startPos:decompose()

   -- Calculate direction vector using Vector2 rotation
   local directionVector = prism.Vector2.RIGHT -- Start with right (1, 0)
   for i = 1, (direction or 0) do
      directionVector = directionVector:rotateClockwise()
   end

   return spectrum.Animation(function(t, display)
      local progress = math.min(t / duration, 1.0)
      local currentDistance = progress * distance

      -- Fill tiles progressively based on distance
      for i = 1, distance do
         local x = startX + (directionVector.x * i)
         local y = startY + (directionVector.y * i)

         if currentDistance >= i then
            -- Calculate tile position relative to start
            -- Draw colored tile
            display:put(x, y, index, color)
         elseif currentDistance >= i - 1 then
            -- This is the "next" tile - lerp from black to target color
            local tileProgress = currentDistance - (i - 1)
            local lerpedColor = prism.Color4.BLACK:lerp(color, tileProgress)

            display:put(x, y, index, lerpedColor)
         end
      end

      return t >= duration
   end)
end)

--- Make an explosion animation at a point.
---@param position Vector2
---@param duration number
---@param range integer
---@param color Color4
---@return Animation
spectrum.registerAnimation("Explosion", function(position, duration, range, color)
   local x, y = position:decompose()

   return spectrum.Animation(function(t, display)
      local progress = math.min(t / duration, 1.0)

      -- Flash orange immediately, then fade to grey
      local flashColor
      if progress < 0.1 then
         -- Quick orange flash at the start
         flashColor = color
      else
         -- Fade from orange back to grey
         local fadeProgress = (progress - 0.1) / 0.9
         flashColor = color:lerp(prism.Color4.DARKGREY, fadeProgress)
      end

      -- Apply color to all affected cells (change only FG to light up smoke)
      display:putBG(x, y, flashColor)

      return t >= duration
   end)
end)
