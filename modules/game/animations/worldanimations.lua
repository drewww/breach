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
         local fadeProgress = (progress - 0.3) / 0.7
         flashColor = color:lerp(prism.Color4.DARKGREY, fadeProgress)
      end

      -- Apply color to all affected cells (change only FG to light up smoke)
      display:putBG(x, y, flashColor)

      return t >= duration
   end)
end)

---Generates an animation that moves a character along a set of positions.
---@param steps Vector2[]
---@param index number|string
---@param fg Color4
---@param bg Color4
---@param layer number
---@param duration number
---@return Animation
local function makePathAnimation(steps, index, fg, bg, layer, duration)
   return spectrum.Animation(function(t, display)
      local i = math.min(math.floor((t / duration) * #steps) + 1, #steps - 1)
      if steps[i] then
         display:put(steps[i].x, steps[i].y, index, fg, bg, layer)
      end
      return t >= duration
   end)
end

spectrum.registerAnimation("Bounce", function(path, duration)
   return makePathAnimation(path, 43, prism.Color4.ORANGE, prism.Color4.TRANSPARENT, math.huge, duration)
end)

spectrum.registerAnimation("Bullet", function(duration, source, target)
   local sx, sy = source:getPosition():decompose()
   local tx, ty = target:getPosition():decompose()
   local path = prism.Bresenham(sx, sy, tx, ty)

   local steps = {}
   if path then
      steps = path:getPath()
   end

   return makePathAnimation(steps, 250, prism.Color4.RED, prism.Color4.TRANSPARENT, math.huge, duration)
end)
