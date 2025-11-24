--- @param x number
--- @param y number
--- @param message string The message to display
--- @param duration number Reveal duration, in seconds.
--- @param hold number Hold duration after reveal, in seconds.
--- @param mode? "total" | "char" If total, duration represents time to show whole message (in s). If char, duration represents time per char.
--- @param fg Color4
--- @param bg Color4
--- @param layer number?
--- @param align "left"|"center"|"right"?
--- @param width number?
spectrum.registerAnimation("OverlayTextReveal", function(x, y, message,
                                                         duration, hold, mode, fg, bg, layer, align, width)
   -- default to "total" mode.
   if not mode then
      mode = "total"
   end

   if mode == "char" then
      -- rescale duration to total message length
      duration = duration * #message
   else
      duration = duration
   end

   return spectrum.Animation(function(t, display)
      -- when we're beyond the reveal duration, index will continue to grow
      -- but substr's behavior for index > #message is to just show the
      -- whole string.
      local index = math.floor((t * #message) / duration) + 1

      -- display the message up to the index
      local substr = string.sub(message, 1, index)

      display:print(x, y, substr,
         fg, bg, layer, align, width)

      return t >= duration + hold
   end)
end)
