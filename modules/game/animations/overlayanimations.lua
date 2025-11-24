--- @param x number
--- @param y number
--- @param message string The message to display
--- @param duration number Duration, in ms.
--- @param mode? "total" | "char" If total, duration represents time to show whole message (in s). If char, duration represents time per char.
--- @param fg Color4
--- @param bg Color4
--- @param layer number?
--- @param align "left"|"center"|"right"?
--- @param width number?
spectrum.registerAnimation("OverlayTextReveal", function(x, y, message, duration, mode, fg, bg, layer, align, width)
   -- default to "total" mode.
   if not mode then
      mode = "total"
   end

   if mode == "char" then
      -- rescale duration to total message length
      duration = duration * #message
   end

   -- prism.logger.info("START REVEAL " .. tostring(duration) .. " " .. message)

   return spectrum.Animation(function(t, display)
      local index = math.floor((t * #message) / duration) + 1

      -- display the message up to the index
      local substr = string.sub(message, 1, index)

      -- prism.logger.info("reveal #" .. tostring(index) .. " @" .. tostring(t) .. "/" .. tostring(duration) .. " " .. substr)

      display:print(x, y, substr,
         fg, bg, layer, align, width)

      return t >= duration
   end)
end)
