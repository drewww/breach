--- @param x number
--- @param y number
--- @param message string|string[] The message to display (string or array of strings for multi-line)
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

   -- Check if message is an array of strings
   local isArray = type(message) == "table" and #message > 0
   local lines = isArray and message or { message }

   -- Calculate the maximum length for duration calculations
   local maxLength = 0
   for _, line in ipairs(lines) do
      maxLength = math.max(maxLength, #line)
   end

   if mode == "char" then
      -- rescale duration to total message length
      duration = duration * maxLength
   else
      duration = duration
   end

   return spectrum.Animation(function(t, display)
      -- when we're beyond the reveal duration, index will continue to grow
      -- but substr's behavior for index > #message is to just show the
      -- whole string.
      local index = math.floor((t * maxLength) / duration) + 1

      -- display each line with the same reveal progress
      for i, line in ipairs(lines) do
         local substr = string.sub(line, 1, index)
         local lineY = y + (i - 1)

         display:print(x, lineY, substr,
            fg, bg, layer, align, width)
      end

      return t >= duration + hold
   end)
end)
