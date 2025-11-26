--- @class TextOptions
--- @field mode? "total" | "char" If total, duration represents time to show whole message (in s). If char, duration represents time per char.
--- @field layer? number
--- @field align? "left"|"center"|"right"
--- @field width? number
--- @field fadeFrom? Color4 If set, blends fadeFrom to fg color for the 6 most recent characters

--- @param x number
--- @param y number
--- @param message string|string[] The message to display (string or array of strings for multi-line)
--- @param duration number Reveal duration, in seconds.
--- @param hold number Hold duration after reveal, in seconds.
--- @param fg Color4
--- @param bg Color4
--- @param options? TextOptions
spectrum.registerAnimation("TextReveal", function(x, y, message,
                                                  duration, hold, fg, bg, options)
   -- Extract options with defaults
   options = options or {}
   local mode = options.mode or "total"
   local layer = options.layer
   local align = options.align
   local width = options.width
   local fadeFrom = options.fadeFrom

   -- Error checking for fadeFrom
   if fadeFrom and not fg then
      error("fadeFrom parameter requires fg to be set")
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
         local lineY = y + (i - 1)

         if fadeFrom then
            -- Determine how many characters to fade (up to 6)
            local fadeCount = math.min(6, index)
            local mainCount = math.max(0, index - fadeCount)

            -- Draw the main text (everything except the faded chars)
            if mainCount > 0 then
               local mainSubstr = string.sub(line, 1, mainCount)
               display:print(x, lineY, mainSubstr, fg, bg, layer, align, width)
            end

            -- Draw the fading characters
            for j = 1, fadeCount do
               local charIndex = mainCount + j
               if charIndex > 0 and charIndex <= #line then
                  local char = string.sub(line, charIndex, charIndex)
                  local blendFactor = math.max(0, (fadeCount - j - 1) / fadeCount)
                  local blendedColor = fadeFrom:lerp(fg, blendFactor)
                  -- Calculate x position for this character
                  local charX = x + (charIndex - 1)
                  display:print(charX, lineY, char, blendedColor, bg, layer, align, 1)
               end
            end
         else
            -- Normal rendering without fade effect
            local substr = string.sub(line, 1, index)
            display:print(x, lineY, substr, fg, bg, layer, align, width)
         end
      end

      return t >= duration + hold
   end)
end)

---Animates text in a direction.
---@param x number
---@param y number
---@param message string
---@param direction Vector2 Vector representing the direction and distance to move.
---@param duration number Time (in seconds) over which to move.
---@param fg Color4
---@param bg Color4
---@param options? TextOptions
---@return Animation
spectrum.registerAnimation("TextMove", function(x, y, message, direction, duration, fg, bg, options)
   -- Extract options with defaults
   options = options or {}
   local mode = options.mode or "total"
   local layer = options.layer
   local align = options.align
   local width = options.width
   local fadeFrom = options.fadeFrom

   -- Error checking for fadeFrom - not supported in TextMove
   if fadeFrom then
      error("fadeFrom is not supported in TextMove animation")
   end

   -- compute the steps from x,y to destination
   local start = prism.Vector2(x, y)
   local destination = start + direction
   local path, found = prism.Bresenham(x, y, destination.x, destination.y)

   -- Calculate duration based on mode
   if mode == "char" then
      -- rescale duration based on number of path steps
      duration = duration * #path.path
   end

   return spectrum.Animation(function(t, display)
      local index = math.floor((t * #path.path) / duration) + 1

      local step = path.path[index]

      if step then
         display:print(step.x, step.y, message, fg, bg, layer, align, width)
      end

      return t >= duration
   end)
end)
